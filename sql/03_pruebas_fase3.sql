-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- Fase 3 - Script 03: Pruebas de integridad (casos válidos e inválidos)
-- Ejecutar DESPUÉS de 12_creacion_esquema_mariadb.sql (o 01_ddl.sql) y de
-- 14_carga_datos_sinteticos_mariadb.sql, y ANTES de 05_procedimientos_triggers.sql
-- (con los triggers ya creados, P7 y P14 pueden fallar con otro error).
-- Cada prueba inválida debe FALLAR: ejecútenlas una por una (en phpMyAdmin
-- seleccionen la sentencia y den "Continuar"), y capturen el mensaje de error.
-- =====================================================================
USE setp_santa_marta;

-- ---------------------------------------------------------------------
-- P0. Conteo de registros por tabla (evidencia del mínimo de 50)
-- ---------------------------------------------------------------------
SELECT 'empresa_operadora' AS tabla, COUNT(*) AS registros FROM empresa_operadora
UNION ALL SELECT 'vehiculo',           COUNT(*) FROM vehiculo
UNION ALL SELECT 'zona',               COUNT(*) FROM zona
UNION ALL SELECT 'paradero',           COUNT(*) FROM paradero
UNION ALL SELECT 'ruta',               COUNT(*) FROM ruta
UNION ALL SELECT 'ruta_paradero',      COUNT(*) FROM ruta_paradero
UNION ALL SELECT 'asignacion',         COUNT(*) FROM asignacion
UNION ALL SELECT 'responsable',        COUNT(*) FROM responsable
UNION ALL SELECT 'inspeccion',         COUNT(*) FROM inspeccion
UNION ALL SELECT 'inspeccion_detalle', COUNT(*) FROM inspeccion_detalle
UNION ALL SELECT 'reporte_ilegal',     COUNT(*) FROM reporte_ilegal
UNION ALL SELECT 'auditoria',          COUNT(*) FROM auditoria;
-- Esperado: 50, 120, 50, 60, 50, 296, 10000, 50, 3340, 10000, 200 y 0 (auditoria).

-- ---------------------------------------------------------------------
-- P1. INSERCIÓN VÁLIDA (se revierte para no alterar los datos)
-- Esperado: 1 fila insertada y visible en el SELECT; luego ROLLBACK.
-- ---------------------------------------------------------------------
START TRANSACTION;
INSERT INTO empresa_operadora (nit, nombre) VALUES ('900999999-9', 'Transportes Prueba S.A.S.');
SELECT * FROM empresa_operadora WHERE nit = '900999999-9';   -- estado = 'ACTIVA' (DEFAULT)
ROLLBACK;

-- ---------------------------------------------------------------------
-- P2. UNIQUE: placa duplicada
-- Esperado: ERROR 1062 (23000): Duplicate entry ... for key 'uq_vehiculo_placa'
-- ---------------------------------------------------------------------
INSERT INTO vehiculo (id_empresa, placa, capacidad)
SELECT 1, placa, 30 FROM vehiculo WHERE id_vehiculo = 1;

-- ---------------------------------------------------------------------
-- P3. CHECK: capacidad negativa
-- Esperado: ERROR 4025 (23000): CONSTRAINT `ck_vehiculo_capacidad` failed
-- ---------------------------------------------------------------------
INSERT INTO vehiculo (id_empresa, placa, capacidad) VALUES (1, 'ZZZ999', -5);

-- ---------------------------------------------------------------------
-- P4. CHECK: turno fuera del dominio
-- Esperado: ERROR 4025 (23000): CONSTRAINT `ck_asig_turno` failed
-- ---------------------------------------------------------------------
INSERT INTO asignacion (id_vehiculo, id_ruta, fecha, turno, hora_inicio, hora_fin)
VALUES (1, 1, '2026-11-20', 'MADRUGADA', '04:00:00', '08:00:00');

-- ---------------------------------------------------------------------
-- P5. RN4 (CHECK): hora_fin menor que hora_inicio
-- Esperado: ERROR 4025 (23000): CONSTRAINT `ck_asig_horas` failed
-- ---------------------------------------------------------------------
INSERT INTO asignacion (id_vehiculo, id_ruta, fecha, turno, hora_inicio, hora_fin)
VALUES (1, 1, '2026-11-20', 'MANANA', '12:00:00', '06:00:00');

-- ---------------------------------------------------------------------
-- P6. RN1 (UNIQUE): mismo vehículo, misma fecha y turno en otra ruta
-- Primero se toma una asignación existente; luego se intenta duplicar su
-- vehículo, fecha y turno con otra ruta.
-- Esperado: ERROR 1062 (23000): Duplicate entry ... for key 'uq_asig_vehiculo_fecha_turno'
-- ---------------------------------------------------------------------
INSERT INTO asignacion (id_vehiculo, id_ruta, fecha, turno, hora_inicio, hora_fin)
SELECT id_vehiculo, 1, fecha, turno, hora_inicio, hora_fin
FROM asignacion WHERE id_asignacion = 1;

-- ---------------------------------------------------------------------
-- P7. RN3 (UNIQUE compuesto): orden repetido dentro de una ruta
-- Esperado: ERROR 1062 (23000): Duplicate entry ... for key 'uq_ruta_orden'
-- (se usa un paradero que no esté en la ruta 1 para aislar este error)
-- ---------------------------------------------------------------------
INSERT INTO ruta_paradero (id_ruta, id_paradero, orden)
SELECT 1, p.id_paradero, 1
FROM paradero p
WHERE p.id_paradero NOT IN (SELECT id_paradero FROM ruta_paradero WHERE id_ruta = 1)
LIMIT 1;

-- ---------------------------------------------------------------------
-- P8. RN5 (CHECK): total de reportes negativo
-- Esperado: ERROR 4025 (23000): CONSTRAINT `ck_reporte_total` failed
-- ---------------------------------------------------------------------
INSERT INTO reporte_ilegal (id_zona, anio, mes, total_reportes) VALUES (1, 2026, 11, -3);

-- ---------------------------------------------------------------------
-- P9. CHECK: mes fuera de rango
-- Esperado: ERROR 4025 (23000): CONSTRAINT `ck_reporte_mes` failed
-- ---------------------------------------------------------------------
INSERT INTO reporte_ilegal (id_zona, anio, mes, total_reportes) VALUES (1, 2026, 13, 5);

-- ---------------------------------------------------------------------
-- P10. RN5 (UNIQUE): un solo reporte por zona y periodo
-- Esperado: ERROR 1062 (23000): Duplicate entry ... for key 'uq_reporte_zona_periodo'
-- ---------------------------------------------------------------------
INSERT INTO reporte_ilegal (id_zona, anio, mes, total_reportes) VALUES (1, 2026, 7, 10);

-- ---------------------------------------------------------------------
-- P11. FK: vehículo con empresa inexistente
-- Esperado: ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
-- ---------------------------------------------------------------------
INSERT INTO vehiculo (id_empresa, placa, capacidad) VALUES (9999, 'QQQ111', 30);

-- ---------------------------------------------------------------------
-- P12. RN6 (RESTRICT): borrar una empresa que tiene vehículos
-- Esperado: ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails
-- ---------------------------------------------------------------------
DELETE FROM empresa_operadora WHERE id_empresa = 1;

-- ---------------------------------------------------------------------
-- P13. RN7 (CHECK): resultado de inspección fuera del dominio
-- Esperado: ERROR 4025 (23000): CONSTRAINT `ck_det_resultado` failed
-- ---------------------------------------------------------------------
INSERT INTO inspeccion_detalle (id_inspeccion, condicion, resultado) VALUES (1, 'LABORAL', 'TAL_VEZ');

-- ---------------------------------------------------------------------
-- P14. CASCADE justificado: borrar una ruta sin asignaciones elimina sus paraderos
-- (se revierte). Esperado: ruta_paradero de esa ruta pasa de N filas a 0.
-- ---------------------------------------------------------------------
START TRANSACTION;
INSERT INTO ruta (codigo, nombre) VALUES ('R99', 'Ruta de prueba');
INSERT INTO ruta_paradero (id_ruta, id_paradero, orden)
SELECT LAST_INSERT_ID(), id_paradero, 1 FROM paradero LIMIT 1;
SELECT COUNT(*) AS filas_antes FROM ruta_paradero rp JOIN ruta r ON r.id_ruta = rp.id_ruta WHERE r.codigo = 'R99';
DELETE FROM ruta WHERE codigo = 'R99';
SELECT COUNT(*) AS filas_despues FROM ruta_paradero rp JOIN ruta r ON r.id_ruta = rp.id_ruta WHERE r.codigo = 'R99';
ROLLBACK;
