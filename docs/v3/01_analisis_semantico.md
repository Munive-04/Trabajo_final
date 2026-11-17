# E1 · Análisis semántico del enunciado

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

## A. Diagnóstico consultivo

**Situación.** El Sistema Estratégico de Transporte Público (SETP) de Santa Marta reorganiza el servicio con operadores, paraderos y terminales de transferencia, mientras la ciudad adopta medidas contra el transporte ilegal en mototaxis. Hace falta gestionar flota, rutas y cumplimiento de condiciones.

**Objetivo.** Organizar flota, rutas, turnos, paraderos y la verificación de las condiciones de operación del transporte público.

**Alcance (incluye).** Empresas operadoras, vehículos con capacidad y accesibilidad, rutas, paraderos y terminales, orden de paraderos por ruta, asignaciones por fecha y turno con hora de inicio y fin, inspecciones por condición y totales de transporte ilegal por zona y periodo.

**No alcance (excluye).** Recaudo y pagos (solo se verifica que exista tecnología de recaudo), seguimiento GPS, tarifas, pasajeros, sanciones, registro individual de mototaxistas y datos personales de conductores.

**Actores.** Operadores del transporte público, responsables de flota y autoridades de movilidad.

**Unidades de observación.** (1) Una asignación: vehículo, ruta, fecha y turno. (2) Una condición verificada en una inspección. (3) Un total mensual de reportes de transporte ilegal por zona (dato agregado, no individual).

**Riesgos y tensiones.**
- *Privacidad:* el enunciado exige proteger datos de conductores y prohíbe identificar personas en los reportes de transporte ilegal.
- *Agregado frente a individual:* el transporte ilegal solo puede conservarse como total por zona y periodo; no se pueden modelar casos individuales.
- *Vigencia e historial:* se conserva el historial de asignaciones e inspecciones; esto condiciona los borrados.
- *Cifras de contexto:* las fuentes (Alcaldía, BID, Santa Marta Cómo Vamos) son contexto; el modelo no incorpora cifras reales y los datos de prueba son sintéticos.

### Hechos confirmados (provienen del enunciado)
1. Se registran empresas operadoras, vehículos, capacidad y características de accesibilidad.
2. Se registran rutas, paraderos habilitados, terminales de transferencia y el orden de los paraderos en cada ruta.
3. Se registran asignaciones de vehículos a rutas por fecha y turno, con hora de inicio y fin.
4. Se registran inspecciones sobre condiciones laborales, uso de paradas autorizadas y tecnología de recaudo, con fecha, responsable y resultado.
5. Los reportes de transporte ilegal son solo totales por zona y periodo.
6. Un vehículo no puede estar en dos rutas durante un mismo turno; las paradas programadas deben pertenecer a paraderos autorizados; se conserva el historial.
7. El diseño debe responder cuatro preguntas (vehículos por ruta y turno, proporción accesible, sectores sin cobertura, empresas que cumplen y puntos de transbordo).

### Inferencias
- I1. «Turno» es una franja del día con valores finitos (se infieren mañana, tarde y noche).
- I2. Una terminal de transferencia es un tipo de paradero (comparte atributos).
- I3. La «cobertura» de un sector depende de tener al menos un paradero habilitado que pertenezca a alguna ruta.

### Supuestos por validar
- S1. El «periodo» de los reportes es mensual.
- S2. La «zona» es un barrio o sector.
- S3. «Capacidad» es el número de pasajeros, sin distinguir sentados de pie. *(PENDIENTE DE CONFIRMAR)*
- S4. Un resultado de inspección admite tres valores: CUMPLE, NO_CUMPLE y OBSERVACION.
- S5. «Accesible» significa tener rampa y espacio para silla de ruedas.

### Dudas abiertas
- D-1. Causas y efectos del estado SUSPENDIDA de una empresa. *(PENDIENTE DE CONFIRMAR con el docente)*
- D-2. Si un turno puede cruzar la medianoche (el modelo actual no lo permite).

### Propuestas de mejora
Registradas y **no aplicadas** en `12c_mejoras_diseno_no_aplicadas.md` (M1 a M10).

### Redacción mejorada propuesta

| Fragmento del enunciado | Propuesta | Qué cambia | Tipo de cambio |
|---|---|---|---|
| «Hace falta gestionar flota, rutas y cumplimiento de condiciones.» | «El sistema debe permitir consultar la flota por ruta y turno, medir su accesibilidad, detectar sectores sin cobertura y verificar el cumplimiento de condiciones por empresa.» | Convierte la frase general en capacidades verificables | Editorial |
| «Registrar reportes sobre transporte ilegal únicamente como totales por zona y periodo.» | «Registrar, por zona y mes, un único total de reportes de transporte ilegal, sin identificar personas ni vehículos.» | Fija el periodo (mensual) y la unicidad | **Nuevo requisito propuesto (S1)** |
| «capacidad y características de accesibilidad» | «Capacidad en pasajeros e indicadores de rampa, piso bajo y espacio para silla de ruedas.» | Define la capacidad y las características | **Nuevo requisito propuesto (S3, S5)** |
| «verificación de las condiciones de operación» | «Resultado por condición (laboral, paradas autorizadas, recaudo) con valores CUMPLE, NO_CUMPLE u OBSERVACION.» | Fija el dominio del resultado | **Nuevo requisito propuesto (S4)** |
| «Los datos de conductores deben protegerse» | «El sistema no almacena datos de conductores.» | Resuelve la protección por diseño | Decisión D01 |
| «Se conserva el historial de asignaciones e inspecciones.» | «No se eliminan asignaciones ni inspecciones; las claves foráneas impiden borrar registros referenciados.» | Traduce el principio a un mecanismo | Editorial |

## B. Requisitos, reglas y decisiones

### Requisitos de almacenamiento y consulta (R)

| Id | Requisito | Criterio de aceptación observable |
|---|---|---|
| R01 | Registrar empresas operadoras | Existen empresas con NIT único y estado |
| R02 | Registrar vehículos con capacidad y accesibilidad | Existen vehículos con placa única y tres indicadores de accesibilidad |
| R03 | Registrar rutas, paraderos habilitados y terminales | Existen rutas y paraderos con tipo PARADERO o TERMINAL y marca de habilitado |
| R04 | Registrar el orden de los paraderos de cada ruta | Cada paradero de una ruta tiene una posición única en ella |
| R05 | Registrar asignaciones por fecha y turno con horas | Cada asignación tiene vehículo, ruta, fecha, turno, inicio y fin |
| R06 | Registrar inspecciones por condición con fecha, responsable y resultado | Cada inspección tiene responsable, fecha y un resultado por condición |
| R07 | Registrar totales de transporte ilegal por zona y periodo | Un total por zona y mes, sin datos personales |
| R08 | Conservar el historial | Ninguna asignación ni inspección puede perderse por un borrado en cascada |

### Reglas de negocio (RN)

| Id | Regla |
|---|---|
| RN01 | Un vehículo no puede estar asignado a dos rutas en la misma fecha y turno |
| RN02 | Las paradas programadas deben pertenecer a paraderos autorizados (habilitados) |
| RN03 | El orden de un paradero no se repite dentro de una ruta |
| RN04 | La hora de fin es posterior a la hora de inicio |
| RN05 | Un solo reporte por zona y periodo, con total no negativo y sin datos personales |
| RN06 | Se conserva el historial de asignaciones e inspecciones |
| RN07 | El resultado de una inspección pertenece a un dominio fijo |
| RN08 | Solo vehículos operativos se asignan, y solo a rutas activas *(regla adicional del equipo)* |
| RN09 | Un vehículo con asignaciones futuras no pasa a mantenimiento ni a retiro *(regla adicional del equipo)* |

### Decisiones (D)

| Id | Decisión | Justificación |
|---|---|---|
| D01 | No se almacenan conductores | Privacidad por diseño |
| D02 | Transporte ilegal solo como totales agregados | Lo exige el enunciado |
| D03 | Turno y condición como dominio `CHECK`, sin tablas catálogo | Dominios pequeños y estables; un catálogo de 3 filas no podría llegar a 50 registros de forma honesta |
| D04 | `tipo` del paradero como atributo | Las terminales no tienen atributos propios |
| D05 | Zona = barrio o sector | Mayor granularidad para medir la cobertura |
| D06 | Accesible = rampa y espacio para silla de ruedas | Criterio único (`fn_vehiculo_accesible`) |
| D07 | Cumplimiento: ≥ 80 % cumple; 60 a 80 % cumple parcialmente; < 60 % no cumple | Umbrales del equipo, no del enunciado |
| D08 | El resultado general de una inspección no se almacena | Es derivado; evita una dependencia transitiva |
| D09 | Periodo como `anio` y `mes` | Valores atómicos |
| D10 | Motor: MariaDB (XAMPP) | Decisión del equipo |
| D11 | Turnos que no cruzan la medianoche | Consecuencia de RN04; ver M1 |
| D12 | Estados de vehículo, ruta y empresa como dominios `CHECK` | Misma razón que D03 |

*Estado:* REVISADO ESTÁTICAMENTE (documento de análisis).
