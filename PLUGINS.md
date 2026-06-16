# Plugins y herramientas — Codename Malvinas

Guía de lo que tenemos instalado y lo que vale la pena agregar.
Todos se instalan desde el Asset Library de Godot (menú **AssetLib** en el editor)
o descargándolos desde GitHub y copiando la carpeta `addons/` al proyecto.

---

## ✅ YA INSTALADO

### LPCAnimatedSprite2D
- **Dónde:** `addons/LPCAnimatedSprite/`
- **Qué hace:** carga spritesheets LPC modular para personajes.
- **Cómo lo usamos:** referencia, pero el jugador ya usa el sistema propio
  (`player.gd` corta los sheets manualmente). El addon queda como respaldo.

---

## 🔌 PLUGINS RECOMENDADOS — Instalar ya

### 1. Phantom Camera 2D ⭐ (muy recomendado)
- **Asset Library ID:** buscar "Phantom Camera"
- **GitHub:** `ramokz/phantom-camera`
- **Qué hace:** sistema de cámara avanzado con zoom suave, follow con dead zone,
  shake de pantalla, lerp personalizable. Reemplaza manipular Camera2D a mano.
- **Por qué nos sirve:** el shaking de combate ya está hecho con Tween, pero
  Phantom Camera lo hace 10 veces mejor y más fácil. También para hacer que
  la cámara siga al jugador con inercia (más cinematográfico).
- **Cómo instalar:**
  1. Abrir Godot → pestaña **AssetLib** → buscar "Phantom Camera"
  2. Descargar e instalar → activar en **Project → Project Settings → Plugins**
  3. En la escena del jugador, agregar nodo `PhantomCamera2D` como hijo de la cámara.

---

### 2. GodotSteam ⭐ (para cuando publiques)
- **GitHub:** `GodotSteam/GodotSteam`
- **Qué hace:** integración completa con Steamworks SDK: achievements,
  tablas de posiciones, guardado en la nube, estadísticas, DLC.
- **Por qué nos sirve:** para publicar en Steam y tener achievements
  (refuerza la retención).
- **Cómo instalar:** requiere compilar Godot con el SDK de Steam. Hay binarios
  precompilados en su repo. Instalar cuando estés en FASE 5 del ROADMAP.
- **Nota:** no instalar todavía, cambia el ejecutable de Godot.

---

### 3. Dialogue Manager (Nathan Hoad) ⭐
- **Asset Library:** buscar "Dialogue Manager"
- **GitHub:** `nathanhoad/godot_dialogue_manager`
- **Qué hace:** sistema de diálogos en formato `.dialogue` (texto plano estilo
  screenplay), con condiciones, variables y llamadas a funciones de GDScript.
  Tiene editor visual dentro de Godot.
- **Por qué nos sirve:** actualmente `DataDialogue` hace lo básico con `.tres`.
  Si los diálogos crecen (muchos NPCs, ramas largas), Dialogue Manager escala
  mucho mejor. El formato texto es más fácil de escribir y mantener.
- **Decisión:** instalar cuando haya más de 5 NPCs con diálogos propios.

---

### 4. Beehave (Behavior Trees)
- **Asset Library:** buscar "Beehave"
- **GitHub:** `bitbrain/beehave`
- **Qué hace:** árboles de comportamiento para IA de enemigos. Permite construir
  lógica de IA compleja (patrullar → detectar → perseguir → atacar → huir) de
  forma visual y modular.
- **Por qué nos sirve:** el chase de enemigos en `enemy_encounter.gd` es lineal.
  Con Beehave podés hacer enemigos con más capas (buscar al jugador, rodear, huir
  si les rompés los brazos).
- **Decisión:** instalar cuando los enemigos necesiten más comportamiento. Todavía no.

---

### 5. AsepriteWizard
- **Asset Library:** buscar "AsepriteWizard"  
- **GitHub:** `viniciusgerevini/godot-aseprite-wizard`
- **Qué hace:** importa archivos `.ase`/`.aseprite` directamente a Godot con
  todas las animaciones convertidas automáticamente a `AnimationPlayer` o
  `AnimatedSprite2D`. Al guardar el Aseprite, Godot reimporta solo.
- **Por qué nos sirve:** si vas a dibujar en Aseprite (ver GUIA_ARTE.md),
  este plugin ahorra horas de exportar PNGs manualmente.
- **Cómo instalar:**
  1. AssetLib → "AsepriteWizard" → Descargar
  2. Project → Project Settings → Plugins → activar
  3. En la configuración del plugin, apuntar a la ruta del ejecutable de Aseprite.

---

### 6. SmartShape2D
- **Asset Library:** buscar "SmartShape2D"
- **GitHub:** `SirRamEsq/SmartShape2D`
- **Qué hace:** dibujás polígonos libres y los rellena con texturas del tileset
  automáticamente (para hacer suelo irregular, ríos, bordes orgánicos).
- **Por qué nos sirve:** para el campo abierto de Malvinas: suelo de tussock
  irregular, charcos de barro con forma rara. Más flexible que el TileMapLayer.
- **Decisión:** instalar cuando empieces a armar `nivel1_campo.tscn` en serio.

---

### 7. Godot Shaders (colección de la comunidad)
- **No es un plugin:** es un repositorio de shaders listos para copiar.
- **GitHub:** `godotengine/godot-demo-projects` + `GDQuest/godot-shaders`
- **Qué tiene útil para nosotros:**
  - `old_film.gdshader` — efecto de película vieja (para cutscenes o flashbacks)
  - `water_2d.gdshader` — agua animada en 2D (para el barco naval)
  - `outline.gdshader` — borde de selección alrededor del jugador (debug)
  - `fog_of_war.gdshader` — oscuridad de niebla de guerra con reveal
- **Cómo usar:** copiar el `.gdshader` a `assets/shaders/`, crear un
  `ShaderMaterial` y asignarlo a un `ColorRect` o `Sprite2D`.

---

### 8. GUT — Godot Unit Testing (opcional, para más adelante)
- **Asset Library:** buscar "GUT"
- **GitHub:** `bitwes/Gut`
- **Qué hace:** tests automáticos de GDScript. Podés escribir tests para
  `GameState`, `Dice`, `CraftRecipe`, etc.
- **Decisión:** no es urgente, pero cuando el juego crezca conviene tener
  tests para `GameState.use_item`, `Dice.check`, `CraftRecipe` y el loot.

---

## 🛠 HERRAMIENTAS EXTERNAS (no son plugins de Godot)

### Aseprite — editor de pixel art
- **Precio:** USD 19.99 (también en Steam). Hay versión compilable gratis.
- **Por qué:** el estándar de la industria indie para pixel art.
  Capas, animaciones, paleta de colores, todo en una sola herramienta.
- **Alternativa gratuita:** **Pixelorama** (hecho en Godot, open source,
  buscarlo en pixelorama.io — muy bueno para empezar).

### Tiled Map Editor
- **Gratis:** mapeditor.org
- **Por qué:** editor visual de niveles más potente que el TileMapLayer de Godot.
  Exportás el mapa como `.tmj` y lo importás con el plugin **Rex Tiled Map Importer**
  (Asset Library: "Tiled Map Importer").
- **Decisión:** útil cuando los niveles se vuelvan grandes y complejos.

### BFXR / SFXR / Chiptone — generador de SFX retro
- **Gratuito:** bfxr.net / sfxr.me / chiptone.sourceforge.io
- **Qué hace:** generás SFX de 8-bit/16-bit al instante (golpes, explosiones,
  saltos, etc.) sin saber nada de audio.
- **Limitación:** suena muy retro. Mejor para placeholder o si querés ese estilo.

### Audacity
- **Gratis:** audacityteam.org
- **Qué hace:** editor de audio. Recortás, mezclás, normalizás volumen y
  exportás OGG/WAV. Esencial para ajustar los sonidos que descargás de freesound.

---

## 📋 ORDEN DE INSTALACIÓN SUGERIDO

| Cuándo | Plugin |
|---|---|
| **Ahora** | Phantom Camera (game feel inmediato) |
| **Cuando dibujés en Aseprite** | AsepriteWizard |
| **Al armar campo abierto** | SmartShape2D |
| **Cuando haya más de 5 NPCs** | Dialogue Manager |
| **Cuando los enemigos necesiten más IA** | Beehave |
| **Antes de publicar en Steam** | GodotSteam |
| **Opcional / tarde** | GUT (tests) |
