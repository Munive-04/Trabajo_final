# 17 · Plan de pruebas y rendimiento

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

## 1. Estado de la evidencia (R8)

| Estado | Significado en este proyecto |
|---|---|
| **PROBADO EN SGBD (reportado)** | El equipo informó el 13-nov-2026 que ejecutó los scripts 12 a 16 y 03 a 07 en MariaDB (XAMPP) con la carga masiva de `14`, sin errores y con resultados que coinciden con los esperados. **Las capturas deben guardarse en `evidencias/`** como respaldo. |
| **REVISADO ESTÁTICAMENTE** | Solo para lo que no se ejecutó: por ejemplo, las columnas «Observado» e «Interpretación» de los EXPLAIN, que siguen pendientes de pegar. |

Los tiempos de ejecución **no se han medido**: no se afirma que ninguna consulta sea rápida o lenta.

## 2. Pruebas por regla crítica

Datos de entrada: todos ficticios, de `14_carga_datos_sinteticos_mariadb.sql`.

| Regla | Prueba positiva | Prueba negativa | Resultado esperado | Estado |
|---|---|---|---|---|
| **RN1** un vehículo no puede estar en dos rutas en el mismo turno | TP1 (06): asignar vehículo 1, ruta 1, 2027-01-15, MANANA | P6 (03) y TP2 (06): repetir vehículo, fecha y turno | Positiva: id 10001. Negativa: error 1062 con `uq_asig_vehiculo_fecha_turno` | PROBADO EN SGBD (reportado) |
| **RN2** solo paraderos autorizados | TT2 (06): añadir un paradero habilitado a la ruta 1 y revertir | TT1 y TT3 (06): paradero no habilitado al insertar y al actualizar | Negativas: error 1644 «RN2: solo se pueden programar paraderos autorizados» | PROBADO EN SGBD (reportado) |
| **RN3** orden único por ruta | `15` V3: cero duplicados en la carga | P7 (03): repetir el orden 1 en la ruta 1 | Negativa: error 1062 con `uq_ruta_orden` | PROBADO EN SGBD (reportado) |
| **RN4** hora de fin posterior a la de inicio | TP1 (06) | P5 (03) y TP5 (06): 12:30 a 05:30 | Negativa: error 4025 `ck_asig_horas` | PROBADO EN SGBD (reportado) |
| **RN5** un reporte por zona y periodo, total no negativo | `15` V3: cero duplicados | P8, P9 y P10 (03) | Errores 4025 (`ck_reporte_total`, `ck_reporte_mes`) y 1062 (`uq_reporte_zona_periodo`) | PROBADO EN SGBD (reportado) |
| **RN6** se conserva el historial | P14 (03): `CASCADE` solo en `ruta_paradero` | P12 (03): borrar la empresa 1 | Negativa: error 1451 | PROBADO EN SGBD (reportado) |
| **RN7** resultado en dominio fijo | TP6 (06): inspección válida, id 3341 | P13 (03) y TP7 (06): resultado `TAL_VEZ` | Negativa: error 4025 `ck_det_resultado` y rollback sin huérfanos (3341 inspecciones, 10003 detalles) | PROBADO EN SGBD (reportado) |
| **RN8** solo vehículos operativos en rutas activas | TP1 (06) | TP3, TP4 y TT4 (06): vehículo 101 en mantenimiento y ruta 11 inactiva | Error 1644 «Control: solo vehiculos en estado OPERATIVO…» y «…rutas ACTIVAS» | PROBADO EN SGBD (reportado) |
| **RN9** no retirar vehículos con asignaciones futuras | TP8 (06): vehículo 2 a MANTENIMIENTO y vuelta | TP9 (06): vehículo 1 con asignación de 2027-01-15 | Negativa: «ERROR: el vehiculo tiene 1 asignacion(es) futura(s)…» | PROBADO EN SGBD (reportado) |
| **RF8** historial y auditoría | TT5 y TT6 (06): 53 filas en `auditoria` | TT7 (06): actualizar sin cambio de estado no registra | `auditoria` en 53 filas | PROBADO EN SGBD (reportado) |
| **Privacidad** no se almacenan conductores ni personas en los reportes | `13` V8 (`SHOW CREATE TABLE`): ninguna tabla ni columna de conductor | No aplica: no existe dónde guardarlos | 12 tablas sin datos personales de conductores | PROBADO EN SGBD (reportado) |
| **Integridad de la carga** | `15` V1, V2 y V4 | `15` V3 | Conteos esperados y 0 en huérfanos, duplicados y violaciones | PROBADO EN SGBD (reportado) |

## 3. Consultas funcionales (`16_consultas_validacion_mariadb.sql`)

| Consulta | Pregunta del enunciado / invariante | Técnica | Esperado | Caso límite | Estado |
|---|---|---|---|---|---|
| Q01 | ¿Qué vehículos operan por ruta, fecha y turno? | JOIN | 4 filas (R08, 2026-01-02, MANANA) | Ruta R11: 0 filas | PROBADO EN SGBD (reportado) |
| Q02 | Asignaciones por mes y turno | GROUP BY | oct 2026: MANANA 423, NOCHE 265, TARDE 379 | Rango sin datos: 0 filas | PROBADO EN SGBD (reportado) |
| Q03 | ¿Qué proporción de la flota es accesible? | GROUP BY, HAVING | 21 empresas con 3 o más vehículos | `@p_min_flota = 100`: 0 filas | PROBADO EN SGBD (reportado) |
| Q04 | ¿Qué sectores no tienen cobertura? | Subconsulta | 14 zonas | 4 de ellas sí tienen paraderos | PROBADO EN SGBD (reportado) |
| Q05 | Paraderos habilitados fuera de rutas | JOIN | 5 filas | Ninguna es terminal | PROBADO EN SGBD (reportado) |
| Q06 | ¿Dónde están los puntos de transbordo? | Vista | 5 terminales con 10 o más rutas | `@p_min_rutas = 14`: 0 filas | PROBADO EN SGBD (reportado) |
| Q07 | ¿Qué empresas cumplen condiciones? | Vista | 15 empresas con clasificación CUMPLE | Las 3 sin inspecciones no aparecen | PROBADO EN SGBD (reportado) |
| Q08 | Incumplimientos en recaudo | JOIN, GROUP BY | 55, 42 y 39 (tres empresas) | Sin inspecciones no aparece | PROBADO EN SGBD (reportado) |
| Q09 | Cumplimiento por condición | GROUP BY | RECAUDO 60,02 %, PARADAS 65,73 %, LABORAL 69,37 % | OBSERVACION no cuenta | PROBADO EN SGBD (reportado) |
| Q10 | Zonas con más reportes ilegales | JOIN, GROUP BY, HAVING | 8 zonas con 100 o más | `@p_min = 1000`: 0 filas | PROBADO EN SGBD (reportado) |
| Q11 | Vehículos operativos sin asignaciones | Subconsulta | octubre: 0 filas | Un solo día (domingo): 88 filas | PROBADO EN SGBD (reportado) |
| Q12 | Invariante: sin horas solapadas del mismo vehículo | JOIN propio | 0 filas | 1.029 pares de turnos sin solape no aparecen | PROBADO EN SGBD (reportado) |
| Q13 | Vigencia de inspecciones | LEFT JOIN, HAVING | 2 empresas sin inspección | `@p_dias = 30`: 3 filas | PROBADO EN SGBD (reportado) |
| Q14 | Indicadores generales | Vista | 46, 108, 36,21 %, 47, 54, 14, 65,04 % | Coincide con Q04 (14 zonas) | PROBADO EN SGBD (reportado) |

## 3b. Conceptos del V3 que NO APLICAN a este modelo

| Concepto | Estado | Justificación |
|---|---|---|
| **Límite de cupo** (aforo, plazas o reservas con tope) | **NO APLICA** | El modelo no maneja cupos: el enunciado no pide reservar ni limitar el número de pasajeros, y los pasajeros están fuera del alcance (no se registran). `vehiculo.capacidad` es un dato descriptivo de la flota (RF2) que no se contrasta con ninguna ocupación, y no existe una regla de negocio que limite asignaciones por capacidad. La regla más cercana a un tope de recurso es **RN1** (un vehículo solo puede ocupar un turno por fecha), que sí se prueba (TP1, TP2, P6 y 15 V3). Inventar una regla de cupo sería complejidad artificial (R12). |

## 4. Rendimiento: EXPLAIN

Se analizan 7 consultas (mínimo exigido: 3). Con 10.000 asignaciones y 3.340 inspecciones, el optimizador debería usar los índices en E1, E3 y Q01; en E2 (60 filas) puede elegir recorrer la tabla completa.

| Id | Consulta (script) | Índice relevante | Qué se espera ver | Observado | Interpretación |
|---|---|---|---|---|---|
| E1 | Vehículos de una ruta, fecha y turno (07) | `idx_asig_ruta_fecha_turno` | `type = ref`, `key` = ese índice, pocas filas; con `IGNORE INDEX`, `type = ALL` con ~10.000 | [pegar] | [completar] |
| E2 | Paraderos habilitados de la zona 35 (07) | `idx_paradero_zona_hab` | Con índice, `key` = ese índice; sin él, `ALL` con ~60 filas | [pegar] | [completar] |
| E3 | Inspecciones de la empresa 1 en un rango (07) | `idx_insp_empresa_fecha` | `range` o `ref` sobre el índice; sin él, `ALL` con ~3.340 | [pegar] | [completar] |
| E4 | Vista de cobertura (07) | Índices de FK y compuesto | Uso de índice en `paradero` y `ruta_paradero`; posible `Using temporary` | [pegar] | [completar] |
| E-Q01 | Vehículos por ruta, fecha y turno con JOIN (16) | `uq_ruta_codigo` y `idx_asig_ruta_fecha_turno` | `ruta` por código y `asignacion` por `ref` | [pegar] | [completar] |
| E-Q11 | `NOT EXISTS` por vehículo y periodo (16) | `uq_asig_vehiculo_fecha_turno` | Búsqueda por (`id_vehiculo`, `fecha`) en la subconsulta | [pegar] | [completar] |
| E-Q12 | Auto-join de asignaciones (16) | `uq_asig_vehiculo_fecha_turno` | `ref` por (`id_vehiculo`, `fecha`) | [pegar] | [completar] |

**Para el informe:** de cada plan anoten `type`, `key`, `rows` y `Extra`. `ANALYZE` (en 16) añade filas y tiempos reales; **anoten solo lo que midan**. Si un índice debe cambiarse, se justifica, se pide aprobación y se actualizan el diseño y las evidencias.

## 5. Hallazgos de la revisión crítica

1. **Solapes horarios (Q12 / M10).** Al revisar la carga se detectó que la primera versión del generador producía **162 casos** en que un mismo vehículo tenía horas solapadas el mismo día en turnos consecutivos (por ejemplo, MANANA hasta las 13:00 y TARDE desde las 12:30). No violaba RN1, que solo habla del mismo turno, pero era un dato poco realista. El generador se corrigió y ahora comprueba la ausencia de solapes antes de escribir el archivo. **La base de datos sigue sin impedirlo** (mejora M10 en `12c`, no aplicada).
2. **Esperados calculados fuera del servidor y confirmados en MariaDB.** Los resultados esperados de `06`, `15` y `16` se calcularon en SQLite; el equipo reportó que MariaDB los confirmó. Si en alguna captura aparece una diferencia, la causa más probable es la colación al ordenar nombres con tildes.

## 6. Pendientes para cerrar la evidencia
1. Guardar en `evidencias/` las capturas de las ejecuciones ya realizadas (12 a 16, 03 a 07).
2. Pegar la salida real de cada EXPLAIN en la columna «Observado» de la sección 4 e interpretarla (`type`, `key`, `rows`, `Extra`).
3. Si algún resultado difiere del esperado, registrarlo aquí con su causa antes de cambiar nada.
