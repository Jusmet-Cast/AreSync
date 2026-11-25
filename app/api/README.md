# AreSync API (app/api)

**Estado: sin código todavía.** Esto documenta el plan de capas para que
`app/front` tenga contra qué puerto diseñar sus interfaces (`ArcRepository`,
`AgentOrchestrator`, `MealVisionSource`, `TelemetrySource`) sin esperar a que
el backend exista.

## Por qué hace falta un backend y no alcanza con pegarle a Notion directo

El cliente Flutter no puede:
- Guardar la API key de un LLM o de un proveedor de visión (Gemini/DeepSeek)
  dentro del APK/IPA — viaja descompilable.
- Invocar un LLM con el prompt completo de los 11 agentes (`System/Agentes/`)
  en cada pregunta sin un punto central que decida a cuál(es) activar.
- Servir a más de un usuario contra un único workspace de Notion — el sistema
  real (`System/`) es single-tenant por diseño (un usuario, su Notion). La
  app, en cambio, tiene que ser multi-usuario desde el día uno.

`app/api` es esa frontera: multi-tenant, dueño de los secretos, y el único
lado que decide si "la fuente de verdad" de un usuario dado es su propio
Notion (si alguna vez se ofrece esa integración) o solo su base de datos.

## Capas planeadas (Clean Architecture, stack por defecto del usuario)

```
Domain          Arc, UserProfile, AgentInsight, Adventure — las mismas
                entidades que ya existen en app/front/lib/core y
                app/front/lib/features/*/domain, sin redefinirlas distinto.
Application     Casos de uso: ObtenerSnapshotDeAgentes, EstimarMacrosDeFoto,
                SincronizarTelemetria, CrearArc.
Infrastructure  - Adaptador LLM (el que realmente invoca a AEGIS/FORGE/...
                  con los prompts de System/Agentes/*.md como contexto)
                - Adaptador de visión (Gemini/DeepSeek) para MealVisionSource
                - Persistencia multi-tenant (SQL Server — VARCHAR, no
                  NVARCHAR, por convención del usuario)
Presentation    API HTTP que `app/front` consume vía `dio` (ya en pubspec.yaml)
```

## Qué NO es

No es una reimplementación de `System/`. Los agentes siguen siendo los mismos
11 prompts; `app/api` es quien los invoca para un usuario de la app en vez de
para el usuario único que hoy los invoca por chat.

## Siguiente paso real

Nada todavía — este README es la base para la próxima sesión que arranque el
proyecto .NET (`dotnet new webapi`, capas de Clean Architecture). No se crea
un `.csproj` vacío hoy para evitar un esqueleto que compile pero no diga
nada: mejor un plan honesto que un placeholder que finge ser código.
