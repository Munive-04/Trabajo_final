-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- Fase 3 - Script 01: DDL (tablas, restricciones, cascadas e índices)
-- Motor: MariaDB (XAMPP) >= 10.2.1  (CHECK y DEFAULT con expresiones)
-- =====================================================================

DROP DATABASE IF EXISTS setp_santa_marta;
CREATE DATABASE setp_santa_marta
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;
USE setp_santa_marta;

-- ---------------------------------------------------------------------
-- 1. EMPRESA_OPERADORA
-- ---------------------------------------------------------------------
CREATE TABLE empresa_operadora (
    id_empresa  INT          NOT NULL AUTO_INCREMENT,
    nit         VARCHAR(20)  NOT NULL,
    nombre      VARCHAR(120) NOT NULL,
    estado      VARCHAR(15)  NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT pk_empresa        PRIMARY KEY (id_empresa),
    CONSTRAINT uq_empresa_nit    UNIQUE (nit),
    CONSTRAINT ck_empresa_estado CHECK (estado IN ('ACTIVA','SUSPENDIDA'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. VEHICULO
--    RESTRICT al borrar empresa: se conserva el historial (RN6).
-- ---------------------------------------------------------------------
CREATE TABLE vehiculo (
    id_vehiculo          INT         NOT NULL AUTO_INCREMENT,
    id_empresa           INT         NOT NULL,
    placa                VARCHAR(10) NOT NULL,
    capacidad            SMALLINT    NOT NULL,
    tiene_rampa          TINYINT(1)  NOT NULL DEFAULT 0,
    piso_bajo            TINYINT(1)  NOT NULL DEFAULT 0,
    espacio_silla_ruedas TINYINT(1)  NOT NULL DEFAULT 0,
    estado               VARCHAR(15) NOT NULL DEFAULT 'OPERATIVO',
    CONSTRAINT pk_vehiculo        PRIMARY KEY (id_vehiculo),
    CONSTRAINT uq_vehiculo_placa  UNIQUE (placa),
    CONSTRAINT fk_vehiculo_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa_operadora (id_empresa)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_vehiculo_capacidad CHECK (capacidad > 0),
    CONSTRAINT ck_vehiculo_rampa     CHECK (tiene_rampa IN (0,1)),
    CONSTRAINT ck_vehiculo_pisobajo  CHECK (piso_bajo IN (0,1)),
    CONSTRAINT ck_vehiculo_silla     CHECK (espacio_silla_ruedas IN (0,1)),
    CONSTRAINT ck_vehiculo_estado    CHECK (estado IN ('OPERATIVO','MANTENIMIENTO','RETIRADO'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. ZONA (barrio o sector)
-- ---------------------------------------------------------------------
CREATE TABLE zona (
    id_zona INT         NOT NULL AUTO_INCREMENT,
    nombre  VARCHAR(80) NOT NULL,
    CONSTRAINT pk_zona        PRIMARY KEY (id_zona),
    CONSTRAINT uq_zona_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. PARADERO (incluye terminales de transferencia)
-- ---------------------------------------------------------------------
CREATE TABLE paradero (
    id_paradero INT          NOT NULL AUTO_INCREMENT,
    id_zona     INT          NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    tipo        VARCHAR(10)  NOT NULL DEFAULT 'PARADERO',
    habilitado  TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT pk_paradero PRIMARY KEY (id_paradero),
    CONSTRAINT fk_paradero_zona FOREIGN KEY (id_zona)
        REFERENCES zona (id_zona)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_paradero_tipo       CHECK (tipo IN ('PARADERO','TERMINAL')),
    CONSTRAINT ck_paradero_habilitado CHECK (habilitado IN (0,1))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. RUTA
-- ---------------------------------------------------------------------
CREATE TABLE ruta (
    id_ruta INT          NOT NULL AUTO_INCREMENT,
    codigo  VARCHAR(10)  NOT NULL,
    nombre  VARCHAR(100) NOT NULL,
    estado  VARCHAR(15)  NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT pk_ruta        PRIMARY KEY (id_ruta),
    CONSTRAINT uq_ruta_codigo UNIQUE (codigo),
    CONSTRAINT ck_ruta_estado CHECK (estado IN ('ACTIVA','INACTIVA'))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. RUTA_PARADERO (tabla puente N:M)
--    CASCADE al borrar ruta: la composición de una ruta no tiene sentido
--    sin la ruta (y una ruta con asignaciones no se puede borrar por RESTRICT).
--    RESTRICT al borrar paradero: no se elimina un paradero que está en una ruta.
-- ---------------------------------------------------------------------
CREATE TABLE ruta_paradero (
    id_ruta     INT      NOT NULL,
    id_paradero INT      NOT NULL,
    orden       SMALLINT NOT NULL,
    CONSTRAINT pk_ruta_paradero PRIMARY KEY (id_ruta, id_paradero),
    CONSTRAINT uq_ruta_orden    UNIQUE (id_ruta, orden),                  -- RN3
    CONSTRAINT fk_rp_ruta FOREIGN KEY (id_ruta)
        REFERENCES ruta (id_ruta)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rp_paradero FOREIGN KEY (id_paradero)
        REFERENCES paradero (id_paradero)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_rp_orden CHECK (orden > 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. ASIGNACION (historial: RESTRICT en ambas FK)
-- ---------------------------------------------------------------------
CREATE TABLE asignacion (
    id_asignacion INT         NOT NULL AUTO_INCREMENT,
    id_vehiculo   INT         NOT NULL,
    id_ruta       INT         NOT NULL,
    fecha         DATE        NOT NULL,
    turno         VARCHAR(10) NOT NULL,
    hora_inicio   TIME        NOT NULL,
    hora_fin      TIME        NOT NULL,
    CONSTRAINT pk_asignacion PRIMARY KEY (id_asignacion),
    CONSTRAINT uq_asig_vehiculo_fecha_turno UNIQUE (id_vehiculo, fecha, turno),   -- RN1
    CONSTRAINT fk_asig_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_asig_ruta FOREIGN KEY (id_ruta)
        REFERENCES ruta (id_ruta)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_asig_turno CHECK (turno IN ('MANANA','TARDE','NOCHE')),
    CONSTRAINT ck_asig_horas CHECK (hora_fin > hora_inicio)                       -- RN4
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. RESPONSABLE (autoridad que inspecciona)
-- ---------------------------------------------------------------------
CREATE TABLE responsable (
    id_responsable INT          NOT NULL AUTO_INCREMENT,
    nombre         VARCHAR(100) NOT NULL,
    entidad        VARCHAR(100) NOT NULL,
    CONSTRAINT pk_responsable PRIMARY KEY (id_responsable)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. INSPECCION
-- ---------------------------------------------------------------------
CREATE TABLE inspeccion (
    id_inspeccion  INT  NOT NULL AUTO_INCREMENT,
    id_empresa     INT  NOT NULL,
    id_responsable INT  NOT NULL,
    fecha          DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_inspeccion PRIMARY KEY (id_inspeccion),
    CONSTRAINT fk_insp_empresa FOREIGN KEY (id_empresa)
        REFERENCES empresa_operadora (id_empresa)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_insp_responsable FOREIGN KEY (id_responsable)
        REFERENCES responsable (id_responsable)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. INSPECCION_DETALLE (una fila por condición verificada)
-- ---------------------------------------------------------------------
CREATE TABLE inspeccion_detalle (
    id_detalle    INT         NOT NULL AUTO_INCREMENT,
    id_inspeccion INT         NOT NULL,
    condicion     VARCHAR(20) NOT NULL,
    resultado     VARCHAR(15) NOT NULL,
    CONSTRAINT pk_insp_detalle PRIMARY KEY (id_detalle),
    CONSTRAINT uq_insp_condicion UNIQUE (id_inspeccion, condicion),
    CONSTRAINT fk_det_inspeccion FOREIGN KEY (id_inspeccion)
        REFERENCES inspeccion (id_inspeccion)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_det_condicion CHECK (condicion IN ('LABORAL','PARADAS','RECAUDO')),
    CONSTRAINT ck_det_resultado CHECK (resultado IN ('CUMPLE','NO_CUMPLE','OBSERVACION'))  -- RN7
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 11. REPORTE_ILEGAL (solo totales agregados; no identifica personas)
-- ---------------------------------------------------------------------
CREATE TABLE reporte_ilegal (
    id_reporte     INT      NOT NULL AUTO_INCREMENT,
    id_zona        INT      NOT NULL,
    anio           SMALLINT NOT NULL,
    mes            SMALLINT NOT NULL,
    total_reportes INT      NOT NULL DEFAULT 0,
    CONSTRAINT pk_reporte PRIMARY KEY (id_reporte),
    CONSTRAINT uq_reporte_zona_periodo UNIQUE (id_zona, anio, mes),                -- RN5
    CONSTRAINT fk_reporte_zona FOREIGN KEY (id_zona)
        REFERENCES zona (id_zona)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_reporte_anio  CHECK (anio BETWEEN 2020 AND 2100),
    CONSTRAINT ck_reporte_mes   CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT ck_reporte_total CHECK (total_reportes >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 12. AUDITORIA (se llena con triggers en la Fase 4)
-- ---------------------------------------------------------------------
CREATE TABLE auditoria (
    id_auditoria   INT          NOT NULL AUTO_INCREMENT,
    tabla_afectada VARCHAR(40)  NOT NULL,
    operacion      VARCHAR(10)  NOT NULL,
    id_registro    INT          NOT NULL,
    usuario_bd     VARCHAR(80)  NOT NULL,
    fecha_evento   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detalle        VARCHAR(255) NULL,
    CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria),
    CONSTRAINT ck_aud_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
) ENGINE=InnoDB;

-- =====================================================================
-- ÍNDICES ADICIONALES (los PK, UNIQUE y FK ya generan sus propios índices)
-- =====================================================================
-- Consulta: vehículos que operan por ruta y turno en una fecha.
CREATE INDEX idx_asig_ruta_fecha_turno ON asignacion (id_ruta, fecha, turno);

-- Consulta: cobertura por zona (paraderos habilitados de cada zona).
CREATE INDEX idx_paradero_zona_hab ON paradero (id_zona, habilitado);

-- Consulta: cumplimiento por empresa en un rango de fechas.
CREATE INDEX idx_insp_empresa_fecha ON inspeccion (id_empresa, fecha);

-- Consulta: conteo de resultados por condición.
CREATE INDEX idx_det_condicion_resultado ON inspeccion_detalle (condicion, resultado);

-- Consulta: totales de transporte ilegal por periodo.
CREATE INDEX idx_reporte_periodo ON reporte_ilegal (anio, mes);

-- Consulta: proporción de flota por estado y accesibilidad.
CREATE INDEX idx_vehiculo_estado ON vehiculo (estado);
