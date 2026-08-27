package com.coderhouse.flink;

import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;

import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.connector.kinesis.source.KinesisStreamsSource;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.streaming.api.datastream.KeyedStream;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.api.common.functions.AggregateFunction;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.Map;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UrbanSensorsJob {

  private static final Logger LOG = LoggerFactory.getLogger(UrbanSensorsJob.class);

  public static void main(String[] args) throws Exception {

    // =====================================================
    // 1. Entorno de ejecución de Flink
    // =====================================================

    StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
    
    env.enableCheckpointing(60000);

    // =====================================================
    // 2. Leer propiedades de Managed Flink
    // =====================================================

    Map<String, Properties> applicationProperties = KinesisAnalyticsRuntime.getApplicationProperties();

    if (applicationProperties == null) {
      throw new RuntimeException(
          "No se pudieron obtener las propiedades de la aplicación.");
    }

    Properties flinkAppProps = applicationProperties.get("FlinkAppProperties");

    if (flinkAppProps == null) {
      throw new RuntimeException(
          "No se encontró el grupo FlinkAppProperties.");
    }

    String streamArn = flinkAppProps.getProperty("KINESIS_STREAM_ARN");

    if (streamArn == null) {
      throw new RuntimeException(
          "No se encontró la propiedad KINESIS_STREAM_ARN.");
    }

    // =====================================================
    // 3. Región AWS
    // =====================================================

    String awsRegion = streamArn.split(":")[3];

    Configuration sourceConfig = new Configuration();

    sourceConfig.setString(
        "aws.region",
        awsRegion);

    // =====================================================
    // 4. Source de Kinesis
    // =====================================================

    KinesisStreamsSource<String> source = KinesisStreamsSource.<String>builder()
        .setStreamArn(streamArn)
        .setSourceConfig(sourceConfig)
        .setDeserializationSchema(
            new SimpleStringSchema())
        .build();

    // =====================================================
    // 5. Crear DataStream desde Kinesis
    // =====================================================

    DataStream<String> rawEvents = env.fromSource(
        source,
        org.apache.flink.api.common.eventtime.WatermarkStrategy.noWatermarks(),
        "kinesis-source",
        org.apache.flink.api.common.typeinfo.TypeInformation.of(String.class));

    DataStream<SensorEvent> sensorEvents = rawEvents.map(new SensorEventMapper());

    // =====================================================
    // 6. Event Time + Watermarks
    // =====================================================

    DataStream<SensorEvent> timedEvents = sensorEvents.assignTimestampsAndWatermarks(
        WatermarkStrategy
            .<SensorEvent>forBoundedOutOfOrderness(
                Duration.ofSeconds(10))
            .withTimestampAssigner(
                (event, recordTimestamp) -> LocalDateTime
                    .parse(
                        event.getTimestamp(),
                        java.time.format.DateTimeFormatter.ofPattern(
                            "yyyy-MM-dd HH:mm:ss"))
                    .toInstant(ZoneOffset.UTC)
                    .toEpochMilli()));

    // =====================================================
    // 7. Mostrar eventos
    // =====================================================

    timedEvents.print();

    // =====================================================
    // 8. KeyBy por sensor
    // =====================================================

    KeyedStream<SensorEvent, String> keyedEvents = timedEvents.keyBy(SensorEvent::getSensorId);

    // =====================================================
    // 9. Ventana Tumbling de 1 minuto
    // =====================================================

    DataStream<SensorAggregate> aggregatedEvents = keyedEvents
      .window(
          TumblingEventTimeWindows.of(
              Duration.ofMinutes(1)))
      .aggregate(
          new SensorAggregateFunction());
    
    aggregatedEvents.print();

    aggregatedEvents.map(aggregate -> {
      LOG.info(">>> Ventana 1-min completada: {}", aggregate);
      return aggregate;
    });

    // =====================================================
    // 10. Ejecutar el Job de Flink
    // =====================================================
    env.execute("Urban Sensors Processing Job");
  }

  public static class SensorEventMapper implements MapFunction<String, SensorEvent> {

    private static final Logger MAPPER_LOG = LoggerFactory.getLogger(SensorEventMapper.class);
    private transient ObjectMapper objectMapper;

    @Override
    public SensorEvent map(String value) throws Exception {

      if (objectMapper == null) {
        objectMapper = new ObjectMapper();
      }

      SensorEvent event = objectMapper.readValue(
          value,
          SensorEvent.class);

      MAPPER_LOG.info(">>> Evento recibido de Kinesis: {}", event);

      return event;
    }
  }

  public static class SensorAccumulator {

    private String sensorId;

    private double temperatureSum;

    private double airQualitySum;

    private long count;
  }

  public static class SensorAggregateFunction
      implements AggregateFunction<SensorEvent, SensorAccumulator, SensorAggregate> {

    @Override
    public SensorAccumulator createAccumulator() {
      return new SensorAccumulator();
    }

    @Override
    public SensorAccumulator add(
        SensorEvent event,
        SensorAccumulator accumulator) {

      accumulator.sensorId = event.getSensorId();

      accumulator.temperatureSum += event.getTemperature();

      accumulator.airQualitySum += event.getAirQualityIndex();

      accumulator.count++;

      return accumulator;
    }

    @Override
    public SensorAggregate getResult(
        SensorAccumulator accumulator) {

      double avgTemperature = accumulator.count == 0
          ? 0
          : accumulator.temperatureSum / accumulator.count;

      double avgAirQuality = accumulator.count == 0
          ? 0
          : accumulator.airQualitySum / accumulator.count;

      return new SensorAggregate(
          accumulator.sensorId,
          avgTemperature,
          avgAirQuality,
          accumulator.count);
    }

    @Override
    public SensorAccumulator merge(
        SensorAccumulator a,
        SensorAccumulator b) {

      SensorAccumulator merged = new SensorAccumulator();

      merged.sensorId = a.sensorId != null
          ? a.sensorId
          : b.sensorId;

      merged.temperatureSum = a.temperatureSum + b.temperatureSum;

      merged.airQualitySum = a.airQualitySum + b.airQualitySum;

      merged.count = a.count + b.count;

      return merged;
    }
  }
}