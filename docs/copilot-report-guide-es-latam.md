# Guia ejecutiva (ES-LATAM)
## Reporte de GitHub Copilot Enterprise (USD por usuario)

Este documento explica, en lenguaje simple para gerencia, como ejecutar el script, que significan sus parametros, como se calcula la estimacion de costo por usuario en USD y como leer cada seccion del HTML final.

---

## 1) Como ejecutar el script

Comando base:

```powershell
.\copilot-report.ps1 -Org CleveritDemo -PromptToken
```

El script pedira el token en entrada oculta y generara:
- Un archivo HTML: `copilot-report.html`
- Apertura automatica del reporte en el navegador

---

## 2) Parametros configurables

```powershell
.\copilot-report.ps1 \
  -Org CleveritDemo \
  -PromptToken \
  -SeatPriceUsd 39 \
  -VariableCostWeight 0.30 \
  -BillingDaysPerMonth 30
```

### Descripcion de parametros

- `-Org`
  - Organizacion de GitHub a consultar.
  - Ejemplo: `CleveritDemo`

- `-PromptToken`
  - Pide el token de forma segura (no visible en consola).

- `-Token`
  - Permite pasar el token directo (menos recomendado que `-PromptToken`).

- `-SeatPriceUsd`
  - Precio mensual por licencia Copilot Enterprise en USD.
  - Ejemplo: `39`

- `-VariableCostWeight`
  - Peso de la parte variable por uso, entre `0` y `1`.
  - Ejemplo: `0.30` significa 30% variable y 70% fijo.

- `-BillingDaysPerMonth`
  - Dias de referencia para prorrateo mensual.
  - Ejemplo: `30`

---

## 3) Para que sirven los parametros (ejemplos)

### Escenario A: reparto conservador (mas parejo)

```powershell
.\copilot-report.ps1 -Org CleveritDemo -PromptToken -SeatPriceUsd 39 -VariableCostWeight 0.10 -BillingDaysPerMonth 30
```

Interpretacion:
- 90% del costo se reparte parejo por licencia.
- 10% se asigna por uso.

### Escenario B: reparto equilibrado

```powershell
.\copilot-report.ps1 -Org CleveritDemo -PromptToken -SeatPriceUsd 39 -VariableCostWeight 0.30 -BillingDaysPerMonth 30
```

Interpretacion:
- 70% fijo por licencia.
- 30% variable por uso.

### Escenario C: reparto sensible al uso

```powershell
.\copilot-report.ps1 -Org CleveritDemo -PromptToken -SeatPriceUsd 39 -VariableCostWeight 0.50 -BillingDaysPerMonth 30
```

Interpretacion:
- 50% fijo por licencia.
- 50% variable segun actividad.

---

## 4) Formula usada para estimar costo por usuario (USD)

El script usa un modelo de asignacion contable (showback interno), porque GitHub factura por asiento, no con un valor oficial por usuario individual.

### Paso 1: costo de organizacion del periodo

- `Costo mensual org = seats * SeatPriceUsd`
- `Costo periodo = Costo mensual org * (dias_del_periodo / BillingDaysPerMonth)`

### Paso 2: separacion fijo + variable

- `Pool base = Costo periodo * (1 - VariableCostWeight)`
- `Pool variable = Costo periodo * VariableCostWeight`

### Paso 3: costo por usuario

- `USD base usuario = Pool base / total_seats`
- `Interacciones usuario = aceptaciones + chats`
- `USD variable usuario = Pool variable * (interacciones_usuario / interacciones_totales)`
- `USD estimado usuario = USD base usuario + USD variable usuario`

Notas importantes para gerencia:
- Este valor **no** es la factura oficial por usuario de GitHub.
- Es una asignacion financiera interna, trazable y consistente para control de costos.

---

## 5) Como leer el HTML final

### Vista general del reporte

![Vista completa del reporte](images/report-full.png)

### Seccion: KPIs principales

Muestra resultados globales del periodo:
- Seats activos
- Sugerencias generadas
- Sugerencias aceptadas
- Tasa de aceptacion
- Lineas aceptadas
- Chats

Uso gerencial: medir adopcion y efectividad global.

### Seccion: Usuarios con licencia

Lista usuarios con seat y actividad reciente.

Uso gerencial: controlar cobertura de licencias y detectar seats con baja actividad.

### Seccion: Metricas diarias

![Seccion de metricas diarias](images/report-metrics-section.png)

Muestra tendencia diaria (si hay datos disponibles del reporte de uso).

Uso gerencial: detectar cambios de adopcion por fecha.

### Seccion: Estimacion de consumo por usuario

Muestra interacciones promedio por usuario activo en el periodo.

Uso gerencial: indicador operativo de intensidad de uso.

### Seccion: Estimacion de costo por usuario (USD)

![Seccion de costo por usuario en USD](images/report-cost-section.png)

Explica el modelo de costos y presenta tabla por usuario con:
- Aceptaciones
- Chats
- Interacciones
- USD base
- USD variable
- USD estimado total

Uso gerencial: distribuir internamente el costo de licencias por area/equipo/persona.

### Seccion: Auditoria de ejecucion (solo lectura)

![Seccion de auditoria](images/report-audit-section.png)

Evidencia tecnica de compliance:
- Cantidad de llamadas HTTP
- Exitos/errores
- Operaciones de escritura (debe ser 0)

Uso gerencial: tranquilidad de seguridad. El script no cambia configuraciones ni datos de la org.

---

## 6) Recomendacion ejecutiva

Para reportes mensuales, usar `VariableCostWeight = 0.30` como base corporativa y mantener ese criterio fijo en el tiempo para comparabilidad.

Si finanzas desea mayor simplicidad:
- usar `0.00` (100% costo parejo por seat)

Si finanzas desea premiar adopcion:
- usar `0.50` (mitad fijo, mitad por uso)
