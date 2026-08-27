package com.coderhouse.flink;

import java.io.Serializable;
import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class SensorEvent implements Serializable {

  @JsonProperty("sensor_id")
  @JsonAlias({"sensorId", "sensor_id"})
  private String sensorId;

  @JsonProperty("temperature")
  private double temperature;

  @JsonProperty("humidity")
  private double humidity;

  @JsonProperty("air_quality_index")
  @JsonAlias({"airQualityIndex", "air_quality_index"})
  private int airQualityIndex;

  // Timestamp original recibido desde Kinesis
  @JsonProperty("timestamp")
  private String timestamp;

  public SensorEvent() {
  }

  public SensorEvent(
      String sensorId,
      double temperature,
      double humidity,
      int airQualityIndex,
      String timestamp) {

    this.sensorId = sensorId;
    this.temperature = temperature;
    this.humidity = humidity;
    this.airQualityIndex = airQualityIndex;
    this.timestamp = timestamp;
  }

  public String getSensorId() {
    return sensorId;
  }

  public void setSensorId(String sensorId) {
    this.sensorId = sensorId;
  }

  public double getTemperature() {
    return temperature;
  }

  public void setTemperature(double temperature) {
    this.temperature = temperature;
  }

  public double getHumidity() {
    return humidity;
  }

  public void setHumidity(double humidity) {
    this.humidity = humidity;
  }

  public int getAirQualityIndex() {
    return airQualityIndex;
  }

  public void setAirQualityIndex(int airQualityIndex) {
    this.airQualityIndex = airQualityIndex;
  }

  public String getTimestamp() {
    return timestamp;
  }

  public void setTimestamp(String timestamp) {
    this.timestamp = timestamp;
  }

  @Override
  public String toString() {
    return "SensorEvent{" +
        "sensorId='" + sensorId + '\'' +
        ", temperature=" + temperature +
        ", humidity=" + humidity +
        ", airQualityIndex=" + airQualityIndex +
        ", timestamp='" + timestamp + '\'' +
        '}';
  }
}