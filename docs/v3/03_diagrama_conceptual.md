# E3 · Diagrama conceptual

Proyecto Integrador Final · P11 Transporte público y mototaxismo (SETP Santa Marta)

## Especificación textual en notación Chen

Cardinalidades en la forma **(mínimo, máximo)** al lado de cada entidad. Los atributos marcados *(ID)* identifican a la entidad.

| Relación (rombo) | Entidad A | (min,max) A | Entidad B | (min,max) B | Atributos de la relación |
|---|---|---|---|---|---|
| POSEE | EMPRESA_OPERADORA | (0,N) | VEHICULO | (1,1) | — |
| SE_ASIGNA | VEHICULO | (0,N) | ASIGNACION | (1,1) | — |
| RECIBE | RUTA | (0,N) | ASIGNACION | (1,1) | — |
| INCLUYE | RUTA | (0,N) | PARADERO | (0,N) | orden |
| UBICADO_EN | ZONA | (0,N) | PARADERO | (1,1) | — |
| REGISTRA | ZONA | (0,N) | REPORTE_ILEGAL | (1,1) | — |
| ES_INSPECCIONADA | EMPRESA_OPERADORA | (0,N) | INSPECCION | (1,1) | — |
| REALIZA | RESPONSABLE | (0,N) | INSPECCION | (1,1) | — |
| CONTIENE (identificadora) | INSPECCION | (1,3)* | INSPECCION_DETALLE (débil) | (1,1) | — |

\* Intención de negocio: una inspección evalúa de 1 a 3 condiciones. **El DDL no impone el mínimo de 1**; es una limitación conocida.

**Entidades y atributos.**
EMPRESA_OPERADORA(nit *(ID)*, nombre, estado) · VEHICULO(placa *(ID)*, capacidad, tiene_rampa, piso_bajo, espacio_silla_ruedas, estado) · ZONA(nombre *(ID)*) · PARADERO(nombre, tipo, habilitado) · RUTA(codigo *(ID)*, nombre, estado) · ASIGNACION(fecha, turno, hora_inicio, hora_fin; identificada por vehículo + fecha + turno) · RESPONSABLE(nombre, entidad) · INSPECCION(fecha) · INSPECCION_DETALLE(condicion, resultado; identificada por inspección + condición) · REPORTE_ILEGAL(anio, mes, total_reportes; identificada por zona + año + mes).

**Participación total:** ASIGNACION, PARADERO, REPORTE_ILEGAL, INSPECCION, INSPECCION_DETALLE y VEHICULO dependen de su entidad padre (cardinalidad mínima 1 en ese lado).

## REPRESENTACIÓN APROXIMADA EN PATA DE CUERVO — NO ES CHEN

El siguiente código Mermaid (`erDiagram`) muestra el modelo con pata de cuervo y claves. Para exportarlo, péguelo en mermaid.live.

```mermaid
erDiagram
    EMPRESA_OPERADORA ||--o{ VEHICULO : posee
    EMPRESA_OPERADORA ||--o{ INSPECCION : es_inspeccionada
    RESPONSABLE ||--o{ INSPECCION : realiza
    INSPECCION ||--|{ INSPECCION_DETALLE : contiene
    VEHICULO ||--o{ ASIGNACION : es_asignado
    RUTA ||--o{ ASIGNACION : recibe
    RUTA ||--|{ RUTA_PARADERO : incluye
    PARADERO ||--o{ RUTA_PARADERO : forma_parte
    ZONA ||--o{ PARADERO : contiene
    ZONA ||--o{ REPORTE_ILEGAL : registra

    EMPRESA_OPERADORA {
        int id_empresa PK
        string nit UK
        string nombre
        string estado
    }
    VEHICULO {
        int id_vehiculo PK
        int id_empresa FK
        string placa UK
        int capacidad
        boolean tiene_rampa
        boolean piso_bajo
        boolean espacio_silla_ruedas
        string estado
    }
    ZONA {
        int id_zona PK
        string nombre UK
    }
    PARADERO {
        int id_paradero PK
        int id_zona FK
        string nombre
        string tipo
        boolean habilitado
    }
    RUTA {
        int id_ruta PK
        string codigo UK
        string nombre
        string estado
    }
    RUTA_PARADERO {
        int id_ruta PK
        int id_paradero PK
        int orden
    }
    ASIGNACION {
        int id_asignacion PK
        int id_vehiculo FK
        int id_ruta FK
        date fecha
        string turno
        time hora_inicio
        time hora_fin
    }
    RESPONSABLE {
        int id_responsable PK
        string nombre
        string entidad
    }
    INSPECCION {
        int id_inspeccion PK
        int id_empresa FK
        int id_responsable FK
        date fecha
    }
    INSPECCION_DETALLE {
        int id_detalle PK
        int id_inspeccion FK
        string condicion
        string resultado
    }
    REPORTE_ILEGAL {
        int id_reporte PK
        int id_zona FK
        int anio
        int mes
        int total_reportes
    }
    AUDITORIA {
        int id_auditoria PK
        string tabla_afectada
        string operacion
        int id_registro
        string usuario_bd
        datetime fecha_evento
        string detalle
    }
```

*Estado:* REVISADO ESTÁTICAMENTE. La imagen exportada (`docs/er.png`) debe guardarse como evidencia.
