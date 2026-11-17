-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- Fase 4 - Script 06: Matriz de pruebas (vistas, UDF, procedimientos, triggers)
-- Ejecutar DESPUÉS de 04 y 05. Pensado para el cliente mysql de XAMPP, para
-- que las variables @ persistan entre sentencias:
--   mysql -u root -t --force --default-character-set=utf8mb4 < 06_pruebas_fase4.sql
-- (--force sigue después de cada error esperado; -t muestra tablas).
-- Los "Esperado" se calcularon (en SQLite, no en MariaDB) con los datos de
-- 14_carga_datos_sinteticos_mariadb.sql, sin alterarlos.
-- =====================================================================
USE setp_santa_marta;

-- =====================================================================
-- A. VISTAS ANALÍTICAS
-- =====================================================================

-- TV1. Vehículos por ruta y turno (ruta R01).
-- Esperado (detalle): 3 filas entre 2026-10-01 y 2026-10-07 (2 MANANA y 1 NOCHE).
-- Esperado (resumen de todo el periodo): MANANA 91, TARDE 93, NOCHE 48 (232 en total).
SELECT * FROM v_flota_por_ruta_turno
WHERE codigo_ruta = 'R01' AND fecha BETWEEN '2026-10-01' AND '2026-10-07' ORDER BY fecha, turno;
SELECT turno, COUNT(*) AS asignaciones FROM v_flota_por_ruta_turno
WHERE codigo_ruta = 'R01' GROUP BY turno;

-- TV2. Proporción de flota accesible (global, sobre flota no retirada).
-- Esperado: total_flota 116, accesibles 42, pct 36.21.
SELECT SUM(total_flota) AS total_flota,
       SUM(vehiculos_accesibles) AS accesibles,
       ROUND(100 * SUM(vehiculos_accesibles) / SUM(total_flota), 2) AS pct_accesible
FROM v_flota_accesible_empresa;

-- TV3. Cobertura por zona.
-- Esperado: CON COBERTURA = 36, SIN COBERTURA = 14.
SELECT cobertura, COUNT(*) AS zonas FROM v_cobertura_zonas GROUP BY cobertura;
SELECT zona, total_paraderos, paraderos_habilitados, paraderos_en_ruta
FROM v_cobertura_zonas WHERE cobertura = 'SIN COBERTURA' ORDER BY zona;

-- TV4. Cumplimiento por empresa.
-- Esperado: CUMPLE 15, CUMPLE PARCIALMENTE 14, NO CUMPLE 18, SIN INSPECCIONES 3.
SELECT clasificacion, COUNT(*) AS empresas FROM v_cumplimiento_empresa GROUP BY clasificacion;
-- Empresa 1: 31 inspecciones, 93 condiciones evaluadas, 43 cumple, pct 46.24, NO CUMPLE.
SELECT * FROM v_cumplimiento_empresa WHERE id_empresa = 1;

-- TV5. Puntos de transbordo.
-- Esperado: 8 terminales, todas con permite_transbordo = SI. rutas_activas por
-- terminal: Antonio Nariño 11, Quinta de San Pedro 4, Los Naranjos 12,
-- El Rodadero 12, Pescaíto 10, Troncal Sur 4, Los Trupillos 7, Curinca 13.
SELECT terminal, zona, rutas_activas, permite_transbordo, rutas FROM v_puntos_transbordo ORDER BY id_paradero;

-- TV6. Tendencia de transporte ilegal.
-- Esperado: (2026,7) 748 NULL | (2026,8) 667 -81 | (2026,9) 699 +32 | (2026,10) 693 -6;
-- 50 zonas reportadas cada mes.
SELECT * FROM v_tendencia_ilegal ORDER BY anio, mes;

-- TV7. Resumen general.
-- Esperado: 46, 108, 36.21, 47, 54, 14, 65.04.
SELECT * FROM v_resumen_general;

-- =====================================================================
-- B. FUNCIONES (UDF)
-- =====================================================================

-- TF1. fn_vehiculo_accesible. Esperado: 1, 0, 0, 0.
SELECT fn_vehiculo_accesible(1,1) AS rampa_y_silla,
       fn_vehiculo_accesible(1,0) AS solo_rampa,
       fn_vehiculo_accesible(0,1) AS solo_silla,
       fn_vehiculo_accesible(0,0) AS ninguna;

-- TF2. fn_porcentaje_cumplimiento. Esperado: 46.24 para la empresa 1.
SELECT fn_porcentaje_cumplimiento(1) AS pct_empresa_1;
-- TF3. La UDF coincide con la vista en todas las empresas. Esperado: 0 discrepancias.
SELECT COUNT(*) AS discrepancias
FROM v_cumplimiento_empresa v
WHERE NOT (v.pct_cumplimiento <=> fn_porcentaje_cumplimiento(v.id_empresa));
-- TF4. Empresa sin inspecciones -> NULL. Esperado: 3 empresas con pct NULL.
SELECT id_empresa, empresa, fn_porcentaje_cumplimiento(id_empresa) AS pct
FROM v_cumplimiento_empresa WHERE clasificacion = 'SIN INSPECCIONES';

-- =====================================================================
-- C. PROCEDIMIENTOS CON TRANSACCIONES
-- =====================================================================

-- TP1 (válido). Registrar asignación: vehículo 1, ruta 1, 2027-01-15, MANANA.
-- Esperado: p_id_asignacion = 10001, mensaje 'OK: asignacion registrada'.
CALL sp_registrar_asignacion(1, 1, '2027-01-15', 'MANANA', '05:30:00', '12:30:00', @id_a, @msg_a);
SELECT @id_a AS id_asignacion, @msg_a AS mensaje;

-- TP2 (inválido, RN1). Misma asignación otra vez (mismo vehículo, fecha y turno).
-- Esperado: id NULL; mensaje 'ERROR: Duplicate entry ... uq_asig_vehiculo_fecha_turno'.
CALL sp_registrar_asignacion(1, 2, '2027-01-15', 'MANANA', '05:30:00', '12:30:00', @id_a, @msg_a);
SELECT @id_a AS id_asignacion, @msg_a AS mensaje;

-- TP3 (inválido, trigger T3). Vehículo 101 está en MANTENIMIENTO.
-- Esperado: mensaje 'ERROR: Control: solo vehiculos en estado OPERATIVO ...'.
CALL sp_registrar_asignacion(101, 1, '2027-01-16', 'MANANA', '05:30:00', '12:30:00', @id_a, @msg_a);
SELECT @id_a AS id_asignacion, @msg_a AS mensaje;

-- TP4 (inválido, trigger T3). Ruta 11 está INACTIVA.
-- Esperado: mensaje 'ERROR: Control: solo se pueden asignar vehiculos a rutas ACTIVAS'.
CALL sp_registrar_asignacion(2, 11, '2027-01-16', 'MANANA', '05:30:00', '12:30:00', @id_a, @msg_a);
SELECT @id_a AS id_asignacion, @msg_a AS mensaje;

-- TP5 (inválido, RN4). hora_fin menor que hora_inicio.
-- Esperado: mensaje 'ERROR: CONSTRAINT `ck_asig_horas` failed ...'.
CALL sp_registrar_asignacion(2, 1, '2027-01-16', 'MANANA', '12:30:00', '05:30:00', @id_a, @msg_a);
SELECT @id_a AS id_asignacion, @msg_a AS mensaje;

-- Verificación: los 4 intentos fallidos no dejaron filas. Esperado: 10001 (10000 + TP1).
SELECT COUNT(*) AS total_asignaciones FROM asignacion;

-- TP6 (válido). Inspección completa: empresa 1, responsable 1.
-- Esperado: p_id_inspeccion = 3341; 3 detalles para esa inspección.
CALL sp_registrar_inspeccion(1, 1, '2026-11-05', 'CUMPLE', 'CUMPLE', 'OBSERVACION', @id_i, @msg_i);
SELECT @id_i AS id_inspeccion, @msg_i AS mensaje;
SELECT COUNT(*) AS detalles FROM inspeccion_detalle WHERE id_inspeccion = @id_i;

-- TP7 (inválido, atomicidad). El tercer detalle viola ck_det_resultado.
-- Esperado: mensaje 'ERROR: CONSTRAINT `ck_det_resultado` failed ...'. ROLLBACK
-- deshace también la inspección y los 2 detalles ya insertados.
CALL sp_registrar_inspeccion(1, 1, '2026-11-06', 'CUMPLE', 'CUMPLE', 'TAL_VEZ', @id_i, @msg_i);
SELECT @id_i AS id_inspeccion, @msg_i AS mensaje;
-- Esperado: inspeccion = 3341 y inspeccion_detalle = 10003 (10000 + 3 de TP6): sin huérfanos.
SELECT (SELECT COUNT(*) FROM inspeccion) AS inspecciones,
       (SELECT COUNT(*) FROM inspeccion_detalle) AS detalles;

-- TP8 (válido). Vehículo 2: OPERATIVO -> MANTENIMIENTO -> OPERATIVO.
-- Esperado: 'OK: estado cambiado de OPERATIVO a MANTENIMIENTO' y luego
-- 'OK: estado cambiado de MANTENIMIENTO a OPERATIVO'.
CALL sp_actualizar_estado_vehiculo(2, 'MANTENIMIENTO', @msg_v);
SELECT @msg_v AS mensaje;
CALL sp_actualizar_estado_vehiculo(2, 'OPERATIVO', @msg_v);
SELECT @msg_v AS mensaje;

-- TP9 (inválido). El vehículo 1 tiene una asignación futura (TP1: 2027-01-15).
-- Esperado: 'ERROR: el vehiculo tiene 1 asignacion(es) futura(s); reasignelas primero'.
CALL sp_actualizar_estado_vehiculo(1, 'MANTENIMIENTO', @msg_v);
SELECT @msg_v AS mensaje;

-- TP10 (inválido). Estado fuera del dominio.
-- Esperado: 'ERROR: CONSTRAINT `ck_vehiculo_estado` failed ...'.
CALL sp_actualizar_estado_vehiculo(2, 'AVERIADO', @msg_v);
SELECT @msg_v AS mensaje;

-- TP11 (inválido). Vehículo inexistente.
-- Esperado: 'ERROR: el vehiculo no existe'.
CALL sp_actualizar_estado_vehiculo(9999, 'MANTENIMIENTO', @msg_v);
SELECT @msg_v AS mensaje;

-- =====================================================================
-- D. TRIGGERS
-- =====================================================================

-- TT1 (BEFORE INSERT, RN2). Insertar en una ruta un paradero NO habilitado.
-- Esperado: ERROR 1644 (45000): RN2: solo se pueden programar paraderos autorizados (habilitados)
INSERT INTO ruta_paradero (id_ruta, id_paradero, orden)
SELECT 1, id_paradero, 99 FROM paradero WHERE habilitado = 0 LIMIT 1;

-- TT2 (BEFORE INSERT, caso válido; se revierte). Paradero habilitado que no está en la ruta 1.
-- Esperado: 1 fila insertada y visible; luego ROLLBACK.
START TRANSACTION;
INSERT INTO ruta_paradero (id_ruta, id_paradero, orden)
SELECT 1, id_paradero, 99 FROM paradero
WHERE habilitado = 1 AND id_paradero NOT IN (SELECT id_paradero FROM ruta_paradero WHERE id_ruta = 1)
LIMIT 1;
SELECT * FROM ruta_paradero WHERE id_ruta = 1 AND orden = 99;
ROLLBACK;

-- TT3 (BEFORE UPDATE, RN2). Cambiar el paradero de una ruta por uno no habilitado.
-- Esperado: ERROR 1644 (45000): RN2: ...
UPDATE ruta_paradero
SET id_paradero = (SELECT id_paradero FROM paradero WHERE habilitado = 0 LIMIT 1)
WHERE id_ruta = 1 AND orden = 1;

-- TT4 (BEFORE INSERT, control de asignación) por fuera del procedimiento.
-- Esperado: ERROR 1644 (45000): Control: solo vehiculos en estado OPERATIVO pueden ser asignados
INSERT INTO asignacion (id_vehiculo, id_ruta, fecha, turno, hora_inicio, hora_fin)
VALUES (101, 1, '2027-02-01', 'TARDE', '12:30:00', '18:30:00');

-- TT5 (AFTER): estado actual de la auditoría.
-- Esperado: 3 filas = 1 (asignacion, TP1) + 2 (vehiculo, TP8).
SELECT tabla_afectada, operacion, COUNT(*) AS registros FROM auditoria GROUP BY tabla_afectada, operacion;

-- TT6 (AFTER UPDATE): cambiar el estado de 25 vehículos y devolverlos genera 50 registros.
-- Esperado: auditoria pasa a 53 filas (1 INSERT de asignacion + 52 UPDATE de vehiculo).
UPDATE vehiculo SET estado = 'MANTENIMIENTO' WHERE id_vehiculo BETWEEN 3 AND 27;
UPDATE vehiculo SET estado = 'OPERATIVO'     WHERE id_vehiculo BETWEEN 3 AND 27;
SELECT tabla_afectada, operacion, COUNT(*) AS registros FROM auditoria GROUP BY tabla_afectada, operacion;
SELECT * FROM auditoria ORDER BY id_auditoria DESC LIMIT 5;

-- TT7 (AFTER UPDATE no dispara si el estado no cambia). Esperado: total sigue en 53.
UPDATE vehiculo SET estado = estado WHERE id_vehiculo = 3;
SELECT COUNT(*) AS total_auditoria FROM auditoria;

-- =====================================================================
-- E. LIMPIEZA DE LOS DATOS DE PRUEBA (la auditoría se conserva como evidencia)
-- Deja las tablas con los mismos datos de 02_datos.sql.
-- =====================================================================
DELETE FROM inspeccion_detalle WHERE id_inspeccion > 3340;
DELETE FROM inspeccion         WHERE id_inspeccion > 3340;
DELETE FROM asignacion         WHERE fecha > '2026-12-31';
-- Esperado: asignacion 10000, inspeccion 3340, inspeccion_detalle 10000, auditoria 53.
SELECT (SELECT COUNT(*) FROM asignacion) AS asignaciones,
       (SELECT COUNT(*) FROM inspeccion) AS inspecciones,
       (SELECT COUNT(*) FROM inspeccion_detalle) AS detalles,
       (SELECT COUNT(*) FROM auditoria) AS auditoria;
