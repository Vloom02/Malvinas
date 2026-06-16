# Hoja de ruta — Arte, Música y Contenido
## Codename Malvinas

Documento vivo: tildá `[x]` cuando algo esté listo. Se expande a medida que
se agregan escenas, enemigos, NPCs y niveles.

---

## 🎨 PIPELINE DE ARTE

### Método actual (lo que usamos)
| Tipo | Herramienta | Cómo |
|---|---|---|
| Personaje jugador | LPC (layers) + PIL | Compositor Python → PNG → Godot |
| Enemigos | PixelLab MCP | Prompt → imagen → `assets/sprites/enemies/` |
| Props / decorado | PixelLab MCP | Prompt → PNG estático |
| Tilesets | Manual (Godot TileMapLayer) | PNG ya importado en `assets/tilesets/` |
| Sprites de combate | PixelLab MCP | PNG 96×96, fondo transparente |

### Reglas de arte (no cambiar)
- **Paleta reducida**: máx 32 colores por sprite. Ambiente frío, desaturado.
- **Pixel art 64×64** para personajes y enemigos del mundo; **96×96** en combate.
- **Malvinas no tiene árboles**: usar tussock, retama (gorse), roca, barro,
  alambre de púas, bolsas de arena, madera de trinchera.
- **Todos los prompts en inglés** para PixelLab. Siempre especificar:
  `"top-down pixel art, 64×64, transparent background, Falklands 1982,
  [descripción del objeto], cold muted palette"`

---

## 🖼 PERSONAJES — Estado del arte

### Jugador
- [x] Sprite LPC soldado — caminata 4 direcciones (walk.png)
- [x] Sprite LPC soldado — idle 4 direcciones (idle.png)
- [ ] Sprite de **combate** (frente, 96×96) — actualmente usa conscripto viejo
- [ ] Overlay de heridas: **sangre** (mancha roja en torso/brazo/pierna)
- [ ] Overlay de **frío** (tinte azul, aliento visible — puede ser solo modulate)
- [ ] Animación de **muerte** (colapsa) para pantalla de game over

### Enemigos — Combate (96×96, fondo transparente)
- [x] Espectro / Pesadilla (`espectro_combat.png`)
- [x] La Cosa sin Rostro / Madness (`cosa_combat.png`)
- [x] Soldado enloquecido (`soldado_combat.png`)
- [x] Perro (`perro_combat.png`)
- [ ] Oficial fantasmal (jefe — infantería)
- [ ] Tripulante ahogado (jefe — naval)
- [ ] Piloto quemado (jefe — aviación, futuro)

### Enemigos — Mundo (64×64, los que flotan en el mapa)
- [x] Espectro (usa `espectro_combat.png` escalado — funcional, mejorar después)
- [ ] Perro — sprite top-down propio
- [ ] Soldado enloquecido — sprite top-down
- [ ] Oficial fantasmal — sprite top-down

### NPCs
- [ ] Sargento — sprite estático (de frente, para las salas de descanso)
- [ ] Marino (teatro naval, futuro)
- [ ] Enfermero de campaña (futuro, zona segura)

---

## 🗺 NIVELES — Arte y decorado

### Teatro 1: Infantería (EN PROGRESO)
Escenas: `nivel1_trinchera.tscn`, `nivel1_campo.tscn`, `nivel1_pozo.tscn`

#### Trinchera de inicio
- [x] Tileset base de trinchera (`trinchera_tileset.tres`)
- [x] Props: bolsas de arena, roca, tussock, retama, gorse
- [ ] Detalle extra: casco tirado, vaina de bala, bota sola
- [ ] Niebla ambiente (shader ya existe `fog.tscn` — instanciar)
- [ ] Luz parpadeante (linterna rota colgada de un poste)

#### Campo abierto
- [ ] Tileset de pasto malvinero: tussock seco, barro, charco helado
- [ ] Props: alambrado, roca, restos de jeep, señal militar doblada
- [ ] Cielo oscuro (ColorRect gris verdoso de fondo)
- [ ] Nieve / escarcha en el suelo (partículas sutiles)

#### Pozo de mando
- [ ] Tileset interior (madera, tierra, lona)
- [ ] Props: mapa en la pared, radio roto, vela, raciones vacías
- [ ] Sargento NPC (sprite)
- [ ] Puerta sellada hacia teatro naval (cuando esté)

### Teatro 2: Naval (TEASER — IN PROGRESS)
Escena: `naval_barco.tscn`

- [ ] Tileset metálico del barco (piso de acero, remaches)
- [ ] Props: escotilla, tuberías, extintor, chaleco salvavidas
- [ ] Agua que sube (ya programada en `rising_water.gd`) — necesita sprite de agua
- [ ] Efecto de oscilación / balanceo de la cámara (Tween suave en Camera2D)
- [ ] Color de agua: azul oscuro frío con transparencia

### Teatro 3: Aviación (FUTURO)
- Avión caído en el campo. Sin fecha.

---

## 🎵 MÚSICA Y AUDIO

### Música de fondo
| Escena | Archivo | Estado |
|---|---|---|
| Exploración / mundo | `ambient.ogg` | [x] Existe (placeholder) |
| Combate | `combat.ogg` | [x] Existe (placeholder) |
| Barco naval | — | [ ] Falta (eco metálico, agua) |
| Pozo de mando (descanso) | — | [ ] Falta (silencio tenso, viento lejano) |
| Títilo / créditos | — | [ ] Falta |

### Sonidos de efecto (SFX)
| Evento | Archivo | Estado |
|---|---|---|
| Golpe al enemigo | `hit.wav` | [x] Existe |
| Ataque del jugador | `player_attack.wav` | [x] Existe |
| Vendaje | `bandage.wav` | [x] Existe |
| Esquivar | `dodge.wav` | [x] Existe |
| Victoria | `victory.wav` | [x] Existe |
| Muerte | `death.wav` | [x] Existe |
| Susurro / alucinación | `whisper.wav` | [x] Existe |
| Flash de locura | `flash_noise.wav` | [x] Existe |
| Pasos en barro | — | [ ] Falta |
| Puerta que cruje | — | [ ] Falta |
| Viento helado (loop) | — | [ ] Falta |
| Agua subiendo (loop) | — | [ ] Falta |
| Explosión lejana | — | [ ] Falta |
| Disparo lejano | — | [ ] Falta |

### Dónde conseguir audio gratis y legal
1. **freesound.org** — filtrar por CC0 (sin atribución). Buscar: `wind patagonia`,
   `metal creak`, `mud footsteps`, `water rising`.
2. **OpenGameArt.org** — sección Audio, filtrar por CC0 / CC-BY.
3. **Sonniss GDC Audio Bundle** — packs gratis enormes, revisar licencia por pack.
4. **IA (ElevenLabs / Suno / Udio)** — para música generada por IA. Declarar en Steam.

---

## 🖼 TILESETS — Pendientes

| Tileset | Archivo | Estado |
|---|---|---|
| Trinchera (piso + paredes) | `trinchera/trinchera_tileset.tres` | [x] Básico OK |
| Campo / tussock | — | [ ] Falta |
| Interior del barco | — | [ ] Falta |
| Pozo de mando | — | [ ] Falta |

---

## 🖼 PANTALLAS DE UI

| Pantalla | Estado | Notas |
|---|---|---|
| Título `MALVINAS` | [x] Funcional | Texto placeholder, sin logo |
| Inventario | [x] Funcional | Sin íconos de items, solo texto |
| Diario | [x] Funcional | OK |
| Crafteo | [x] Funcional | OK |
| Menú NPC / Sargento | [x] Funcional | OK |
| Pausa | [x] Funcional | OK |
| Game Over | [x] Funcional | Sin arte |
| Combate | [x] Funcional | Sprites de enemigo OK, jugador usa viejo |
| Logo / capsule art Steam | [ ] Pendiente | Para Steam page (fases finales) |
| Portraits de NPC | [ ] Pendiente | Para diálogos con cara |

---

## 📋 PRIORIDAD INMEDIATA (próximas sesiones)

1. [ ] **Sprite de combate del jugador** — 96×96, soldado LPC frente, mismo estilo
2. [ ] **Sprite NPC sargento** — estático, de frente
3. [ ] **Tileset campo abierto** — para `nivel1_campo.tscn`
4. [ ] **SFX viento** — `assets/audio/viento.ogg` (loop en zonas exteriores)
5. [ ] **Sprite de agua** en `naval_barco` (ColorRect por ahora, después PNG ondulante)

---

## 📝 NOTAS DE LICENCIA

- **LPC assets** (personaje): CC-BY-SA / GPL — requieren **atribución** en CREDITS.md
  y que el arte derivado sea también CC-BY-SA. Verificar antes de publicar en Steam.
- **PixelLab**: contenido generado por IA — **declarar en Steam** (AI content disclosure).
- **Freesound / OGA CC0**: libre de uso, sin atribución obligatoria (recomendada igual).
- **Música IA (Suno/Udio)**: leer términos de cada servicio; algunos no permiten
  uso comercial en plan gratuito.
