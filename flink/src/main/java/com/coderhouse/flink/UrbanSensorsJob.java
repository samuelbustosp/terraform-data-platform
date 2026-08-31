package com.coderhouse.flink;

import com.amazonaws.services.kinesisanalytics.runtime.KinesisAnalyticsRuntime;

import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.serialization.SimpleStringSchema;
import org.apache.flink.connector.kinesis.source.KinesisStreamsSource;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.streaming.api.datastream.KeyedStream;
import org.apache.flink.streaming.api.windowing.assigners.TumblingProcessingTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.api.common.functions.AggregateFunction;
import org.apache.flink.table.data.GenericRowData;
import org.apache.flink.table.data.RowData;
import org.apache.flink.table.data.StringData;

import org.apache.iceberg.Schema;
import org.apache.iceberg.catalog.Catalog;
import org.apache.iceberg.catalog.TableIdentifier;
import org.apache.iceberg.flink.CatalogLoader;
import org.apache.iceberg.flink.TableLoader;
import org.apache.iceberg.flink.sink.FlinkSink;
import org.apache.iceberg.types.Types;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UrbanSensorsJob {

  private static final Logger LOG = LoggerFactory.getLogger(UrbanSensorsJob.class);

  public static void main(String[] args) throws Exception {

    // =====================================================
    // 1. Entorno de ejecución de Flink y Checkpointing
    // =====================================================
    StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
    // 1 minuto de checkpointing, requerido para que Iceberg confirme (commit) los metadatos
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
    String lakehouseBucket = flinkAppProps.getProperty("LAKEHOUSE_BUCKET");

    if (streamArn == null || lakehouseBucket == null) {
      throw new RuntimeException(
          "Faltan propiedades en FlinkAppProperties: KINESIS_STREAM_ARN o LAKEHOUSE_BUCKET");
    }

    // =====================================================
    // 3. Región AWS
    // =====================================================
    String awsRegion = streamArn.split(":")[3];

    org.apache.flink.configuration.Configuration sourceConfig =
        new org.apache.flink.configuration.Configuration();
    sourceConfig.setString("aws.region", awsRegion);

    // =====================================================
    // 4. Source de Kinesis
    // =====================================================
    KinesisStreamsSource<String> source = KinesisStreamsSource.<String>builder()
        .setStreamArn(streamArn)
        .setSourceConfig(sourceConfig)
        .setDeserializationSchema(new SimpleStringSchema())
        .build();

    // =====================================================
    // 5. Crear DataStream desde Kinesis
    // =====================================================
    DataStream<String> rawEvents = env.fromSource(
        source,
        WatermarkStrategy.noWatermarks(),
        "kinesis-source",
        org.apache.flink.api.common.typeinfo.TypeInformation.of(String.class));

    DataStream<SensorEvent> sensorEvents = rawEvents.map(new SensorEventMapper());

    // =====================================================
    // 6. KeyBy por sensor y Ventana Tumbling de 1 minuto
    // =====================================================
    KeyedStream<SensorEvent, String> keyedEvents = sensorEvents.keyBy(SensorEvent::getSensorId);

    DataStream<SensorAggregate> aggregatedEvents = keyedEvents
        .window(TumblingProcessingTimeWindows.of(Time.minutes(1)))
        .aggregate(new SensorAggregateFunction());

    aggregatedEvents.print();

    // =====================================================
    // 7. Configuración del Catálogo Glue para Iceberg
    // =====================================================
    Map<String, String> catalogProps = new HashMap<>();
    catalogProps.put("type", "iceberg");
    catalogProps.put("catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog");
    catalogProps.put("warehouse", "s3://" + lakehouseBucket + "/lakehouse/");
    catalogProps.put("io-impl", "org.apache.iceberg.aws.s3.S3FileIO");

    CatalogLoader catalogLoader = CatalogLoader.custom(
        "glue_catalog",
        catalogProps,
        new org.apache.hadoop.conf.Configuration(),
        "org.apache.iceberg.aws.glue.GlueCatalog"
    );

    // Base de datos creada en Terraform y nombre de la tabla Iceberg
    TableIdentifier tableId = TableIdentifier.of("lakehouse_db", "sensor_aggregates");

    // =====================================================
    // 8. Crear la tabla Iceberg en Glue si no existe
    // =====================================================
    Catalog catalog = catalogLoader.loadCatalog();
    if (!catalog.tableExists(tableId)) {
      Schema schema = new Schema(
          Types.NestedField.required(1, "sensor_id", Types.StringType.get()),
          Types.NestedField.required(2, "avg_temperature", Types.DoubleType.get()),
          Types.NestedField.required(3, "avg_air_quality", Types.DoubleType.get()),
          Types.NestedField.required(4, "event_count", Types.LongType.get()),
          Types.NestedField.required(5, "event_time_millis", Types.LongType.get())
      );
      catalog.createTable(tableId, schema);
      LOG.info(">>> Tabla Iceberg '{}' creada exitosamente en Glue Catalog.", tableId);
    }

    TableLoader tableLoader = TableLoader.fromCatalog(catalogLoader, tableId);

    // =====================================================
    // 9. Convertir a RowData y escribir con Iceberg Sink
    // =====================================================
    DataStream<RowData> rowDataStream = aggregatedEvents.map(new ToRowDataMapper());

    FlinkSink.forRowData(rowDataStream)
        .tableLoader(tableLoader)
        .append();

    // =====================================================
    // 10. Ejecutar el Job de Flink
    // =====================================================
    env.execute("Urban Sensors Lakehouse Processing Job");
  }

  public static class SensorEventMapper implements MapFunction<String, SensorEvent> {

    private static final Logger MAPPER_LOG = LoggerFactory.getLogger(SensorEventMapper.class);
    private transient ObjectMapper objectMapper;

    @Override
    public SensorEvent map(String value) throws Exception {
      if (objectMapper == null) {
        objectMapper = new ObjectMapper();
      }

      SensorEvent event = objectMapper.readValue(value, SensorEvent.class);
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
    public SensorAccumulator add(SensorEvent event, SensorAccumulator accumulator) {
      accumulator.sensorId = event.getSensorId();
      accumulator.temperatureSum += event.getTemperature();
      accumulator.airQualitySum += event.getAirQualityIndex();
      accumulator.count++;
      return accumulator;
    }

    @Override
    public SensorAggregate getResult(SensorAccumulator accumulator) {
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
    public SensorAccumulator merge(SensorAccumulator a, SensorAccumulator b) {
      SensorAccumulator merged = new SensorAccumulator();
      merged.sensorId = a.sensorId != null ? a.sensorId : b.sensorId;
      merged.temperatureSum = a.temperatureSum + b.temperatureSum;
      merged.airQualitySum = a.airQualitySum + b.airQualitySum;
      merged.count = a.count + b.count;
      return merged;
    }
  }

  public static class ToRowDataMapper implements MapFunction<SensorAggregate, RowData> {
    @Override
    public RowData map(SensorAggregate agg) {
      GenericRowData row = new GenericRowData(5);
      row.setField(0, StringData.fromString(agg.getSensorId()));
      row.setField(1, agg.getAvgTemperature());
      row.setField(2, agg.getAvgAirQuality());
      row.setField(3, agg.getEventCount());
      row.setField(4, System.currentTimeMillis());
      return row;
    }
  }
}