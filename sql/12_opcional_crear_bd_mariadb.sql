-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- 12_opcional_crear_bd_mariadb.sql  ·  CREACIÓN DE LA BASE DE DATOS (OPCIONAL)
-- ---------------------------------------------------------------------
-- Se mantiene SEPARADO de 12_creacion_esquema_mariadb.sql para que sea
-- revisable antes de ejecutarse. SGBD: MariaDB (XAMPP).
-- Estado: PROBADO EN SGBD (MariaDB/XAMPP), según reporte del equipo (13-nov-2026): ejecutado sin errores y con resultados coincidentes con los esperados.
-- =====================================================================

-- Opción A (recomendada): crear la base si todavía no existe.
CREATE DATABASE IF NOT EXISTS setp_santa_marta
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

-- Opción B: reiniciar desde cero. ATENCIÓN: borra TODA la base, con sus tablas,
-- datos, vistas, funciones, procedimientos y triggers. Úsela solo si ya tiene
-- copia de lo que necesita (02_datos.sql, 04 y 05 se pueden volver a ejecutar).
-- Para activarla, quite los dos guiones de la línea siguiente:
-- DROP DATABASE setp_santa_marta;
-- y vuelva a ejecutar la Opción A.
