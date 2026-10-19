# 📥 ARESYNC — PAQUETE COMPLETO DE DESCARGA
**Versión:** Final Build 5 Ago 2026  
**Tamaño total:** ~50 KB  
**Archivos:** 15 (4 nuevos, 4 infraestructura, 7 existentes)

---

## ✅ LISTA DE DESCARGA — VERIFICA QUE TENGAS TODOS

Descarga todos estos archivos desde la carpeta `/outputs`. Están listos para subir directamente al Project de Claude.

### 🆕 NUEVOS (4 agentes que no existían)
```
☐ PATHFINDER.md (4.1 KB)
☐ MOMENTUM.md (3.3 KB)
☐ CHEFSYNTH.md (3.3 KB)
☐ ORACLE.md (3.1 KB)
```

### 🏗️ INFRAESTRUCTURA (mapeo de Notion + canónicos)
```
☐ NOTION_DATA_REGISTRY.md (6.6 KB) — CRÍTICO: consultar primero
☐ ARESYNC_V2_UPDATES.md (7.8 KB) — amendments a 5 agentes + edit routine
☐ ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md (6.6 KB) — roster v2 + /macros
☐ ARESYNC_BASELINE_DXA.md — YA TIENES, no re-descargar (es canónico, 4 Ago)
☐ INSTALL_MANIFEST.md (5.4 KB) — orden de instalación
```

### 📖 AGENTES EXISTENTES (ya están en tu Project, mantenlos igual)
```
⏸️  AEGIS.md (v1.0) — mantener original
⏸️  ATLAS.md (v1.0) — mantener original
⏸️  ARESYNC_CORE.md (v1.0) — mantener original + leer amendments en ARESYNC_V2_UPDATES.md
⏸️  FORGE.md (v1.0) — mantener original + leer amendments en ARESYNC_V2_UPDATES.md
⏸️  PULSE.md (v1.0) — mantener original + leer amendments en ARESYNC_V2_UPDATES.md
⏸️  NUTRISYNC.md (v1.0) — mantener original + leer amendments en ARESYNC_V2_UPDATES.md
⏸️  ECHO.md (v1.0) — mantener original + leer amendments en ARESYNC_V2_UPDATES.md
```

---

## 📋 INSTRUCCIONES DE INSTALACIÓN

### Paso 1 — Descarga todos los archivos nuevos
- Desde `/outputs`, descarga los 8 archivos nuevos (4 agentes + 4 infraestructura) en una carpeta local

### Paso 2 — Sube en orden (según INSTALL_MANIFEST.md)
1. `NOTION_DATA_REGISTRY.md`
2. `ARESYNC_V2_UPDATES.md`
3. `ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md`
4. `ARESYNC_BASELINE_DXA.md` (opcional si ya lo subiste el 4 Ago)
5. `PATHFINDER.md`
6. `MOMENTUM.md`
7. `CHEFSYNTH.md`
8. `ORACLE.md`
9. Los 7 agentes existentes: no necesitan actualización, pero sí verifica que citen a `NOTION_DATA_REGISTRY.md` en la lectura

### Paso 3 — Actualiza el System Prompt
En tu Project settings, el System Prompt debe referenciar `NOTION_DATA_REGISTRY.md` como infraestructura obligatoria de lectura previa. Sugerencia de línea:

```
**REGLA NUEVA #9:** Antes de leer o escribir cualquier base de Notion, 
consulta NOTION_DATA_REGISTRY.md para confirmar el data source ID exacto 
y el schema real (nombres de campo, tipos). Nunca asumir de memoria.

**REGLA NUEVA #10:** Al generar cualquier entrada nueva, aplica el 
Protocolo Universal de Generación por Espejo (NOTION_DATA_REGISTRY.md §4).
```

---

## 📦 DESGLOSE DE CAMBIOS

| Cambio | Archivo | Tipo |
|---|---|---|
| Nuevo agente outdoor | PATHFINDER.md | ✨ Nuevo |
| Nuevo agente adherencia | MOMENTUM.md | ✨ Nuevo |
| Nuevo agente recetas | CHEFSYNTH.md | ✨ Nuevo |
| Nuevo agente proyecciones | ORACLE.md | ✨ Nuevo |
| Mapeo de todas las bases Notion | NOTION_DATA_REGISTRY.md | ✨ Nuevo |
| Amendments CORE/FORGE/PULSE/NUTRISYNC/ECHO | ARESYNC_V2_UPDATES.md | 🔄 Actualización |
| Protocolo `/macros` formalizado | ARESYNC_SYSTEM_UPDATE_ROSTER_MACROS.md | 🔄 Actualización |
| Línea base DXA + Winter Arc metas | ARESYNC_BASELINE_DXA.md | 🔴 Canónico (sin cambios) |
| Recuperación (sueño, fatiga, HRV) | AEGIS.md | ⏸️ v1.0 (sin cambios) |
| Biomecánica + protocolo cadera | ATLAS.md | ⏸️ v1.0 (sin cambios) |
| Hipertrofia + edición de rutina | FORGE.md | ⏸️ v1.0 + amendments |
| Biométricas + integración Notion | PULSE.md | ⏸️ v1.0 + amendments |
| Nutrición + CHEFSYNTH bridge | NUTRISYNC.md | ⏸️ v1.0 + amendments |
| Patrones históricos + Notion direct | ECHO.md | ⏸️ v1.0 + amendments |
| Orquestación central | ARESYNC_CORE.md | ⏸️ v1.0 + amendments |

---

## 🎯 PRÓXIMOS PASOS DESPUÉS DE INSTALAR

1. **Corrige el campo `Day` en Motion Studio:** falta Friday (hay typo "Thrusday"). Esto afecta cómo FORGE etiqueta ejercicios de viernes.

2. **Prueba `/macros` en tu próxima comida:** copia la foto o describe verbalmente qué comes, y NUTRISYNC va a crear la entrada en FoodLog automáticamente con macros estimados.

3. **Activa `edit routine` la próxima vez que quieras cambiar tu split:** di "cambia mi rutina" o "necesito otra opción para piernas" y FORGE va a:
   - Mostrarte opciones reales del catálogo (incluyendo ejercicios archivados)
   - Proponer ejercicios nuevos si no hay opciones en el catálogo
   - Consultar a AEGIS (recuperación) y ATLAS (cadera) antes de confirmar

4. **Lee `NOTION_DATA_REGISTRY.md` completamente antes de usarlo en conversación.** Es tu mapeo definitivo de todas las bases — sin él, los agentes van a trabajar a ciegas.

---

## 📞 SOPORTE

Si algo no funciona después de instalar:
- Verifica que todos los archivos se hayan subido en el orden correcto
- Revisa que los data source IDs en `NOTION_DATA_REGISTRY.md` coincidan con tu Notion actual
- Confirma que el System Prompt del Project referencia tanto `NOTION_DATA_REGISTRY.md` como `ARESYNC_BASELINE_DXA.md`

---

**Build compilada y lista para instalar.**  
*5 Ago 2026 · AreSync v2.0*
