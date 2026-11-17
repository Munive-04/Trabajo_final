-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- 12_creacion_esquema_mariadb.sql  ·  DDL totalmente documentado
-- ---------------------------------------------------------------------
-- SGBD: MariaDB >= 10.2.1 (XAMPP). Versión exacta del equipo: [completar]
-- Base de datos: setp_santa_marta (debe existir y estar VACÍA).
-- Fecha: 10-nov-2026. Autoría: trabajo asistido por IA, revisado por el equipo.
-- Codificación: utf8mb4. Importar el archivo como UTF-8 (phpMyAdmin lo hace
-- por defecto; con el cliente mysql usar --default-character-set=utf8mb4).
-- Orden de ejecución: [opcional] 12_opcional_crear_bd_mariadb.sql -> este
-- archivo -> 02_datos.sql -> 04_funciones_vistas.sql -> 05_procedimientos_triggers.sql
-- Alcance: 12 tablas, 10 FK, 8 UNIQUE, 18 CHECK y 6 índices adicionales.
-- No contiene datos de prueba, DROP ni CREATE DATABASE.
--
-- INMUTABILIDAD (R14): el diseño es EXACTAMENTE el de 01_ddl.sql (mismos
-- nombres, tipos, nulabilidad, DEFAULT, PK, FK, UNIQUE, CHECK, índices, orden,
-- motor y relaciones). Lo único que cambia son los comentarios.
--
-- DÓNDE VIVE CADA COMENTARIO:
--   * COMMENT nativo (guardado en el catálogo): tablas y columnas.
--   * Comentarios SQL (-- ...): restricciones e índices. NO se guardan en el
--     catálogo; solo existen en este archivo.
--
-- ESTADO (R8): PROBADO EN SGBD (MariaDB/XAMPP), según reporte del equipo (13-nov-2026): ejecutado sin errores y con resultados coincidentes con los esperados.
-- Verificado con 13_verificaciones_estructura_mariadb.sql. Conservar capturas en evidencias/.
-- Convención de requisitos: RF1-RF8 (almacenamiento y consulta), RN1-RN9
-- (reglas de negocio), según la memoria técnica.
-- Marca PENDIENTE DE CONFIRMAR: significado no definido por el enunciado.
-- =====================================================================
USE setp_santa_marta;


-- ---------------------------------------------------------------------
-- 1. EMPRESA_OPERADORA  (RF1, RF6)
-- Empresas que operan el servicio del SETP de Santa Marta. Cada vehículo pertenece a una empresa y cada inspección evalúa a una empresa.
-- ---------------------------------------------------------------------
CREATE TABLE empresa_operadora (
    id_empresa INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria interna de la empresa; la referencian vehiculo e inspeccion.',
    nit VARCHAR(20) NOT NULL COMMENT 'NIT con el que la autoridad identifica a la empresa; único en el sistema. Valores ficticios en el entorno académico.',
    nombre VARCHAR(120) NOT NULL COMMENT 'Razón social o nombre comercial con el que opera en el SETP.',
    estado VARCHAR(15) NOT NULL DEFAULT 'ACTIVA' COMMENT 'Situación definida por el equipo: ACTIVA o SUSPENDIDA (por defecto ACTIVA). El enunciado no detalla causas ni efectos de la suspensión. PENDIENTE DE CONFIRMAR con el docente.',
    -- [PRIMARY KEY] Identifica de forma única cada empresa. (RF1)
    CONSTRAINT pk_empresa PRIMARY KEY (id_empresa),
    -- [UNIQUE] Impide registrar dos empresas con el mismo NIT. (RF1)
    CONSTRAINT uq_empresa_nit UNIQUE (nit),
    -- [CHECK] Limita el estado a los dos valores definidos por el equipo. (RF1)
    CONSTRAINT ck_empresa_estado CHECK (estado IN ('ACTIVA','SUSPENDIDA'))
) ENGINE=InnoDB COMMENT='Empresas que operan el servicio del SETP de Santa Marta. Cada vehículo pertenece a una empresa y cada inspección evalúa a una empresa.';

-- ---------------------------------------------------------------------
-- 2. VEHICULO  (RF2, RN8)
-- Flota del SETP con su capacidad y sus características de accesibilidad. No almacena datos de conductores (decisión de privacidad por diseño).
-- ---------------------------------------------------------------------
CREATE TABLE vehiculo (
    id_vehiculo INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria interna del vehículo; la referencia asignacion.',
    id_empresa INT NOT NULL COMMENT 'Empresa a la que pertenece el vehículo (FK a empresa_operadora).',
    placa VARCHAR(10) NOT NULL COMMENT 'Placa del vehículo, única en toda la flota. Valores sintéticos en el entorno académico.',
    capacidad SMALLINT NOT NULL COMMENT 'Capacidad del vehículo en número de pasajeros; mayor que 0. No distingue sentados de pie. PENDIENTE DE CONFIRMAR si el enunciado la entiende así.',
    tiene_rampa TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Indicador 1/0 de rampa de acceso. Junto con espacio_silla_ruedas define vehículo accesible (fn_vehiculo_accesible). Por defecto 0.',
    piso_bajo TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Indicador 1/0 de piso bajo (abordaje sin escalones). Dato complementario: no interviene en el criterio de accesible del equipo. Por defecto 0.',
    espacio_silla_ruedas TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Indicador 1/0 de espacio habilitado para silla de ruedas. Junto con tiene_rampa define vehículo accesible. Por defecto 0.',
    estado VARCHAR(15) NOT NULL DEFAULT 'OPERATIVO' COMMENT 'Situación operativa: OPERATIVO (puede asignarse), MANTENIMIENTO (fuera de servicio temporal) o RETIRADO (fuera de la flota). Solo los OPERATIVOS se asignan (trigger trg_asignacion_bi, RN8). Por defecto OPERATIVO.',
    -- [PRIMARY KEY] Identifica de forma única cada vehículo. (RF2)
    CONSTRAINT pk_vehiculo PRIMARY KEY (id_vehiculo),
    -- [UNIQUE] Impide placas repetidas en la flota. (RF2)
    CONSTRAINT uq_vehiculo_placa UNIQUE (placa),
    -- [FOREIGN KEY] ON DELETE RESTRICT impide borrar una empresa con vehículos (historial, RN6); ON UPDATE CASCADE propaga cambios de clave. (RF1, RN6)
    CONSTRAINT fk_vehiculo_empresa FOREIGN KEY (id_empresa) REFERENCES empresa_operadora (id_empresa) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [CHECK] La capacidad debe ser positiva. (RF2)
    CONSTRAINT ck_vehiculo_capacidad CHECK (capacidad > 0),
    -- [CHECK] Fuerza el dominio booleano 0/1. (RF2)
    CONSTRAINT ck_vehiculo_rampa CHECK (tiene_rampa IN (0,1)),
    -- [CHECK] Fuerza el dominio booleano 0/1. (RF2)
    CONSTRAINT ck_vehiculo_pisobajo CHECK (piso_bajo IN (0,1)),
    -- [CHECK] Fuerza el dominio booleano 0/1. (RF2)
    CONSTRAINT ck_vehiculo_silla CHECK (espacio_silla_ruedas IN (0,1)),
    -- [CHECK] Limita el estado a los tres valores definidos por el equipo. (RF2, RN8)
    CONSTRAINT ck_vehiculo_estado CHECK (estado IN ('OPERATIVO','MANTENIMIENTO','RETIRADO'))
) ENGINE=InnoDB COMMENT='Flota del SETP con su capacidad y sus características de accesibilidad. No almacena datos de conductores (decisión de privacidad por diseño).';

-- ---------------------------------------------------------------------
-- 3. ZONA  (RF3, RF7)
-- Barrios o sectores de la ciudad. Ubican los paraderos, agrupan los totales de transporte ilegal y permiten medir la cobertura del servicio.
-- ---------------------------------------------------------------------
CREATE TABLE zona (
    id_zona INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria de la zona; la referencian paradero y reporte_ilegal.',
    nombre VARCHAR(80) NOT NULL COMMENT 'Nombre del barrio o sector, único en el sistema. Los nombres cargados son ilustrativos.',
    -- [PRIMARY KEY] Identifica de forma única cada zona. (RF3)
    CONSTRAINT pk_zona PRIMARY KEY (id_zona),
    -- [UNIQUE] Impide zonas con nombre repetido. (RF3)
    CONSTRAINT uq_zona_nombre UNIQUE (nombre)
) ENGINE=InnoDB COMMENT='Barrios o sectores de la ciudad. Ubican los paraderos, agrupan los totales de transporte ilegal y permiten medir la cobertura del servicio.';

-- ---------------------------------------------------------------------
-- 4. PARADERO  (RF3, RN2)
-- Paraderos y terminales de transferencia. Solo los habilitados pueden incorporarse a una ruta.
-- ---------------------------------------------------------------------
CREATE TABLE paradero (
    id_paradero INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria del paradero; la referencia ruta_paradero.',
    id_zona INT NOT NULL COMMENT 'Zona donde se ubica el paradero (FK a zona).',
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre con el que se identifica el paradero o terminal.',
    tipo VARCHAR(10) NOT NULL DEFAULT 'PARADERO' COMMENT 'PARADERO (parada regular) o TERMINAL (terminal de transferencia donde se hace transbordo entre rutas). Por defecto PARADERO.',
    habilitado TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Indicador 1/0: 1 = autorizado para programar paradas. Con 0 no puede añadirse a una ruta (trigger trg_ruta_paradero_bi, RN2). Por defecto 1.',
    -- [PRIMARY KEY] Identifica de forma única cada paradero. (RF3)
    CONSTRAINT pk_paradero PRIMARY KEY (id_paradero),
    -- [FOREIGN KEY] ON DELETE RESTRICT impide borrar una zona con paraderos; ON UPDATE CASCADE propaga cambios de clave. (RF3, RN6)
    CONSTRAINT fk_paradero_zona FOREIGN KEY (id_zona) REFERENCES zona (id_zona) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [CHECK] Limita el tipo a parada regular o terminal. (RF3)
    CONSTRAINT ck_paradero_tipo CHECK (tipo IN ('PARADERO','TERMINAL')),
    -- [CHECK] Fuerza el dominio booleano 0/1. (RN2)
    CONSTRAINT ck_paradero_habilitado CHECK (habilitado IN (0,1))
) ENGINE=InnoDB COMMENT='Paraderos y terminales de transferencia. Solo los habilitados pueden incorporarse a una ruta.';

-- ---------------------------------------------------------------------
-- 5. RUTA  (RF3, RF5)
-- Rutas del servicio. Un vehículo se asigna a una ruta en una fecha y turno; su recorrido se define en ruta_paradero.
-- ---------------------------------------------------------------------
CREATE TABLE ruta (
    id_ruta INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria de la ruta; la referencian ruta_paradero y asignacion.',
    codigo VARCHAR(10) NOT NULL COMMENT 'Código corto y único de la ruta, por ejemplo R01.',
    nombre VARCHAR(100) NOT NULL COMMENT 'Descripción de la ruta. En la carga sintética: zona de origen y zona de destino.',
    estado VARCHAR(15) NOT NULL DEFAULT 'ACTIVA' COMMENT 'ACTIVA (admite asignaciones) o INACTIVA (no admite nuevas asignaciones, trigger trg_asignacion_bi, RN8). Por defecto ACTIVA.',
    -- [PRIMARY KEY] Identifica de forma única cada ruta. (RF3)
    CONSTRAINT pk_ruta PRIMARY KEY (id_ruta),
    -- [UNIQUE] Impide códigos de ruta repetidos. (RF3)
    CONSTRAINT uq_ruta_codigo UNIQUE (codigo),
    -- [CHECK] Limita el estado a los dos valores definidos por el equipo. (RF3, RN8)
    CONSTRAINT ck_ruta_estado CHECK (estado IN ('ACTIVA','INACTIVA'))
) ENGINE=InnoDB COMMENT='Rutas del servicio. Un vehículo se asigna a una ruta en una fecha y turno; su recorrido se define en ruta_paradero.';

-- ---------------------------------------------------------------------
-- 6. RUTA_PARADERO  (RF3, RF4, RN2, RN3)
-- Tabla puente N:M entre ruta y paradero: define qué paraderos recorre cada ruta y en qué orden.
-- ---------------------------------------------------------------------
CREATE TABLE ruta_paradero (
    id_ruta INT NOT NULL COMMENT 'Ruta a la que pertenece la parada. Parte de la clave primaria compuesta (FK a ruta).',
    id_paradero INT NOT NULL COMMENT 'Paradero incluido en la ruta. Parte de la clave primaria compuesta (FK a paradero). Solo paraderos habilitados (RN2).',
    orden SMALLINT NOT NULL COMMENT 'Posición del paradero en el recorrido, desde 1. No se repite dentro de una misma ruta (RN3).',
    -- [PRIMARY KEY] Un paradero aparece una sola vez por ruta. (RF4)
    CONSTRAINT pk_ruta_paradero PRIMARY KEY (id_ruta, id_paradero),
    -- [UNIQUE] Dos paraderos no pueden ocupar la misma posición en una ruta (RN3). (RN3)
    CONSTRAINT uq_ruta_orden UNIQUE (id_ruta, orden),
    -- [FOREIGN KEY] ON DELETE CASCADE: al eliminar una ruta sin asignaciones desaparece su composición, que no tiene sentido sin ella. Una ruta con asignaciones no se borra porque asignacion usa RESTRICT. (RF4, RN6)
    CONSTRAINT fk_rp_ruta FOREIGN KEY (id_ruta) REFERENCES ruta (id_ruta) ON DELETE CASCADE ON UPDATE CASCADE,
    -- [FOREIGN KEY] ON DELETE RESTRICT impide borrar un paradero que forma parte de una ruta. (RF3, RN6)
    CONSTRAINT fk_rp_paradero FOREIGN KEY (id_paradero) REFERENCES paradero (id_paradero) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [CHECK] El orden comienza en 1. (RN3)
    CONSTRAINT ck_rp_orden CHECK (orden > 0)
) ENGINE=InnoDB COMMENT='Tabla puente N:M entre ruta y paradero: define qué paraderos recorre cada ruta y en qué orden.';

-- ---------------------------------------------------------------------
-- 7. ASIGNACION  (RF5, RF8, RN1, RN4, RN8)
-- Historial de asignaciones de vehículos a rutas por fecha y turno, con hora de inicio y fin. Un vehículo no puede repetirse en la misma fecha y turno.
-- ---------------------------------------------------------------------
CREATE TABLE asignacion (
    id_asignacion INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria de la asignación.',
    id_vehiculo INT NOT NULL COMMENT 'Vehículo asignado (FK a vehiculo).',
    id_ruta INT NOT NULL COMMENT 'Ruta en la que opera el vehículo (FK a ruta).',
    fecha DATE NOT NULL COMMENT 'Fecha de la jornada programada.',
    turno VARCHAR(10) NOT NULL COMMENT 'Franja operativa: MANANA, TARDE o NOCHE (sin eñe por compatibilidad). La hora exacta está en hora_inicio y hora_fin.',
    hora_inicio TIME NOT NULL COMMENT 'Hora de inicio de la jornada. Debe ser anterior a hora_fin (RN4); los turnos no cruzan la medianoche.',
    hora_fin TIME NOT NULL COMMENT 'Hora de fin de la jornada. Debe ser posterior a hora_inicio (RN4).',
    -- [PRIMARY KEY] Identifica de forma única cada asignación. (RF5)
    CONSTRAINT pk_asignacion PRIMARY KEY (id_asignacion),
    -- [UNIQUE] RN1: un vehículo no puede estar en dos rutas en la misma fecha y turno. (RN1)
    CONSTRAINT uq_asig_vehiculo_fecha_turno UNIQUE (id_vehiculo, fecha, turno),
    -- [FOREIGN KEY] ON DELETE RESTRICT conserva el historial de asignaciones (RN6). (RF8, RN6)
    CONSTRAINT fk_asig_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo (id_vehiculo) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [FOREIGN KEY] ON DELETE RESTRICT conserva el historial de asignaciones (RN6). (RF8, RN6)
    CONSTRAINT fk_asig_ruta FOREIGN KEY (id_ruta) REFERENCES ruta (id_ruta) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [CHECK] Limita el turno a las tres franjas definidas por el equipo. (RF5)
    CONSTRAINT ck_asig_turno CHECK (turno IN ('MANANA','TARDE','NOCHE')),
    -- [CHECK] RN4: la hora de fin es posterior a la de inicio. (RN4)
    CONSTRAINT ck_asig_horas CHECK (hora_fin > hora_inicio)
) ENGINE=InnoDB COMMENT='Historial de asignaciones de vehículos a rutas por fecha y turno, con hora de inicio y fin. Un vehículo no puede repetirse en la misma fecha y turno.';

-- ---------------------------------------------------------------------
-- 8. RESPONSABLE  (RF6)
-- Autoridades de movilidad que realizan las inspecciones. Datos ficticios en el entorno académico; no son conductores.
-- ---------------------------------------------------------------------
CREATE TABLE responsable (
    id_responsable INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria del responsable; la referencia inspeccion.',
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre ficticio del funcionario que inspecciona.',
    entidad VARCHAR(100) NOT NULL COMMENT 'Entidad u oficina de movilidad a la que pertenece el responsable.',
    -- [PRIMARY KEY] Identifica de forma única a cada responsable. (RF6)
    CONSTRAINT pk_responsable PRIMARY KEY (id_responsable)
) ENGINE=InnoDB COMMENT='Autoridades de movilidad que realizan las inspecciones. Datos ficticios en el entorno académico; no son conductores.';

-- ---------------------------------------------------------------------
-- 9. INSPECCION  (RF6, RF8)
-- Visita de verificación de condiciones de operación a una empresa, con fecha y responsable. El resultado global se deriva en la vista v_cumplimiento_empresa y no se almacena (3FN).
-- ---------------------------------------------------------------------
CREATE TABLE inspeccion (
    id_inspeccion INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria de la inspección; la referencia inspeccion_detalle.',
    id_empresa INT NOT NULL COMMENT 'Empresa inspeccionada (FK a empresa_operadora).',
    id_responsable INT NOT NULL COMMENT 'Autoridad que realizó la inspección (FK a responsable).',
    fecha DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Fecha de la inspección. Por defecto, la fecha actual del servidor.',
    -- [PRIMARY KEY] Identifica de forma única cada inspección. (RF6)
    CONSTRAINT pk_inspeccion PRIMARY KEY (id_inspeccion),
    -- [FOREIGN KEY] ON DELETE RESTRICT conserva el historial de inspecciones (RN6). (RF8, RN6)
    CONSTRAINT fk_insp_empresa FOREIGN KEY (id_empresa) REFERENCES empresa_operadora (id_empresa) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [FOREIGN KEY] ON DELETE RESTRICT conserva el historial de inspecciones (RN6). (RF8, RN6)
    CONSTRAINT fk_insp_responsable FOREIGN KEY (id_responsable) REFERENCES responsable (id_responsable) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Visita de verificación de condiciones de operación a una empresa, con fecha y responsable. El resultado global se deriva en la vista v_cumplimiento_empresa y no se almacena (3FN).';

-- ---------------------------------------------------------------------
-- 10. INSPECCION_DETALLE  (RF6, RN7)
-- Resultado de cada condición verificada en una inspección: condiciones laborales, paradas autorizadas y tecnología de recaudo.
-- ---------------------------------------------------------------------
CREATE TABLE inspeccion_detalle (
    id_detalle INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria del detalle de inspección.',
    id_inspeccion INT NOT NULL COMMENT 'Inspección a la que pertenece el resultado (FK a inspeccion).',
    condicion VARCHAR(20) NOT NULL COMMENT 'Condición evaluada: LABORAL (condiciones laborales), PARADAS (uso de paradas autorizadas) o RECAUDO (tecnología de recaudo). Una vez por inspección.',
    resultado VARCHAR(15) NOT NULL COMMENT 'CUMPLE, NO_CUMPLE u OBSERVACION (RN7). En los porcentajes de cumplimiento solo CUMPLE suma como cumplido.',
    -- [PRIMARY KEY] Identifica de forma única cada resultado. (RF6)
    CONSTRAINT pk_insp_detalle PRIMARY KEY (id_detalle),
    -- [UNIQUE] Cada condición se evalúa una sola vez por inspección. (RF6)
    CONSTRAINT uq_insp_condicion UNIQUE (id_inspeccion, condicion),
    -- [FOREIGN KEY] ON DELETE RESTRICT conserva el historial de inspecciones (RN6). (RF8, RN6)
    CONSTRAINT fk_det_inspeccion FOREIGN KEY (id_inspeccion) REFERENCES inspeccion (id_inspeccion) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [CHECK] Limita las condiciones a las tres que exige el enunciado. (RF6)
    CONSTRAINT ck_det_condicion CHECK (condicion IN ('LABORAL','PARADAS','RECAUDO')),
    -- [CHECK] RN7: dominio fijo de resultados. (RN7)
    CONSTRAINT ck_det_resultado CHECK (resultado IN ('CUMPLE','NO_CUMPLE','OBSERVACION'))
) ENGINE=InnoDB COMMENT='Resultado de cada condición verificada en una inspección: condiciones laborales, paradas autorizadas y tecnología de recaudo.';

-- ---------------------------------------------------------------------
-- 11. REPORTE_ILEGAL  (RF7, RN5)
-- Totales mensuales de reportes de transporte ilegal por zona. Solo agregados: no identifica personas ni vehículos.
-- ---------------------------------------------------------------------
CREATE TABLE reporte_ilegal (
    id_reporte INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria del reporte agregado.',
    id_zona INT NOT NULL COMMENT 'Zona a la que corresponde el total (FK a zona).',
    anio SMALLINT NOT NULL COMMENT 'Año del periodo reportado, entre 2020 y 2100.',
    mes SMALLINT NOT NULL COMMENT 'Mes del periodo reportado, de 1 a 12.',
    total_reportes INT NOT NULL DEFAULT 0 COMMENT 'Cantidad de reportes de transporte ilegal en la zona y el periodo; entero mayor o igual a 0. Cifra sintética. Por defecto 0.',
    -- [PRIMARY KEY] Identifica de forma única cada reporte. (RF7)
    CONSTRAINT pk_reporte PRIMARY KEY (id_reporte),
    -- [UNIQUE] RN5: un solo reporte por zona y periodo. (RN5)
    CONSTRAINT uq_reporte_zona_periodo UNIQUE (id_zona, anio, mes),
    -- [FOREIGN KEY] ON DELETE RESTRICT conserva los totales históricos (RN6). (RF7, RN6)
    CONSTRAINT fk_reporte_zona FOREIGN KEY (id_zona) REFERENCES zona (id_zona) ON DELETE RESTRICT ON UPDATE CASCADE,
    -- [CHECK] Evita años absurdos. (RF7)
    CONSTRAINT ck_reporte_anio CHECK (anio BETWEEN 2020 AND 2100),
    -- [CHECK] Mes válido. (RF7)
    CONSTRAINT ck_reporte_mes CHECK (mes BETWEEN 1 AND 12),
    -- [CHECK] RN5: el total no puede ser negativo. (RN5)
    CONSTRAINT ck_reporte_total CHECK (total_reportes >= 0)
) ENGINE=InnoDB COMMENT='Totales mensuales de reportes de transporte ilegal por zona. Solo agregados: no identifica personas ni vehículos.';

-- ---------------------------------------------------------------------
-- 12. AUDITORIA  (RF8, RN6)
-- Rastro de cambios generado por los triggers trg_asignacion_ai y trg_vehiculo_au. Registra operación, usuario y momento; no se edita manualmente.
-- ---------------------------------------------------------------------
CREATE TABLE auditoria (
    id_auditoria INT NOT NULL AUTO_INCREMENT COMMENT 'Clave primaria del registro de auditoría.',
    tabla_afectada VARCHAR(40) NOT NULL COMMENT 'Nombre de la tabla donde ocurrió el cambio.',
    operacion VARCHAR(10) NOT NULL COMMENT 'INSERT, UPDATE o DELETE. El dominio admite DELETE, pero hoy ningún trigger lo registra.',
    id_registro INT NOT NULL COMMENT 'Clave primaria del registro afectado en tabla_afectada. Sin FK porque apunta a varias tablas.',
    usuario_bd VARCHAR(80) NOT NULL COMMENT 'Usuario de base de datos que ejecutó el cambio (CURRENT_USER()).',
    fecha_evento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Momento del evento. Por defecto, la fecha y hora del servidor.',
    detalle VARCHAR(255) NULL COMMENT 'Texto breve con los valores del cambio. Admite NULL cuando no aplica.',
    -- [PRIMARY KEY] Identifica de forma única cada registro de auditoría. (RF8)
    CONSTRAINT pk_auditoria PRIMARY KEY (id_auditoria),
    -- [CHECK] Limita la operación a los tres tipos de cambio. (RF8)
    CONSTRAINT ck_aud_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
) ENGINE=InnoDB COMMENT='Rastro de cambios generado por los triggers trg_asignacion_ai y trg_vehiculo_au. Registra operación, usuario y momento; no se edita manualmente.';

-- =====================================================================
-- ÍNDICES ADICIONALES (PK, UNIQUE y FK ya generan sus propios índices)
-- =====================================================================
-- Vehículos que operan por ruta, fecha y turno. (RF5)
CREATE INDEX idx_asig_ruta_fecha_turno ON asignacion (id_ruta, fecha, turno);

-- Paraderos habilitados de cada zona (cobertura). (RF3)
CREATE INDEX idx_paradero_zona_hab ON paradero (id_zona, habilitado);

-- Inspecciones de una empresa en un rango de fechas. (RF6)
CREATE INDEX idx_insp_empresa_fecha ON inspeccion (id_empresa, fecha);

-- Conteo de resultados por condición. (RF6)
CREATE INDEX idx_det_condicion_resultado ON inspeccion_detalle (condicion, resultado);

-- Totales de transporte ilegal por periodo. (RF7)
CREATE INDEX idx_reporte_periodo ON reporte_ilegal (anio, mes);

-- Flota por estado y proporción de accesibles. (RF2)
CREATE INDEX idx_vehiculo_estado ON vehiculo (estado);
