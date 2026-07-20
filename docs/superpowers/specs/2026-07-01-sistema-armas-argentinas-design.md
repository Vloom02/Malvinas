# Sistema de armas argentinas (Malvinas 1982) — Diseño

Estado: aprobado (2026-07-01). Orden de ejecución pedido por el usuario:
**1º generar sprites en PixelLab → 2º checkpoint de verificación → 3º código.**

## Objetivo
Ampliar el sistema de armas para: (a) armas argentinas reales equipables en los
personajes, (b) stats finos y detallados, (c) mejoras vía **accesorios acoplables
+ variantes históricas**, (d) mecánica de **clima/barro** (visual + jugabilidad:
encasquillamiento).

## 1. Modelo de datos

### WeaponData (`data/weapon_data.gd`, estático) — campos nuevos
- `reliability: float` (0-1) — confiabilidad base (chance de NO trabarse).
- `accepted_slots: Array[String]` — ranuras que acepta: `optic`, `bipod`, `magazine`, `sling`.
- `mud_sensitivity: float` (0-1) — cuánto le pega el barro a la confiabilidad.
- `ammo_type: String`, `weight: int` (ya existe weight).

### AccessoryData (`data/accessory_data.gd`, recurso nuevo)
- `id`, `display_name`, `description`, `slot_type` (uno de las ranuras).
- Modificadores: `damage_mod`, `pulse_mod`, `dodge_mod`, `reliability_mod`, `ammo_mod`.
- `weight`, `find_text`.

### WeaponInstance (estado runtime, en `GameState`, persistido en save)
Por cada arma que el jugador posee:
- `weapon_id: String`
- `condition: int` (0-100, 100 = limpia/nueva; baja con uso)
- `mud: int` (0-100)
- `wet: int` (0-100)
- `accessories: Dictionary` (slot → accessory_id)

`WeaponData` nunca se muta; el barro/condición/accesorios viven acá.

## 2. Armas (roster)

Se **consolidan los 3 FAL duplicados**: se borran `fusil_f8.tres` y
`fal_m1982.tres`. El rol francotirador pasa a ser FAL + accesorio mira.

### De fuego
| id | nombre | daño (±var) | pulso | esquiva | confiab. | tipo | manos | slots | notas |
|----|--------|-------------|-------|---------|----------|------|-------|-------|-------|
| `fal` | FN FAL 50.61 | 20 ±3 | +1 | 0 | 0.90 | fusil | 2 | optic, magazine, sling | reglamentaria, bleed 25% |
| `fap` | FAP (Fusil Automático Pesado) | 22 ±4 | 0 | −1 | 0.88 | ametralladora | 2 | bipod, magazine | arma automática de escuadra, cañón pesado |
| `fn_mag` | FN MAG 7,62 | 26 ±5 | −1 | −2 | 0.85 | ametralladora | 2 | bipod | cinta, muy pesada, sensible al barro |
| `fmk3` | FMK-3 9mm | 12 ±2 | +1 | +1 | 0.92 | subfusil | 2 | magazine, sling | subfusil nacional, rápido, poco daño |
| `browning_hp` | Browning HP 9mm | 10 ±2 | +1 | +1 | 0.93 | pistola | 1 | magazine | pistola reglamentaria, secundaria |
| `escopeta` | Escopeta (saqueada) | 25 ±5 | −1 | −1 | 0.90 | escopeta | 2 | — | NO reglamentaria; reetiquetada como improvisada, bleed 40% |

### Cuerpo a cuerpo (quedan igual)
`bayoneta`, `cuchillo_combate`, `cuchillo_trinchera`, `palo_filo`.

## 3. Accesorios (reales) — roster ampliado

### Ranuras por arma (confirmado con el usuario)
- **FN FAL**: optic (mira) · magazine (cargador) · sling (correa) · muzzle (boca del cañón) · grip (empuñadura) · stock (culata)
- **FAP**: bipod (bípode) · magazine (cargador) · stock (culata) · optic (mira)
- **FN MAG**: bipod (bípode) · tripod (trípode) · ammo_container (bolsa/caja de balas, cinta)
- **FMK-3**: magazine (cargador) · holster (cartuchera) · grip (empuñadura) · flashlight (linterna)  _(sin correa)_
- **Browning HP**: magazine (cargador) · holster (cartuchera) · grip (empuñadura) · flashlight (linterna) · muzzle (boca del cañón)
- **Escopeta**: shell_holder (portacartuchos en culata) · slide_mod (corredera modificada) · sling (correa)

### Accesorios
| id | nombre | slot | efecto |
|----|--------|------|--------|
| `mira_telescopica` | Mira telescópica | optic | +2 pulso (precisión), alcance |
| `bipode` | Bípode | bipod | +2 pulso si estás quieto |
| `tripode` | Trípode | tripod | +3 pulso quieto, pero inmoviliza (−esquiva, no correr) |
| `cargador_ampliado` | Cargador ampliado | magazine | +munición antes de recargar |
| `correa` | Correa (sling) | sling | +1 esquiva, arma lista más rápido |
| `boca_canon` | Freno/apagallamas (boca del cañón) | muzzle | +1 pulso, menos fogonazo (menos delator) |
| `empunadura` | Empuñadura | grip | +1 pulso (control de retroceso) |
| `culata` | Culata (plegable/fija) | stock | +1 pulso (estabilidad) |
| `cartuchera` | Cartuchera | holster | guardar el arma / listo rápido como secundaria |
| `linterna_arma` | Linterna montada | flashlight | ilumina (integra con sistema de linterna), −sigilo |
| `bolsa_balas` | Bolsa/caja de balas (cinta) | ammo_container | +mucha munición (MAG) |
| `portacartuchos` | Portacartuchos en culata | shell_holder | +capacidad escopeta; habilita recarga parcial (top-off) además de completa |
| `corredera_mod` | Corredera modificada | slide_mod | recarga más rápida / +confiabilidad |

## 4. Mecánica clima/barro

### Encasquillamiento
Por cada disparo/ataque con arma de fuego:
```
jam_chance = (1 - reliability)
           + (mud/100)  * mud_sensitivity * 0.30
           + (wet/100)  * 0.15
           + cold_factor(GameState.cold)
           + ((100 - condition)/100) * 0.20
```
(clamp 0..0.95). Si se traba: el disparo/ataque falla, mensaje "¡Se trabó!",
y hay que **destrabar** (una acción = tirada de dado, encaja con el pilar de
RNG en tensión). Los accesorios pueden sumar `reliability_mod`.

### Fuente de barro/mojado
Cada mapa/room declara su ambiente (ej: turbera = mucho barro; niveles Malvinas =
mojado + frío). Caminar en esos ambientes acumula `mud`/`wet` en el arma equipada;
disparar bajo lluvia suma `wet`.

### Mantenimiento
Ítem nuevo **kit de limpieza** + acción "limpiar arma": baja `mud`/`wet` y
restaura `condition`. (Los soldados limpiaban el FAL constantemente en Malvinas.)

## 5. Visual — arma horneada en el personaje (PixelLab character states)
Decisión final del usuario: **NO generar sprites de arma individuales / overlay**.
El arma se dibuja como parte del personaje usando `create_character_state`
(descripción de texto: "sosteniendo un FN FAL…") sobre el conscripto base
`661d69c6`, manteniendo su identidad en las 8 rotaciones. Luego cada estado se
anima (`animate_character`) con las poses relevantes.

- Un **character state por arma**: conscripto+FAL, conscripto+FMK-3, conscripto+MAG, etc.
  Siempre con el arma **base, SIN accesorios** (los accesorios se encuentran aparte
  y son solo stats — no se dibujan; decisión del usuario "sin mejoras/stocks").
- Cada estado hereda el skeleton del conscripto base → se le generan las animaciones
  necesarias (mínimo idle/walk; ideal + aim/shoot).
- Además, **cada arma como objeto en el suelo** (pickup/ícono) vía objeto 8-dir —
  el FAL ya está (`55cd14f4`); se genera el resto igual.
- **Se elimina** el sistema de overlay: `held_sprite_base`, el rig `_weapon_rig`/
  `_weapon_sprite` y los sprites tipo `fal_este.png` dejan de usarse.
- El objeto FAL 8-dir generado (`55cd14f4`, 68px) se **reutiliza** como sprite del
  **arma en el suelo / ícono de inventario** (pickup), no como sprite sostenido.
- Piloto en curso: estado `250ef0f2` (conscripto con FAL) → verificar calidad →
  definir qué animaciones se generan por arma antes de escalar (es mucha generación).

### Mejoras visibles (solo 3) + mesa de crafteo
Solo **correa, trípode y mira** se ven en el arma; el resto de los accesorios son
stat-only (no se dibujan). Las mejoras visibles se aplican en una **mesa de crafteo**
(animación "mejora" del conscripto trabajando el arma). Cada mejora visible = un
`create_character_state` encima del estado anterior (le agrega el accesorio),
acumulativo (base → +mira → +mira+trípode…). Cada estado nuevo necesita su set de
animaciones. Combos por arma (acotado, no todas aceptan todo):
- FAL: base, +mira, +correa, +mira+correa
- FAP: base, +mira
- FN MAG: base, +trípode
- FMK-3 / Browning HP / escopeta: sin mejoras visibles (solo base)

### Regla del trípode
Las armas con trípode (FN MAG) **solo disparan si el jugador está prono/tirado o
la montás en una superficie**. Parado no puede usarlas. (Fase de código.)

### Barro/mojado visual
Como el arma ahora es parte del personaje, el estado sucio se resuelve con **tinte
(`modulate`)** sobre el sprite del personaje (marrón=barro, oscuro/brillo=mojado),
reutilizando el patrón de `_reflect_body()` que ya existe. NO se generan estados
de personaje embarrado por arma (sería explosión combinatoria). La mecánica de
encasquillamiento (sección 4) es independiente del tinte.

## 6. Integración
- Equipar: `GameState.equipped_weapon` (WeaponData) + su `WeaponInstance`.
- Combate: `combat.gd` usa stats + accesorios + chequeo de jam.
- Disparo con F: `player.gd._fire()` chequea jam, elige sprite por estado.
- Save: `SaveManager` persiste los `WeaponInstance` (con `VALID_KEYS`).

## 7. Fases del plan
1. Modelo de datos (WeaponData ext, AccessoryData, WeaponInstance, save).
2. Armas `.tres` (crear nuevas, consolidar FAL, borrar duplicados).
3. Accesorios `.tres` + lógica de equipar/aplicar mods.
4. Mecánica clima/jam + fuente de barro por ambiente + kit de limpieza.
5. Integración combate + disparo con F.
6. Arte PixelLab (held sprites por estado) — **se hace primero en la práctica**,
   pero el consumo por el código es esta etapa.

## Notas / riesgos
- Alinear un sprite de arma sostenida en 8 direcciones con la mano (que se mueve
  por frame) es intrínsecamente imperfecto con el rig actual (held sprite estático
  por dirección). Se acepta como limitación; se pule con el HAND_OFFSET.
- Volumen de arte alto por decisión explícita del usuario (cada sprite individual
  en PixelLab, incl. barro/mojado).
