# E2 · Catálogo conceptual

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

## Entidades

| Entidad | Naturaleza | Identificador de negocio | Atributos | Justificación |
|---|---|---|---|---|
| EMPRESA_OPERADORA | Maestro | NIT | nit, nombre, estado | Responsable de la flota y sujeto de inspección (R01) |
| VEHICULO | Maestro | Placa | placa, capacidad, tiene_rampa, piso_bajo, espacio_silla_ruedas, estado | Unidad de la flota (R02) |
| ZONA | Dimensión | Nombre | nombre | Ubica paraderos y agrupa reportes (R03, R07) |
| PARADERO | Maestro | — (nombre dentro de la zona) | nombre, tipo, habilitado | Parada o terminal (R03) |
| RUTA | Maestro | Código | codigo, nombre, estado | Recorrido del servicio (R03) |
| ASIGNACION | Transaccional (asociativa) | (vehículo, fecha, turno) | fecha, turno, hora_inicio, hora_fin | Hecho histórico; relaciona vehículo y ruta con atributos y vida propia (R05) |
| RESPONSABLE | Maestro | — | nombre, entidad | Autoridad que inspecciona (R06) |
| INSPECCION | Transaccional | — | fecha | Visita de verificación a una empresa (R06) |
| INSPECCION_DETALLE | Débil (de INSPECCION) | (inspección, condición) | condicion, resultado | Un resultado por condición evaluada (R06) |
| REPORTE_ILEGAL | Hecho agregado | (zona, año, mes) | anio, mes, total_reportes | Total mensual por zona, sin personas (R07) |

*Soporte (no es entidad de negocio):* AUDITORIA, creada por triggers para conservar rastro de cambios (R08).

## Relaciones

| Relación | Entidades | Cardinalidad | Atributos propios |
|---|---|---|---|
| POSEE | EMPRESA_OPERADORA — VEHICULO | 1:N | — |
| SE_ASIGNA | VEHICULO — ASIGNACION | 1:N | — |
| RECIBE | RUTA — ASIGNACION | 1:N | — |
| INCLUYE | RUTA — PARADERO | **M:N** | **orden** |
| UBICADO_EN | ZONA — PARADERO | 1:N | — |
| REGISTRA | ZONA — REPORTE_ILEGAL | 1:N | — |
| ES_INSPECCIONADA | EMPRESA_OPERADORA — INSPECCION | 1:N | — |
| REALIZA | RESPONSABLE — INSPECCION | 1:N | — |
| CONTIENE | INSPECCION — INSPECCION_DETALLE | 1:N (identificadora) | — |

## Atributo, catálogo o entidad: criterios aplicados
- **Turno, condición evaluada, resultado, estados y tipo de paradero** son atributos con dominio fijo (D03, D12), no entidades.
- **Terminal de transferencia** es un valor del atributo `tipo` de PARADERO (D04), no una entidad aparte.
- **Asignación** es entidad y no solo relación, porque tiene identidad, atributos y se consulta como historial.

## Elementos considerados y descartados
CONDUCTOR (D01), PASAJERO, TARIFA, SANCION, PAGO DE RECAUDO y MOTOTAXISTA (fuera de alcance).

*Estado:* REVISADO ESTÁTICAMENTE.
