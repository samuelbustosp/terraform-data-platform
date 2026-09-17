package com.coderhouse.flink;

import java.io.Serializable;

public class SensorAggregate implements Serializable {

    private String sensorId;
    private double avgTemperature;
    private double avgAirQuality;
    private long eventCount;
    private long eventTimeMillis;

    public SensorAggregate() {
    }

    public SensorAggregate(
            String sensorId,
            double avgTemperature,
            double avgAirQuality,
            long eventCount) {

        this.sensorId = sensorId;
        this.avgTemperature = avgTemperature;
        this.avgAirQuality = avgAirQuality;
        this.eventCount = eventCount;
    }

    public SensorAggregate(
            String sensorId,
            double avgTemperature,
            double avgAirQuality,
            long eventCount,
            long eventTimeMillis) {

        this.sensorId = sensorId;
        this.avgTemperature = avgTemperature;
        this.avgAirQuality = avgAirQuality;
        this.eventCount = eventCount;
        this.eventTimeMillis = eventTimeMillis;
    }

    public String getSensorId() {
        return sensorId;
    }

    public double getAvgTemperature() {
        return avgTemperature;
    }

    public double getAvgAirQuality() {
        return avgAirQuality;
    }

    public long getEventCount() {
        return eventCount;
    }

    public long getEventTimeMillis() {
        return eventTimeMillis;
    }

    public void setEventTimeMillis(long eventTimeMillis) {
        this.eventTimeMillis = eventTimeMillis;
    }

    @Override
    public String toString() {
        return "SensorAggregate{" +
                "sensorId='" + sensorId + '\'' +
                ", avgTemperature=" + avgTemperature +
                ", avgAirQuality=" + avgAirQuality +
                ", eventCount=" + eventCount +
                ", eventTimeMillis=" + eventTimeMillis +
                '}';
    }
}