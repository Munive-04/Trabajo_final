# E5 · Modelo lógico

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

Transformación del modelo conceptual aprobado en 12 tablas relacionales. Las claves primarias son identificadores internos autoincrementales; las claves de negocio se conservan como claves candidatas únicas.

| Tabla | PK | FK | Claves únicas | Notas de integridad |
|---|---|---|---|---|
| empresa_operadora | id_empresa | — | nit | estado ∈ {ACTIVA, SUSPENDIDA} |
| vehiculo | id_vehiculo | id_empresa → empresa_operadora | placa | capacidad > 0; indicadores 0/1; estado ∈ {OPERATIVO, MANTENIMIENTO, RETIRADO} |
| zona | id_zona | — | nombre | — |
| paradero | id_paradero | id_zona → zona | — | tipo ∈ {PARADERO, TERMINAL}; habilitado 0/1 |
| ruta | id_ruta | — | codigo | estado ∈ {ACTIVA, INACTIVA} |
| ruta_paradero | (id_ruta, id_paradero) | id_ruta → ruta; id_paradero → paradero | (id_ruta, orden) | orden > 0 |
| asignacion | id_asignacion | id_vehiculo → vehiculo; id_ruta → ruta | (id_vehiculo, fecha, turno) | turno ∈ {MANANA, TARDE, NOCHE}; hora_fin > hora_inicio |
| responsable | id_responsable | — | — | — |
| inspeccion | id_inspeccion | id_empresa → empresa_operadora; id_responsable → responsable | — | fecha por defecto la actual |
| inspeccion_detalle | id_detalle | id_inspeccion → inspeccion | (id_inspeccion, condicion) | condicion ∈ {LABORAL, PARADAS, RECAUDO}; resultado ∈ {CUMPLE, NO_CUMPLE, OBSERVACION} |
| reporte_ilegal | id_reporte | id_zona → zona | (id_zona, anio, mes) | mes 1 a 12; total ≥ 0 |
| auditoria | id_auditoria | — | — | operacion ∈ {INSERT, UPDATE, DELETE} |

## Justificación de las relaciones
- **1:N** (empresa→vehículo, vehículo→asignación, ruta→asignación, zona→paradero, zona→reporte, empresa→inspección, responsable→inspección, inspección→detalle): la clave foránea va en el lado «muchos».
- **M:N** ruta↔paradero: se resuelve con la tabla puente `ruta_paradero`, cuya clave compuesta evita repetir un paradero en una ruta y que lleva el atributo `orden`.
- **Entidad débil:** `inspeccion_detalle` depende de `inspeccion`; se identifica por (inspección, condición).
- **Sin jerarquías ni atributos multivaluados:** la terminal es un valor de `tipo`; las condiciones inspeccionadas son filas, no una lista en una columna.

## Claves surrogate frente a naturales
Se usan claves internas (`INT AUTO_INCREMENT`) porque las claves de negocio (NIT, placa, código) pueden corregirse; se protegen con `UNIQUE`.

## Reglas que el modelo lógico no puede expresar solo
RN02, RN08 y RN09 dependen de datos de otras tablas; se implementan con triggers y un procedimiento (Fase física). El mínimo de una condición por inspección tampoco queda impuesto.

*Estado:* REVISADO ESTÁTICAMENTE. El diagrama relacional gráfico (Diseñador de phpMyAdmin) es evidencia complementaria.
