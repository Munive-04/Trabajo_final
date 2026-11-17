# 18 · Auditoría final, defensa y entrega (Fase 6 del V3)

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

## 1. Cómo leer los estados
- **PROPUESTO:** idea o diseño sin revisión (aquí: mejoras M1 a M10 de `12c`).
- **REVISADO ESTÁTICAMENTE:** leído y comprobado sin ejecutarlo en el servidor.
- **PROBADO EN SGBD (reportado):** ejecutado en MariaDB (XAMPP) por el equipo, que informó resultados coincidentes con los esperados (13-nov-2026). Respaldo pendiente: **capturas en `evidencias/`**.

**«Completa» como archivo no significa «probada en SGBD».**

## 2. Tabla E1 a E20

| E | Archivo | Criterio verificable | Estado del archivo | Estado de la evidencia |
|---|---|---|---|---|
| E1 | `01_analisis_semantico.md` | Hechos, inferencias, supuestos, dudas, redacción mejorada, R/RN/D con criterios | Completa | Revisado estáticamente |
| E2 | `02_catalogo_conceptual.md` | 10 entidades justificadas; 9 relaciones con cardinalidad | Completa | Revisado estáticamente |
| E3 | `03_diagrama_conceptual.md` | Especificación Chen y Mermaid rotulado «NO ES CHEN» | Completa; **falta exportar `er.png`** | Revisado estáticamente |
| E4 | `04_trazabilidad_conceptual.csv` | 17 filas (R01 a R08 y RN01 a RN09) | Completa | Revisado estáticamente |
| E5 | `05_modelo_logico.md` | 12 tablas con PK, FK y claves únicas; relaciones justificadas | Completa | Revisado estáticamente |
| E6 | `06_normalizacion.md` | Dependencias, 1FN a 3FN y BCNF, tres anomalías | Completa | Revisado estáticamente |
| E7 | `07_diagrama_logico.mmd` | Editable con PK/FK | Completa; **falta captura del Diseñador de phpMyAdmin** | Revisado estáticamente |
| E8 | `08_trazabilidad_logica.csv` | 17 filas con tabla y restricción | Completa | Revisado estáticamente |
| E9 | `09_diccionario_fisico.csv` | 56 columnas con tipo, NULL, DEFAULT y restricciones | Completa | Derivado del DDL probado |
| E10 | `10_especificacion_fisica.md` | Motor, tipos, FK, índices, orden, reglas fuera del DDL | Completa (versión exacta de MariaDB no requerida por el docente) | Probado en SGBD (reportado) |
| E11 | `11_verificacion_previa.md` | Compatibilidad por versión | Completa | Probado en SGBD (reportado) |
| E12 | `14_carga_datos_sinteticos_mariadb.sql` y `14_generador_datos.py` | 24.216 filas; 10.000 en 2 tablas; reproducible | Completa | Probado en SGBD (reportado) |
| E13 | `14a_plan_volumen.md` | Tabla de volumen y justificación | Completa | Revisado estáticamente |
| E14 | `15_verificaciones_carga_mariadb.sql` | 9 verificaciones con esperados | Completa | Probado en SGBD (reportado) |
| E15 | `16_consultas_validacion_mariadb.sql` | 14 consultas con requisito, parámetros, esperado y caso límite | Completa | Probado en SGBD (reportado) |
| E16 | `17_plan_pruebas_y_rendimiento.md` | Pruebas por regla y 7 EXPLAIN planificados | Completa como plan; **faltan «Observado» e «Interpretación» de los EXPLAIN** | Parcial |
| E17 | `12a_inventario_documentacion.csv` | 139 objetos con comentario propuesto y estado | Completa | Revisado estáticamente |
| E18 | `12b_migracion_solo_comentarios_PENDIENTE.md` | Pendiente justificada (esquema recreado) | Completa (no requerida) | — |
| E19 | `13a_comparacion_documental.md` | Antes y después; sin diferencias no documentales | Completa; **captura del «antes» por confirmar** | Mixto |
| E20 | `12c_mejoras_diseno_no_aplicadas.md` | 10 hallazgos, ninguno aplicado | Completa | Propuesto |

Complementos del DDL: `12_creacion_esquema_mariadb.sql`, `12_opcional_crear_bd_mariadb.sql` y `13_verificaciones_estructura_mariadb.sql` (**Probado en SGBD, reportado**). La matriz de trazabilidad completa está en `19_matriz_trazabilidad.csv` y la bitácora en `20_bitacora_prompts.md`.

## 3. Revisión crítica real de la IA (con evidencia)
1. **ER desactualizado.** El diagrama de la Fase 1 conservaba `resultado_general` y `periodo`, eliminados en la Fase 2. Se detectó al verificar los entregables y se reemplazó por `er_diagrama.mmd` (10-nov-2026).
2. **Solapes horarios en la carga.** La primera versión del generador producía 162 casos de un mismo vehículo con horas solapadas el mismo día. Se detectó al revisar la carga, se corrigió el generador y se añadió la consulta Q12 y la mejora M10.
3. **EXPLAIN sin efecto visible.** El análisis de paraderos filtraba por la zona 1, que no tiene paraderos (devolvería cero filas). Se cambió a la zona 35, que tiene 4 paraderos habilitados.
4. **Omisión en el plan de volumen.** `14a` no decía que `reporte_ilegal` también se regeneró (cambian los totales de tendencia). Corregido el 12-nov-2026. Además, el 13-nov se corrigieron tres imprecisiones menores (técnicas de 16, «6» por «7» EXPLAIN en 17, «9» por «10» mejoras).

**Limitación reconocida:** los resultados esperados se calcularon en SQLite; su confirmación en MariaDB es un reporte del equipo.

## 4. Conceptos del V3 que no aplican
**Límite de cupo: no aplica.** No hay cupos ni aforos que limitar, los pasajeros están fuera del alcance y `capacidad` es un dato descriptivo. La regla más cercana a un tope de recurso es RN01 (probada). Ver `17_plan_pruebas_y_rendimiento.md`, sección 3b.

## 5. Cinco preguntas de defensa oral
1. **¿Por qué RN02 se implementa con un trigger y no con un `CHECK`, y qué no cubre?** *(Un `CHECK` no consulta otra tabla; no cubre deshabilitar luego un paradero ya usado: M3.)*
2. **¿Qué garantiza RN01 y qué no?** *(Impide repetir vehículo, fecha y turno; no impide solapes entre turnos distintos: M10.)*
3. **¿Por qué las 10.000 filas están en `asignacion` e `inspeccion_detalle` y no en `ruta_paradero` o `reporte_ilegal`?** *(Son las tablas de hechos; las otras están acotadas por su cardinalidad, y inflarlas sería artificial.)*
4. **¿Por qué el resultado general de una inspección no se almacena y cómo se obtiene?** *(Es derivado; evita una dependencia transitiva; se calcula en `v_cumplimiento_empresa`.)*
5. **¿Qué significa «PROBADO EN SGBD (reportado)» y qué falta para respaldarlo del todo?** *(Ejecución por el equipo con resultados coincidentes; faltan las capturas en `evidencias/` y los EXPLAIN observados.)*

## 6. Conclusión
- **Probado en SGBD (reportado):** DDL, carga masiva, verificaciones, consultas, procedimientos, triggers y pruebas de integridad.
- **Revisado estáticamente:** análisis, catálogos, modelos, normalización, inventario y planes.
- **Propuesto y no aplicado:** mejoras M1 a M10.

## 7. Pendientes que solo puede completar el equipo
1. Guardar las capturas en `evidencias/` y exportar `docs/er.png` y la captura del Diseñador de phpMyAdmin.
2. Pegar los EXPLAIN observados y su interpretación (`17`, sección 4, y la memoria 5.6).
3. Confirmar si existe la captura del «antes» de `13`.
4. Completar los corchetes de la memoria (URL del repositorio) y ajustar el Anexo B al trabajo individual.
5. Subir el repositorio (trabajo individual de Luis Munive) y definir con el docente la fecha y el canal de entrega.
