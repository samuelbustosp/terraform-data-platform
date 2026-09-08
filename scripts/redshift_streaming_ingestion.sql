-- =============================================================================
-- PRE-ENTREGA 6: ANALÍTICA AVANZADA IN-STREAM CON REDSHIFT
-- Plataforma: Amazon Redshift + Kinesis Data Streams + Apache Iceberg
-- Autor: sbustos
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. REDSHIFT STREAMING INGESTION (RSI): VINCULAR KINESIS DATA STREAMS
-- -----------------------------------------------------------------------------
-- Se define el esquema externo mapeado directamente contra el servicio Kinesis
-- utilizando el rol IAM con permisos DescribeStream, GetRecords y GetShardIterator.
CREATE EXTERNAL SCHEMA IF NOT EXISTS kinesis_stream_schema
FROM KINESIS
IAM_ROLE 'arn:aws:iam::985879611495:role/pre-entrega1-dev-redshift-role';


-- -----------------------------------------------------------------------------
-- 2. MATERIALIZED VIEW DE TIEMPO REAL CON MODELADO JSON Y SCHEMA DRIFT RESILIENCE
-- -----------------------------------------------------------------------------
-- Se crea la vista materializada sobre el stream "pre-entrega1-dev-stream".
-- * kinesis_data viene como VARBYTE, se convierte a UTF-8 y se parsea a JSON.
-- * CAN_JSON_PARSE previene fallas si se produce Schema Drift o mensajes corruptos.
-- * Se extraen y castean tipos nativos: sensor_id, timestamp, temperature, humidity, aqi.
-- * Se almacena también el payload crudo como tipo SUPER para consultas dinámicas.
CREATE MATERIALIZED VIEW mv_sensor_telemetry_stream
AS
SELECT
    approximate_arrival_timestamp,
    partition_key,
    shard_id,
    sequence_number,
    -- Campos tipados extraídos del JSON
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'sensor_id')::VARCHAR(50) AS sensor_id,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'timestamp')::VARCHAR(30) AS event_timestamp,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'temperature')::FLOAT8   AS temperature,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'humidity')::FLOAT8      AS humidity,
    JSON_EXTRACT_PATH_TEXT(FROM_VARBYTE(kinesis_data, 'utf-8'), 'air_quality_index')::INT AS air_quality_index,
    -- Objeto JSON completo (SUPER) para absorber atributos futuros (Schema Drift)
    JSON_PARSE(FROM_VARBYTE(kinesis_data, 'utf-8')) AS raw_payload
FROM kinesis_stream_schema."pre-entrega1-dev-stream"
WHERE CAN_JSON_PARSE(FROM_VARBYTE(kinesis_data, 'utf-8'));


-- -----------------------------------------------------------------------------
-- 3. VALIDACIÓN DE INGESTA IN-STREAM
-- -----------------------------------------------------------------------------
-- Forzar refresco manual para sincronizar los últimos eventos del stream:
REFRESH MATERIALIZED VIEW mv_sensor_telemetry_stream;

-- Consulta de verificación: eventos calientes en tiempo real
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


-- -----------------------------------------------------------------------------
-- 4. INTEGRACIÓN LAKEHOUSE: EXTERNAL SCHEMA HACIA GLUE CATALOG (APACHE ICEBERG)
-- -----------------------------------------------------------------------------
-- Conecta Redshift directamente a la base de datos de Glue donde residen
-- las tablas Iceberg generadas en las entregas anteriores.
CREATE EXTERNAL SCHEMA IF NOT EXISTS lakehouse_catalog
FROM DATA CATALOG
DATABASE 'lakehouse_db'
IAM_ROLE 'arn:aws:iam::985879611495:role/pre-entrega1-dev-redshift-role'
REGION 'us-east-1';

-- Consulta de validación de la tabla Iceberg histórica:
SELECT 
    sensor_id,
    avg_temperature,
    avg_air_quality,
    event_count,
    event_time_millis
FROM lakehouse_catalog.sensor_aggregates
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 5. CONSULTA FEDERADA / JOIN HÍBRIDO (STREAM CALIENTE + HISTÓRICO ICEBERG)
-- -----------------------------------------------------------------------------
-- Cruce analítico unificado: compara la lectura en tiempo real del sensor (Stream)
-- contra su promedio histórico consolidado en la tabla Iceberg (Lakehouse).
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


-- -----------------------------------------------------------------------------
-- 6. SEGURIDAD Y GOBERNANZA RBAC (ROL ANALYTICS - LEAST PRIVILEGE)
-- -----------------------------------------------------------------------------
-- Se crea un rol de base de datos específico para el equipo de analítica
-- con acceso de solo lectura restringido exclusivamente a la MV y al Lakehouse.
CREATE ROLE analytics_role;

-- Acceso a la vista materializada en el esquema público
GRANT USAGE ON SCHEMA public TO ROLE analytics_role;
GRANT SELECT ON mv_sensor_telemetry_stream TO ROLE analytics_role;

-- Acceso al catálogo externo Iceberg
GRANT USAGE ON SCHEMA lakehouse_catalog TO ROLE analytics_role;
GRANT SELECT ON ALL TABLES IN SCHEMA lakehouse_catalog TO ROLE analytics_role;


-- -----------------------------------------------------------------------------
-- 7. MONITOREO DE LATENCIA Y LAG DE CONSUMO
-- -----------------------------------------------------------------------------
-- Métrica de lag y estado de lectura de shards en Kinesis:
SELECT * 
FROM SYS_STREAM_SCAN_STATES 
LIMIT 10;

-- Métrica de estado y automatización de la Materialized View:
SELECT
    database_name,
    schema_name,
    name,
    autorefresh,
    refresh_type,
    state,
    last_refresh_time
FROM SVV_MV_INFO
WHERE name = 'mv_sensor_telemetry_stream';