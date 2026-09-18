-- =============================================================================
-- CAPSTONE FINAL: SISTEMA DE STREAMING END-TO-END
-- Motor: Amazon Redshift (Streaming Ingestion + Redshift Spectrum Iceberg)
-- Autor: Samuel Bustos Puntis
-- =============================================================================

-- INSTRUCCIÓN DE REPRODUCIBILIDAD:
-- Reemplaza '<TU_ACCOUNT_ID>' por tu ID de cuenta de AWS (ej: 985879611495)
-- o el ID de la cuenta donde se despliegue el stack de Terraform.

-- =============================================================================
-- FASE 1: REDSHIFT STREAMING INGESTION (RSI) - KINESIS DATA STREAMS
-- =============================================================================

-- 1.1 Crear esquema externo apuntando al stream de Kinesis
CREATE EXTERNAL SCHEMA IF NOT EXISTS kinesis_stream_schema
FROM KINESIS
IAM_ROLE 'arn:aws:iam::<TU_ACCOUNT_ID>:role/pre-entrega1-dev-redshift-role';

-- 1.2 Crear Materialized View en tiempo real
-- Maneja Schema Drift con CAN_JSON_PARSE y almacena el payload en tipo SUPER
CREATE MATERIALIZED VIEW mv_sensor_telemetry_stream
AS
SELECT
    approximate_arrival_timestamp,
    partition_key,
    shard_id,
    sequence_number,
    -- Campos fuertemente tipados
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'sensor_id')::VARCHAR(50) AS sensor_id,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'timestamp')::VARCHAR(30) AS event_timestamp,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'temperature')::FLOAT8   AS temperature,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'humidity')::FLOAT8      AS humidity,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'air_quality_index')::INT AS air_quality_index,
    -- Objeto JSON crudo para absorber atributos futuros sin romper la vista
    JSON_PARSE(FROM_VARBYTE(kinesis_data, 'utf-8')) AS raw_payload
FROM kinesis_stream_schema."pre-entrega1-dev-stream"
WHERE CAN_JSON_PARSE(FROM_VARBYTE(kinesis_data, 'utf-8'));

-- 1.3 Forzar refresco manual inicial
REFRESH MATERIALIZED VIEW mv_sensor_telemetry_stream;

-- 1.4 VALIDACIÓN 1 (Pedida por el profesor):
-- Comprobar ingesta directa desde Kinesis y parseo correcto de tipos de datos
SELECT 
    sensor_id,
    event_timestamp,
    temperature,
    humidity,
    air_quality_index,
    approximate_arrival_timestamp
FROM mv_sensor_telemetry_stream
ORDER BY approximate_arrival_timestamp DESC
LIMIT 10;


-- =============================================================================
-- FASE 2: INTEGRACIÓN LAKEHOUSE - GLUE DATA CATALOG (APACHE ICEBERG)
-- =============================================================================

-- 2.1 Crear esquema externo apuntando a la base de datos de Glue (Iceberg)
CREATE EXTERNAL SCHEMA IF NOT EXISTS lakehouse_catalog
FROM DATA CATALOG
DATABASE 'lakehouse_db'
IAM_ROLE 'arn:aws:iam::<TU_ACCOUNT_ID>:role/pre-entrega1-dev-redshift-role'
REGION 'us-east-1';

-- 2.2 VALIDACIÓN 2 (Pedida por el profesor):
-- Comprobar por separado la lectura de los agregados generados por Flink en S3 Iceberg
SELECT 
    sensor_id,
    avg_temperature,
    avg_air_quality,
    event_count,
    event_time_millis
FROM lakehouse_catalog.sensor_aggregates
LIMIT 10;


-- =============================================================================
-- FASE 3: CONSULTA HÍBRIDA / JOIN FEDERADO (STREAM + ICEBERG)
-- =============================================================================

-- 3.1 VALIDACIÓN 3:
-- Cruce analítico: compara la lectura en tiempo real del sensor (Stream)
-- contra su promedio histórico consolidado (Lakehouse Iceberg)
SELECT
    s.sensor_id,
    s.event_timestamp                                              AS real_time_timestamp,
    s.temperature                                                  AS real_time_temperature,
    h.avg_temperature                                              AS historical_avg_temp,
    ROUND((s.temperature - h.avg_temperature)::NUMERIC, 2)        AS temp_deviation,
    s.air_quality_index                                            AS real_time_aqi,
    h.avg_air_quality                                              AS historical_avg_aqi,
    ROUND((s.air_quality_index - h.avg_air_quality)::NUMERIC, 2)   AS aqi_deviation
FROM mv_sensor_telemetry_stream s
INNER JOIN lakehouse_catalog.sensor_aggregates h
    ON s.sensor_id = h.sensor_id
ORDER BY s.approximate_arrival_timestamp DESC
LIMIT 50;


-- =============================================================================
-- FASE 4: POLÍTICA DE REFRESCO, MONITOREO Y GOBERNANZA RBAC
-- =============================================================================

-- 4.1 Definición del mecanismo de refresco:
-- Modo: Programado (Scheduled) vía EventBridge / Airflow / dbt o bajo demanda en sesión analítica.
-- Frecuencia objetivo en producción: Cada 60 segundos.
-- Comando de refresco:
REFRESH MATERIALIZED VIEW mv_sensor_telemetry_stream;

-- 4.2 Monitoreo del estado y tiempo de último refresco de la vista
SELECT 
    database_name,
    schema_name,
    name,
    refresh_type,
    state,
    last_refresh_time
FROM SVV_MV_INFO
WHERE name = 'mv_sensor_telemetry_stream';

-- 4.3 Monitoreo del lag de lectura sobre los shards de Kinesis
SELECT 
    stream_name,
    shard_id,
    sequence_number,
    status
FROM SYS_STREAM_SCAN_STATES
LIMIT 10;

-- 4.4 Seguridad y Principio de Mínimo Privilegio (RBAC)
CREATE ROLE analytics_role;
GRANT USAGE ON SCHEMA public TO ROLE analytics_role;
GRANT SELECT ON mv_sensor_telemetry_stream TO ROLE analytics_role;
GRANT USAGE ON SCHEMA lakehouse_catalog TO ROLE analytics_role;
GRANT SELECT ON ALL TABLES IN SCHEMA lakehouse_catalog TO ROLE analytics_role;