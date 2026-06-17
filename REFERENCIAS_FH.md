# Referencias de diseño — Fear & Hunger (análisis)

> **Aclaración legal/ética:** este documento son **notas de análisis de diseño** hechas
> observando cómo Fear & Hunger resuelve sus mecánicas, para usarlas como **inspiración**.
> NO se copian ni se deben copiar sus assets (arte, música, texto, sonidos) ni su código.
> Inspiración en mecánicas/estructura = OK. Copia de contenido = infracción de copyright.

## Motor y estructura
- F&H está hecho en **RPG Maker MV** (NW.js). Lógica en `www/data/*.json` (datos) y
  `www/js/plugins/*.js` (mecánicas). 186 mapas, ~600 entradas de enemigos, 67 plugins.
- Stack de plugins relevante:
  - **Olivia_OctoBattle** + **YEP_BattleEngineCore** + **YEP_X_ActSeqPack1/2** → combate por turnos con secuencias de ataque custom.
  - **YEP_BuffsStatesCore** → estados avanzados (sangrado, infección, miedo...).
  - **TerraxLighting** + **MrTS_DarkRoomCovers** + **VE_FogAndOverlay** → oscuridad, antorcha/linterna y niebla.
  - **YEP_ItemSynthesis** → crafteo. **YEP_EventChasePlayer** → enemigos que te persiguen en el mapa.
  - **YEP_FootstepSounds**, **EnemyBook/ItemBook** (bestiario/enciclopedia), **DK_Name_Input**.

## 1. Desmembramiento (el sistema central)
- En F&H **cada enemigo se modela como varios battlers**: `[torso]`, `[head]`,
  `[right arm]`, `[left arm]`, `[right leg]`, `[left leg]`. Cada parte tiene HP propio.
- Atacás una parte concreta; destruirla cambia al enemigo (sin brazos pega menos,
  sin piernas no alcanza, cabeza/torso = muerte).
- **Cómo lo hacemos nosotros (ya alineado):** `EnemyData.body_parts` (dict parte→HP) y
  `combat.gd` que ataca por parte y aplica consecuencias (`_enemy_skip_turn`,
  daño reducido, `_enemy_staggered`). Mismo concepto, más limpio.
- **Para profundizar:** sprites del enemigo con variantes por miembro destruido
  (swap cuando `parts_hp[parte] == 0`) + charcos/gibs de sangre.

## 2. Estados (catálogo observado) → ideas para Malvinas
F&H tiene un set de estados muy rico. Los que aplican a un survival-horror bélico:
- **Heridas/cuerpo:** `Arm cut`, `Leg cut`, `Headless`, `Fracture`, `Bleeding`,
  `Infection arm`, `Infection leg`, `Burns`, `Parasites`, `ACID`, `BONESAW` (amputación).
- **Mente/cordura:** `Fear LVL 1-5`, `Terror`, `Depressed`, `Bloodlust`, y **fobias
  específicas**: `Zoophobia`, `Necrophobia`, `Phasmophobia`, `Teratophobia`, etc.
  (ciertos enemigos disparan ciertos miedos).
- **Hambre:** `Hunger LVL 1-5` (niveles discretos con efectos crecientes) + `Food small/medium/large`.
- **Comunes:** `Blind`, `Poisoned`, `Silence`, `Sleep`, `Confusion`, `Stunned`, `Rage`, `Guard`, `Counter`, `Vulnerable`.

**Lo que YA tenemos:** sangrado, frío, infección, veneno, parálisis, ceguera, hambre (0-100), cordura (0-100), miembros rotos.

**Ideas a robar (mecánica, no contenido):**
- **Hambre/Miedo por niveles discretos** (en vez de solo 0-100): cada umbral mete un
  efecto temático (manos temblorosas, alucinaciones, debilidad). Más legible y "de mesa".
- **Fobias por tipo de enemigo:** un enemigo puntual te puede dejar una fobia que te
  penaliza ante ese tipo. Da identidad a los bichos.
- **Infección separada por miembro** (brazo/pierna) en vez de una sola barra global.
- **Amputación (BONESAW):** poder cortar un miembro propio infectado para frenar la
  infección a costa de quedar mutilado. Decisión brutal estilo F&H.

## 3. Oscuridad / linterna
- F&H usa **TerraxLighting** (radio de luz alrededor del jugador / antorcha) +
  **DarkRoomCovers** (capas negras por sala). La antorcha es un ítem que ilumina un radio.
- **Nuestro equivalente:** shader de viñeta (`darkness.gd`) + cono de linterna direccional.
  Ya estamos a la par o mejor (cono que apunta a la mirada).

## 4. Otros sistemas que vale tener en el radar
- **Crafteo** (ItemSynthesis): ya tenemos `crafting`. F&H lo usa para combinar ítems comunes.
- **Enemigos que persiguen en el mapa** (EventChasePlayer): ya tenemos `enemy_encounter` con chase.
- **Bestiario/Enciclopedia** (EnemyBook/ItemBook): idea futura — registro de enemigos
  vistos y sus partes/debilidades.
- **Pasos con sonido** (FootstepSounds) y **niebla** (FogAndOverlay): tenemos fog; los
  pasos serían un SFX al caminar.
- **Pre-title events / name input:** intro previa al título y poner nombre al soldado.

## Prioridad sugerida (lo que más "se nota" del estilo F&H)
1. **Variantes visuales de miembro destruido en enemigos** (dibujadas a mano) + más sangre.
2. **Hambre y Miedo por niveles** con efectos temáticos por umbral.
3. **Fobias por tipo de enemigo** (poco código, mucha personalidad).
4. **Amputación de miembros infectados** (decisión dura).
5. Bestiario + pasos con sonido (pulido).

---

# Fear & Hunger 2: Termina — diferencias y referencias extra

También **RPG Maker MV**, pero más robusto: **119 plugins** (vs 67 del 1). Mismo
sistema de desmembramiento (partes como battlers) y mismos estados base
(Arm/Leg cut, Headless, BONESAW, Hunger/Fear LVL 1-5, fobias).

## Lo NUEVO que aporta Termina (buenas referencias)
- **Sprites de enemigo dañado** → plugin `YEP_X_WeakEnemyPoses`: el battler cambia a una
  pose "debilitada" según el daño. **Esta es la referencia directa para nuestra idea #1**
  (swap de sprite por miembro destruido).
- **FX visual por estado** → `YEP_X_VisualStateFX`: overlays animados sobre el battler
  cuando está sangrando/envenenado/etc. Idea para reforzar el feedback de heridas.
- **Efectos de horror de pantalla** → `Olivia_HorrorEffects`: glitch/distorsión cuando
  baja la cordura. Equivale a nuestras alucinaciones en `darkness.gd` — se puede ampliar.
- **Iluminación mejorada** → `MVNovaLighting` + `TerraxLightingQuasiABS` (luz dinámica).
  Nosotros ya tenemos el cono de linterna por shader.
- **Equipo más profundo** → `YEP_EquipCore` + `commandequip`: armas, anillos/amuletos,
  armadura. Nuestro `equipped_weapon` es un primer paso; se podría sumar slots (amuleto, abrigo).
- **Armas con skill propia** → `YEP_WeaponUnleash` / `WeaponSkill`: cada arma habilita un
  golpe especial. Encaja con nuestro `WeaponData`.
- **Elementos** → `YEP_ElementCore` (fuego, etc.). Termina suma armas de fuego.
- **Estados nuevos** (vs F&H1): `Nausea`, `Concussion`, `Face rip`, `Burning`, `Toxic`,
  `Curse`, `Paralyzed`, `Ruin1`, `RESIST DEATH`, `Nosophobia`.
  → Ojo: ya empezaste a alinear esto (en `game_state.gd` hay `concussion`, `shell_shock`,
  `burns`, `wound_infection`). Vamos por buen camino.
- **Party de hasta 4** con afinidades/skills aprendidas de libros. Nuestro sistema de
  `companion` es la base; Termina lo lleva a varios miembros con builds.
- **Movimiento** → `Galv_PixelMove` (pixel-perfect) + `VE_DiagonalMovement` (8 direcciones).
  Nosotros caminamos en 4; pasar a 8 direcciones sería un plus de fluidez.

## Conclusión de ambos juegos
El "ADN" de F&H que más conviene replicar (mecánica, no contenido):
1. **Partes del cuerpo como objetivos con consecuencias** ✅ (ya lo tenés).
2. **Sprites que cambian al dañar/desmembrar** (WeakEnemyPoses) → idea #1, la más impactante.
3. **Capas de estado densas pero legibles** (heridas + mente + hambre por niveles).
4. **Cordura con efectos de pantalla + fobias** por tipo de enemigo.
5. **Decisiones brutales** (amputar, sacrificar) que el jugador siente.
