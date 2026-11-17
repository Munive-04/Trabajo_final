-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- 13_verificaciones_estructura_mariadb.sql
-- ---------------------------------------------------------------------
-- Consultas de solo lectura sobre el catálogo (INFORMATION_SCHEMA). No
-- modifican nada. Ejecútelas DOS veces y conserve las capturas:
--   ANTES : sobre la base actual (creada con 01_ddl.sql).
--   DESPUÉS: tras recrear la base con 12_creacion_esquema_mariadb.sql.
-- Con los resultados complete 13a_comparacion_documental.md.
-- Estado: PROBADO EN SGBD (MariaDB/XAMPP), según reporte del equipo (13-nov-2026): ejecutado sin errores y con resultados coincidentes con los esperados. Conserve las capturas.
-- Opción: mysql -u root -t --default-character-set=utf8mb4 < este_archivo.sql
-- =====================================================================
USE setp_santa_marta;

-- ---------------------------------------------------------------------
-- V1. Resumen de objetos y comentarios (solo tablas base, sin vistas).
-- Esperado en AMBOS momentos: tablas = 12, columnas = 56.
-- Esperado ANTES : tablas_con_comentario = 0, columnas_con_comentario = 0.
-- Esperado DESPUÉS: tablas_con_comentario = 12, columnas_con_comentario = 56.
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM information_schema.TABLES t
    WHERE t.TABLE_SCHEMA = 'setp_santa_marta' AND t.TABLE_TYPE = 'BASE TABLE') AS tablas,
  (SELECT COUNT(*) FROM information_schema.TABLES t
    WHERE t.TABLE_SCHEMA = 'setp_santa_marta' AND t.TABLE_TYPE = 'BASE TABLE'
      AND t.TABLE_COMMENT <> '') AS tablas_con_comentario,
  (SELECT COUNT(*) FROM information_schema.COLUMNS c
    JOIN information_schema.TABLES t
      ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
    WHERE c.TABLE_SCHEMA = 'setp_santa_marta' AND t.TABLE_TYPE = 'BASE TABLE') AS columnas,
  (SELECT COUNT(*) FROM information_schema.COLUMNS c
    JOIN information_schema.TABLES t
      ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
    WHERE c.TABLE_SCHEMA = 'setp_santa_marta' AND t.TABLE_TYPE = 'BASE TABLE'
      AND c.COLUMN_COMMENT <> '') AS columnas_con_comentario;

-- ---------------------------------------------------------------------
-- V2. Tablas, motor, collation y comentario.
-- Esperado: 12 filas, ENGINE = InnoDB; TABLE_COMMENT vacío ANTES, con texto DESPUÉS.
-- ---------------------------------------------------------------------
SELECT TABLE_NAME, ENGINE, TABLE_COLLATION, TABLE_COMMENT
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'setp_santa_marta' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- ---------------------------------------------------------------------
-- V3. Columnas SIN comentario (debe quedar vacío DESPUÉS).
-- Esperado ANTES: 56 filas. Esperado DESPUÉS: 0 filas.
-- ---------------------------------------------------------------------
SELECT c.TABLE_NAME, c.COLUMN_NAME
FROM information_schema.COLUMNS c
JOIN information_schema.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = 'setp_santa_marta' AND t.TABLE_TYPE = 'BASE TABLE'
  AND c.COLUMN_COMMENT = ''
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- ---------------------------------------------------------------------
-- V4. Definición de columnas (debe ser IDÉNTICA antes y después, salvo COLUMN_COMMENT).
-- Guarde la salida de ambos momentos y compárelas excluyendo la última columna.
-- ---------------------------------------------------------------------
SELECT c.TABLE_NAME, c.ORDINAL_POSITION, c.COLUMN_NAME, c.COLUMN_TYPE, c.IS_NULLABLE,
       c.COLUMN_DEFAULT, c.EXTRA, c.COLUMN_KEY, c.CHARACTER_SET_NAME, c.COLLATION_NAME,
       c.COLUMN_COMMENT
FROM information_schema.COLUMNS c
JOIN information_schema.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE c.TABLE_SCHEMA = 'setp_santa_marta' AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- ---------------------------------------------------------------------
-- V5. Conteo de restricciones por tipo.
-- Esperado (antes y después): PRIMARY KEY 12, FOREIGN KEY 10, UNIQUE 8.
-- ---------------------------------------------------------------------
SELECT CONSTRAINT_TYPE, COUNT(*) AS cantidad
FROM information_schema.TABLE_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'setp_santa_marta'
  AND CONSTRAINT_TYPE IN ('PRIMARY KEY','FOREIGN KEY','UNIQUE')
GROUP BY CONSTRAINT_TYPE;

-- V5b. Restricciones CHECK. Esperado: 18.
SELECT COUNT(*) AS checks
FROM information_schema.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'setp_santa_marta';

-- ---------------------------------------------------------------------
-- V6. Reglas de las claves foráneas.
-- Esperado: 10 filas; DELETE_RULE = CASCADE solo en fk_rp_ruta; el resto RESTRICT.
-- UPDATE_RULE = CASCADE en todas.
-- ---------------------------------------------------------------------
SELECT CONSTRAINT_NAME, TABLE_NAME, REFERENCED_TABLE_NAME, DELETE_RULE, UPDATE_RULE
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'setp_santa_marta'
ORDER BY CONSTRAINT_NAME;

-- ---------------------------------------------------------------------
-- V7. Índices adicionales.
-- Esperado: 6 índices (idx_asig_ruta_fecha_turno, idx_paradero_zona_hab,
-- idx_insp_empresa_fecha, idx_det_condicion_resultado, idx_reporte_periodo,
-- idx_vehiculo_estado).
-- ---------------------------------------------------------------------
SELECT TABLE_NAME, INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS columnas
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'setp_santa_marta' AND INDEX_NAME LIKE 'idx\_%'
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME, INDEX_NAME;

-- ---------------------------------------------------------------------
-- V8. Definición completa de cada tabla (guardar como evidencia).
-- Después debe mostrar COMMENT en cada columna y en la tabla.
-- ---------------------------------------------------------------------
SHOW CREATE TABLE empresa_operadora;
SHOW CREATE TABLE vehiculo;
SHOW CREATE TABLE zona;
SHOW CREATE TABLE paradero;
SHOW CREATE TABLE ruta;
SHOW CREATE TABLE ruta_paradero;
SHOW CREATE TABLE asignacion;
SHOW CREATE TABLE responsable;
SHOW CREATE TABLE inspeccion;
SHOW CREATE TABLE inspeccion_detalle;
SHOW CREATE TABLE reporte_ilegal;
SHOW CREATE TABLE auditoria;

-- Ejemplo de lectura de comentarios de columnas de una tabla:
SHOW FULL COLUMNS FROM vehiculo;
