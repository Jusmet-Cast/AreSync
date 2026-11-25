# FitCodex (app/front)

Coach de **entrenamiento, nutrición y telemetría** en una sola app, para
cualquier usuario en cualquier fase de sus objetivos — no una app de un solo
perfil. Los pilares no son módulos sueltos: el valor del producto está en las
decisiones que sólo se pueden tomar cruzándolos, alrededor de un **Arc**: el
objetivo que el usuario setea (tipo, metas de peso/grasa/VO2max/proteína/
sueño/pasos) y que gobierna todo lo demás.

Vive dentro del monorepo `AreSync` — ver `../../README.md` para cómo se
relaciona con `System/` (los agentes) y `app/api` (el backend planeado).

> Estado: esqueleto con dominio generalizado y datos mock. **El código
> todavía no se compiló** — Flutter no está instalado en esta máquina. Ver
> «Puesta en marcha».

---

## Puesta en marcha

El Android SDK ya está presente (`%LOCALAPPDATA%\Android\Sdk`). Falta Flutter:

```bash
# 1. Instalar el SDK de Flutter y dejarlo en el PATH
#    https://docs.flutter.dev/get-started/install/windows

# 2. Verificar que el toolchain quedó completo
flutter doctor

# 3. Generar las carpetas de plataforma sobre este proyecto
#    (no están versionadas a propósito: se regeneran)
cd AreSync/app/front
flutter create . --platforms=android,ios --org com.jusmet

# 4. Dependencias, y subirlas a sus versiones mayores actuales
flutter pub get
flutter pub upgrade --major-versions

# 5. Correr
flutter run
```

> **iOS desde Windows:** firmar iOS exige macOS. La salida es CI en la nube
> (Codemagic o Bitrise). Hay que montarlo antes de tener la app lista, no después.

---

## Arquitectura

Clean Architecture, organizada **por feature** y no por capa, para que cada
pilar se pueda tocar sin abrir toda la app.

```
lib/
├── main.dart
├── app/                     Composición: tema, router, arranque
│   ├── router.dart          5 destinos en la barra + /aventuras y /coach
│   └── theme/               Tokens de color y tipografía
├── core/                    Transversal a todos los pilares
│   ├── domain/
│   │   ├── entities/arc.dart           ← la unidad de planificación
│   │   ├── entities/user_profile.dart  ← quién usa la app (generico)
│   │   ├── entities/agent_insight.dart ← espejo de lo que cada agente real
│   │   │                                 devuelve (aegis_output, forge_output...)
│   │   ├── entities/metric.dart        ← el modelo canónico de telemetría
│   │   ├── ports/arc_repository.dart
│   │   ├── ports/telemetry_source.dart ← el contrato agnóstico del wearable
│   │   └── calculators/                ← IRA (AEGIS) e IAA (MOMENTUM), puras
│   └── data/repositories/              ← mocks en memoria, hoy la única fuente
└── features/
    ├── today/               El coach: la síntesis de todos los pilares
    ├── training/            Pilar — fuerza (1RM, zonas de hipertrofia)
    ├── nutrition/           Pilar — macros, plan, ayuno, foto → macros
    ├── telemetry/           Pilar — lo que el cuerpo reporta
    ├── profile/             Nivel, Arc activo, fuentes conectadas
    ├── adventures/          Retos personales + eventos de comunidad (social)
    └── coach/               Chat/orquestación de agentes (hoy mock)
```

Cada feature usa `domain/` · `data/` · `presentation/`. **El dominio no importa
`package:flutter`**: por eso `TelemetrySource` recibe dos `DateTime` y no un
`DateTimeRange` de Material, y por eso los calculadores (`IraCalculator`,
`IaaCalculator`, `OneRepMaxCalculator`, `BalanceVerdictCalculator`) son Dart
puro — las mismas fórmulas documentadas en `System/Agentes/*.md`, para que la
app no invente un número que el sistema de agentes calcularía distinto.

### Las piezas que sostienen todo

**`Arc`** — el objetivo que el usuario setea (tipo, metas, fechas). Nada más
en la app tiene metas propias: training, nutrition y telemetry leen las del
Arc activo. Espejo generalizado de "Routes of Arcs" en Notion.

**`AgentInsight`** (sealed: `RecoveryInsight`/`TrainingInsight`/
`NutritionInsight`/`AdherenceInsight`) — la forma en que la app representa lo
que AEGIS, FORGE, NUTRISYNC y MOMENTUM devuelven hoy vía chat. `AgentOrchestrator`
(`features/coach`) es el puerto que, el día que `app/api` exista, invoca a esos
agentes de verdad; hoy lo llena `MockAgentOrchestrator` con las mismas fórmulas.

**`Metric` / `TelemetrySource`** — todo dato de telemetría entra por acá y
guarda su procedencia. FitCodex no habla con fabricantes: habla con Apple
Health y Health Connect. Garmin, Polar, Oura, Whoop y Xiaomi escriben ahí.
Cambiar de reloj no toca una línea — y conectar un wearable real el día de
mañana es implementar este puerto, no rediseñar la app.

**`MealVisionSource`** (`features/nutrition/domain/ports`) — contrato para
"foto de comida → macros", tercerizado a un proveedor de visión (Gemini,
DeepSeek u otro a evaluar). La API key nunca viaja en el cliente: la
implementación real vive en `app/api`, acá solo hay un mock.

**`Adventure`** (`features/adventures`) — retos (`AdventureKind.personal`) y
eventos de comunidad (`AdventureKind.community`, con cupo/organizador/
confirmados) en la misma entidad, distinguidos por `kind` — la base para que
una maratón o una salida grupal funcione como evento social más adelante.

**`TelemetrySource`** — el contrato que vuelve a la app agnóstica del wearable.
FitCodex no habla con fabricantes: habla con Apple Health y Health Connect.
Garmin, Polar, Oura, Whoop y Xiaomi escriben ahí. Cambiar de reloj no toca
una línea.

---

## Restricciones verificadas

No son opiniones; se verificaron contra la fuente antes de decidir el stack.

| Restricción | Consecuencia |
| --- | --- |
| **Strava** prohíbe en su API Policy (vig. 1 Jun 2026) ingresar sus datos a una IA — nombra la ventana de contexto y RAG | No es fuente para el coach. No aparece en `MetricSource` |
| **Garmin** tiene el programa de devs cerrado, exige entidad legal y US$ 5 000 | Se lee vía Health Connect, no vía su API |
| **Google Fit** termina servicio a fines de 2026 | Android va directo a Health Connect |
| La **Xiaomi global no publica HRV** | `MetricType.heartRateVariability.puedeFaltar == true`; la disposición diaria degrada a pulso en reposo + sueño |

---

## Convenciones

No se sostienen con disciplina, se sostienen con tooling:

- `analysis_options.yaml` en modo estricto (`strict-casts`, `strict-inference`).
- `dart format` antes de cada commit.
- Conventional commits, sin excepciones.
- Un test de integración por flujo crítico: registrar serie sin señal → sincronizar.

## Pendientes inmediatos

Hecho (25 Nov 2026 — sesión de fundación del monorepo):
- [x] Dominio generalizado: `Arc`, `UserProfile`, `AgentInsight` ya no cargan
  ningún dato de una sola persona — ver `MockArcRepository` para el seed
  neutral que reemplazó al literal "Serio"/texto fijo del hero de Hoy.
- [x] Calculadores puros espejo de las fórmulas reales: `IraCalculator`
  (AEGIS), `IaaCalculator` (MOMENTUM), `OneRepMaxCalculator` + zonas de
  hipertrofia (FORGE), `BalanceVerdictCalculator` (NUTRISYNC/AdheLog).
- [x] Puertos para las tres integraciones futuras que importan: wearables
  (`TelemetrySource`, ya existía), orquestación de agentes
  (`AgentOrchestrator`, `features/coach`) y visión de comida
  (`MealVisionSource`, `features/nutrition`) — los tres con mock, ninguno
  con implementación real todavía.
- [x] `features/adventures`: retos personales + eventos de comunidad.

Sin hacer:
- [ ] Adaptadores `HealthConnectSource` y `AppleHealthSource` implementando `TelemetrySource`
- [ ] Implementación real de `AgentOrchestrator` contra `app/api` (hoy mock)
- [ ] Implementación real de `MealVisionSource` contra Gemini/DeepSeek vía `app/api`
- [ ] Esquema Drift y motor de sincronización contra el backend .NET
- [ ] `session_page.dart` (training) todavía usa datos de ejemplo fijos en vez
  de leer del repositorio de ejercicios — generalización de UI pendiente,
  el dominio (`WorkingSet`, `OneRepMaxCalculator`) ya está listo para eso
- [ ] Capa social real de `adventures` (perfiles, feed, invitaciones) — hoy
  es solo la entidad y una lista con botón "Sumarme"
- [ ] Evaluar GPS en background sostenido (`geolocator` no alcanza para 4 h con pantalla apagada)
- [ ] Empaquetar las tipografías como assets — hoy `google_fonts` las baja en runtime
- [ ] Pipeline de build iOS en la nube
