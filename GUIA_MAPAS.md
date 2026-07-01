# Guía de mapas para Alan — Cómo diseñar niveles en Codename Malvinas

Guía práctica para armar mapas con lo que ya tenemos construido en el
proyecto. No es teoría general de Godot — es específicamente **cómo se hace
acá**, con los tilesets, scripts y convenciones que ya existen.

---

## 🗺 ¿Qué querés hacer?

```
¿Vas a practicar / probar cosas?
  → Seguí usando scenes/maps/sandbox.tscn, es la sala de pruebas.

¿Querés crear una sala REAL del juego (trinchera, campo, pozo, barco)?
  → Sección 5: Crear una sala nueva

¿Necesitás pintar el piso / paredes / poner un vehículo?
  → Secciones 2, 3 y 4

¿Necesitás conectar dos salas con una puerta?
  → Sección 6: Puertas entre salas

¿Querés que aparezcan enemigos al entrar?
  → Sección 7: Encuentros
```

---

## Sección 1 — Anatomía de un mapa

Abrí `scenes/maps/sandbox.tscn` y mirá el árbol de nodos: esa es la
plantilla de **toda** sala del juego. De arriba a abajo:

| Nodo | Tipo | Para qué |
|---|---|---|
| `Sandbox` (raíz) | `Node2D` + script `room.gd` | Maneja spawn del jugador y emboscadas. Cambiale el nombre por el de tu sala. |
| `Backdrop` | `ColorRect` | Color de fondo (casi negro) que se ve donde no pintaste nada. No es un bug, es el "vacío" intencional. |
| `Ground` | `TileMapLayer` | Piso base (tierra, cemento, cráteres) — tileset `campo_batalla_tileset.tres`. |
| `Detalle` | `TileMapLayer` | Una segunda capa de piso, mismo tileset, para variar el suelo encima de `Ground` sin reemplazarlo. |
| `Walls` | `TileMapLayer` | Paredes/trincheras — tileset `walls_tileset.tres`, **con colisión por tile**. |
| `Objetos` | `TileMapLayer` | Vehículos y props grandes — tileset `objetos_tileset.tres` (categoría "TileObject"). |
| `WallsCollision` | `StaticBody2D` | Caja invisible que limita el borde exterior del mapa (ver Sección 5, ojo que esto se rompe si extendés el mapa). |
| `Enemigo` (opcional) | instancia de `enemy_encounter.tscn` | Emboscada fija en un punto. |
| `Player` | instancia de `player.tscn` | El jugador. |
| `Fog`, `Darkness`, `Inventory` | UI/overlay | Capas visuales fijas, no las toques al armar el mapa. |

---

## Sección 2 — Las 3 capas de tiles y cuándo usar cada una

| Capa | Tileset | Grilla | Colisión | Usalo para |
|---|---|---|---|---|
| `Ground` / `Detalle` | `assets/tilesets/lpc_battlefield/campo_batalla_tileset.tres` | 32×32 | Ninguna (es piso, se camina encima) | Tierra, barro, cemento, cráteres, piedra |
| `Walls` | `assets/tilesets/walls/walls_tileset.tres` | 32×32 | Por tile (Physics Layer ya configurado) | Paredes de trinchera, muros — todo lo que bloquea el paso en una grilla chica |
| `Objetos` | `assets/tilesets/objetos/objetos_tileset.tres` | 224×224 ("TileObject") | Por tile, **la dibujás vos** | Vehículos (Panhard, y los que sumemos) y props grandes |

Por qué `Objetos` usa una grilla de 224 y no 32: un vehículo es mucho más
grande que un tile de piso, así que tiene su propio TileSet con celdas
gigantes — un clic pone el vehículo entero, no lo armás tile por tile.

Si en algún momento necesitás un prop chico suelto (una caja, un barril)
que no amerite ser un "tile" reutilizable, usá en cambio
`scenes/world/prop.tscn` (ver Sección 4) en lugar de meterlo en un tileset.

---

## Sección 3 — Cómo pintar tiles (paso a paso)

1. En el árbol de la escena, seleccioná la capa que quieras pintar
   (`Ground`, `Detalle`, `Walls` u `Objetos`).
2. Abajo se abre el panel **TileMap** con la Paleta de Tiles a la derecha.
3. Elegí el tile haciendo clic en la paleta.
4. Click izquierdo en el lienzo = pintar. Click derecho = borrar.
5. Mantené `Shift` y arrastrá para pintar una línea recta; `Ctrl+Z` deshace.
6. Para pintar un área grande de relleno: seleccioná el tile, mantené
   apretado y arrastrá (o usá el balde de pintura, ícono en la barra del
   panel TileMap).

Tip: pintá primero todo `Ground`, después `Walls` (el perímetro y
divisiones), y al final `Objetos`/decoración — así no tapás nada.

---

## Sección 4 — Colisión: 3 mecanismos distintos (y cuál usar)

En este proyecto hay **tres** formas de que algo bloquee el paso. No son
intercambiables, cada una es para un caso:

| Mecanismo | Dónde se configura | Cuándo usarlo |
|---|---|---|
| **Physics Layer por tile** | TileSet de `Walls` u `Objetos`, panel inferior → pestaña "Tiles" → seleccionás el tile → dibujás el polígono de colisión | Cualquier cosa que pintás como tile (paredes, vehículos) |
| **`prop.tscn`** (`scenes/world/prop.tscn`) | Instanciás la escena, le asignás `texture`, `collision_size`, `collision_offset` en el Inspector | Props sueltos que NO querés convertir en tile (algo único, que no se repite) |
| **Auto-colisión de `Deco`** (`room.gd` → `_add_prop_collisions()`) | Poné un `Sprite2D` plano (sin script) dentro de un nodo llamado `Deco` en tu sala | Decoración rápida tipo sacos/cruces/rocas sueltas — el script le agrega colisión sola al arrancar, **excepto** si el nombre del nodo empieza con `Tussock`, `Gorse`, `Crater`, `Charco` o `Pasto` (esas son pisables a propósito, no bloquean) |

Para configurar la colisión de un tile (paredes u objetos):
1. Seleccioná la capa (`Walls` u `Objetos`) → se abre el panel TileMap.
2. En ese panel inferior, click en la pestaña **"Tiles"** (al lado de
   "Pintar tiles").
3. Elegí el tile en la lista de la izquierda.
4. A la derecha, en la sección de **Physics Layers**, dibujás el polígono
   con el mouse (clic para poner cada punto, click derecho o Enter para
   cerrarlo).
5. Esa forma se aplica automáticamente a **todas** las copias de ese tile
   en cualquier mapa que use el mismo tileset.

---

## Sección 5 — Bordes del mapa (cuidado acá)

`WallsCollision` (la caja invisible StaticBody2D con `ColTop/ColBottom/
ColLeft/ColRight`) define hasta dónde puede caminar el jugador, **pero es
un tamaño fijo puesto a mano** — no crece sola si vos seguís pintando mapa
para afuera. Si extendés un mapa y el jugador no puede llegar a la parte
nueva, es casi siempre por esto.

Dos formas de resolverlo:
- **Rápida:** entrar a cada `Col*` dentro de `WallsCollision` y
  arrastrar/agrandar el rectángulo para que cubra todo lo pintado.
- **Recomendada (sin mantenimiento):** pintar un perímetro cerrado de tiles
  de `Walls` alrededor de todo el mapa (ya tienen colisión por tile, ver
  Sección 4) y borrar `WallsCollision` — así el límite del mapa es "lo que
  pintaste" y se actualiza solo cada vez que extendés.

---

## Sección 6 — Crear una sala nueva real

Según `AGENTS.md`, las salas reales del juego son `nivel1_trinchera`,
`nivel1_campo`, `nivel1_pozo` y `naval_barco` (hoy solo existe el
prototipo `sandbox.tscn`). Para crear una:

1. En el FileSystem, click derecho sobre `sandbox.tscn` → **Duplicar**.
2. Renombrala (ej `nivel1_trinchera.tscn`) y movela a `scenes/maps/` (ya
   debería estar ahí).
3. Abrila, seleccioná el nodo raíz y renombralo igual que la escena
   (`Sandbox` → `Trinchera`, por ejemplo) — no es obligatorio pero ayuda a
   no confundirse.
4. Borrá del `Ground`/`Detalle`/`Walls`/`Objetos` lo que sea específico del
   sandbox de pruebas y empezá a pintar tu sala real (Secciones 2-3).
5. Poné al menos un `Marker2D` como punto de aparición y nombralo (ej.
   `SpawnNorte`) — ahí es donde aparece el jugador si llega por una puerta
   que apunte a ese nombre (ver Sección 7).
6. Ajustá `WallsCollision` o pintá el perímetro con `Walls` (Sección 5).

---

## Sección 7 — Conectar salas con puertas

Ya existe la escena `scenes/world/door.tscn` (script `door.gd`) lista para
usar — **no hace falta programar nada nuevo**, solo configurarla:

1. Arrastrá `door.tscn` a tu mapa, en el lugar donde está la puerta/salida.
2. Seleccioná el nodo y en el Inspector completá:
   - `target_scene`: ruta a la otra sala (ej.
     `res://scenes/maps/nivel1_campo.tscn`).
   - `target_spawn`: nombre exacto del `Marker2D` de esa otra sala donde
     tiene que aparecer el jugador (el que creaste en el paso 5 de la
     Sección 6).
   - Opcional: `locked` + `unlock_flag` si la puerta necesita una llave o
     palanca, o `force_dc` si se puede forzar con una tirada de Fuerza.
3. Repetí del otro lado (la sala destino necesita su propia puerta de
   vuelta, con su propio `target_spawn` apuntando a esta sala).

El jugador cruza la puerta caminando encima (es un `Area2D`), no hace
falta apretar ninguna tecla.

---

## Sección 8 — Encuentros de enemigos al entrar a una sala

**No coloques enemigos "a mano" con su lógica de IA en el mapa.** El
sistema ya soporta emboscadas por sala sin tocar código:

1. Seleccioná el nodo raíz de tu mapa (el que tiene el script `room.gd`).
2. En el Inspector, completá:
   - `encounter_chance`: probabilidad de 0 a 1 de que pase algo al entrar
     (0 = nunca).
   - `encounter_enemy`: ruta al `.tres` del enemigo (ej.
     `res://data/enemies/ghoul.tres`).
   - `stealth_dc`: dificultad para notar la emboscada antes de que ocurra
     (0 = no se puede evitar).
3. Si necesitás un enemigo **fijo** en un punto exacto del mapa (no
   aleatorio al entrar), instanciá `scenes/world/enemy_encounter.tscn`
   directamente en el árbol, como ya está hecho en `sandbox.tscn` (nodo
   `Enemigo`).

---

## Referencia rápida

```
Piso              → capa Ground/Detalle, tileset campo_batalla_tileset.tres (32px)
Paredes           → capa Walls, tileset walls_tileset.tres (32px), colisión por tile
Vehículos/objetos → capa Objetos, tileset objetos_tileset.tres (224px), colisión por tile
Prop suelto único → scenes/world/prop.tscn
Decoración rápida → Sprite2D dentro de un nodo "Deco" (auto-colisión)
Límite del mapa   → WallsCollision (a mano) o perímetro de Walls (recomendado)
Puerta a otra sala→ scenes/world/door.tscn (target_scene + target_spawn)
Enemigos al entrar→ encounter_chance / encounter_enemy / stealth_dc (en el root, room.gd)
```
