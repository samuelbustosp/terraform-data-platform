package com.coderhouse.flink;

import java.io.Serializable;

public class SensorAggregate implements Serializable {

    private String sensorId;
    private double avgTemperature;
    private double avgAirQuality;
    private long eventCount;

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

    @Override
    public String toString() {
        return "SensorAggregate{" +
                "sensorId='" + sensorId + '\'' +
                ", avgTemperature=" + avgTemperature +
                ", avgAirQuality=" + avgAirQuality +
                ", eventCount=" + eventCount +
                '}';
    }
}