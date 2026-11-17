-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- Fase 4 - Script 07: EXPLAIN (análisis de planes de ejecución)
-- Ejecutar DESPUÉS de 12_creacion_esquema_mariadb.sql (o 01_ddl.sql) y de
-- 14_carga_datos_sinteticos_mariadb.sql (10.000 asignaciones, 3.340 inspecciones).
--
-- Cómo leer cada plan (columnas de EXPLAIN):
--   type          : ALL = recorre toda la tabla | ref/range = usa un índice
--   possible_keys : índices que el optimizador podría usar
--   key           : índice que realmente usó (NULL = ninguno)
--   rows          : filas que estima revisar (menos es mejor)
--   Extra         : Using where, Using index, Using temporary, Using filesort...
--
-- NOTA: con 10.000 filas el optimizador debería preferir los índices en E1 y E3;
-- en E2 (60 filas) puede elegir ALL porque leer la tabla entera es barato.
-- Por eso cada consulta se ejecuta dos veces: normal y con IGNORE INDEX, para
-- comparar. Peguen la salida real de SU servidor en la memoria técnica
-- y escriban la interpretación con esos números.
-- =====================================================================
USE setp_santa_marta;

-- ---------------------------------------------------------------------
-- E1. Vehículos de una ruta, fecha y turno (índice idx_asig_ruta_fecha_turno)
-- Qué se espera ver: con el índice, type = ref, key = idx_asig_ruta_fecha_turno
-- y muy pocas filas estimadas (la consulta devuelve 4 filas reales); sin el índice,
-- type = ALL con ~10.000 filas.
-- ---------------------------------------------------------------------
EXPLAIN SELECT id_vehiculo
FROM asignacion
WHERE id_ruta = 8 AND fecha = '2026-01-02' AND turno = 'MANANA';

EXPLAIN SELECT id_vehiculo
FROM asignacion IGNORE INDEX (idx_asig_ruta_fecha_turno)
WHERE id_ruta = 8 AND fecha = '2026-01-02' AND turno = 'MANANA';

-- Tiempos y filas reales (MariaDB): compara "rows" estimadas con las leídas.
ANALYZE SELECT id_vehiculo
FROM asignacion
WHERE id_ruta = 8 AND fecha = '2026-01-02' AND turno = 'MANANA';

-- ---------------------------------------------------------------------
-- E2. Paraderos habilitados de una zona (índice idx_paradero_zona_hab)
-- Qué se espera ver: con el índice, key = idx_paradero_zona_hab; sin él,
-- type = ALL con ~60 filas. La zona 35 tiene 4 paraderos habilitados.
-- ---------------------------------------------------------------------
EXPLAIN SELECT id_paradero, nombre
FROM paradero
WHERE id_zona = 35 AND habilitado = 1;

EXPLAIN SELECT id_paradero, nombre
FROM paradero IGNORE INDEX (idx_paradero_zona_hab)
WHERE id_zona = 35 AND habilitado = 1;

-- ---------------------------------------------------------------------
-- E3. Inspecciones de una empresa en un rango de fechas (idx_insp_empresa_fecha)
-- Qué se espera ver: con el índice, type = range o ref sobre
-- idx_insp_empresa_fecha (igualdad en id_empresa + rango en fecha);
-- sin él, type = ALL con ~3.340 filas. La empresa 1 tiene 10 inspecciones en ese rango.
-- ---------------------------------------------------------------------
EXPLAIN SELECT id_inspeccion, fecha
FROM inspeccion
WHERE id_empresa = 1 AND fecha BETWEEN '2026-04-01' AND '2026-08-31';

EXPLAIN SELECT id_inspeccion, fecha
FROM inspeccion IGNORE INDEX (idx_insp_empresa_fecha)
WHERE id_empresa = 1 AND fecha BETWEEN '2026-04-01' AND '2026-08-31';

-- ---------------------------------------------------------------------
-- E4. Vista de cobertura (consulta con 2 LEFT JOIN y GROUP BY)
-- Qué se espera ver: en la tabla zona, type = ALL (hay que recorrer todas
-- las zonas: es lo correcto porque se quiere el resultado de todas). En
-- paradero, uso de idx_paradero_zona_hab (ref por id_zona) y en
-- ruta_paradero, uso del índice de la FK sobre id_paradero (ref).
-- Probablemente aparezca "Using temporary" por el GROUP BY: es esperable
-- y aceptable con 50 zonas.
-- ---------------------------------------------------------------------
EXPLAIN SELECT * FROM v_cobertura_zonas WHERE cobertura = 'SIN COBERTURA';

-- ---------------------------------------------------------------------
-- E5. Índices existentes por tabla (evidencia para el apartado de optimización)
-- ---------------------------------------------------------------------
SHOW INDEX FROM asignacion;
SHOW INDEX FROM paradero;
SHOW INDEX FROM inspeccion;
