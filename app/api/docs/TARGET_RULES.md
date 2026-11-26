# Reglas de derivación de targets — para validación profesional

Este documento existe para que un profesional de la salud (nutriología,
fisioterapia, medicina deportiva) pueda revisar **qué decide el sistema y con
qué fundamento**, sin leer código.

Cada regla está marcada con su procedencia:

- **[AGENTE]** — viene del sistema agéntico ya en uso (`System/Agentes/`),
  validado por el uso real de un usuario durante meses.
- **[GENERALIZADO]** — regla nueva, necesaria para servir a cualquier usuario.
  El sistema original no la necesitaba porque tenía un solo usuario.
  **Estas son las que necesitan firma profesional.**

Implementación: `src/FitCodex.Domain/Targets/TargetEngine.cs`.
Tests que fijan cada comportamiento: `tests/FitCodex.Domain.Tests/TargetEngineTests.cs`.

---

## 1. Antes de fijar cualquier target

El sistema **no fija targets sin un levantamiento de composición corporal**.
El orden es: medir → conversar el objetivo → derivar.

| Método | Confianza | Consecuencia |
| --- | --- | --- |
| DXA | 1.00 | Sin restricciones |
| Navy (cinta) | 0.70 | Se compara solo contra otro Navy, nunca contra DXA |
| Caliper | 0.65 | — |
| Bioimpedancia | 0.60 | — |
| Estimado visual | 0.30 | Se marca `UnmeasuredBaseline`; el sistema declara que trabaja a ciegas |

**[AGENTE]** El margen Navy vs DXA (±3–4 puntos, con sesgo individual
impredecible) y la regla de no comparar entre métodos salen del registro real
de MedLog.

**[GENERALIZADO]** Los valores numéricos de confianza son nuestros.

---

## 2a. Gasto energético total (TDEE)

Hay dos caminos, y el sistema prefiere el segundo apenas puede:

1. **Fórmula**: basal × multiplicador de actividad. Es la muleta inicial.
2. **Observado**: derivado de la tendencia real de peso contra la ingesta
   registrada. **[GENERALIZADO]**

El cálculo observado es una identidad, no un modelo: la energía que entra y no
se almacena, se gastó.

```
TDEE = ingesta media − (cambio de tendencia en kg × 7700 / días)
```

**Salvaguardas, porque esta cuenta se rompe fácil:**

| Situación | Qué hace el sistema |
| --- | --- |
| Menos de 14 días | Usa la fórmula. El ruido de agua y glucógeno de una semana puede inventar o borrar un déficit entero |
| 14–28 días | Mezcla fórmula y observación, soltándose de la tabla a medida que acumula evidencia |
| Más de 28 días | Confía enteramente en la observación |
| Menos de 70% de días con comida registrada | Marca `SparseIntakeLogging` y baja la confianza |
| Peso muy ruidoso (>1.5% de desvío medio) | Marca `HighWeightVariance` y descuenta a la mitad |
| TDEE calculado < basal | Marca `ImplausiblyLow`, **no lo usa**, y pide revisar el registro |

> El último caso es el más importante. Alguien que registra 1.200 kcal y no
> baja de peso **no tiene el metabolismo roto**: tiene comida sin registrar.
> Si el sistema se creyera ese número, prescribiría una dieta de hambre sobre
> un error de registro. Por eso lo reporta en vez de obedecerlo.

El peso se suaviza con media móvil exponencial (inercia ≈ 1 semana) antes de
leer ninguna tendencia: comparar dos pesajes sueltos es leer ruido y llamarlo
progreso.

**Pregunta para el profesional:** los 7.700 kcal/kg asumen tejido graso. El
tejido que se pierde en déficit es mezcla de grasa, músculo y glucógeno con su
agua, y esa mezcla cambia según el contexto. ¿Vale la aproximación para
ventanas de 4+ semanas, o conviene ajustar el factor según composición?

---

## 2. Metabolismo basal

Orden de resolución, de mejor a peor:

1. **TMR medida** (la reporta el DXA) — si existe, gana siempre. **[AGENTE]**
2. **Katch-McArdle** (`370 + 21.6 × masa magra`) — cuando hay grasa corporal
   medida. Parte de la masa magra, así que es más preciso en cualquiera que se
   aleje de la composición promedio. **[GENERALIZADO]**
3. **Mifflin-St Jeor** — último recurso, cuando no hay composición. **[GENERALIZADO]**

La app expone cuál se usó (`BmrSource`): un número medido y uno estimado no
merecen la misma confianza.

> **[AGENTE]** NUTRISYNC prohíbe explícitamente usar Mifflin cuando existe una
> TMR medida. Esa jerarquía se respeta.

---

## 3. Déficit y superávit

**No se usan kcal fijas.** El offset es un porcentaje del gasto, porque
−500 kcal es un déficit severo en alguien de 55 kg y moderado en alguien de 100 kg.

| Objetivo | Conservador | Moderado | Agresivo |
| --- | --- | --- | --- |
| Pérdida de grasa | −10% | −20% | −25% |
| Recomposición | −10% | −10% | −10% (tope) |
| Ganancia muscular | +5% | +10% | +15% |
| Mantenimiento / rendimiento | 0 | 0 | 0 |

**[GENERALIZADO]** — los porcentajes son nuestros.

### Topes de seguridad que recortan lo anterior

1. **Piso metabólico**: la ingesta nunca baja del metabolismo basal.
   **[GENERALIZADO]**
2. **Ritmo máximo**: 1% del peso corporal por semana.
   **[AGENTE]** — NUTRISYNC escala cuando se pierde más de 0.5 kg/semana por
   riesgo de pérdida muscular; lo expresamos como porcentaje para que escale
   con el tamaño de la persona.
3. **Piso de grasa esencial**: 8% en hombres, 15% en mujeres. Por debajo, el
   sistema **no prescribe déficit** aunque el usuario lo pida, y marca el caso
   para revisión profesional. **[GENERALIZADO]**
4. **Margen reducido**: con menos de 10 puntos sobre el piso de grasa, el
   déficit se limita a 15%. **[GENERALIZADO]**

Cuando un tope recorta el plan, queda registrado en `Constraints` — el usuario
se entera de que su plan es menos agresivo de lo que pidió, no lo descubre por
el número final.

---

## 4. Proteína — la corrección más importante

**La proteína se calcula sobre masa magra, no sobre peso corporal.**

NUTRISYNC dice "1.8 g/kg mínimo, 2.2–2.4 g/kg óptimo" sin aclarar de qué peso,
porque con un solo usuario a 20% de grasa la diferencia era menor. En
multi-usuario deja de serlo:

> Alguien de 120 kg con 40% de grasa, a 2 g/kg de **peso corporal** → 240 g.
> Sobre su **masa magra** (72 kg) → 144 g.
> El tejido graso no demanda proteína: la primera cifra no tiene sustento.

| Objetivo | g/kg de masa magra |
| --- | --- |
| Pérdida de grasa | 2.2 – 2.6 |
| Recomposición | 2.2 – 2.8 |
| Ganancia muscular | 1.8 – 2.4 |
| Rendimiento | 1.8 – 2.2 |
| Mantenimiento | 1.6 – 2.0 |

**[GENERALIZADO]** — el anclaje a masa magra y los rangos por objetivo.
En déficit la proteína sube: es lo que protege la masa magra cuando falta energía.

Si no hay grasa corporal medida, se estima masa magra conservadoramente (72%
del peso en hombres, 65% en mujeres). Subestimarla baja el piso de proteína y
el déficit — el lado seguro para equivocarse.

---

## 5. Grasa y carbohidratos

- **Grasa**: 25–30% de las calorías. **[AGENTE]** (NUTRISYNC Paso 4)
- **Carbohidratos**: el resto. Proteína y grasa tienen piso fisiológico; los
  carbos absorben el ajuste. **[AGENTE]** (NUTRISYNC Paso 3)

NUTRISYNC además periodiza carbos por día de entreno (40–45%) vs descanso
(25–30%). **Eso todavía no está implementado** — hoy el target es diario y
plano. Pendiente.

---

## 6. Pasos y sueño

| Nivel actual | Meta |
| --- | --- |
| Sedentario | 6.000 |
| Ligeramente activo | 8.000 |
| Moderadamente activo | 10.000 |
| Muy activo | 12.000 |

En pérdida de grasa, +1.000 sobre el escalón.

**[AGENTE]** PULSE define 7.500–10.000 como rango activo y <5.000 como
sedentario con impacto negativo en recomposición.
**[GENERALIZADO]** La progresión por escalones: a quien hoy camina 3.000 pasos
no se le exige 10.000 el primer día, se le pide el escalón siguiente, que es el
que se sostiene.

Sueño objetivo: score ≥ 80. **[AGENTE]** (AEGIS Paso 3)

---

## 7. Plazos

Si el usuario declara meta y plazo, el sistema calcula el ritmo requerido y lo
compara contra el ritmo seguro. Si no alcanza, marca `TimelineInfeasible`.

**[AGENTE]** ORACLE: *"reportar el gap como ajuste requerido, nunca como
fracaso ya consumado"* y *"nunca comunicar una proyección puntual como si fuera
certeza"*.

---

## 8. Recálculo

Los targets declaran `RecalculateAfter` = 28 días. Un target derivado de una
composición de hace tres meses describe a una persona que ya no existe.

**[GENERALIZADO]**

---

## Preguntas abiertas para el profesional

1. ¿Los pisos de grasa esencial (8% / 15%) son apropiados como corte duro, o
   deberían depender de edad y de historial?
2. ¿El tope de 1% de peso corporal por semana es seguro en obesidad grado II–III,
   donde la literatura suele permitir ritmos mayores al inicio?
3. ¿La proteína sobre masa magra debería tener un techo absoluto además del
   relativo?
4. ¿Qué condiciones deberían **bloquear** la derivación automática y exigir
   derivación a consulta? (embarazo, trastornos de conducta alimentaria,
   diabetes, patología renal, menores de edad.)
   **Hoy el sistema no contempla ninguna de estas — es el hueco más grande.**
5. ¿El rango de superávit (+5% a +15%) es razonable o debería acotarse según
   experiencia de entrenamiento?

---

## Lo que este motor todavía NO hace

- **Periodización de carbos** por día de entreno vs descanso.
- **Ajuste por carga de entrenamiento** del día (NUTRISYNC Paso 6: Load > 130 →
  TDEE +150–200 kcal).
- **Contraindicaciones clínicas** (ver pregunta 4).
