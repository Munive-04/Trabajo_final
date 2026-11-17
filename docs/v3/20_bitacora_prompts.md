# 20 · Bitácora de prompts y revisión humana

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

Resumen de la intención de cada interacción relevante, **no una transcripción literal**. Las fechas se indican solo cuando constan en los archivos.

| # | Intención | Versión | Propuesta de la IA | Revisión humana | Corrección | Aprobación |
|---|---|---|---|---|---|---|
| 1 | Elegir el problema y delimitar el alcance (Fase 1) | v1 | Alcance, 12 entidades, cardinalidades, 7 reglas, glosario y ER | Revisó las opciones de diseño | Se mantuvo la propuesta | «Estoy de acuerdo»: sin conductores, `tipo` como atributo, turno y condición con `CHECK` |
| 2 | Modelo lógico y normalización (Fase 2) | v1 | Modelo de 12 tablas y justificación 1FN–3FN | Revisó el modelo | La IA detectó al normalizar que `resultado_general` era derivado (se eliminó) y que `periodo` debía ser `anio` + `mes` | Elección del motor: MariaDB en XAMPP |
| 3 | DDL, DML y pruebas de integridad (Fase 3) | v1 | Scripts 01 a 03 con datos ficticios | Los ejecutó en XAMPP | — | «Todo correcto, y verificado» |
| 4 | Lógica avanzada (Fase 4) | v1 | Vistas, UDF, procedimientos, triggers, pruebas y EXPLAIN (scripts 04 a 07) | Ejecutó los scripts | — | «Todo compiló sin errores» |
| 5 | Memoria técnica y README (Fase 5) | v1 | Documento de 6 apartados y README | Revisión pendiente de capturas | Se actualizó con los números nuevos | En curso |
| 6 | Verificar entregables por fase | v1 | Auditoría contra la guía del PDF | Leyó los hallazgos | **Se detectó que el ER de la Fase 1 estaba desactualizado**; se reemplazó por `er_diagrama.mmd` (10-nov-2026) | Aceptó el plan de cierre |
| 7 | Verificar contra el prompt maestro V3 | v1 | Matriz de brechas (COMMENT nativo, DML masivo, trazabilidad, etc.) | Decidió cumplir el V3 | — | «Comencemos con el DDL» |
| 8 | DDL documentado (12, 12a, 12c, 13) | v1 | `COMMENT` nativo en 12 tablas y 56 columnas, inventario CSV y reporte de mejoras | Ejecutó los scripts | Comparación normalizada: diseño idéntico a `01_ddl.sql` | «Sigamos con el DML masivo» |
| 9 | DML masivo (14, 14a, 15) | v2 | 24.216 filas; 10.000 en `asignacion` e `inspeccion_detalle`; generador reproducible (sesión anterior) | Auditado en esta sesión | **Se corrigió el plan 14a, que omitía que `reporte_ilegal` también cambió** (12-nov-2026) | Aprobó las tablas objetivo al continuar |
| 10 | Consultas y plan de pruebas (16, 17) | v1 | 14 consultas y plan con 7 EXPLAIN (sesión anterior) | Auditados: los 14 esperados se recalcularon | **Se corrigieron** la lista de técnicas de 16, «6» por «7» consultas en 17 y «9» por «10» mejoras en la memoria (13-nov-2026) | «Primero audita el 16 y el 17» |
| 11 | Ejecución en MariaDB | — | Resultados esperados por script | Ejecutó todo y comparó | — | «Todo probado y ejecutado; los resultados concuerdan» (13-nov-2026) |
| 12 | Cerrar los entregables del V3 | v1 | Documentos E1 a E11, matriz, auditoría final; «límite de cupo» como no aplicable | Pendiente de revisión | — | Pendiente |

## Revisión crítica real de la IA
Ver `18_auditoria_final.md`, sección 3: cuatro correcciones con evidencia.

## Límite de esta bitácora
Los resultados esperados los calculó la IA en SQLite; la confirmación en MariaDB es un **reporte del equipo**. Las capturas deben conservarse en `evidencias/`.
