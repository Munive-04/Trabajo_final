-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- 16_consultas_validacion_mariadb.sql  ·  Consultas funcionales de validación
-- ---------------------------------------------------------------------
-- 14 consultas de solo lectura. Cada una indica: requisito, parámetros
-- (variables @p_...), resultado esperado y un caso límite.
-- Requiere: 12, 14, 04 (vistas y funciones). Ejecutar con el cliente mysql
-- para que las variables @ persistan:
--   mysql -u root -t --default-character-set=utf8mb4 < 16_consultas_validacion_mariadb.sql
-- ESTADO (R8): PROBADO EN SGBD (reportado por el equipo, 13-nov-2026). Los "Esperado" se
-- calcularon en SQLite sobre 14_carga_datos_sinteticos_mariadb.sql y MariaDB los confirmó.
-- Límite de cupo (V3): NO APLICA a este modelo; ver 17_plan_pruebas_y_rendimiento.md, sección 3b.
-- Técnicas: JOIN (Q01,Q03,Q05,Q08,Q10,Q12,Q13), GROUP BY (Q02,Q03,Q08,Q09,Q10,Q13),
-- HAVING (Q03,Q10,Q13), subconsulta (Q04,Q11), vista (Q06,Q07,Q14).
-- =====================================================================
USE setp_santa_marta;

-- ---------------------------------------------------------------------
-- Q01 · ¿Qué vehículos operan por ruta, fecha y turno?          Requisito: RF5
-- Parámetros: @p_ruta, @p_fecha, @p_turno
-- Esperado (R08, 2026-01-02, MANANA): 4 filas, en este orden de placa:
--   MNU880 (Servicios de Transporte Guajira S.A.S., cap. 25, 06:00-12:30)
--   NCF547 (Transportes Cóndor S.A.S., cap. 45, 05:30-12:30)
--   PRY053 (Movilidad Marlin S.A.S., cap. 18, 06:00-12:30)
--   RDU814 (Buses Coral S.A.S., cap. 30, 06:00-12:30)
-- Caso límite: @p_ruta = 'R11' (ruta INACTIVA, sin asignaciones) -> 0 filas.
-- ---------------------------------------------------------------------
SET @p_ruta = 'R08'; SET @p_fecha = '2026-01-02'; SET @p_turno = 'MANANA';
SELECT r.codigo AS ruta, a.fecha, a.turno, v.placa, e.nombre AS empresa,
       v.capacidad, a.hora_inicio, a.hora_fin
FROM asignacion a
JOIN ruta              r ON r.id_ruta     = a.id_ruta
JOIN vehiculo          v ON v.id_vehiculo = a.id_vehiculo
JOIN empresa_operadora e ON e.id_empresa  = v.id_empresa
WHERE r.codigo = @p_ruta AND a.fecha = @p_fecha AND a.turno = @p_turno
ORDER BY v.placa;

-- Q01 caso límite (ausencia de datos): esperado 0 filas.
SET @p_ruta = 'R11';
SELECT r.codigo AS ruta, a.fecha, a.turno, v.placa
FROM asignacion a JOIN ruta r ON r.id_ruta = a.id_ruta JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
WHERE r.codigo = @p_ruta AND a.fecha = @p_fecha AND a.turno = @p_turno;

-- ---------------------------------------------------------------------
-- Q02 · Asignaciones y vehículos distintos por mes y turno.      Requisito: RF5, RF8
-- Parámetros: @p_ini, @p_fin
-- Esperado (2026-10-01 a 2026-10-31), 3 filas ordenadas por turno:
--   MANANA 423 asignaciones / 106 vehículos | NOCHE 265 / 98 | TARDE 379 / 105
--   (total 1067).
-- Caso límite: rango sin datos (2025-01-01 a 2025-01-31) -> 0 filas.
-- ---------------------------------------------------------------------
SET @p_ini = '2026-10-01'; SET @p_fin = '2026-10-31';
SELECT DATE_FORMAT(a.fecha, '%Y-%m') AS mes, a.turno,
       COUNT(*) AS asignaciones, COUNT(DISTINCT a.id_vehiculo) AS vehiculos
FROM asignacion a
WHERE a.fecha BETWEEN @p_ini AND @p_fin
GROUP BY DATE_FORMAT(a.fecha, '%Y-%m'), a.turno
ORDER BY mes, a.turno;

-- Q02 caso límite: esperado 0 filas.
SET @p_ini = '2025-01-01'; SET @p_fin = '2025-01-31';
SELECT DATE_FORMAT(a.fecha, '%Y-%m') AS mes, a.turno, COUNT(*) AS asignaciones
FROM asignacion a WHERE a.fecha BETWEEN @p_ini AND @p_fin
GROUP BY DATE_FORMAT(a.fecha, '%Y-%m'), a.turno;

-- ---------------------------------------------------------------------
-- Q03 · ¿Qué proporción de la flota es accesible, por empresa?   Requisito: RF2
-- Parámetros: @p_min_flota. Flota = vehículos no retirados. Requiere fn_vehiculo_accesible.
-- Esperado (@p_min_flota = 3): 21 empresas cumplen el HAVING; las 5 primeras:
--   Buses Solimar S.A.S. 3 / 3 / 100.00 | Buses Coral S.A.S. 4 / 3 / 75.00 |
--   Cooperativa de Transportadores Zafiro 4 / 3 / 75.00 | Buses Bahía S.A.S. 3 / 2 / 66.67 |
--   Cooperativa de Transportadores Horizonte 3 / 2 / 66.67   (flota / accesibles / %).
-- Caso límite: @p_min_flota = 100 -> 0 filas.
-- ---------------------------------------------------------------------
SET @p_min_flota = 3;
SELECT e.nombre AS empresa, COUNT(*) AS flota,
       SUM(fn_vehiculo_accesible(v.tiene_rampa, v.espacio_silla_ruedas)) AS accesibles,
       ROUND(100 * SUM(fn_vehiculo_accesible(v.tiene_rampa, v.espacio_silla_ruedas)) / COUNT(*), 2) AS pct_accesible
FROM vehiculo v
JOIN empresa_operadora e ON e.id_empresa = v.id_empresa
WHERE v.estado <> 'RETIRADO'
GROUP BY e.id_empresa, e.nombre
HAVING COUNT(*) >= @p_min_flota
ORDER BY pct_accesible DESC, flota DESC, e.nombre
LIMIT 5;

-- ---------------------------------------------------------------------
-- Q04 · ¿Qué sectores no tienen cobertura?                      Requisito: RF3
-- Cobertura = al menos un paradero habilitado perteneciente a alguna ruta.
-- Esperado: 14 filas. 10 zonas con 0 paraderos (20 de Julio, Centro Histórico,
--   Ciudad Equidad, Cristo Rey, El Prado, Gaira, Garagoa, Los Almendros,
--   María Eugenia, Minca); 3 con 1 paradero (Bello Horizonte, Libertador,
--   Tayrona) y 1 con 2 paraderos (Santa Ana).
-- Caso límite: zonas con paraderos que igual quedan sin cobertura (4 de las 14):
--   sus paraderos están deshabilitados o fuera de toda ruta.
-- ---------------------------------------------------------------------
SELECT z.nombre AS zona,
       (SELECT COUNT(*) FROM paradero p WHERE p.id_zona = z.id_zona) AS paraderos
FROM zona z
WHERE NOT EXISTS (SELECT 1
                  FROM paradero p
                  JOIN ruta_paradero rp ON rp.id_paradero = p.id_paradero
                  WHERE p.id_zona = z.id_zona AND p.habilitado = 1)
ORDER BY paraderos, zona;

-- ---------------------------------------------------------------------
-- Q05 · Paraderos habilitados que no pertenecen a ninguna ruta.  Requisito: RF3, RN2
-- Esperado: 5 filas: Paradero El Rodadero 2, Paradero Los Trupillos 1,
--   Paradero Santa Ana 1, Paradero Santa Ana 2, Paradero Villa del Mar 2.
-- Caso límite: ninguna es TERMINAL (las 8 terminales están en rutas).
-- ---------------------------------------------------------------------
SELECT p.nombre AS paradero, z.nombre AS zona, p.tipo
FROM paradero p
JOIN zona z ON z.id_zona = p.id_zona
LEFT JOIN ruta_paradero rp ON rp.id_paradero = p.id_paradero
WHERE p.habilitado = 1 AND rp.id_paradero IS NULL
ORDER BY p.nombre;

-- ---------------------------------------------------------------------
-- Q06 · ¿Dónde están los puntos de transbordo?  (usa la vista v_puntos_transbordo)  Requisito: RF3
-- Parámetros: @p_min_rutas
-- Esperado (@p_min_rutas = 10): 5 filas: Curinca 13, El Rodadero 12, Los Naranjos 12,
--   Antonio Nariño 11, Pescaíto 10 (rutas activas por terminal).
-- Caso límite: @p_min_rutas = 14 -> 0 filas.
-- ---------------------------------------------------------------------
SET @p_min_rutas = 10;
SELECT terminal, zona, rutas_activas, permite_transbordo, rutas
FROM v_puntos_transbordo
WHERE rutas_activas >= @p_min_rutas
ORDER BY rutas_activas DESC, terminal;

-- ---------------------------------------------------------------------
-- Q07 · ¿Qué empresas cumplen las condiciones?  (vista v_cumplimiento_empresa)  Requisito: RF6
-- Esperado: 15 empresas con clasificación CUMPLE; las 5 primeras por porcentaje:
--   Movilidad Amanecer S.A.S. 33 insp. 96.97 | Cooperativa de Transportadores Magdalena 32 insp. 91.67 |
--   Buses Coral S.A.S. 147 insp. 91.57 | Movilidad Sierra Nevada S.A.S. 98 insp. 91.10 |
--   Transportes Meridiano S.A.S. 89 insp. 91.01.
-- Caso límite: las 3 empresas SIN INSPECCIONES no aparecen entre las que cumplen.
-- ---------------------------------------------------------------------
SELECT empresa, inspecciones, pct_cumplimiento
FROM v_cumplimiento_empresa
WHERE clasificacion = 'CUMPLE'
ORDER BY pct_cumplimiento DESC, inspecciones DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- Q08 · Empresas con más incumplimientos en tecnología de recaudo.  Requisito: RF6
-- Esperado: Movilidad Arrecife S.A.S. 55 | Movilidad Ceiba S.A.S. 42 |
--   Servicios de Transporte Aurora S.A.S. 39.
-- Caso límite: una empresa sin inspecciones nunca aparece (no tiene filas en el JOIN).
-- ---------------------------------------------------------------------
SELECT e.nombre AS empresa, COUNT(*) AS incumplimientos_recaudo
FROM inspeccion_detalle d
JOIN inspeccion        i ON i.id_inspeccion = d.id_inspeccion
JOIN empresa_operadora e ON e.id_empresa    = i.id_empresa
WHERE d.condicion = 'RECAUDO' AND d.resultado = 'NO_CUMPLE'
GROUP BY e.id_empresa, e.nombre
ORDER BY incumplimientos_recaudo DESC, e.nombre
LIMIT 3;

-- ---------------------------------------------------------------------
-- Q09 · Porcentaje de cumplimiento por condición.                Requisito: RF6, RN7
-- Esperado (ordenado de menor a mayor): RECAUDO 3332 evaluadas / 2000 cumplen / 60.02 |
--   PARADAS 3335 / 2192 / 65.73 | LABORAL 3333 / 2312 / 69.37. Suma de evaluadas = 10000.
-- Caso límite: OBSERVACION no cuenta como cumplimiento.
-- ---------------------------------------------------------------------
SELECT condicion, COUNT(*) AS evaluadas, SUM(resultado = 'CUMPLE') AS cumplen,
       ROUND(100 * SUM(resultado = 'CUMPLE') / COUNT(*), 2) AS pct_cumple
FROM inspeccion_detalle
GROUP BY condicion
ORDER BY pct_cumple;

-- ---------------------------------------------------------------------
-- Q10 · Zonas con más reportes de transporte ilegal (solo agregados). Requisito: RF7, RN5
-- Parámetros: @p_min (total mínimo en jul-oct 2026)
-- Esperado (@p_min = 100): 8 zonas cumplen el HAVING; las 5 primeras:
--   Mirador de Gaira 120 | El Líbano 119 | Villa del Mar 115 | 20 de Julio 110 | Los Naranjos 109.
-- Caso límite: @p_min = 1000 -> 0 filas.
-- ---------------------------------------------------------------------
SET @p_min = 100;
SELECT z.nombre AS zona, SUM(r.total_reportes) AS total_jul_oct
FROM reporte_ilegal r
JOIN zona z ON z.id_zona = r.id_zona
WHERE r.anio = 2026 AND r.mes BETWEEN 7 AND 10
GROUP BY z.id_zona, z.nombre
HAVING SUM(r.total_reportes) >= @p_min
ORDER BY total_jul_oct DESC, z.nombre
LIMIT 5;

-- ---------------------------------------------------------------------
-- Q11 · Vehículos operativos SIN asignaciones en un periodo.       Requisito: RF5
-- Parámetros: @p_ini, @p_fin
-- Esperado (octubre de 2026): 0 filas (los 108 vehículos operativos tuvieron al
--   menos una asignación).
-- Caso límite: un solo día, 2026-10-04 (domingo, el de menor carga) -> 88 filas.
-- ---------------------------------------------------------------------
SET @p_ini = '2026-10-01'; SET @p_fin = '2026-10-31';
SELECT v.placa, e.nombre AS empresa
FROM vehiculo v
JOIN empresa_operadora e ON e.id_empresa = v.id_empresa
WHERE v.estado = 'OPERATIVO'
  AND NOT EXISTS (SELECT 1 FROM asignacion a
                  WHERE a.id_vehiculo = v.id_vehiculo AND a.fecha BETWEEN @p_ini AND @p_fin)
ORDER BY v.placa;

-- Q11 caso límite: esperado 88 filas.
SET @p_ini = '2026-10-04'; SET @p_fin = '2026-10-04';
SELECT v.placa, e.nombre AS empresa
FROM vehiculo v
JOIN empresa_operadora e ON e.id_empresa = v.id_empresa
WHERE v.estado = 'OPERATIVO'
  AND NOT EXISTS (SELECT 1 FROM asignacion a
                  WHERE a.id_vehiculo = v.id_vehiculo AND a.fecha BETWEEN @p_ini AND @p_fin)
ORDER BY v.placa;

-- ---------------------------------------------------------------------
-- Q12 · Invariante: un vehículo no debe tener horas solapadas el mismo día. Requisito: RF5, RN1
-- RN1 solo prohíbe repetir el MISMO turno; esta consulta busca solapes entre
-- turnos distintos (hallazgo M10 de 12c: la base de datos no lo impide).
-- Esperado: 0 filas (el generador lo evita). Una versión previa del generador
--   producía 162 solapes (105 MANANA/TARDE y 57 TARDE/NOCHE).
-- Caso límite: dos turnos el mismo día sin solape (hay 1029 pares) NO deben aparecer.
-- ---------------------------------------------------------------------
SELECT a1.id_vehiculo, a1.fecha, a1.turno AS turno_1, a1.hora_fin AS fin_1,
       a2.turno AS turno_2, a2.hora_inicio AS inicio_2
FROM asignacion a1
JOIN asignacion a2 ON a2.id_vehiculo = a1.id_vehiculo AND a2.fecha = a1.fecha
                  AND a2.id_asignacion > a1.id_asignacion
WHERE a1.hora_inicio < a2.hora_fin AND a2.hora_inicio < a1.hora_fin
ORDER BY a1.fecha, a1.id_vehiculo
LIMIT 5;

-- ---------------------------------------------------------------------
-- Q13 · Vigencia: empresas activas sin inspección reciente.        Requisito: RF6, RF8
-- Parámetros: @p_corte (fecha de corte), @p_dias (antigüedad máxima aceptable)
-- Esperado (@p_corte = 2026-10-31, @p_dias = 90): 2 filas, ambas sin ninguna inspección:
--   id 10 Cooperativa de Transportadores Horizonte | id 24 Servicios de Transporte Costa Azul S.A.S.
--   (la empresa 20 también carece de inspecciones, pero está SUSPENDIDA y se excluye).
-- Caso límite: @p_dias = 30 -> 3 filas (las 2 anteriores y 1 con última inspección
--   anterior al 2026-10-01).
-- ---------------------------------------------------------------------
SET @p_corte = '2026-10-31'; SET @p_dias = 90;
SELECT e.id_empresa, e.nombre AS empresa, MAX(i.fecha) AS ultima_inspeccion,
       DATEDIFF(@p_corte, MAX(i.fecha)) AS dias_desde
FROM empresa_operadora e
LEFT JOIN inspeccion i ON i.id_empresa = e.id_empresa
WHERE e.estado = 'ACTIVA'
GROUP BY e.id_empresa, e.nombre
HAVING MAX(i.fecha) IS NULL OR DATEDIFF(@p_corte, MAX(i.fecha)) > @p_dias
ORDER BY ultima_inspeccion, e.id_empresa;

-- ---------------------------------------------------------------------
-- Q14 · Indicadores generales (vista v_resumen_general).
-- Esperado: empresas_activas 46 | vehiculos_operativos 108 | pct_flota_accesible 36.21 |
--   rutas_activas 47 | paraderos_habilitados 54 | zonas_sin_cobertura 14 |
--   pct_cumplimiento_global 65.04.
-- Caso límite: zonas_sin_cobertura coincide con las filas de Q04 (14).
-- ---------------------------------------------------------------------
SELECT * FROM v_resumen_general;

-- =====================================================================
-- PLANES DE EJECUCIÓN de consultas importantes (ver 17_plan_pruebas_y_rendimiento.md)
-- ANALYZE (MariaDB) ejecuta la consulta y muestra filas y tiempos REALES.
-- No hay tiempos esperados: se anotan solo los observados.
-- =====================================================================
SET @p_ruta = 'R08'; SET @p_fecha = '2026-01-02'; SET @p_turno = 'MANANA';
-- E-Q01: se espera ref/eq_ref con el índice idx_asig_ruta_fecha_turno sobre asignacion.
EXPLAIN SELECT r.codigo, a.fecha, a.turno, v.placa
FROM asignacion a JOIN ruta r ON r.id_ruta = a.id_ruta JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
WHERE r.codigo = @p_ruta AND a.fecha = @p_fecha AND a.turno = @p_turno;
ANALYZE SELECT r.codigo, a.fecha, a.turno, v.placa
FROM asignacion a JOIN ruta r ON r.id_ruta = a.id_ruta JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
WHERE r.codigo = @p_ruta AND a.fecha = @p_fecha AND a.turno = @p_turno;

SET @p_ini = '2026-10-01'; SET @p_fin = '2026-10-31';
-- E-Q11: se espera uso del índice único (id_vehiculo, fecha, turno) en la subconsulta NOT EXISTS.
EXPLAIN SELECT v.placa FROM vehiculo v
WHERE v.estado = 'OPERATIVO'
  AND NOT EXISTS (SELECT 1 FROM asignacion a WHERE a.id_vehiculo = v.id_vehiculo AND a.fecha BETWEEN @p_ini AND @p_fin);

-- E-Q12: auto-join sobre asignacion; se espera ref por (id_vehiculo, fecha) usando el índice único.
EXPLAIN SELECT a1.id_vehiculo
FROM asignacion a1
JOIN asignacion a2 ON a2.id_vehiculo = a1.id_vehiculo AND a2.fecha = a1.fecha AND a2.id_asignacion > a1.id_asignacion
WHERE a1.hora_inicio < a2.hora_fin AND a2.hora_inicio < a1.hora_fin;
