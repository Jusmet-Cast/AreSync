# ARESYNC — REGISTRO MAESTRO DE BASES DE DATOS NOTION
**Versión:** 1.5
**Fecha de emisión:** 5 Ago 2026 · **Última actualización:** 29 Sep 2026
**Estatus:** 🔴 ARCHIVO CANÓNICO — Infraestructura compartida. Todo agente con acceso a Notion debe consultar este archivo antes de leer o escribir cualquier base de datos.

---

## 1. PROPÓSITO

Este archivo es lo que convierte al sistema en una simbiosis real y no en un asesor de un solo sentido: es el mapa que permite que cualquier agente sepa qué base de datos gobierna qué dominio, el schema exacto (nombres de campo y tipos tal como existen hoy en Notion), y cómo generar entradas nuevas consistentes con el estilo del usuario en vez de inventar una estructura nueva cada vez.

Datos verificados en vivo contra el workspace real el 5 Ago 2026, contra TrainLog el 25 Sep 2026, y contra AdheLog (ledger de cierre) el 28 Sep 2026.

---

## 2. MAPA DE MÓDULOS FITCODEX

| Módulo | Data Source ID | Database ID | Agente(s) dueño(s) | Propósito |
|---|---|---|---|---|
| Motion Studio | `2c2ef7d9-a13c-80cb-9229-000b24b0771c` | — | FORGE, ATLAS | Catálogo de ejercicios: día, músculo, uso, hecho — bitácora semanal mutable |
| NutriCore | `2c2ef7d9-a13c-803c-be93-000bdfba3c33` | — | NUTRISYNC, CHEFSYNTH | Recetario base |
| Essentials Hub | `2c2ef7d9-a13c-80e3-837a-000ba88aec63` | — | NUTRISYNC, CHEFSYNTH | Inventario de alacena |
| FoodLog | `5c1f6761-57b9-435c-b19d-f80cab980e77` | — | NUTRISYNC (`/macros`), MOMENTUM | Log diario de comidas |
| Routes of Arcs | `1bd3802c-8fbf-4228-9be4-0fa6ee8d2baa` | — | CORE, ECHO | Ciclos de entrenamiento (arcs) |
| MedLog | `b83f0afb-c219-4775-bccc-da2eb77ae596` | — | PULSE, ECHO | Métricas corporales (DXA, antropometría, etc.) |
| Adventures | `2deef7d9-a13c-805f-bb53-000b96dfbe4c` | — | PATHFINDER | Destinos outdoor |
| Control Tower · check diario | `7a16f88e-0dd5-4a8e-9c93-822179050e7d` | — | CORE, MOMENTUM | Desglose de composición DXA por fecha de examen (no es un check diario real pese al nombre) |
| **TrainLog** (ex PR Log) | `600fc00c-c035-42dd-b27b-6ae120fec595` | `6fa9a98cad524245b3403ae2db8dffc0` | FORGE, ECHO, AEGIS, PULSE | Data lake de entrenamiento: telemetría de sesión (Mi Fitness) + registro por ejercicio + PRs, multidisciplinar |
| **AdheLog** | `9f95d220-1d08-4133-adf9-126218ffa517` | `0fec27f693354a57a84153ea08bef098` | MOMENTUM, NUTRISYNC, ECHO, ORACLE | Ledger de cierre: filas Daily (`/close`) y Weekly (IAA) con totales y veredictos de balance; vistas por día, semana, mes y año |

Root FitCodex: `2b1ef7d9a13c80e28b58d2eb63df89c7`

---

## 3. SCHEMAS EXACTOS

### Motion Studio
```
Exercise (title) · Day (multi_select: Monday, Tuesday, Wednesday, Thrusday, Saturday, Sunday)
Main Muscle (select: Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Cardio)
Complementary Muscle (multi_select: 14 opciones de músculo secundario)
Series (text) · Weight (text) · Use (checkbox) · Done (checkbox)
Description (text) · Example Video (url)
```
⚠️ **Inconsistencia detectada:** la opción "Day" no incluye **Friday** (aparece "Thrusday" con typo, falta viernes por completo). Esto puede estar causando que ejercicios de viernes queden mal etiquetados. No se corrige automáticamente — cambiar opciones de select puede romper vistas filtradas existentes. Flag para que lo revises tú directamente en Notion.

Motion Studio es **bitácora semanal mutable**: `Weight` y `Series` reflejan lo que se hizo esa semana, no un plan fijo. Ningún dato de telemetría de sesión (kcal, FC, intervalos, sueño) vive aquí — si aparece escrito en un campo o en la bitácora, se migra a TrainLog como fila `Telemetry` y se limpia el origen.

### NutriCore
```
Receta (title) · Categoría (select: Desayuno, Almuerzo, Cena, Snack, Postre)
Proteína (g) (number) · Calorías (number)
Tiempo de preparación (select: <15 min, 15-30 min, 30-60 min, >60 min)
Origen (url)
```

### Essentials Hub
```
Nombre (title)
Categoría (multi_select: Fruits, Vegetables, Meats, Dairy, Grains, Protein, Supplements, Snacks, Legumes, Liquid boost)
Alacena (status: Empty, Low, Half, Full)
Prioridad de consumo (select: Alta, Media, Baja)
Marca (text) · Tienda (text) · Precio (number)
```

### FoodLog
```
Name (title) · Categoría (select: Desayuno, Almuerzo, Cena, Snack)
Proteína (g) · Carbohidratos (g) · Grasa (g) · Calorías (todos number)
Confianza (select: Alta, Media, Baja) · Dentro del plan (checkbox)
Fecha (date) · Notas (text)
```

### Routes of Arcs
```
Nombre (title) · Tipo (select: Recomp Arc, Bulk Arc, Cut Arc, Hybrid Arc, Endurance Arc, Mental Arc)
Estado (select: Planeado, Activo, Completado)
Fecha de inicio / Fecha de fin (date) · Duración (días) (number)
Peso inicial / Peso final (number) · Progreso (%) (number) · Score promedio (number)
Descripción breve (text)
```

### MedLog
```
Registro (title) · Tipo de Registro (select: DXA, Antropometría, Laboratorio, Chequeo Médico, Wearable)
Método (select: DXA (Hologic), Navy Method, Bioimpedancia, Caliper, Estimado visual)
Arc (select: Winter Arc 2025, Summer Arc 2026, Post-Arc, Winter Arc 2026)
Fecha del Examen (date)
+ ~28 campos numéricos de composición corporal (Grasa Corporal %, Masa Magra, ALMI, FFMI,
  VAT, Z-Score DMO, Asimetría Piernas %, Peso, IMC, TMR Medida, etc. — el registro
  base es el DXA del 29 Jul 2026 en la propia MedLog)
```

### Adventures
```
Nombre del Destino (title)
Tipo de Actividad (multi_select: Hiking, Biking, Alpinism, Camping, Canopy, Espeleología, Trekking)
State (status: Upcoming Challenge, In Planning, Completed)
Difficulty (select: easy, moderate, hard, extreme)
Duration (hr) (number) · Fecha de Visita (date)
Location (label) (text) · msnm (text) · Pin (place)
```

### TrainLog
```
Record (title) · Date (date) · Entry Type (select: Exercise, PR, Telemetry)
Session ID (text) · Session Type (select: Push, Pull, Legs, Full Body, Recovery, Run,
  Speed Work, Trail, Walking, Hiking, Cycling, Swimming, Boxing, Kickboxing, Muay Thai,
  BJJ, MMA, Other) — campo único para split y deporte; el sistema es agnóstico a la disciplina
— Ejercicio —
Exercise (relation → Motion Studio) · Weight (kg) · Reps · Estimated 1RM (kg) (number)
Unit (select: Total, Per Side, Per Dumbbell)
Type (select: Added Load, Bodyweight, Volume, Adjustment)
— Telemetría —
Duration (min) · Active kcal · Total kcal · Avg HR · Max HR · Training Load
Aerobic TE · Anaerobic TE · Recovery (h) · Distance (km) · Steps (number) · Pace (text)
Sleep (h) · Sleep Score (number) — histórico de sueño previo al 28 Sep 2026; desde entonces el sueño se escribe una sola vez en AdheLog Daily
Daily Close (relation → AdheLog Daily) · Daily Sleep (h) · Daily Sleep Score (rollup max vía Daily Close) — sueño del día visible en cada sesión sin reescribirlo
Z Light · Z Intensive · Z Aerobic · Z Anaerobic · Z VO2max (min) — zonas de FC de Mi Fitness
Pace (min/km) · Cadence (spm) · Stride (cm) (number) — métricas de carrera graficables
Notes (text)
```
Vistas: **History** (agrupada por fecha) · **Cadense/Exercise** (chart de progreso por ejercicio, nombre legacy con typo, no tocar) · **🏆 PRs** (`Entry Type = PR`) · **📈 Sessions** (`Entry Type = Telemetry`) · **🔥 Active kcal by Day** (Sum de Active kcal agrupado por día).

**Convención de identificador de sesión:** `D{día}S{semana}{ArcCode}` — ej. `D3S7WA26`
- Inicio = `Fecha de inicio` del arc activo, leída en vivo de Routes of Arcs (nunca hardcodeada)
- `días = Date − Inicio` · `S = floor(días / 7) + 1` · `D = (días mod 7) + 1`
- Winter Arc 2026 inicia lunes 10 Ago 2026 → D1 = lunes, D7 = domingo
- ArcCode: iniciales del arc + año (Winter Arc 2026 = `WA26`)
- Dos sesiones el mismo día comparten ID; el `Session Type` las distingue

**Convención de títulos e iconos:**

| Entry Type | Título | Icono |
|---|---|---|
| Telemetry | `{Session Type} Session Telemetry {ID}` → `Legs Session Telemetry D3S7WA26` | 📈 |
| Exercise | `{Ejercicio} {ID}` → `Curl Martillo D1S6WA26` | Icono de la página del ejercicio en Motion Studio |
| PR | `PR {Ejercicio} {ID}` → `PR Curl Martillo D1S6WA26` | 🏆 |

Filtrar siempre por `Entry Type`, nunca por el texto del título.

**Un solo registro por ejercicio por día.** Un PR no genera una fila adicional: es la misma fila del ejercicio con `Entry Type = PR`, prefijo `PR` y 🏆.

**Regla de PR** (contra el máximo previo del mismo ejercicio y la misma `Unit` en TrainLog o en la bitácora de Motion Studio): más peso → PR; mismo peso con más reps → PR; una notación de rango (`8-10`) cuenta por su límite inferior; un `Adjustment`, un cambio de equipo o la primera fila de un ejercicio sin referencia previa no son PR.

**Fechas y días asignados.** Las fechas reales de ejecución no se mueven. Los registros con fecha estimada o de backfill se colocan en el día de la semana asignado a su ejercicio en el split (D1 = lunes). Los baselines pre-arc viven en S1, cada uno en su día de split.

### AdheLog

**Ledger de cierre diario y semanal.** Guarda solo totales y veredictos del día o de la semana, nunca números por comida o por ejercicio: ese detalle vive en FoodLog y TrainLog. Cada fila es una página viva con cuerpo de plantilla.

```
Entry (title) · Date (date) · Entry Type (select: Daily, Weekly) · Period ID (text)
Arc (relation → Routes of Arcs)
Week Entry (relation → AdheLog, una Weekly) ↔ Daily Entries (relation → AdheLog, sus Daily)
Sessions Log (relation → TrainLog, solo filas Telemetry del día) ↔ Daily Close (en TrainLog)
Day Type (select: Training, Rest, Active Recovery, Event)
Data Quality (select: Complete, Partial, Estimated)
— IAA (solo Weekly) —
Flag (select: G, Y, O, R) · Score Total · Score Training · Score Nutrition · Score Telemetry · Score PR (number)
— Ingesta (por día; en Weekly = promedio diario) —
Intake (kcal) · Protein (g) · Carbs (g) · Fat (g) (number)
Days Over Fat Ceiling · Days Under Protein Floor (number) — Daily: 0 o 1 · Weekly: conteo de días
— Entreno (total del período) —
Sessions · PRs · Training Load · Active kcal (number)
— Gasto y balance —
RMR (kcal) · NEAT (kcal) (number) — por día
Phase Target (kcal) (rollup: sum de Arc → "Déficit Fase Actual (kcal)")
Day Count (formula: 7 si Weekly, 1 si Daily)
TDEE (kcal) (formula: RMR + NEAT + Active kcal / Day Count)
Energy Balance (kcal) (formula: Intake − TDEE, por día)
Period Balance (kcal) (formula: Energy Balance × Day Count)
Balance Verdict (formula) · Target Fit (formula)
— Recuperación y cuerpo (solo Daily) —
Sleep (h) · Sleep Score · Steps · Weight (kg) (number) — Sleep es canónico aquí desde el 28 Sep
— Texto —
Focus Areas (text, Weekly) · Notes (text)
Month (formula: YYYY-MM de Date) · Year (formula: YYYY de Date)
```

Fórmulas y rollups no son consultables por SQL y la API los devuelve como referencia, no como valor: se verifican en la UI. Nunca se escriben a mano. Las fórmulas quedan vacías si falta `Intake (kcal)` o `RMR (kcal)`; `Target Fit` además si falta `Arc`.

**Balance Verdict** — sobre `Energy Balance (kcal)` por día, independiente del tipo de arc:

| Verdict | Balance/día | Escenario típico |
|---|---|---|
| Aggressive Deficit | < −750 | Cut agresivo, o alerta de sub-ingesta |
| Deficit | −750 a −250 | Cut estándar (Fase 2 del Winter Arc) |
| Mild Deficit | −250 a −100 | Recomp |
| Maintenance | −100 a +100 | Mantenimiento, taper |
| Lean Surplus | +100 a +300 | Lean bulk |
| Surplus | +300 a +600 | Bulk, refeed |
| Aggressive Surplus | > +600 | Comida libre, dirty bulk |

**Target Fit** — `Energy Balance − Phase Target`, contra el arc activo: `On Target` (±150 kcal), `Under Target` (< −150, más déficit del planeado), `Over Target` (> +150, menos déficit o más superávit del planeado). Funciona igual para arcs de bulk con target positivo.

**Convención de títulos, iconos e identificador:**

| Entry Type | Título | Icono | Period ID | Date |
|---|---|---|---|---|
| Daily | `Daily Close {ID}` → `Daily Close D6S7WA26` | 📅 | `D{día}S{semana}{ArcCode}` (mismo cálculo que TrainLog) | El día |
| Weekly | `Weekly Close {ID}` → `Weekly Close S7WA26` | 📊 | `S{semana}{ArcCode}` | Domingo de cierre |

**Cálculo de la fila Daily** (`/close`, siempre desde Notion en vivo):

| Campo | Fuente |
|---|---|
| Intake, Protein, Carbs, Fat | Σ de FoodLog con Date = día |
| Days Over Fat Ceiling | 1 si Fat > 92 g, si no 0 |
| Days Under Protein Floor | 1 si Protein < "Meta Proteína Min (g)" del arc activo, si no 0 |
| Sessions · Training Load · Active kcal | TrainLog `Telemetry` del día (conteo y sumas) |
| PRs | TrainLog `PR` del día |
| RMR (kcal) | "TMR Medida (kcal)" más reciente en MedLog |
| NEAT (kcal) | kcal totales del día (resumen diario de Mi Fitness) − RMR − Active kcal. Sin resumen: 200 estimado y Data Quality = Estimated |
| Sleep (h), Sleep Score | Sueño de Mi Fitness con fecha del día (noche que termina esa mañana, siestas incluidas) |
| Steps · Weight (kg) | Resumen diario de Mi Fitness · báscula AM en ayunas |
| Week Entry | Fila Weekly de esa semana, si ya existe |
| Sessions Log | Filas Telemetry de TrainLog del día (nunca Exercise ni PR) |

**Cálculo de la fila Weekly** (`/weekly` o `/adherencia`): a partir de sus filas Daily cuando existen (promedios diarios de Intake, macros, RMR y NEAT; sumas de Sessions, PRs, Training Load, Active kcal y de los contadores de días). Si faltan días Daily, se completa desde FoodLog y TrainLog en vivo y se declara en Notes. Al crearla se enlaza `Daily Entries` con los 7 días. Scores del IAA según `MOMENTUM.md`.

**Data Quality:** `Complete` = llegaron todos los inputs requeridos (sueño y resumen diario) · `Partial` = falta un requerido y no se estimó · `Estimated` = NEAT y/o sueño con estimado.

**Cuerpo de página (plantilla).** Contenido en español, solo totales, remitiendo a FoodLog y TrainLog para el detalle:
- Daily: callout ⚖️ `{Balance Verdict} · {Target Fit}` + balance y Data Quality · `## Nutrition` · `## Training` · `## Balance` (RMR + NEAT + activas = TDEE → ingesta → balance) · `## Recovery` (sueño, pasos, peso) · `## Retro` (Funcionó · Ajustar · Foco de mañana).
- Weekly: callout 📊 `Flag · Score Total · {Balance Verdict}` · `## Nutrition` · `## Training` · `## Balance` · `## IAA` · `## Focus Areas`.
- La plantilla nativa de base de datos no se puede crear por API: se crea en la UI con "Duplicate as template" sobre `Daily Close D6S7WA26`. Mientras no exista, `/close` escribe este cuerpo al crear la página.

**Vistas** (creadas 29 Sep, DSL de `notion-create-view` / `notion-update-view`):

| Vista | Tipo | Configuración |
|---|---|---|
| History | table | Todas las filas · `SORT BY "Date" DESC` · `QUICK FILTER "Entry Type"` |
| Daily | table | `FILTER "Entry Type" = "Daily"` · `SORT BY "Date" DESC` |
| Weekly | table | `FILTER "Entry Type" = "Weekly"` · `SORT BY "Date" DESC` |
| Monthly | table | `FILTER "Entry Type" = "Weekly"` · agrupar por Date → Month (solo en la UI) |
| Yearly | table | `FILTER "Entry Type" = "Weekly"` · agrupar por Date → Year (solo en la UI) |
| Calendar | calendar | `CALENDAR BY "Date"` · `FILTER "Entry Type" = "Daily"` · muestra Balance Verdict y Target Fit |
| Balance Trend | chart | Daily · `GROUP BY "Date"` · `CHART line AGGREGATE sum ON "Energy Balance (kcal)"` |
| Verdict Mix | chart | Daily · `GROUP BY "Balance Verdict"` · `CHART donut` |
| Protein Trend | chart | Daily · `GROUP BY "Date"` · `CHART line AGGREGATE sum ON "Protein (g)"` |
| Fat Trend | chart | Daily · `GROUP BY "Date"` · `CHART line AGGREGATE sum ON "Fat (g)"` |
| Sleep Trend | chart | Daily · `FILTER "Sleep Score" IS NOT EMPTY` · `GROUP BY "Date"` · `CHART line AGGREGATE average ON "Sleep Score"` |
| Weight Trend | chart | Daily · `FILTER "Weight (kg)" IS NOT EMPTY` · `GROUP BY "Date"` · `CHART line AGGREGATE average ON "Weight (kg)"` |

`GROUP BY` sobre las fórmulas Month/Year no se aplica por API: en Monthly y Yearly la agrupación se configura en la UI (Group → Date → Month / Year).

⚠️ Monthly y Yearly **siempre** filtradas a Weekly: sin el filtro, las filas Daily duplican los totales del período. Month y Year no son consultables por SQL: para agregados mensuales, filtrar por rango de `date:Date:start`.

`Flag` usa G/Y/O/R: coinciden con Green/Yellow/Orange/Red y con Verde/Amarillo/Naranja/Rojo.

`Score promedio` de Routes of Arcs promedia `Score Total`; las filas Daily lo dejan vacío, así que no alteran el promedio.

Las panorámicas Monthly y Yearly son vistas sobre las filas semanales, no filas nuevas.

---

## 4. PROTOCOLO UNIVERSAL — GENERACIÓN DE ENTRADA POR ESPEJO

Cuando el usuario pida crear una nueva entrada en cualquiera de estas bases (ej. "registra esta aventura", "agrega esta receta", "loguea este DXA nuevo", "abre el siguiente arc"), el agente dueño de esa base sigue este flujo:

```
PASO 1 — Leer las 2-3 entradas más recientes de la BD objetivo
         (notion-fetch sobre el data_source_id, ordenado por el campo de
         fecha propio de esa BD, o por createdTime si no tiene fecha)

PASO 2 — Extraer el patrón de estructura:
         - Qué campos se llenan siempre vs cuáles suelen quedar vacíos
         - Formato de valores (unidades, redondeo, estilo de Notas)
         - Selects/status usados con más frecuencia, para sugerir un
           default coherente si el usuario no lo especifica

PASO 3 — Mapear el input del usuario (foto, texto, voz) a esos mismos
         campos exactos — nunca inventar nombres de campo nuevos

PASO 4 — Mostrar el borrador de la entrada al usuario ANTES de escribir
         (excepción: /macros ya tiene su propio paso de confirmación
         formal — ver NUTRISYNC v2.0)

PASO 5 — Escribir con notion-create-pages usando
         parent = {"data_source_id": "..."} — nunca database_id cuando
         la base tiene múltiples data sources
```

Este es el mecanismo central de la simbiosis: el sistema no solo lee tu Notion, aprende su propio patrón de registro y lo repite con consistencia — igual que lo harías tú manualmente, sin la fricción de decidir el formato cada vez.

---

## 5. REGLAS DE ESCRITURA (aplican a todos los agentes)

- Checkbox: `__YES__` / `__NO__`
- Campos de fecha sin hora: `date:Campo:is_datetime` = 0
- Multi-select: array JSON de strings exactamente como aparecen en el schema
- Nombres de campo: en Motion Studio, NutriCore, Essentials Hub, FoodLog, Routes of Arcs, MedLog y Adventures, se usan con mayúsculas/acentos exactos tal como existen hoy — no traducir ni normalizar. **Excepción: TrainLog y AdheLog usan campos y labels en inglés por diseño** (normalizado 24–25 Sep 2026) — nunca escribir un nombre de campo en español en esas dos bases. Las entradas y su contenido (títulos, Notes) sí se escriben en el idioma del usuario, normalmente español; la normalización a inglés aplica solo a la estructura (nombres de campo y opciones de select), nunca al contenido.
- Confirmar con el usuario antes de escribir, salvo que el comando ya lo prevea explícitamente (ej. `/macros`)
