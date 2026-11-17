# 12c · Mejoras de diseño NO aplicadas

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

**Regla R14 (inmutabilidad):** al documentar el DDL no se rediseñó nada. `12_creacion_esquema_mariadb.sql` conserva exactamente las definiciones de `01_ddl.sql` (comparación normalizada excluyendo solo comentarios: idéntica).
Lo que sigue son hallazgos detectados durante la documentación. **Ninguno se aplicó.** Cada uno requiere decisión y aprobación explícita antes de cambiar el diseño, y obligaría a actualizar DDL, DML, pruebas y memoria.

**Estado:** REVISADO ESTÁTICAMENTE (análisis de diseño; no se ejecutó ninguna prueba).

| # | Hallazgo | Gravedad | Requisito afectado | Cambio alternativo | Consecuencia si se aplica |
|---|---|---|---|---|---|
| M1 | Los turnos no pueden cruzar la medianoche: `CHECK (hora_fin > hora_inicio)` rechaza un turno nocturno que termina al día siguiente. | Media | RF5, RN4 | Agregar `fecha_fin` o una duración en minutos, o permitir `hora_fin < hora_inicio` cuando el turno es NOCHE. | Cambia columnas y el CHECK; hay que regenerar datos y las pruebas de RN4. |
| M2 | La hora de inicio y fin no se valida contra el turno: se podría guardar un turno MANANA con horas de la noche. | Media | RF5 | `CHECK` por turno o una tabla `turno` con su franja horaria. | Nueva tabla o CHECK más complejo; contradice la decisión aprobada de turno como `CHECK` sin catálogo. |
| M3 | RN2 solo se valida al **programar** la parada. Deshabilitar después un paradero que ya está en una ruta no genera alerta ni bloqueo. | Media | RN2 | Trigger BEFORE UPDATE en `paradero` que impida deshabilitar uno usado en rutas activas, o una vista de control de inconsistencias. | Nuevo trigger y pruebas; define qué hacer con rutas ya existentes. |
| M4 | El estado SUSPENDIDA de una empresa no tiene efecto: sus vehículos siguen pudiendo asignarse. El enunciado no define sus causas ni efectos. | Media | RF1, RN8 | Ampliar `trg_asignacion_bi` para rechazar vehículos de empresas suspendidas. | Cambia la regla RN8 y los datos de prueba (hoy hay asignaciones de vehículos de empresas suspendidas). **PENDIENTE DE CONFIRMAR con el docente.** |
| M5 | La auditoría no registra borrados ni cambios en otras tablas, aunque el dominio de `operacion` admite DELETE. | Baja | RF8 | Triggers AFTER DELETE y AFTER UPDATE en las tablas relevantes. | Más triggers; crece `auditoria`. |
| M6 | Turno, condición, estados y tipo de paradero son dominios `CHECK`; cambiar uno exige `ALTER TABLE`. | Baja | RF2, RF3, RF5, RF6 | Tablas catálogo con FK. | Es una decisión ya aprobada y justificada; aplicarla agrega tablas con pocas filas (no llegarían a 50). |
| M7 | El periodo se guarda como `anio` y `mes` en dos columnas, sin garantía de que el mes sea del pasado ni coherente con el calendario. | Baja | RF7 | Una sola columna `DATE` con el primer día del mes. | Cambia el UNIQUE y las vistas de tendencia; más simple pero distinto del modelo aprobado. |
| M8 | NIT y placa no tienen validación de formato (solo unicidad). | Baja | RF1, RF2 | `CHECK` con expresión regular o longitudes mínimas. | Riesgo de rechazar datos sintéticos válidos; depende del formato real. |
| M9 | No se impide repetir el nombre de un paradero dentro de una zona. | Baja | RF3 | `UNIQUE (id_zona, nombre)`. | Podría chocar con la carga sintética si hay nombres repetidos. |
| M10 | RN1 solo impide repetir el **mismo turno**: no impide que un vehículo tenga dos asignaciones con horas solapadas el mismo día en turnos distintos (por ejemplo, MANANA hasta las 13:00 y TARDE desde las 12:30). La consulta Q12 detectó 162 casos en una primera versión del generador, que se corrigió; la base de datos, en cambio, sigue sin garantizarlo. | Media | RF5, RN1 | Trigger BEFORE INSERT que compare las horas con las demás asignaciones del vehículo en esa fecha. | Nuevo trigger y pruebas; hay que decidir si un solape parcial se rechaza o solo se advierte. |

## Preguntas abiertas (significado no confirmado)
1. **`empresa_operadora.estado` (SUSPENDIDA):** causas y efectos no definidos en el enunciado. Impacto: M4.
2. **`vehiculo.capacidad`:** se interpreta como número de pasajeros, sin distinguir sentados de pie. Impacto: bajo, solo semántico.

## Cómo usar este reporte
Si el equipo o el docente aprueban alguno, se registra como nueva versión del diseño y se actualizan **todas** las evidencias afectadas (DDL, DML, pruebas, memoria). Mientras tanto, M1, M3 y M5 ya figuran en la sección de limitaciones de la memoria técnica; M2 y M4 conviene agregarlas allí.
