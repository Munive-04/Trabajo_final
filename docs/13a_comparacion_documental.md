# 13a · Comparación documental antes y después

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

**Objetivo.** Demostrar que `12_creacion_esquema_mariadb.sql` agrega **solo comentarios** respecto a `01_ddl.sql`.

## 1. Comparación estática (revisada)
Se normalizaron ambos archivos quitando únicamente los comentarios (`COMMENT '…'`, comentarios SQL) y las sentencias `DROP/CREATE DATABASE` y `USE`, y se compararon.

| Resultado | Valor |
|---|---|
| Definiciones de tablas, columnas, restricciones, índices y orden | **Idénticas** |
| `FALLO: NO EJECUTAR MIGRACIÓN` | No se produce ninguna diferencia no documental |

## 2. Inventario antes y después

| Elemento | `01_ddl.sql` (antes) | `12_creacion_esquema_mariadb.sql` (después) |
|---|---|---|
| Tablas | 12 | 12 |
| Columnas | 56 | 56 |
| Claves primarias | 12 | 12 |
| Claves foráneas | 10 | 10 |
| UNIQUE | 8 | 8 |
| CHECK | 18 | 18 |
| Índices adicionales | 6 | 6 |
| `COMMENT` nativo en tablas | 0 | 12 |
| `COMMENT` nativo en columnas | 0 | 56 |
| Motor / collation | InnoDB / utf8mb4_general_ci | InnoDB / utf8mb4_general_ci |

Los comentarios de restricciones e índices son comentarios SQL (no persistidos en el catálogo) y se documentan en `12a_inventario_documentacion.csv`.

## 3. Comparación ejecutada en el servidor (script `13`)

| Consulta de `13` | Esperado antes | Esperado después | Observado |
|---|---|---|---|
| V1 tablas / columnas | 12 / 56 | 12 / 56 | Coincide (reportado por el equipo, 13-nov-2026) |
| V1 tablas con comentario | 0 | 12 | Coincide (reportado) |
| V1 columnas con comentario | 0 | 56 | Coincide (reportado) |
| V3 columnas sin comentario | 56 filas | 0 filas | Coincide (reportado) |
| V4 definición de columnas | igual | igual (salvo `COLUMN_COMMENT`) | Coincide (reportado) |
| V5 restricciones | PK 12, FK 10, UNIQUE 8 | PK 12, FK 10, UNIQUE 8 | Coincide (reportado) |
| V5b CHECK | 18 | 18 | Coincide (reportado) |
| V6 reglas de FK | CASCADE solo en `fk_rp_ruta` | igual | Coincide (reportado) |
| V7 índices adicionales | 6 | 6 | Coincide (reportado) |

## 4. Qué se revisó estáticamente y qué se comprobó en el servidor
- **Estático:** la identidad de las definiciones (sección 1) y el inventario del DDL (sección 2).
- **En el servidor:** las consultas de `13`, ejecutadas por el equipo, que reportó coincidencia con lo esperado.

## 5. Pendiente de respaldar
Guardar en `evidencias/` las capturas de `13` **después** de recrear la base. La captura del **«antes»** existe solo si el equipo ejecutó `13` sobre la base creada con `01_ddl.sql` antes de recrearla; si no se capturó, debe declararse como *no capturado* (la comparación estática de la sección 1 sigue siendo válida).

*Estado:* REVISADO ESTÁTICAMENTE (secciones 1 y 2) y PROBADO EN SGBD (reportado) (sección 3).
