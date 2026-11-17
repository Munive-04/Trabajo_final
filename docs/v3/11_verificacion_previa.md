# E11 · Verificación previa de compatibilidad (MariaDB)

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

Revisión de las funciones usadas frente a la versión mínima de MariaDB que las soporta.

| Característica usada | Dónde | Versión mínima | Observación |
|---|---|---|---|
| `CHECK` que se hace cumplir | DDL (18 restricciones) | MariaDB 10.2.1 | En versiones anteriores se aceptaba la sintaxis pero se ignoraba |
| `DEFAULT (CURRENT_DATE)` | `inspeccion.fecha` | 10.2.1 | Expresiones como valor por defecto |
| Funciones de ventana (`LAG … OVER`) | `v_tendencia_ilegal` | 10.2.0 | — |
| `COMMENT` en tablas y columnas | DDL | Soportado | Límites: 2.048 caracteres (tabla) y 1.024 (columna); los usados son menores (máx. 179 y 212) |
| `CREATE OR REPLACE VIEW` | Vistas | Soportado | — |
| `GROUP_CONCAT(DISTINCT … ORDER BY … SEPARATOR …)` | `v_puntos_transbordo` | Soportado | — |
| `SIGNAL SQLSTATE '45000'` y `GET DIAGNOSTICS` | Triggers y procedimientos | Soportado | — |
| `INFORMATION_SCHEMA.CHECK_CONSTRAINTS` | `13` V5b | 10.2.1 | — |
| `ANALYZE <consulta>` | `07`, `16` | 10.1 | Instrucción propia de MariaDB |
| `DELIMITER` | `04`, `05` | Cliente | Lo interpretan el cliente `mysql` y la importación de phpMyAdmin |

## Diferencias con otros motores (si se migrara)
- **MySQL:** `CHECK` solo se aplica desde 8.0.16; `ANALYZE <consulta>` no existe (se usa `EXPLAIN ANALYZE` desde 8.0.18).
- **PostgreSQL:** `AUTO_INCREMENT` pasa a `IDENTITY`/`SERIAL`, `COMMENT` a `COMMENT ON`, y triggers y rutinas usan PL/pgSQL.
- **SQL Server:** `IDENTITY`, `sp_addextendedproperty` para comentarios y T-SQL para rutinas.

## Compatibilidad comprobada y no comprobada
- **Comprobada:** el equipo ejecutó todos los scripts en MariaDB (XAMPP) sin errores (reportado, 13-nov-2026).
- **No se requiere:** el docente indicó que no hace falta registrar la versión exacta de MariaDB.

*Estado:* PROBADO EN SGBD (reportado).
