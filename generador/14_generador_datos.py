#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
Problema P11: Transporte público y mototaxismo (SETP Santa Marta)

14_generador_datos.py: genera 14_carga_datos_sinteticos_mariadb.sql

DATASET SINTÉTICO - SOLO USO ACADÉMICO. Ningún dato corresponde a personas,
vehículos, empresas ni reportes reales. Los nombres de sectores son ilustrativos.

Uso:   python3 14_generador_datos.py [archivo_salida.sql]
Reproducible: con la misma semilla genera exactamente el mismo archivo.

Volumen objetivo (ver 14a_plan_volumen.md):
  asignacion          10.000 filas  (tabla de hechos / historial)
  inspeccion_detalle  10.000 filas  (tabla de hechos / historial)
  inspeccion           3.340 filas  (3.330 completas + 10 parciales)
  catálogos y maestros con cantidades coherentes (no se inflan).

Estado: PROBADO EN SGBD (reportado por el equipo, 13-nov-2026).
generado y 15_verificaciones_carga_mariadb.sql.
"""
import random, datetime, sys

SEED = 2026
N_ASIGNACION = 10000
N_INSP_COMPLETAS = 3330     # 3 detalles cada una  -> 9.990
N_INSP_PARCIALES = 10       # 1 detalle cada una   ->    10   (total 10.000)
FECHA_INI = datetime.date(2026, 1, 1)
FECHA_FIN = datetime.date(2026, 10, 31)
SALIDA = sys.argv[1] if len(sys.argv) > 1 else "14_carga_datos_sinteticos_mariadb.sql"

esc = lambda s: str(s).replace("'", "''")
S = lambda x: "'" + esc(x) + "'"
N = lambda x: str(x)
out = []

def emit(table, cols, rows, batch=500):
    for i in range(0, len(rows), batch):
        chunk = rows[i:i + batch]
        vals = ",\n  ".join("(" + ", ".join(v) + ")" for v in chunk)
        out.append(f"INSERT INTO {table} ({', '.join(cols)}) VALUES\n  {vals};\n")

# =====================================================================
# BLOQUE 1: catálogos y maestros (misma secuencia aleatoria que la carga
# inicial: empresas, paraderos, rutas y vehículos NO cambian)
# =====================================================================
rng = random.Random(SEED)

pref = ["Transportes", "Movilidad", "Buses", "Servicios de Transporte", "Cooperativa de Transportadores"]
suf = ["Tayrona", "Sierra Nevada", "Bahía", "Caribe", "Magdalena", "Gaira", "Taganga", "Perla", "Brisa", "Horizonte",
       "Cóndor", "Lagarto", "Ancla", "Marítima", "Ciénaga", "Rodadero", "Bastidas", "Libertad", "Aurora", "Cumbre",
       "Delfín", "Palmera", "Solimar", "Costa Azul", "Mirador", "Faro", "Arrecife", "Coral", "Velero", "Atardecer",
       "Manglar", "Alcatraz", "Guacamaya", "Colibrí", "Zafiro", "Nogal", "Amanecer", "Ribera", "Montaña", "Estrella",
       "Cabo", "Marlin", "Pelícano", "Tortuga", "Delta", "Meridiano", "Ceiba", "Almirante", "Guajira", "Samario"]
empresas = []
for i in range(50):
    nombre = f"{pref[i % 5]} {suf[i]} S.A.S." if i % 5 != 4 else f"{pref[i % 5]} {suf[i]}"
    nit = f"9{rng.randint(0, 99999999):08d}-{rng.randint(0, 9)}"
    estado = "SUSPENDIDA" if i in (7, 19, 33, 46) else "ACTIVA"
    empresas.append((i + 1, nit, nombre, estado))
assert len({e[1] for e in empresas}) == 50
emit("empresa_operadora", ["id_empresa", "nit", "nombre", "estado"],
     [[N(a), S(b), S(c), S(d)] for a, b, c, d in empresas])

zonas = ["Centro Histórico", "El Rodadero", "Gaira", "Taganga", "Bastidas", "Pescaíto", "Mamatoco", "Bello Horizonte",
         "Los Naranjos", "Los Almendros", "Villa del Mar", "Tayrona", "Ciudad Equidad", "Pando", "Curinca", "Pozos Colorados",
         "Libertador", "María Eugenia", "20 de Julio", "Divino Niño", "Santa Ana", "San Jorge", "Cundí", "Nueva Mansión",
         "Villa Betel", "El Prado", "Quinta de San Pedro", "Garagoa", "Antonio Nariño", "Bonda", "Minca", "Don Jaca", "Ziruma",
         "Riascos", "Los Trupillos", "San Fernando", "Altos del Rodadero", "Ciudad Bolívar", "Mirador de Gaira", "Playa Salguero",
         "El Líbano", "Alcázares", "Los Fundadores", "Santa Catalina", "Cristo Rey", "Villa Concha", "La Esperanza", "Jardín",
         "Ondas del Caribe", "Troncal Sur"]
assert len(set(zonas)) == 50
emit("zona", ["id_zona", "nombre"], [[N(i + 1), S(z)] for i, z in enumerate(zonas)])

# paraderos: 40 zonas con paraderos, 10 sin ninguno
zids = list(range(1, 51)); rng.shuffle(zids)
con_par = zids[:40]
zona_par = list(con_par) + [rng.choice(con_par) for _ in range(20)]
rng.shuffle(zona_par)
cnt = {}
for z in zona_par: cnt[z] = cnt.get(z, 0) + 1
paraderos, seq = [], {}
for i, z in enumerate(zona_par):
    seq[z] = seq.get(z, 0) + 1
    paraderos.append([i + 1, z, f"Paradero {zonas[z - 1]} {seq[z]}", "PARADERO", 1])
solo1 = [z for z, c in cnt.items() if c == 1]
rng.shuffle(solo1)
for z in solo1[:3]:                       # 3 zonas con un solo paradero, deshabilitado
    for p in paraderos:
        if p[1] == z: p[4] = 0
multi = [p for p in paraderos if cnt[p[1]] >= 2 and p[4] == 1]
for p in rng.sample(multi, 3): p[4] = 0   # 3 paraderos deshabilitados más
terms, usadas = [], set()
habs = [p for p in paraderos if p[4] == 1]
for p in rng.sample(habs, len(habs)):
    if p[1] not in usadas and len(terms) < 8:
        p[3] = "TERMINAL"; p[2] = f"Terminal de Transferencia {zonas[p[1] - 1]}"
        usadas.add(p[1]); terms.append(p[0])
emit("paradero", ["id_paradero", "id_zona", "nombre", "tipo", "habilitado"],
     [[N(a), N(b), S(c), S(d), N(e)] for a, b, c, d, e in paraderos])

# rutas y ruta_paradero
hab = [p for p in paraderos if p[4] == 1]
no_term_hab = [p for p in hab if p[3] == "PARADERO"]
excluidos = {p[0] for p in rng.sample(no_term_hab, 5)}   # habilitados que no están en ninguna ruta
usables_no_term = [p[0] for p in no_term_hab if p[0] not in excluidos]
pz = {p[0]: p[1] for p in paraderos}
rutas, rp = [], []
for r in range(1, 51):
    estado = "INACTIVA" if r in (11, 29, 44) else "ACTIVA"
    k = rng.randint(4, 8)
    nt = rng.choice([1, 2])
    ts = rng.sample(terms, nt)
    otros = rng.sample(usables_no_term, k - nt)
    seqp = [ts[0]] + otros + ts[1:]
    if len(ts) == 2:
        rng.shuffle(otros); seqp = [ts[0]] + otros + [ts[1]]
    rutas.append((r, f"R{r:02d}", f"{zonas[pz[seqp[0]] - 1]} - {zonas[pz[seqp[-1]] - 1]}", estado))
    for o, pid in enumerate(seqp, 1): rp.append((r, pid, o))
assert len({(a, b) for a, b, _ in rp}) == len(rp)
emit("ruta", ["id_ruta", "codigo", "nombre", "estado"], [[N(a), S(b), S(c), S(d)] for a, b, c, d in rutas])
emit("ruta_paradero", ["id_ruta", "id_paradero", "orden"], [[N(a), N(b), N(c)] for a, b, c in rp])

# vehículos
letras = "ABCDEFGHJKLMNPRSTUVWXYZ"; placas, vehs = set(), []
for i in range(120):
    while True:
        pl = "".join(rng.choice(letras) for _ in range(3)) + f"{rng.randint(0, 999):03d}"
        if pl not in placas: placas.add(pl); break
    emp = (i % 50) + 1 if i < 50 else rng.randint(1, 50)
    cap = rng.choice([18, 25, 30, 40, 45, 60, 80, 90])
    rampa = 1 if rng.random() < 0.45 else 0
    silla = 1 if rng.random() < (0.85 if rampa else 0.10) else 0
    pbajo = 1 if rng.random() < 0.35 else 0
    estado = "MANTENIMIENTO" if i in range(100, 108) else ("RETIRADO" if i in range(108, 112) else "OPERATIVO")
    vehs.append((i + 1, emp, pl, cap, rampa, pbajo, silla, estado))
emit("vehiculo", ["id_vehiculo", "id_empresa", "placa", "capacidad", "tiene_rampa", "piso_bajo", "espacio_silla_ruedas", "estado"],
     [[N(a), N(b), S(c), N(d), N(e), N(f), N(g), S(h)] for a, b, c, d, e, f, g, h in vehs])

# =====================================================================
# BLOQUE 2: datos nuevos con un generador aparte (semilla derivada)
# =====================================================================
r2 = random.Random(SEED + 11)

# responsables (50)
nom = ["Carlos", "Luisa", "Andrés", "Marta", "Jorge", "Diana", "Felipe", "Sandra", "Camilo", "Paola", "Ricardo", "Natalia",
       "Héctor", "Laura", "Iván", "Mónica", "Óscar", "Yuliana", "Rafael", "Katherine"]
ape = ["Pérez", "Gómez", "Rojas", "Mendoza", "Vergara", "Orozco", "Cantillo", "Barrios", "Fontalvo", "Pacheco", "Ospino",
       "Daza", "Linero", "Escorcia", "Charris"]
combos = [(n, a) for n in nom for a in ape]; r2.shuffle(combos)
ents = ["Secretaría de Movilidad de Santa Marta", "Policía de Tránsito", "Dirección de Tránsito y Transporte",
        "Oficina de Control Operativo SETP"]
resp = [(i + 1, f"{n} {a}", ents[i % 4]) for i, (n, a) in enumerate(combos[:50])]
emit("responsable", ["id_responsable", "nombre", "entidad"], [[N(a), S(b), S(c)] for a, b, c in resp])

# asignaciones (10.000): solo vehículos OPERATIVOS en rutas ACTIVAS; sin repetir (vehículo, fecha, turno)
op = [v[0] for v in vehs if v[7] == "OPERATIVO"]
act = [r[0] for r in rutas if r[3] == "ACTIVA"]
pref_rutas = {v: r2.sample(act, 2) for v in op}           # cada vehículo tiene 2 rutas habituales
peso_ruta = {r: r2.choice([1, 1, 2, 3]) for r in act}     # rutas con demanda desigual
# Variantes de horario por turno. Todas respetan los límites 12:30 y 18:30 entre turnos,
# de modo que un mismo vehículo nunca queda en dos rutas con horas solapadas el mismo día.
horas = {"MANANA": [("05:30:00", "12:30:00"), ("06:00:00", "12:30:00")],
         "TARDE":  [("12:30:00", "18:30:00"), ("13:00:00", "18:30:00")],
         "NOCHE":  [("18:30:00", "23:30:00"), ("19:00:00", "23:30:00")]}
dias = (FECHA_FIN - FECHA_INI).days
usados, asig = set(), []
while len(asig) < N_ASIGNACION:
    v = r2.choice(op)
    f = FECHA_INI + datetime.timedelta(days=r2.randint(0, dias))
    prob = {5: 0.60, 6: 0.35}.get(f.weekday(), 1.0)       # sábado menos, domingo mucho menos
    if r2.random() > prob: continue
    t = r2.choices(["MANANA", "TARDE", "NOCHE"], [40, 38, 22])[0]
    if (v, f, t) in usados: continue
    usados.add((v, f, t))
    ruta = r2.choice(pref_rutas[v]) if r2.random() < 0.85 else r2.choices(act, [peso_ruta[x] for x in act])[0]
    hi, hf = horas[t][0] if r2.random() < 0.7 else horas[t][1]
    if t == "NOCHE" and r2.random() < 0.01:               # caso límite: fin a las 23:59
        hf = "23:59:00"
    asig.append((v, ruta, f, t, hi, hf))
orden_t = {"MANANA": 0, "TARDE": 1, "NOCHE": 2}
asig.sort(key=lambda a: (a[2], orden_t[a[3]], a[0]))
asig = [(i + 1, *a) for i, a in enumerate(asig)]
emit("asignacion", ["id_asignacion", "id_vehiculo", "id_ruta", "fecha", "turno", "hora_inicio", "hora_fin"],
     [[N(a), N(b), N(c), S(d.isoformat()), S(e), S(f), S(g)] for a, b, c, d, e, f, g in asig])

# inspecciones: 3 empresas sin ninguna inspección (caso límite); resto con cumplimiento desigual
sin_insp = set(r2.sample(range(1, 51), 3))
emp_ins = [e for e in range(1, 51) if e not in sin_insp]
p_emp = {e: r2.choice([0.95, 0.88, 0.78, 0.68, 0.55, 0.40]) for e in emp_ins}
w_emp = [r2.choice([1, 2, 3, 5]) for _ in emp_ins]
n_insp = N_INSP_COMPLETAS + N_INSP_PARCIALES
insp = []
for _ in range(n_insp):
    e = r2.choices(emp_ins, w_emp)[0]
    f = FECHA_INI + datetime.timedelta(days=r2.randint(0, dias))
    insp.append([e, r2.randint(1, 50), f])
insp.sort(key=lambda x: (x[2], x[0]))
parciales = set(r2.sample(range(n_insp), N_INSP_PARCIALES))
insp = [(i + 1, a, b, c) for i, (a, b, c) in enumerate(insp)]
emit("inspeccion", ["id_inspeccion", "id_empresa", "id_responsable", "fecha"],
     [[N(a), N(b), N(c), S(d.isoformat())] for a, b, c, d in insp])

cond = ["LABORAL", "PARADAS", "RECAUDO"]; ajuste = {"LABORAL": 0.0, "PARADAS": -0.05, "RECAUDO": -0.10}
det = []
for idx, (i, e, _, _) in enumerate(insp):
    conds = [r2.choice(cond)] if idx in parciales else cond      # parcial: una sola condición evaluada
    for c in conds:
        p = max(0.05, min(0.99, p_emp[e] + ajuste[c]))
        res = "CUMPLE" if r2.random() < p else r2.choices(["NO_CUMPLE", "OBSERVACION"], [60, 40])[0]
        det.append((len(det) + 1, i, c, res))
assert len(det) == 10000, len(det)
emit("inspeccion_detalle", ["id_detalle", "id_inspeccion", "condicion", "resultado"],
     [[N(a), N(b), S(c), S(d)] for a, b, c, d in det])

# reportes de transporte ilegal: 50 zonas x 4 meses (agregados; sin personas)
rep = []
for z in range(1, 51):
    base = r2.randint(0, 25)
    for m in (7, 8, 9, 10):
        rep.append((len(rep) + 1, z, 2026, m, max(0, base + r2.randint(-6, 12))))
emit("reporte_ilegal", ["id_reporte", "id_zona", "anio", "mes", "total_reportes"],
     [[N(a), N(b), N(c), N(d), N(e)] for a, b, c, d, e in rep])

# =====================================================================
# VALIDACIONES INTERNAS (reglas de negocio) ANTES de escribir el archivo
# =====================================================================
assert len({(a[1], a[3], a[4]) for a in asig}) == len(asig)                          # RN1
assert all(a[6] > a[5] for a in asig)                                                # RN4
por_dia = {}
for a in asig: por_dia.setdefault((a[1], a[3]), []).append(a)
for lista in por_dia.values():                                                       # sin solapes horarios
    lista.sort(key=lambda x: x[5])
    assert all(lista[i][6] <= lista[i + 1][5] for i in range(len(lista) - 1)), "solape horario"
vest = {v[0]: v[7] for v in vehs}; rest = {r[0]: r[3] for r in rutas}
assert all(vest[a[1]] == "OPERATIVO" and rest[a[2]] == "ACTIVA" for a in asig)       # RN8
habil = {p[0]: p[4] for p in paraderos}
assert all(habil[b] == 1 for _, b, _ in rp)                                          # RN2
assert len({(a, c) for a, _, c in rp}) == len(rp)                                    # RN3
assert len({(d[1], d[2]) for d in det}) == len(det)                                  # una condición por inspección
assert len({(r[1], r[3], r[4]) for r in rep}) == len(rep)                            # RN5

# =====================================================================
header = """-- =====================================================================
-- PROYECTO INTEGRADOR FINAL - BASES DE DATOS (Universidad del Magdalena)
-- Problema P11: Transporte público y mototaxismo (SETP Santa Marta)
-- 14_carga_datos_sinteticos_mariadb.sql  ·  DML MASIVO, INDEPENDIENTE DEL DDL
-- ---------------------------------------------------------------------
-- SINTÉTICO - SOLO USO ACADÉMICO. No contiene datos reales de personas,
-- vehículos, empresas ni reportes. Los nombres de sectores son ilustrativos.
-- Generado por 14_generador_datos.py (semilla 2026), reproducible.
--
-- EJECUTAR UNA SOLA VEZ sobre una base RECIÉN CREADA y VACÍA con
-- 12_creacion_esquema_mariadb.sql. Orden: 12 -> este archivo -> 04 -> 05.
-- IMPORTANTE: cargar ANTES de 05_procedimientos_triggers.sql. Con los triggers
-- ya creados, las 10.000 asignaciones generarían 10.000 filas de auditoría.
-- Contiene solo INSERT (sin DROP, TRUNCATE, DELETE ni UPDATE) y NO desactiva
-- las claves foráneas: los padres se insertan antes que los hijos.
-- Todo el lote va en una transacción: si hay un error, ejecute ROLLBACK y
-- recree la base antes de reintentar.
--
-- Volumen: asignacion 10.000 · inspeccion_detalle 10.000 · inspeccion 3.340
-- (3.330 completas + 10 parciales) · ruta_paradero 296 · reporte_ilegal 200
-- · vehiculo 120 · paradero 60 · empresa_operadora, zona, ruta, responsable 50.
-- Total: 24.216 filas. auditoria queda en 0 (la llenan los triggers).
-- Estado: PROBADO EN SGBD (MariaDB/XAMPP), según reporte del equipo (13-nov-2026): ejecutado sin errores y con resultados coincidentes con los esperados.
-- =====================================================================
USE setp_santa_marta;
SET NAMES utf8mb4;
START TRANSACTION;

"""
open(SALIDA, "w", encoding="utf-8").write(header + "\n".join(out) + "\nCOMMIT;\n")
tot = 50 + 50 + len(paraderos) + 50 + len(rp) + 120 + len(asig) + 50 + len(insp) + len(det) + len(rep)
print(f"Archivo: {SALIDA} | asignacion={len(asig)} inspeccion={len(insp)} detalle={len(det)} ruta_paradero={len(rp)} reporte={len(rep)} | total filas={tot}")
