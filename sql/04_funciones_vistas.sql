-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- Fase 4 - Script 04: UDF (funciones) y vistas analíticas
-- Ejecutar DESPUÉS de 01_ddl.sql y 02_datos.sql. Motor: MariaDB >= 10.2.1
-- (las vistas con LAG() requieren funciones de ventana: MariaDB >= 10.2.0)
-- =====================================================================
USE setp_santa_marta;

-- =====================================================================
-- A. FUNCIONES DEFINIDAS POR EL USUARIO (UDF)
-- =====================================================================

-- ---------------------------------------------------------------------
-- fn_vehiculo_accesible
-- Propósito : centralizar la definición de "vehículo accesible" para que
--             todas las consultas usen el mismo criterio.
-- Criterio  : accesible = tiene rampa Y espacio para silla de ruedas.
--             (piso_bajo se conserva como dato complementario.)
-- Parámetros: p_tiene_rampa (0/1), p_espacio_silla (0/1)
-- Retorna   : 1 si es accesible, 0 si no.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_vehiculo_accesible;
DELIMITER $$
CREATE FUNCTION fn_vehiculo_accesible(p_tiene_rampa TINYINT, p_espacio_silla TINYINT)
RETURNS TINYINT
DETERMINISTIC
NO SQL
BEGIN
    RETURN IF(p_tiene_rampa = 1 AND p_espacio_silla = 1, 1, 0);
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- fn_porcentaje_cumplimiento
-- Propósito : porcentaje de condiciones inspeccionadas con resultado
--             CUMPLE para una empresa (todas sus inspecciones).
-- Parámetros: p_id_empresa (INT) - empresa a evaluar.
-- Retorna   : DECIMAL(5,2) entre 0 y 100; NULL si la empresa no tiene
--             inspecciones (no se puede calcular).
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_porcentaje_cumplimiento;
DELIMITER $$
CREATE FUNCTION fn_porcentaje_cumplimiento(p_id_empresa INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_total  INT DEFAULT 0;
    DECLARE v_cumple INT DEFAULT 0;

    SELECT COUNT(*), COALESCE(SUM(d.resultado = 'CUMPLE'), 0)
      INTO v_total, v_cumple
      FROM inspeccion_detalle d
      JOIN inspeccion i ON i.id_inspeccion = d.id_inspeccion
     WHERE i.id_empresa = p_id_empresa;

    IF v_total = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(100 * v_cumple / v_total, 2);
END$$
DELIMITER ;

-- =====================================================================
-- B. VISTAS ANALÍTICAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- V1 (dimensión: ruta y turno)
-- Responde: ¿Cuáles vehículos operan por ruta y turno?
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_flota_por_ruta_turno AS
SELECT a.fecha,
       r.codigo      AS codigo_ruta,
       r.nombre      AS ruta,
       a.turno,
       v.placa,
       e.nombre      AS empresa,
       v.capacidad,
       a.hora_inicio,
       a.hora_fin
FROM asignacion a
JOIN vehiculo          v ON v.id_vehiculo = a.id_vehiculo
JOIN ruta              r ON r.id_ruta     = a.id_ruta
JOIN empresa_operadora e ON e.id_empresa  = v.id_empresa;

-- ---------------------------------------------------------------------
-- V2 (dimensión: empresa)
-- Responde: ¿Qué proporción de la flota es accesible?
-- Flota = vehículos no retirados. Usa la UDF fn_vehiculo_accesible.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_flota_accesible_empresa AS
SELECT e.id_empresa,
       e.nombre                                   AS empresa,
       COUNT(v.id_vehiculo)                       AS total_flota,
       COALESCE(SUM(fn_vehiculo_accesible(v.tiene_rampa, v.espacio_silla_ruedas)), 0)
                                                  AS vehiculos_accesibles,
       ROUND(100 * COALESCE(SUM(fn_vehiculo_accesible(v.tiene_rampa, v.espacio_silla_ruedas)), 0)
                 / NULLIF(COUNT(v.id_vehiculo), 0), 2) AS pct_accesible
FROM empresa_operadora e
LEFT JOIN vehiculo v ON v.id_empresa = e.id_empresa AND v.estado <> 'RETIRADO'
GROUP BY e.id_empresa, e.nombre;

-- ---------------------------------------------------------------------
-- V3 (dimensión: zona)
-- Responde: ¿Qué sectores o paraderos no tienen cobertura?
-- Una zona tiene cobertura si posee al menos un paradero habilitado que
-- pertenece a alguna ruta.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_cobertura_zonas AS
SELECT z.id_zona,
       z.nombre AS zona,
       COUNT(DISTINCT p.id_paradero) AS total_paraderos,
       COUNT(DISTINCT CASE WHEN p.habilitado = 1 THEN p.id_paradero END) AS paraderos_habilitados,
       COUNT(DISTINCT CASE WHEN p.habilitado = 1 AND rp.id_ruta IS NOT NULL
                           THEN p.id_paradero END) AS paraderos_en_ruta,
       CASE WHEN COUNT(DISTINCT CASE WHEN p.habilitado = 1 AND rp.id_ruta IS NOT NULL
                                     THEN p.id_paradero END) > 0
            THEN 'CON COBERTURA' ELSE 'SIN COBERTURA' END AS cobertura
FROM zona z
LEFT JOIN paradero      p  ON p.id_zona      = z.id_zona
LEFT JOIN ruta_paradero rp ON rp.id_paradero = p.id_paradero
GROUP BY z.id_zona, z.nombre;

-- ---------------------------------------------------------------------
-- V4 (dimensión: empresa)
-- Responde: ¿Qué empresas cumplen condiciones?
-- Deriva el "resultado general" que se quitó de la tabla inspeccion
-- (evita redundancia, 3FN). Umbrales definidos por el equipo:
--   >= 80 % CUMPLE | >= 60 % CUMPLE PARCIALMENTE | < 60 % NO CUMPLE
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_cumplimiento_empresa AS
SELECT e.id_empresa,
       e.nombre AS empresa,
       e.estado,
       COUNT(DISTINCT i.id_inspeccion)                  AS inspecciones,
       COUNT(d.id_detalle)                              AS condiciones_evaluadas,
       COALESCE(SUM(d.resultado = 'CUMPLE'), 0)         AS cumple,
       COALESCE(SUM(d.resultado = 'NO_CUMPLE'), 0)      AS no_cumple,
       COALESCE(SUM(d.resultado = 'OBSERVACION'), 0)    AS observacion,
       ROUND(100 * SUM(d.resultado = 'CUMPLE') / NULLIF(COUNT(d.id_detalle), 0), 2)
                                                        AS pct_cumplimiento,
       CASE WHEN COUNT(d.id_detalle) = 0 THEN 'SIN INSPECCIONES'
            WHEN SUM(d.resultado = 'CUMPLE') / COUNT(d.id_detalle) >= 0.80 THEN 'CUMPLE'
            WHEN SUM(d.resultado = 'CUMPLE') / COUNT(d.id_detalle) >= 0.60 THEN 'CUMPLE PARCIALMENTE'
            ELSE 'NO CUMPLE' END                        AS clasificacion
FROM empresa_operadora e
LEFT JOIN inspeccion         i ON i.id_empresa    = e.id_empresa
LEFT JOIN inspeccion_detalle d ON d.id_inspeccion = i.id_inspeccion
GROUP BY e.id_empresa, e.nombre, e.estado;

-- ---------------------------------------------------------------------
-- V5 (dimensión: terminal)
-- Responde: ¿Dónde están los puntos de transbordo?
-- Terminales habilitadas y las rutas activas que pasan por ellas.
-- Permite transbordo si por la terminal pasan 2 o más rutas activas.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_puntos_transbordo AS
SELECT p.id_paradero,
       p.nombre AS terminal,
       z.nombre AS zona,
       COUNT(DISTINCT r.id_ruta) AS rutas_activas,
       GROUP_CONCAT(DISTINCT r.codigo ORDER BY r.codigo SEPARATOR ', ') AS rutas,
       CASE WHEN COUNT(DISTINCT r.id_ruta) >= 2 THEN 'SI' ELSE 'NO' END AS permite_transbordo
FROM paradero p
JOIN zona z ON z.id_zona = p.id_zona
LEFT JOIN ruta_paradero rp ON rp.id_paradero = p.id_paradero
LEFT JOIN ruta r ON r.id_ruta = rp.id_ruta AND r.estado = 'ACTIVA'
WHERE p.tipo = 'TERMINAL' AND p.habilitado = 1
GROUP BY p.id_paradero, p.nombre, z.nombre;

-- ---------------------------------------------------------------------
-- V6 (tendencia por periodo)
-- Totales de transporte ilegal por mes (solo agregados, sin personas) y
-- variación frente al mes anterior (LAG sobre el total agregado).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_tendencia_ilegal AS
SELECT anio,
       mes,
       SUM(total_reportes) AS total_reportes,
       COUNT(*)            AS zonas_reportadas,
       SUM(total_reportes) - LAG(SUM(total_reportes)) OVER (ORDER BY anio, mes)
                           AS variacion_mes_anterior
FROM reporte_ilegal
GROUP BY anio, mes;

-- ---------------------------------------------------------------------
-- V7 (resumen general)
-- Indicadores clave del sistema en una sola fila.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_resumen_general AS
SELECT
    (SELECT COUNT(*) FROM empresa_operadora WHERE estado = 'ACTIVA')   AS empresas_activas,
    (SELECT COUNT(*) FROM vehiculo WHERE estado = 'OPERATIVO')         AS vehiculos_operativos,
    (SELECT ROUND(100 * SUM(fn_vehiculo_accesible(tiene_rampa, espacio_silla_ruedas)) / COUNT(*), 2)
       FROM vehiculo WHERE estado <> 'RETIRADO')                       AS pct_flota_accesible,
    (SELECT COUNT(*) FROM ruta WHERE estado = 'ACTIVA')                AS rutas_activas,
    (SELECT COUNT(*) FROM paradero WHERE habilitado = 1)               AS paraderos_habilitados,
    (SELECT COUNT(*) FROM v_cobertura_zonas WHERE cobertura = 'SIN COBERTURA')
                                                                       AS zonas_sin_cobertura,
    (SELECT ROUND(100 * SUM(resultado = 'CUMPLE') / COUNT(*), 2)
       FROM inspeccion_detalle)                                        AS pct_cumplimiento_global;
