# E6 · Normalización

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

## Dependencias funcionales relevantes

| Tabla | Dependencias funcionales |
|---|---|
| empresa_operadora | id_empresa → nit, nombre, estado · nit → id_empresa |
| vehiculo | id_vehiculo → id_empresa, placa, capacidad, accesibilidad, estado · placa → id_vehiculo |
| paradero | id_paradero → id_zona, nombre, tipo, habilitado |
| ruta | id_ruta → codigo, nombre, estado · codigo → id_ruta |
| ruta_paradero | (id_ruta, id_paradero) → orden · (id_ruta, orden) → id_paradero |
| asignacion | id_asignacion → todos · (id_vehiculo, fecha, turno) → id_asignacion |
| inspeccion_detalle | id_detalle → todos · (id_inspeccion, condicion) → id_detalle, resultado |
| reporte_ilegal | id_reporte → todos · (id_zona, anio, mes) → total_reportes |

En todas las tablas el determinante es una clave candidata o una superclave: el modelo cumple **Boyce-Codd**, que es más exigente que la 3FN.

## Punto de partida (tabla plana)
`ASIGNACION_PLANA(placa, nit, nombre_empresa, capacidad, tiene_rampa, codigo_ruta, nombre_ruta, paraderos, zona_paradero, fecha, turno, hora_inicio, hora_fin)`

## Paso a paso
**1FN.** La columna `paraderos` guardaba una lista («Terminal, Parque Bolívar, Mercado»). Se separa en filas: nace `ruta_paradero` con `orden`. El periodo de los reportes se parte en `anio` y `mes`.

**2FN.** En `ruta_paradero` la clave es compuesta. `orden` depende de la clave completa, pero el nombre de la ruta dependería solo de `id_ruta` y la zona solo de `id_paradero`: esos datos pasan a `ruta` y `paradero`.

**3FN.** `id_vehiculo → id_empresa → nombre_empresa` se resuelve con `empresa_operadora`; la asignación no guarda la empresa porque se obtiene por el vehículo. `id_paradero → id_zona → nombre_zona` se resuelve con `zona`. El resultado general de una inspección dependía del conjunto de sus detalles, por lo que **se eliminó** de `inspeccion` y se calcula en la vista `v_cumplimiento_empresa`.

## Anomalías que la normalización previene

| Anomalía | En la tabla plana | En el modelo final |
|---|---|---|
| **Inserción** | No se puede registrar una ruta, un paradero o un vehículo sin una asignación | Cada entidad se registra por separado |
| **Modificación** | Cambiar el nombre de una empresa obliga a actualizar todas las filas de sus asignaciones; olvidar una crea inconsistencia | El nombre vive en una sola fila de `empresa_operadora` |
| **Eliminación** | Borrar la última asignación de una ruta elimina también los datos de la ruta y de sus paraderos | Rutas, paraderos y vehículos viven en sus propias tablas; además las FK con `RESTRICT` protegen el historial |

## Desnormalización
No se aplicó ninguna. Los datos derivados (resultado de inspección, porcentaje de cumplimiento, accesibilidad) se calculan en vistas y funciones.

*Estado:* REVISADO ESTÁTICAMENTE.
