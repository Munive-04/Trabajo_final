# SETP Santa Marta: flota, rutas y cumplimiento del transporte público

Proyecto Integrador Final · Bases de Datos · Universidad del Magdalena
Problema **P11** del Banco de Problemas del Caribe: *Transporte público y mototaxismo: rutas, flota y cumplimiento*.

**Autor:** Luis Munive (código 2022114078) · **Docente:** Leonardo J. Arias-Alemán

## Propósito

Base de datos relacional que organiza la flota, las rutas, los turnos, los paraderos y la verificación de condiciones de operación del transporte público de Santa Marta (SETP), y conserva el historial de asignaciones e inspecciones. Responde cuatro preguntas:

1. ¿Qué vehículos operan por ruta y turno?
2. ¿Qué proporción de la flota es accesible?
3. ¿Qué sectores o paraderos no tienen cobertura?
4. ¿Qué empresas cumplen condiciones y dónde están los puntos de transbordo?

## Contenido del repositorio

```
.
├── README.md
├── sql/
│   ├── 12_opcional_crear_bd_mariadb.sql          Crea la base (opcional, separado)
│   ├── 12_creacion_esquema_mariadb.sql           DDL documentado (COMMENT nativo) · 12 tablas
│   ├── 13_verificaciones_estructura_mariadb.sql  Verificación del catálogo (antes/después)
│   ├── 14_carga_datos_sinteticos_mariadb.sql     DML masivo sintético (24.216 filas)
│   ├── 15_verificaciones_carga_mariadb.sql       Verificación de la carga
│   ├── 03_pruebas_fase3.sql                      Pruebas de integridad (14)
│   ├── 04_funciones_vistas.sql                   2 UDF y 7 vistas analíticas
│   ├── 05_procedimientos_triggers.sql            3 procedimientos con transacciones y 5 triggers
│   ├── 06_pruebas_fase4.sql                      Matriz de pruebas de la lógica avanzada (29)
│   ├── 16_consultas_validacion_mariadb.sql       14 consultas funcionales con casos límite
│   ├── 07_explain.sql                            Análisis de planes de ejecución
│   └── historico/                                01_ddl.sql y 02_datos.sql (versión inicial, superada)
├── generador/
│   └── 14_generador_datos.py                     Genera el DML (semilla 2026, reproducible)
├── docs/
│   ├── memoria_tecnica.pdf                       Memoria técnica (6 apartados)
│   ├── diccionario_datos.md                      Diccionario de datos
│   ├── er_diagrama.mmd / er.png                  Diagrama entidad-relación
│   ├── 12a_inventario_documentacion.csv          Inventario documental
│   ├── 12b_migracion_solo_comentarios_PENDIENTE.md
│   ├── 12c_mejoras_diseno_no_aplicadas.md        Mejoras M1 a M10 detectadas y no aplicadas
│   ├── 13a_comparacion_documental.md             Antes y después del DDL documentado
│   ├── 14a_plan_volumen.md                       Plan de volumen del DML
│   ├── 17_plan_pruebas_y_rendimiento.md          Plan de pruebas y rendimiento
│   └── v3/                                       Entregables del prompt maestro V3 (E1 a E11,
│                                                 auditoría final, matriz de trazabilidad y bitácora)
└── evidencias/                                   Capturas de las pruebas y de EXPLAIN
```

## Requisitos

- XAMPP con MariaDB 10.2.1 o superior (necesario para `CHECK`, `DEFAULT (CURRENT_DATE)` y funciones de ventana).
- phpMyAdmin o el cliente `mysql` incluido en XAMPP.

## Cómo ejecutarlo

Orden validado en MariaDB (XAMPP). Ejecuten **una sola vez** sobre una base vacía.

1. Inicien **Apache** y **MySQL** en el panel de XAMPP.
2. Desde la pestaña **Importar** de phpMyAdmin (como UTF-8), en este orden:
   `12_opcional_crear_bd_mariadb.sql`, `12_creacion_esquema_mariadb.sql` y `14_carga_datos_sinteticos_mariadb.sql`.
   Para reiniciar desde cero, activen el `DROP DATABASE` comentado en el script opcional.
3. Verifiquen la estructura e importen las funciones y vistas, que `15` necesita:

```bash
mysql -u root -t --default-character-set=utf8mb4 < sql/13_verificaciones_estructura_mariadb.sql
mysql -u root --default-character-set=utf8mb4 < sql/04_funciones_vistas.sql
```

4. Verifiquen la carga y corran las pruebas de integridad:

```bash
mysql -u root -t --default-character-set=utf8mb4 < sql/15_verificaciones_carga_mariadb.sql
mysql -u root -t --force --default-character-set=utf8mb4 < sql/03_pruebas_fase3.sql
```

5. **Después** de esas pruebas, creen los triggers y procedimientos (la carga va antes que los triggers: con ellos creados, las 10.000 asignaciones generarían 10.000 filas de auditoría):

```bash
mysql -u root --default-character-set=utf8mb4 < sql/05_procedimientos_triggers.sql
```

6. Corran la matriz de la lógica avanzada, las consultas funcionales y el análisis de planes:

```bash
mysql -u root -t --force --default-character-set=utf8mb4 < sql/06_pruebas_fase4.sql
mysql -u root -t --default-character-set=utf8mb4 < sql/16_consultas_validacion_mariadb.sql
mysql -u root -t --default-character-set=utf8mb4 < sql/07_explain.sql
```

La opción `--force` hace que continúe después de cada error esperado. Antes de los EXPLAIN, ejecuten `ANALYZE TABLE asignacion, inspeccion, paradero;`.

## Estado de la verificación

Los resultados esperados se calcularon en SQLite. El autor ejecutó todos los scripts en MariaDB (XAMPP) el 13-nov-2026 y reportó resultados coincidentes: estado **PROBADO EN SGBD (reportado)**. Las capturas se guardan en `evidencias/`.

## Modelo

12 tablas normalizadas hasta Boyce-Codd, con `COMMENT` nativo en todas las tablas y columnas: `empresa_operadora`, `vehiculo`, `zona`, `paradero`, `ruta`, `ruta_paradero` (tabla puente N:M), `asignacion`, `responsable`, `inspeccion`, `inspeccion_detalle`, `reporte_ilegal` y `auditoria`. Volumen: `asignacion` e `inspeccion_detalle` con 10.000 filas cada una (datos **sintéticos, solo uso académico**). Ver `docs/diccionario_datos.md` y el diagrama en `docs/er.png`.

## Decisiones de diseño

- **No se almacenan conductores.** Protege sus datos por diseño; la trazabilidad es por vehículo, empresa y asignación. El transporte ilegal se registra solo como totales por zona y periodo.
- **Turno y condición inspeccionada con `CHECK`**, no con tablas catálogo.
- **`resultado_general` no se guarda:** se deriva en la vista `v_cumplimiento_empresa` para evitar redundancia (3FN).
- **Accesible** = tiene rampa y espacio para silla de ruedas (`fn_vehiculo_accesible`).
- **Cumplimiento:** 80 % o más cumple; entre 60 y 80 % cumple parcialmente; menos de 60 % no cumple.
- **Cascadas:** solo `ruta_paradero.id_ruta` usa `ON DELETE CASCADE`; el resto usa `RESTRICT` para conservar el historial.
- **Triggers:** RN2 (solo paraderos habilitados en rutas), control de asignaciones (vehículo operativo y ruta activa) y auditoría de asignaciones y cambios de estado.

## Limitaciones

Los turnos no cruzan la medianoche; los datos son ficticios y los nombres de sectores son ilustrativos; la auditoría no cubre borrados; no se definen roles ni permisos de base de datos; RN1 no impide solapes entre turnos distintos de un mismo vehículo (mejora M10). El detalle está en `docs/12c_mejoras_diseno_no_aplicadas.md`.

**Límite de cupo (prompt maestro V3): NO APLICA.** El modelo no maneja cupos, aforos ni reservas, los pasajeros están fuera del alcance y `capacidad` es un dato descriptivo del vehículo. Ver `docs/17_plan_pruebas_y_rendimiento.md`, sección 3b.

## Estado de las fases

| Fase | Entregable | Estado |
|---|---|---|
| 1. Requisitos y ER | Documentos y diagrama (`docs/er.png`) | Hecha |
| 2. Modelo lógico y normalización | Modelo, diccionario y justificación | Hecha |
| 3. Implementación DDL/DML | Scripts 12 a 15 y 03 | Hecha, probada (reportado) |
| 4. Lógica avanzada y optimización | Scripts 04 a 07 y 16 | Hecha, probada (reportado); falta incorporar los EXPLAIN observados |
| 5. Memoria técnica, Git y sustentación | `docs/memoria_tecnica.pdf` | Memoria exportada; falta agregar las capturas en `evidencias/` |
