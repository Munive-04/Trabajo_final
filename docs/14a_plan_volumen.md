# 14a · Plan de volumen del DML sintético

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

**SINTÉTICO — SOLO USO ACADÉMICO.** Ningún dato corresponde a personas, vehículos, empresas o reportes reales.
**Estado:** REVISADO ESTÁTICAMENTE. El archivo se cargó en SQLite con claves foráneas, UNIQUE y CHECK activos y no produjo violaciones, pero **NO PROBADO EN MARIADB** hasta ejecutarlo y conservar las capturas de `15_verificaciones_carga_mariadb.sql`.
**Aprobación de las tablas objetivo:** tomada de la respuesta «siguiente paso» a la propuesta anterior. Confirmenla o ajusten.

## 1. Tablas objetivo (hechos / historial)

| Tabla | Rol | Volumen | Justificación | Dependencia | Resultado esperado |
|---|---|---|---|---|---|
| `asignacion` | Historial de asignaciones por fecha y turno | **10.000** | Es la tabla de hechos con mayor crecimiento natural: 108 vehículos operativos por 3 turnos por día. | `vehiculo`, `ruta` | 10.000 filas, sin repetir (vehículo, fecha, turno); todas con vehículo OPERATIVO y ruta ACTIVA. |
| `inspeccion_detalle` | Resultado por condición inspeccionada | **10.000** | Segunda tabla de hechos: 3 condiciones por inspección. | `inspeccion` | 10.000 filas: 3.330 inspecciones completas (9.990) y 10 parciales (10). |
| `inspeccion` (padre) | Cabecera de cada inspección | 3.340 | Resulta de lo anterior (3.330 + 10). | `empresa_operadora`, `responsable` | 3.340 filas; 3 empresas sin ninguna inspección. |

## 2. Tablas que NO se inflan (V3: no llenar catálogos solo por cumplir una cifra)

| Tabla | Volumen | Por qué |
|---|---|---|
| `empresa_operadora`, `zona`, `ruta`, `responsable` | 50 cada una | Cantidad coherente con el tamaño del SETP ficticio; es el mínimo de la guía del PDF. |
| `paradero` | 60 | 8 terminales, 6 deshabilitados, 10 zonas sin paraderos. |
| `ruta_paradero` | 296 | Entre 4 y 8 paraderos por ruta; el máximo posible es 50 × 54 = 2.700, no tiene sentido llegar a 10.000. |
| `vehiculo` | 120 | 108 operativos, 8 en mantenimiento y 4 retirados. |
| `reporte_ilegal` | 200 | 50 zonas × 4 meses; con 24 meses el máximo sería 1.200, nunca 10.000. |
| `auditoria` | 0 | La llenan los triggers (53 filas tras las pruebas de la Fase 4). |

**Total: 24.216 filas.** Seis tablas (`empresa_operadora`, `zona`, `paradero`, `ruta`, `ruta_paradero` y `vehiculo`) son **idénticas** a la carga inicial, fila por fila (se comprobó). `responsable` y `reporte_ilegal` se regeneraron (otros nombres ficticios y otros totales mensuales), por eso cambian la vista de tendencia y sus resultados esperados.

## 3. Perfil sintético (casos típicos, límites y distribuciones desiguales)

| Aspecto | Decisión | Justificación |
|---|---|---|
| Periodo | 2026-01-01 a 2026-10-31 (asignaciones e inspecciones) | Diez meses completos, anteriores a la fecha actual: no hay asignaciones «futuras». |
| Turnos | MANANA ≈ 39 %, TARDE ≈ 38 %, NOCHE ≈ 23 % | La noche tiene menos servicio. |
| Días | Sábado con menos carga y domingo con mucha menos | Variación semanal realista. |
| Rutas | Cada vehículo tiene 2 rutas habituales (85 % de sus asignaciones); el resto, ponderado | Carga desigual: la ruta más cargada tiene 479 asignaciones y la menos cargada, 56. |
| Horarios | Dos variantes por turno, con límites comunes a las 12:30 y a las 18:30 | Evita datos uniformes y que un mismo vehículo tenga horas solapadas el mismo día (se comprueba en el generador y en `15`). |
| Caso límite horario | 20 asignaciones de NOCHE terminan a las 23:59 | Prueba el borde del `CHECK` de horas. |
| Cumplimiento | Cada empresa tiene una probabilidad base distinta; RECAUDO es la condición más baja | Distribuye la clasificación: 15 cumplen, 14 parcialmente, 18 no cumplen, 3 sin inspecciones. |
| Caso límite de inspecciones | 3 empresas sin ninguna; 10 inspecciones con una sola condición | Prueba `SIN INSPECCIONES` y los conteos de detalles. |

## 4. Reglas de negocio que el generador garantiza antes de escribir el archivo

RN1 sin repetir (vehículo, fecha, turno) · RN2 solo paraderos habilitados en rutas · RN3 orden único por ruta · RN4 `hora_fin > hora_inicio` · RN5 un reporte por zona y periodo · RN8 vehículos operativos en rutas activas · una condición por inspección · sin solapes horarios de un mismo vehículo el mismo día.

## 5. Procedimiento seguro de ejecución

1. Base **recién creada y vacía** con `12_creacion_esquema_mariadb.sql`.
2. Ejecutar **una sola vez** `14_carga_datos_sinteticos_mariadb.sql`. Va en una transacción: si hay error, `ROLLBACK`, recrear la base y reintentar.
3. Ejecutar **antes** `05_procedimientos_triggers.sql`; con los triggers creados, las 10.000 asignaciones generarían 10.000 filas de auditoría.
4. Verificar con `15_verificaciones_carga_mariadb.sql`.
5. El archivo pesa ≈ 1,2 MB. Si phpMyAdmin rechaza la importación por tamaño, usar el cliente `mysql`.

## 6. Reproducibilidad
`python3 14_generador_datos.py` genera exactamente el mismo archivo (semilla 2026; se verificó con dos ejecuciones).

## 7. Qué NO se afirma
No se mide tiempo de carga ni tamaño en disco: se medirán en el servidor (`15`, consulta V9). Los resultados esperados se calcularon en SQLite y pueden diferir en MariaDB solo si hay una incompatibilidad de sintaxis.
