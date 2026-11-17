-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- 15_verificaciones_carga_mariadb.sql  ·  Verificación de la carga masiva
-- ---------------------------------------------------------------------
-- Solo lectura. Ejecutar DESPUÉS de 14_carga_datos_sinteticos_mariadb.sql.
-- Los "Esperado" se calcularon en SQLite con el mismo archivo de datos y el equipo
-- reportó que MariaDB los confirmó (13-nov-2026). Estado: PROBADO EN SGBD (reportado).
-- Conserve las capturas en evidencias/.
-- Opción: mysql -u root -t --default-character-set=utf8mb4 < este_archivo.sql
-- =====================================================================
USE setp_santa_marta;

-- ---------------------------------------------------------------------
-- V1. Conteo por tabla.
-- Esperado: 50, 120, 50, 60, 50, 296, 10000, 50, 3340, 10000, 200 y 0 (auditoria);
-- total sin auditoria = 24216.
-- ---------------------------------------------------------------------
SELECT 'empresa_operadora' AS tabla, COUNT(*) AS registros FROM empresa_operadora
UNION ALL SELECT 'vehiculo',           COUNT(*) FROM vehiculo
UNION ALL SELECT 'zona',               COUNT(*) FROM zona
UNION ALL SELECT 'paradero',           COUNT(*) FROM paradero
UNION ALL SELECT 'ruta',               COUNT(*) FROM ruta
UNION ALL SELECT 'ruta_paradero',      COUNT(*) FROM ruta_paradero
UNION ALL SELECT 'asignacion',         COUNT(*) FROM asignacion
UNION ALL SELECT 'responsable',        COUNT(*) FROM responsable
UNION ALL SELECT 'inspeccion',         COUNT(*) FROM inspeccion
UNION ALL SELECT 'inspeccion_detalle', COUNT(*) FROM inspeccion_detalle
UNION ALL SELECT 'reporte_ilegal',     COUNT(*) FROM reporte_ilegal
UNION ALL SELECT 'auditoria',          COUNT(*) FROM auditoria;

-- ---------------------------------------------------------------------
-- V2. Huérfanos (filas hijas sin padre). Esperado: todas las columnas en 0.
-- (Las FK ya lo impiden; esta consulta lo comprueba de forma independiente.)
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM vehiculo v LEFT JOIN empresa_operadora e ON e.id_empresa = v.id_empresa WHERE e.id_empresa IS NULL)        AS vehiculo_sin_empresa,
  (SELECT COUNT(*) FROM paradero p LEFT JOIN zona z ON z.id_zona = p.id_zona WHERE z.id_zona IS NULL)                              AS paradero_sin_zona,
  (SELECT COUNT(*) FROM ruta_paradero rp LEFT JOIN ruta r ON r.id_ruta = rp.id_ruta WHERE r.id_ruta IS NULL)                       AS rp_sin_ruta,
  (SELECT COUNT(*) FROM ruta_paradero rp LEFT JOIN paradero p ON p.id_paradero = rp.id_paradero WHERE p.id_paradero IS NULL)       AS rp_sin_paradero,
  (SELECT COUNT(*) FROM asignacion a LEFT JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo WHERE v.id_vehiculo IS NULL)            AS asig_sin_vehiculo,
  (SELECT COUNT(*) FROM asignacion a LEFT JOIN ruta r ON r.id_ruta = a.id_ruta WHERE r.id_ruta IS NULL)                            AS asig_sin_ruta,
  (SELECT COUNT(*) FROM inspeccion i LEFT JOIN empresa_operadora e ON e.id_empresa = i.id_empresa WHERE e.id_empresa IS NULL)      AS insp_sin_empresa,
  (SELECT COUNT(*) FROM inspeccion i LEFT JOIN responsable r ON r.id_responsable = i.id_responsable WHERE r.id_responsable IS NULL) AS insp_sin_responsable,
  (SELECT COUNT(*) FROM inspeccion_detalle d LEFT JOIN inspeccion i ON i.id_inspeccion = d.id_inspeccion WHERE i.id_inspeccion IS NULL) AS detalle_sin_inspeccion,
  (SELECT COUNT(*) FROM reporte_ilegal r LEFT JOIN zona z ON z.id_zona = r.id_zona WHERE z.id_zona IS NULL)                        AS reporte_sin_zona;

-- ---------------------------------------------------------------------
-- V3. Duplicados prohibidos. Esperado: 0 filas en cada consulta.
-- ---------------------------------------------------------------------
-- RN1: mismo vehículo, fecha y turno.
SELECT id_vehiculo, fecha, turno, COUNT(*) AS veces FROM asignacion
GROUP BY id_vehiculo, fecha, turno HAVING COUNT(*) > 1;
-- RN3: mismo orden dentro de una ruta.
SELECT id_ruta, orden, COUNT(*) AS veces FROM ruta_paradero
GROUP BY id_ruta, orden HAVING COUNT(*) > 1;
-- RN5: dos reportes para la misma zona y periodo.
SELECT id_zona, anio, mes, COUNT(*) AS veces FROM reporte_ilegal
GROUP BY id_zona, anio, mes HAVING COUNT(*) > 1;
-- Una condición evaluada dos veces en la misma inspección.
SELECT id_inspeccion, condicion, COUNT(*) AS veces FROM inspeccion_detalle
GROUP BY id_inspeccion, condicion HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- V4. Reglas de negocio y dominios. Esperado: todas las columnas en 0.
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM asignacion WHERE hora_fin <= hora_inicio)                       AS rn4_horas_invalidas,
  (SELECT COUNT(*) FROM ruta_paradero rp JOIN paradero p ON p.id_paradero = rp.id_paradero
    WHERE p.habilitado = 0)                                                             AS rn2_paraderos_no_habilitados_en_rutas,
  (SELECT COUNT(*) FROM asignacion a JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
    WHERE v.estado <> 'OPERATIVO')                                                      AS rn8_vehiculo_no_operativo,
  (SELECT COUNT(*) FROM asignacion a JOIN ruta r ON r.id_ruta = a.id_ruta
    WHERE r.estado <> 'ACTIVA')                                                         AS rn8_ruta_inactiva,
  (SELECT COUNT(*) FROM reporte_ilegal WHERE total_reportes < 0 OR mes NOT BETWEEN 1 AND 12) AS reportes_fuera_de_rango,
  (SELECT COUNT(*) FROM vehiculo WHERE capacidad <= 0)                                  AS capacidad_invalida,
  (SELECT COUNT(*) FROM empresa_operadora WHERE TRIM(nombre) = '' OR TRIM(nit) = '')    AS empresas_con_texto_vacio,
  (SELECT COUNT(*) FROM asignacion WHERE fecha > CURRENT_DATE)                          AS asignaciones_futuras,
  (SELECT COUNT(*) FROM asignacion a1 JOIN asignacion a2
      ON a2.id_vehiculo = a1.id_vehiculo AND a2.fecha = a1.fecha AND a2.id_asignacion > a1.id_asignacion
    WHERE a1.hora_inicio < a2.hora_fin AND a2.hora_inicio < a1.hora_fin)                AS solapes_horarios_mismo_vehiculo;

-- ---------------------------------------------------------------------
-- V5. Distribución de dominios.
-- Esperado: turno MANANA 3936, NOCHE 2252, TARDE 3812.
-- Esperado: resultado CUMPLE 6504, NO_CUMPLE 2052, OBSERVACION 1444.
-- Esperado: 8 terminales; 6 paraderos deshabilitados; 4 empresas suspendidas;
--           3 rutas inactivas; 8 vehículos en mantenimiento y 4 retirados.
-- ---------------------------------------------------------------------
SELECT 'turno' AS dominio, turno AS valor, COUNT(*) AS filas FROM asignacion GROUP BY turno
UNION ALL SELECT 'resultado', resultado, COUNT(*) FROM inspeccion_detalle GROUP BY resultado
UNION ALL SELECT 'tipo_paradero', tipo, COUNT(*) FROM paradero GROUP BY tipo
UNION ALL SELECT 'paradero_habilitado', habilitado, COUNT(*) FROM paradero GROUP BY habilitado
UNION ALL SELECT 'estado_empresa', estado, COUNT(*) FROM empresa_operadora GROUP BY estado
UNION ALL SELECT 'estado_ruta', estado, COUNT(*) FROM ruta GROUP BY estado
UNION ALL SELECT 'estado_vehiculo', estado, COUNT(*) FROM vehiculo GROUP BY estado;

-- ---------------------------------------------------------------------
-- V6. Cobertura temporal.
-- Esperado: asignaciones entre 2026-01-01 y 2026-10-31, mensuales entre 885 y 1086
-- (ene 1086, feb 885, mar 1044, abr 953, may 1004, jun 979, jul 1022, ago 962,
--  sep 998, oct 1067). 108 vehículos distintos y 47 rutas distintas con asignaciones.
-- ---------------------------------------------------------------------
SELECT DATE_FORMAT(fecha, '%Y-%m') AS mes, COUNT(*) AS asignaciones
FROM asignacion GROUP BY DATE_FORMAT(fecha, '%Y-%m') ORDER BY mes;
SELECT MIN(fecha) AS primera, MAX(fecha) AS ultima,
       COUNT(DISTINCT id_vehiculo) AS vehiculos_distintos, COUNT(DISTINCT id_ruta) AS rutas_distintas
FROM asignacion;

-- ---------------------------------------------------------------------
-- V7. Casos límite presentes en la carga.
-- Esperado: 20 asignaciones con hora_fin = 23:59:00; 3 empresas sin inspecciones
-- (ids 10, 20 y 24); 10 inspecciones con 1 detalle y 3330 con 3 detalles;
-- inspecciones por empresa entre 17 y 157 (solo las empresas que tienen).
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS asignaciones_fin_2359 FROM asignacion WHERE hora_fin = '23:59:00';
SELECT e.id_empresa FROM empresa_operadora e
LEFT JOIN inspeccion i ON i.id_empresa = e.id_empresa WHERE i.id_inspeccion IS NULL ORDER BY e.id_empresa;
SELECT detalles, COUNT(*) AS inspecciones
FROM (SELECT id_inspeccion, COUNT(*) AS detalles FROM inspeccion_detalle GROUP BY id_inspeccion) x
GROUP BY detalles ORDER BY detalles;
SELECT MIN(n) AS minimo, MAX(n) AS maximo
FROM (SELECT id_empresa, COUNT(*) AS n FROM inspeccion GROUP BY id_empresa) x;

-- ---------------------------------------------------------------------
-- V8. Cobertura de cada consulta del enunciado (los datos permiten responderlas).
-- Esperado: vehículos accesibles 42 de 116 (36.21 %); 14 zonas sin cobertura;
-- 8 terminales con transbordo; reportes por mes: jul 748, ago 667, sep 699, oct 693.
-- ---------------------------------------------------------------------
SELECT SUM(fn_vehiculo_accesible(tiene_rampa, espacio_silla_ruedas)) AS accesibles, COUNT(*) AS flota,
       ROUND(100 * SUM(fn_vehiculo_accesible(tiene_rampa, espacio_silla_ruedas)) / COUNT(*), 2) AS pct
FROM vehiculo WHERE estado <> 'RETIRADO';            -- requiere 04_funciones_vistas.sql
SELECT COUNT(*) AS zonas_sin_cobertura FROM v_cobertura_zonas WHERE cobertura = 'SIN COBERTURA';
SELECT COUNT(*) AS terminales_con_transbordo FROM v_puntos_transbordo WHERE permite_transbordo = 'SI';
SELECT anio, mes, SUM(total_reportes) AS total FROM reporte_ilegal GROUP BY anio, mes ORDER BY anio, mes;

-- ---------------------------------------------------------------------
-- V9. Tamaño REAL en disco (medido, no estimado) y filas aproximadas del motor.
-- No hay valor esperado: anótelo como observación.
-- ---------------------------------------------------------------------
SELECT TABLE_NAME, TABLE_ROWS AS filas_aprox,
       ROUND(DATA_LENGTH / 1024, 1) AS datos_kb, ROUND(INDEX_LENGTH / 1024, 1) AS indices_kb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'setp_santa_marta' AND TABLE_TYPE = 'BASE TABLE'
ORDER BY DATA_LENGTH DESC;
