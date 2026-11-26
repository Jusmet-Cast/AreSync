# Modelo de datos — FitCodex / AreSync

SQL Server. DDL en `schema/`, numerado por orden de ejecución (las FKs
dependen de ese orden).

```bash
# Ejecutar en orden sobre una base vacía
sqlcmd -S <server> -d <db> -i schema/00_core.sql
sqlcmd -S <server> -d <db> -i schema/01_arcs.sql
# ... hasta 08_coach.sql
```

## Por qué relacional

Decidido el 25 Nov 2026 con tres spikes sobre el Notion real, no por preferencia:

- **Cero relaciones N:N** en las 9 bases existentes. Todo 1:N o N:1.
- **2 de 7 fórmulas** cruzan tablas; el resto es aritmética sobre la misma fila.
- La detección de PR exige agregación con filtro (`max(1RM)` por ejercicio +
  unidad) — una consulta relacional, no un lookup de documento.
- El cliente ya es relacional (Drift/SQLite en `app/front`).
- El problema dominante no era la cardinalidad: era **falta de tipado** sobre
  datos que vivían como prosa. Eso lo resuelve un schema fuerte, no un motor
  sin schema.

Las únicas N:N del modelo son las que **introduce la app**, no las que tenía
Notion: participantes de un evento de comunidad, tipos de actividad por
aventura, y el vínculo profesional↔paciente.

## Mapa de schemas

| Schema | Qué guarda | Origen en Notion |
| --- | --- | --- |
| `core` | Usuarios, roles, vínculo profesional↔paciente | — (nuevo) |
| `arcs` | Arc, metas, fases, suplementación, split, reglas, lesiones | Routes of Arcs + body de la página |
| `medical` | Composición corporal por método + proveedor | MedLog |
| `training` | Catálogo de ejercicios + sesiones reales + PRs | Motion Studio + TrainLog |
| `nutrition` | Recetario, alacena, log de comidas, foto→macros | NutriCore + Essentials + FoodLog |
| `adherence` | Ledger de cierre diario y semanal, IAA, balance | AdheLog |
| `adventures` | Retos personales + eventos de comunidad | Adventures (+ capa social nueva) |
| `telemetry` | Lecturas crudas de wearables y fuentes conectadas | — (hoy entra a mano) |
| `coach` | Qué recomendó la IA y quién lo supervisó | — (nuevo) |

## Aristas principales

```
core.User ─1:N─ arcs.Arc ─1:N─ arcs.ArcGoal
                          ├1:N─ arcs.ArcPhase
                          ├1:N─ arcs.Supplement
                          ├1:N─ arcs.SplitDay
                          ├1:N─ arcs.ArcRule
                          └1:N─ arcs.ArcLesson

core.User ─1:N─ arcs.BiomechanicalRestriction   (del cuerpo, no del ciclo)

core.User ─1:N─ medical.MedLogEntry ─N:1─ arcs.Arc
                medical.MedLogEntry ─1:1─ medical.DxaMeasurement
                                    ├1:1─ medical.NavyMeasurement
                                    ├1:1─ medical.EstimateMeasurement
                                    └1:N─ medical.AnthropometricReading
                medical.MedLogEntry ─N:1─ medical.Provider

core.User ─1:N─ training.Exercise ─1:N─ training.ExerciseDaySchedule
                training.Exercise ─1:1─ training.ExercisePrescription
                training.Exercise ─N:N─ training.Exercise  (alternativas)

core.User ─1:N─ training.TrainingSession ─1:1─ training.SessionTelemetry
                training.TrainingSession ─1:N─ training.ExerciseLog ─N:1─ training.Exercise

core.User ─1:N─ adherence.AdherenceEntry ─N:1─ arcs.Arc
                adherence.AdherenceEntry ─1:N─ adherence.AdherenceEntry  (weekly→daily)
                adherence.AdherenceEntry ─N:N─ training.TrainingSession

core.User ─1:N─ nutrition.FoodLogEntry ─N:1─ nutrition.Recipe
                nutrition.MealPhotoEstimate ─1:N─ nutrition.MealPhotoComponent

core.User ─1:N─ adventures.Adventure ─N:N─ core.User  (participantes)
                adventures.Adventure ─N:N─ training.TrainingSession

core.User ─N:N─ core.User  (CareRelationship: profesional ↔ paciente)
core.User ─1:N─ coach.AgentInsight ─1:N─ coach.AgentInsightFlag
```

## Qué se corrigió respecto de Notion

Cada uno verificado en vivo, no asumido:

| Problema real | Corrección |
| --- | --- |
| `MedLog.Arc` era un `select` de texto: renombrar un arc rompía el vínculo | FK real `MedLogEntry.ArcId` |
| `Adventures.msnm` guardaba el string `"msnm 2884"` | `AltitudeMeters DECIMAL` |
| `Adventures.Pin` (lat/lon/placeId) se perdía al aplanar a texto | Columnas de geodata propias |
| `Tipo de Actividad` no incluía `running` aunque estaba en uso | Tabla con el enum completo |
| `Motion Studio.Day` no tenía `friday` | Tabla con los 7 días |
| Fases, suplementos, split y reglas vivían en el body de una página | `ArcPhase`, `Supplement`, `SplitDay`, `ArcRule` |
| Lecciones de cierre no tenían campo | `ArcLesson` |
| Historial de lesión existía solo como prosa en un callout | `BiomechanicalRestriction` |
| Lecturas crudas y fórmula de una medición vivían en `Notas` | `AnthropometricReading`, `NavyMeasurement.FormulaVersion` |
| `Centro / Lab` mezclaba centro + médico + equipo + software | `medical.Provider` |
| Detalle de sueño (onset, eficiencia, despertares) iba en prosa | Columnas en `AdherenceEntry` |

## Decisiones que conviene recordar

- **Sin JSON.** Se evaluó para el payload disjunto de MedLog y se rechazó: son
  datos clínicos que un profesional tiene que poder consultar y auditar. Una
  tabla hija por método, todo tipado. Se mantiene `VARCHAR`, nunca `NVARCHAR`.
- **GUID como PK.** El cliente captura offline (una serie en un gimnasio sin
  señal) y tiene que poder generar el id antes de sincronizar.
- **Un solo arc activo por usuario**, garantizado por índice filtrado: toda la
  app resuelve "el arc activo" en singular.
- **El catálogo es mutable, la bitácora no.** `ExercisePrescription` se
  reescribe cada semana; `ExerciseLog` es el hecho de lo que pasó ese día.
- **Un ejercicio no se borra**, se desactiva (`Exercise.IsActive = 0`): su
  historial de PRs tiene que seguir existiendo.
- **El sueño es del día, no de la sesión.** Vive en `AdherenceEntry`, una sola
  vez: dos sesiones el mismo día comparten la misma noche.

## Pendiente de decidir

- Mensajería profesional↔paciente: no modelada a propósito. Implica hilos,
  adjuntos, posiblemente video, y alcance regulatorio sin evaluar.
- Estrategia de blobs para `MedLogEntry.AttachmentUrl` (los PDFs de
  laboratorio) y para las fotos de comida.
- Si `ProgressPercent` del arc se calcula por job, por vista o se escribe
  desde la app.
