# 12b · Migración solo documental (comentarios) — PENDIENTE JUSTIFICADA

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

**Estado: BORRADOR NO EJECUTABLE HASTA COTEJAR METADATOS. No se generó un script SQL.**

## Por qué no hay script
El prompt maestro pide una migración de comentarios **solo cuando existe un esquema previo que no se puede recrear** y se conocen sus definiciones reales. En este proyecto el esquema inicial (`01_ddl.sql`) se **recreó** con el DDL documentado (`12_creacion_esquema_mariadb.sql`), que conserva exactamente el mismo diseño (ver `13a_comparacion_documental.md`). Por eso la migración no fue necesaria.

## Cuándo sí haría falta
Si se quisiera comentar la base **sin borrarla** (por ejemplo, con datos que no se pueden recargar), habría que:
1. Obtener la definición real de cada tabla: `SHOW CREATE TABLE <tabla>;` (las 12 tablas) y `SHOW FULL COLUMNS FROM <tabla>;`.
2. Comparar esas definiciones con las de `12_creacion_esquema_mariadb.sql`, excluyendo solo los comentarios. Cualquier otra diferencia se marca **FALLO: NO EJECUTAR MIGRACIÓN**.
3. Para el comentario de tabla: `ALTER TABLE <tabla> COMMENT = '...';`.
4. Para el comentario de columna: `ALTER TABLE <tabla> MODIFY COLUMN <columna> <definición completa vigente> COMMENT '...';`. **`MODIFY` obliga a repetir toda la definición** (tipo, longitud, NULL, DEFAULT, AUTO_INCREMENT, collation); omitir algo la cambiaría.
5. Hacer copia de seguridad antes y ejecutar fuera de horas de uso.

## Riesgos que deben conocerse
- `ALTER TABLE` puede **bloquear** la tabla o **reconstruirla** según la versión y el motor.
- En MariaDB, el DDL produce **confirmación implícita**: no hay `ROLLBACK` universal.
- No se debe usar `DROP`, `TRUNCATE`, `DELETE` ni `UPDATE` de registros en una migración documental.

## Datos necesarios para completarla
La salida de `SHOW CREATE TABLE` de las 12 tablas del esquema que se quiera migrar.

*Estado:* PENDIENTE JUSTIFICADA (no requerida).
