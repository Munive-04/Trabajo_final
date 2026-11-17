-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- Fase 4 - Script 05: Procedimientos almacenados (con transacciones) y triggers
-- Ejecutar DESPUÉS de 04_funciones_vistas.sql.
-- IMPORTANTE: importar con el botón "Importar" de phpMyAdmin o con el
-- cliente mysql (ambos entienden DELIMITER).
-- =====================================================================
USE setp_santa_marta;

-- =====================================================================
-- A. TRIGGERS
-- =====================================================================

-- ---------------------------------------------------------------------
-- T1 (BEFORE INSERT) - RN2: las paradas programadas deben pertenecer al
-- conjunto de paraderos autorizados (habilitados).
-- Problema que resuelve: impedir rutas con paraderos no autorizados, regla
-- que un CHECK/UNIQUE no puede expresar porque depende de otra tabla.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_ruta_paradero_bi;
DELIMITER $$
CREATE TRIGGER trg_ruta_paradero_bi
BEFORE INSERT ON ruta_paradero
FOR EACH ROW
BEGIN
    DECLARE v_hab TINYINT;
    SELECT habilitado INTO v_hab FROM paradero WHERE id_paradero = NEW.id_paradero;
    IF v_hab = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'RN2: solo se pueden programar paraderos autorizados (habilitados)';
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- T2 (BEFORE UPDATE) - RN2 también al cambiar el paradero de una ruta.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_ruta_paradero_bu;
DELIMITER $$
CREATE TRIGGER trg_ruta_paradero_bu
BEFORE UPDATE ON ruta_paradero
FOR EACH ROW
BEGIN
    DECLARE v_hab TINYINT;
    IF NEW.id_paradero <> OLD.id_paradero THEN
        SELECT habilitado INTO v_hab FROM paradero WHERE id_paradero = NEW.id_paradero;
        IF v_hab = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN2: solo se pueden programar paraderos autorizados (habilitados)';
        END IF;
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- T3 (BEFORE INSERT) - Control de asignaciones: solo vehículos OPERATIVOS
-- en rutas ACTIVAS.
-- Problema que resuelve: evitar programar un vehículo en mantenimiento o
-- retirado, o una ruta inactiva.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_asignacion_bi;
DELIMITER $$
CREATE TRIGGER trg_asignacion_bi
BEFORE INSERT ON asignacion
FOR EACH ROW
BEGIN
    DECLARE v_estado_veh  VARCHAR(15);
    DECLARE v_estado_ruta VARCHAR(15);

    SELECT estado INTO v_estado_veh  FROM vehiculo WHERE id_vehiculo = NEW.id_vehiculo;
    SELECT estado INTO v_estado_ruta FROM ruta     WHERE id_ruta     = NEW.id_ruta;

    IF v_estado_veh IS NOT NULL AND v_estado_veh <> 'OPERATIVO' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Control: solo vehiculos en estado OPERATIVO pueden ser asignados';
    END IF;
    IF v_estado_ruta IS NOT NULL AND v_estado_ruta <> 'ACTIVA' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Control: solo se pueden asignar vehiculos a rutas ACTIVAS';
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- T4 (AFTER INSERT) - Auditoría de asignaciones.
-- Problema que resuelve: conservar rastro de quién y cuándo programó
-- cada asignación (historial, RN6).
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_asignacion_ai;
DELIMITER $$
CREATE TRIGGER trg_asignacion_ai
AFTER INSERT ON asignacion
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (tabla_afectada, operacion, id_registro, usuario_bd, detalle)
    VALUES ('asignacion', 'INSERT', NEW.id_asignacion, CURRENT_USER(),
            CONCAT('vehiculo=', NEW.id_vehiculo, ' ruta=', NEW.id_ruta,
                   ' fecha=', NEW.fecha, ' turno=', NEW.turno));
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- T5 (AFTER UPDATE) - Auditoría de cambios de estado de un vehículo.
-- Solo registra cuando el estado realmente cambia.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_vehiculo_au;
DELIMITER $$
CREATE TRIGGER trg_vehiculo_au
AFTER UPDATE ON vehiculo
FOR EACH ROW
BEGIN
    IF NOT (OLD.estado <=> NEW.estado) THEN
        INSERT INTO auditoria (tabla_afectada, operacion, id_registro, usuario_bd, detalle)
        VALUES ('vehiculo', 'UPDATE', NEW.id_vehiculo, CURRENT_USER(),
                CONCAT('estado: ', OLD.estado, ' -> ', NEW.estado));
    END IF;
END$$
DELIMITER ;

-- =====================================================================
-- B. PROCEDIMIENTOS ALMACENADOS CON TRANSACCIONES
-- Patrón común: START TRANSACTION -> operaciones -> COMMIT; ante cualquier
-- error, el handler captura el mensaje, hace ROLLBACK y lo devuelve en
-- el parámetro de salida p_mensaje.
-- =====================================================================

-- ---------------------------------------------------------------------
-- P1 - Procedimiento de ALTA: registrar una asignación.
-- Parámetros de entrada: vehículo, ruta, fecha, turno, hora inicio y fin.
-- Salida: p_id_asignacion (NULL si falló) y p_mensaje.
-- Las reglas (RN1, RN4, estados) las hacen cumplir las restricciones y
-- los triggers; el procedimiento garantiza que el error se maneje y la
-- transacción se revierta.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_asignacion;
DELIMITER $$
CREATE PROCEDURE sp_registrar_asignacion(
    IN  p_id_vehiculo   INT,
    IN  p_id_ruta       INT,
    IN  p_fecha         DATE,
    IN  p_turno         VARCHAR(10),
    IN  p_hora_inicio   TIME,
    IN  p_hora_fin      TIME,
    OUT p_id_asignacion INT,
    OUT p_mensaje       VARCHAR(255))
BEGIN
    DECLARE v_err TEXT DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err = MESSAGE_TEXT;
        ROLLBACK;
        SET p_id_asignacion = NULL;
        SET p_mensaje = CONCAT('ERROR: ', LEFT(v_err, 240));
    END;

    SET p_id_asignacion = NULL;
    START TRANSACTION;
        INSERT INTO asignacion (id_vehiculo, id_ruta, fecha, turno, hora_inicio, hora_fin)
        VALUES (p_id_vehiculo, p_id_ruta, p_fecha, p_turno, p_hora_inicio, p_hora_fin);
        SET p_id_asignacion = LAST_INSERT_ID();
    COMMIT;
    SET p_mensaje = 'OK: asignacion registrada';
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- P2 - Procedimiento de ALTA compuesta: registrar una inspección completa.
-- Inserta la inspección y sus 3 condiciones (laboral, paradas, recaudo) en
-- UNA sola transacción: o se guarda todo o no se guarda nada.
-- Parámetros: empresa, responsable, fecha y resultado de cada condición.
-- Salida: p_id_inspeccion (NULL si falló) y p_mensaje.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_inspeccion;
DELIMITER $$
CREATE PROCEDURE sp_registrar_inspeccion(
    IN  p_id_empresa     INT,
    IN  p_id_responsable INT,
    IN  p_fecha          DATE,
    IN  p_res_laboral    VARCHAR(15),
    IN  p_res_paradas    VARCHAR(15),
    IN  p_res_recaudo    VARCHAR(15),
    OUT p_id_inspeccion  INT,
    OUT p_mensaje        VARCHAR(255))
BEGIN
    DECLARE v_err TEXT DEFAULT '';

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err = MESSAGE_TEXT;
        ROLLBACK;
        SET p_id_inspeccion = NULL;
        SET p_mensaje = CONCAT('ERROR: ', LEFT(v_err, 240));
    END;

    SET p_id_inspeccion = NULL;
    START TRANSACTION;
        INSERT INTO inspeccion (id_empresa, id_responsable, fecha)
        VALUES (p_id_empresa, p_id_responsable, p_fecha);
        SET p_id_inspeccion = LAST_INSERT_ID();

        INSERT INTO inspeccion_detalle (id_inspeccion, condicion, resultado)
        VALUES (p_id_inspeccion, 'LABORAL', p_res_laboral),
               (p_id_inspeccion, 'PARADAS', p_res_paradas),
               (p_id_inspeccion, 'RECAUDO', p_res_recaudo);
    COMMIT;
    SET p_mensaje = 'OK: inspeccion registrada con sus 3 condiciones';
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- P3 - Procedimiento de ACTUALIZACIÓN: cambiar el estado de un vehículo.
-- Regla: no se puede pasar a MANTENIMIENTO ni RETIRADO un vehículo que
-- tenga asignaciones desde hoy en adelante (primero deben reasignarse);
-- el historial pasado no se toca (RN6).
-- Usa SELECT ... FOR UPDATE para bloquear la fila durante la transacción.
-- Parámetros: p_id_vehiculo, p_nuevo_estado. Salida: p_mensaje.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_actualizar_estado_vehiculo;
DELIMITER $$
CREATE PROCEDURE sp_actualizar_estado_vehiculo(
    IN  p_id_vehiculo  INT,
    IN  p_nuevo_estado VARCHAR(15),
    OUT p_mensaje      VARCHAR(255))
proc: BEGIN
    DECLARE v_err           TEXT DEFAULT '';
    DECLARE v_estado_actual VARCHAR(15) DEFAULT NULL;
    DECLARE v_futuras       INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err = MESSAGE_TEXT;
        ROLLBACK;
        SET p_mensaje = CONCAT('ERROR: ', LEFT(v_err, 240));
    END;

    START TRANSACTION;
        SELECT estado INTO v_estado_actual
          FROM vehiculo WHERE id_vehiculo = p_id_vehiculo FOR UPDATE;

        IF v_estado_actual IS NULL THEN
            ROLLBACK;
            SET p_mensaje = 'ERROR: el vehiculo no existe';
            LEAVE proc;
        END IF;

        IF p_nuevo_estado <> 'OPERATIVO' THEN
            SELECT COUNT(*) INTO v_futuras
              FROM asignacion
             WHERE id_vehiculo = p_id_vehiculo AND fecha >= CURRENT_DATE;
            IF v_futuras > 0 THEN
                ROLLBACK;
                SET p_mensaje = CONCAT('ERROR: el vehiculo tiene ', v_futuras,
                                       ' asignacion(es) futura(s); reasignelas primero');
                LEAVE proc;
            END IF;
        END IF;

        UPDATE vehiculo SET estado = p_nuevo_estado WHERE id_vehiculo = p_id_vehiculo;
    COMMIT;
    SET p_mensaje = CONCAT('OK: estado cambiado de ', v_estado_actual, ' a ', p_nuevo_estado);
END$$
DELIMITER ;
