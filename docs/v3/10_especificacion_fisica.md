# E10 · Especificación física

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

| Aspecto | Decisión |
|---|---|
| SGBD | MariaDB (XAMPP), versión 10.2.1 o superior. **Versión exacta: no se requiere registrarla (indicación del docente)** |
| Base de datos | `setp_santa_marta`, `utf8mb4` / `utf8mb4_general_ci` |
| Motor de almacenamiento | InnoDB en las 12 tablas (claves foráneas y transacciones) |
| Nombres | Minúsculas con guion bajo; restricciones con prefijo (`pk_`, `uq_`, `fk_`, `ck_`), índices con `idx_` |
| Claves primarias | `INT NOT NULL AUTO_INCREMENT` (excepto la compuesta de `ruta_paradero`) |
| Textos | `VARCHAR` con longitud según el dato (NIT 20, placa 10, nombre 80 a 120, estado 15) |
| Fechas y horas | `DATE` para fecha, `TIME` para horas de asignación, `DATETIME` para la auditoría; sin zona horaria (hora del servidor) |
| Booleanos | `TINYINT(1)` con `CHECK` 0/1 |
| Dominios | `CHECK (col IN (...))` para turno, condición, resultado, estados y tipo |
| `NOT NULL` y `DEFAULT` | Todas las columnas `NOT NULL` salvo `auditoria.detalle`; defaults: estados, indicadores, habilitado, total_reportes, fecha de inspección y de auditoría |
| `ON DELETE` / `ON UPDATE` | `RESTRICT` en 9 de las 10 FK; `CASCADE` solo en `ruta_paradero.id_ruta`; `ON UPDATE CASCADE` en todas |
| Índices adicionales | 6: `idx_asig_ruta_fecha_turno`, `idx_paradero_zona_hab`, `idx_insp_empresa_fecha`, `idx_det_condicion_resultado`, `idx_reporte_periodo`, `idx_vehiculo_estado` |
| Comentarios persistentes | `COMMENT` nativo en las 12 tablas y 56 columnas; comentarios SQL en restricciones e índices (no persistidos) |
| Orden de creación | empresa_operadora, vehiculo, zona, paradero, ruta, ruta_paradero, asignacion, responsable, inspeccion, inspeccion_detalle, reporte_ilegal, auditoria; cada tabla se crea después de las que referencia |
| Orden de ejecución del proyecto | 12 opcional → 12 → 14 → 13 → 04 → 15 → 03 → 05 → 06 → 16 → 07 |

## Reglas que requieren lógica fuera del DDL declarativo

| Regla | Mecanismo | Objeto |
|---|---|---|
| RN02 | Trigger BEFORE INSERT y BEFORE UPDATE | `trg_ruta_paradero_bi`, `trg_ruta_paradero_bu` |
| RN08 | Trigger BEFORE INSERT | `trg_asignacion_bi` |
| RN09 | Procedimiento con transacción | `sp_actualizar_estado_vehiculo` |
| Auditoría (R08) | Triggers AFTER | `trg_asignacion_ai`, `trg_vehiculo_au` |
| Atomicidad de altas | Procedimientos con `COMMIT`/`ROLLBACK` | `sp_registrar_asignacion`, `sp_registrar_inspeccion` |

Estas reglas son lógica programada y no DDL: no se presentan como restricciones declarativas.

*Estado:* PROBADO EN SGBD (reportado por el equipo, 13-nov-2026).
