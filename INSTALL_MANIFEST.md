# ARESYNC — MANIFEST DE INSTALACIÓN
**Versión:** Final Build 5 Ago 2026
**Estado:** 🟢 Listo para subir al Project

---

## ORDEN DE INSTALACIÓN (CRÍTICO)

Sube los archivos exactamente en este orden al Project. Los archivos de infraestructura van primero, porque otros archivos los citan.

```
1. NOTION_DATA_REGISTRY.md              [NUEVO — infraestructura]
2. ARESYNC_V2_UPDATES.md                [ACTUALIZACIÓN — reemplaza v1.0 en esos 5 agentes]
3. ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md [CANÓNICO — ubica /macros y roster v2]
4. ARESYNC_BASELINE_DXA.md              [CANÓNICO — línea base biométrica, sin cambios]
5. PATHFINDER.md                        [NUEVO — agente outdoor]
6. MOMENTUM.md                          [NUEVO — agente de adherencia]
7. CHEFSYNTH.md                         [NUEVO — agente de recetas]
8. ORACLE.md                            [NUEVO — agente de proyecciones]
9. AEGIS.md                             [v1.0 — SIN CAMBIOS, mantener original]
10. ATLAS.md                            [v1.0 — SIN CAMBIOS, mantener original]
11. FORGE.md                            [v1.0 + amendments v2.0 en ARESYNC_V2_UPDATES.md]
12. PULSE.md                            [v1.0 + amendments v2.0 en ARESYNC_V2_UPDATES.md]
13. NUTRISYNC.md                        [v1.0 + amendments v2.0 en ARESYNC_V2_UPDATES.md]
14. ECHO.md                             [v1.0 + amendments v2.0 en ARESYNC_V2_UPDATES.md]
15. ARESYNC_CORE.md                     [v1.0 + amendments v2.0 en ARESYNC_V2_UPDATES.md]
```

---

## CATEGORÍA DE CADA ARCHIVO

### Infraestructura (consultar primero)
- `NOTION_DATA_REGISTRY.md` — mapeo de bases de datos Notion, esquemas exactos, protocolo universal de generación por espejo
- `ARESYNC_V2_UPDATES.md` — amendments a 5 agentes (CORE, FORGE, PULSE, NUTRISYNC, ECHO) + nuevo protocolo de edición de rutina
- `ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md` — roster completo v2 + formalización de `/macros`
- `ARESYNC_BASELINE_DXA.md` — línea base biométrica, metas de Winter Arc 2026

### Agentes nuevos (construidos 5 Ago 2026)
- `PATHFINDER.md` — outdoorventura + compatibilidad con recuperación/VO2 Max
- `MOMENTUM.md` — tasa de registro y adherencia
- `CHEFSYNTH.md` — formalización de recetas + meal prep con inventario real
- `ORACLE.md` — proyecciones de cierre de arc + probabilidad de MMA

### Agentes v1.0 (sin cambios)
- `AEGIS.md` — recuperación/sueño (no toca Notion)
- `ATLAS.md` — biomecánica/cadera (no toca Notion)

### Agentes v1.0 + amendments v2.0 (leer los dos archivos)
- `FORGE.md` (v1.0) + capa `edit routine` en `ARESYNC_V2_UPDATES.md`
- `PULSE.md` (v1.0) + integración Notion en `ARESYNC_V2_UPDATES.md`
- `NUTRISYNC.md` (v1.0) + puente con CHEFSYNTH en `ARESYNC_V2_UPDATES.md`
- `ECHO.md` (v1.0) + acceso directo a Notion en `ARESYNC_V2_UPDATES.md`
- `ARESYNC_CORE.md` (v1.0) + roster completo v2 + reglas 9-10 en `ARESYNC_V2_UPDATES.md`

---

## QUÉ REEMPLAZA QUÉ

| Archivo anterior | Reemplazado por |
|---|---|
| `ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md` (4 Ago) | `ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md` (mismo, sin cambios — es canónico) |
| (ninguno) | `NOTION_DATA_REGISTRY.md` (nuevo) |
| (ninguno) | `ARESYNC_V2_UPDATES.md` (nuevo) |
| (ninguno) | `PATHFINDER.md` (nuevo) |
| (ninguno) | `MOMENTUM.md` (nuevo) |
| (ninguno) | `CHEFSYNTH.md` (nuevo) |
| (ninguno) | `ORACLE.md` (nuevo) |

**AEGIS.md, ATLAS.md, FORGE.md, PULSE.md, NUTRISYNC.md, ECHO.md, ARESYNC_CORE.md, ARESYNC_BASELINE_DXA.md:** mantener las versiones 1.0 originales; los amendments v2.0 viven únicamente en `ARESYNC_V2_UPDATES.md` como referencia y ampliación.

---

## RESUMEN DE CONTENIDO

**Total:** 15 archivos (4 nuevos agentes, 4 infraestructura, 7 agentes existentes)

**Línea de comandos rápida completa de instalación:**
```bash
# Crear carpeta local temporaria
mkdir ~/aresync-build-final

# Descargar todos desde outputs:
cp NOTION_DATA_REGISTRY.md ~/aresync-build-final/
cp ARESYNC_V2_UPDATES.md ~/aresync-build-final/
cp ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md ~/aresync-build-final/
cp ARESYNC_BASELINE_DXA.md ~/aresync-build-final/
cp PATHFINDER.md ~/aresync-build-final/
cp MOMENTUM.md ~/aresync-build-final/
cp CHEFSYNTH.md ~/aresync-build-final/
cp ORACLE.md ~/aresync-build-final/
cp AEGIS.md ~/aresync-build-final/
cp ATLAS.md ~/aresync-build-final/
cp FORGE.md ~/aresync-build-final/
cp PULSE.md ~/aresync-build-final/
cp NUTRISYNC.md ~/aresync-build-final/
cp ECHO.md ~/aresync-build-final/
cp ARESYNC_CORE.md ~/aresync-build-final/

# Subir a Notion/Project según orden de ORDEN DE INSTALACIÓN
```

---

## NOTAS FINALES ANTES DE SUBIR

1. **Conflictos de nombre a evitar:** los archivos `.md` de agentes (AEGIS, ATLAS, FORGE, etc.) pueden quedarse en el Project con sus nombres tal cual — el System Prompt los cita por nombre de archivo exacto.

2. **Orden de lectura recomendado para ti primero, antes de subir:**
   - Lee `NOTION_DATA_REGISTRY.md` primero — es el mapa de todas las bases
   - Lee `ARESYNC_V2_UPDATES.md` — entender qué cambió en los 5 agentes existentes
   - Lee los 4 agentes nuevos (PATHFINDER, MOMENTUM, CHEFSYNTH, ORACLE)

3. **Cambio de Friday en Motion Studio:** quedó flageado en `ARESYNC_V2_UPDATES.md` bajo FORGE. Vale la pena que lo corrijas en Notion directamente antes de que FORGE proponga ejercicios de viernes, porque el campo `Day` todavía está roto.

---

*Build final compilada y lista para instalar 5 Ago 2026.*
