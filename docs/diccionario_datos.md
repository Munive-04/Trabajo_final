# Diccionario de datos - SETP Santa Marta (P11)

Base de datos `setp_santa_marta` · MariaDB (XAMPP) · InnoDB · utf8mb4.
Los nombres de las restricciones están en `sql/01_ddl.sql`.

## empresa_operadora
Empresas que operan el servicio de transporte público.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_empresa | INT autoincremental | PK |
| nit | VARCHAR(20) | UNIQUE, NOT NULL |
| nombre | VARCHAR(120) | NOT NULL |
| estado | VARCHAR(15) | NOT NULL, DEFAULT 'ACTIVA', CHECK (ACTIVA, SUSPENDIDA) |

## vehiculo
Flota de cada empresa, con su accesibilidad.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_vehiculo | INT autoincremental | PK |
| id_empresa | INT | FK → empresa_operadora, NOT NULL, ON DELETE RESTRICT |
| placa | VARCHAR(10) | UNIQUE, NOT NULL |
| capacidad | SMALLINT | NOT NULL, CHECK > 0 |
| tiene_rampa | TINYINT(1) | NOT NULL, DEFAULT 0, CHECK (0, 1) |
| piso_bajo | TINYINT(1) | NOT NULL, DEFAULT 0, CHECK (0, 1) |
| espacio_silla_ruedas | TINYINT(1) | NOT NULL, DEFAULT 0, CHECK (0, 1) |
| estado | VARCHAR(15) | NOT NULL, DEFAULT 'OPERATIVO', CHECK (OPERATIVO, MANTENIMIENTO, RETIRADO) |

## zona
Barrio o sector de la ciudad.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_zona | INT autoincremental | PK |
| nombre | VARCHAR(80) | UNIQUE, NOT NULL |

## paradero
Paraderos y terminales de transferencia.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_paradero | INT autoincremental | PK |
| id_zona | INT | FK → zona, NOT NULL, ON DELETE RESTRICT |
| nombre | VARCHAR(100) | NOT NULL |
| tipo | VARCHAR(10) | NOT NULL, DEFAULT 'PARADERO', CHECK (PARADERO, TERMINAL) |
| habilitado | TINYINT(1) | NOT NULL, DEFAULT 1, CHECK (0, 1) |

## ruta
Rutas del servicio.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_ruta | INT autoincremental | PK |
| codigo | VARCHAR(10) | UNIQUE, NOT NULL |
| nombre | VARCHAR(100) | NOT NULL |
| estado | VARCHAR(15) | NOT NULL, DEFAULT 'ACTIVA', CHECK (ACTIVA, INACTIVA) |

## ruta_paradero (tabla puente N:M)
Paraderos de cada ruta y su orden.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_ruta | INT | PK (compuesta), FK → ruta, ON DELETE CASCADE |
| id_paradero | INT | PK (compuesta), FK → paradero, ON DELETE RESTRICT |
| orden | SMALLINT | NOT NULL, CHECK > 0, UNIQUE (id_ruta, orden) |

## asignacion
Vehículo asignado a una ruta en una fecha y turno.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_asignacion | INT autoincremental | PK |
| id_vehiculo | INT | FK → vehiculo, NOT NULL, ON DELETE RESTRICT |
| id_ruta | INT | FK → ruta, NOT NULL, ON DELETE RESTRICT |
| fecha | DATE | NOT NULL |
| turno | VARCHAR(10) | NOT NULL, CHECK (MANANA, TARDE, NOCHE) |
| hora_inicio | TIME | NOT NULL |
| hora_fin | TIME | NOT NULL, CHECK hora_fin > hora_inicio |
| (compuesta) | | UNIQUE (id_vehiculo, fecha, turno) |

## responsable
Autoridad que realiza inspecciones.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_responsable | INT autoincremental | PK |
| nombre | VARCHAR(100) | NOT NULL |
| entidad | VARCHAR(100) | NOT NULL |

## inspeccion
Visita de verificación a una empresa.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_inspeccion | INT autoincremental | PK |
| id_empresa | INT | FK → empresa_operadora, NOT NULL, ON DELETE RESTRICT |
| id_responsable | INT | FK → responsable, NOT NULL, ON DELETE RESTRICT |
| fecha | DATE | NOT NULL, DEFAULT fecha actual |

## inspeccion_detalle
Resultado por condición verificada en una inspección.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_detalle | INT autoincremental | PK |
| id_inspeccion | INT | FK → inspeccion, NOT NULL, ON DELETE RESTRICT |
| condicion | VARCHAR(20) | NOT NULL, CHECK (LABORAL, PARADAS, RECAUDO) |
| resultado | VARCHAR(15) | NOT NULL, CHECK (CUMPLE, NO_CUMPLE, OBSERVACION) |
| (compuesta) | | UNIQUE (id_inspeccion, condicion) |

## reporte_ilegal
Totales de transporte ilegal por zona y periodo (sin identificar personas).

| Campo | Tipo | Restricciones |
|---|---|---|
| id_reporte | INT autoincremental | PK |
| id_zona | INT | FK → zona, NOT NULL, ON DELETE RESTRICT |
| anio | SMALLINT | NOT NULL, CHECK entre 2020 y 2100 |
| mes | SMALLINT | NOT NULL, CHECK entre 1 y 12 |
| total_reportes | INT | NOT NULL, DEFAULT 0, CHECK >= 0 |
| (compuesta) | | UNIQUE (id_zona, anio, mes) |

## auditoria
Rastro de cambios, llenado por triggers.

| Campo | Tipo | Restricciones |
|---|---|---|
| id_auditoria | INT autoincremental | PK |
| tabla_afectada | VARCHAR(40) | NOT NULL |
| operacion | VARCHAR(10) | NOT NULL, CHECK (INSERT, UPDATE, DELETE) |
| id_registro | INT | NOT NULL |
| usuario_bd | VARCHAR(80) | NOT NULL |
| fecha_evento | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| detalle | VARCHAR(255) | NULL |
