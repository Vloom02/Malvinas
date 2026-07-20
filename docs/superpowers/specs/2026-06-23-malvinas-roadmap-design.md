# Diseño a largo plazo — Codename Malvinas

Fecha: 2026-06-23
Estado: aprobado por Alan, pendiente de descomponer en planes de implementación.

## Contexto

Hasta ahora el proyecto tenía sistemas sueltos (combate, inventario, guardado,
narrativa básica) y 2 mapas de prueba (`sandbox.tscn`, `area1.tscn`), pero
ninguna estructura de campaña que los conecte de principio a fin. Este
documento define esa estructura completa: personajes, actos, niveles y la
entidad antagonista, para tener una guía estable a la que volver en vez de
improvisar mapa por mapa.

Escala elegida deliberadamente **corta** (9 niveles totales) para que sea
terminable por un dev solo con ayuda de IA. Se puede expandir después de
tener un primer recorrido completo jugable.

## Estructura de personajes

El jugador elige **uno** de 3 personajes al empezar (como elegir clase). Cada
uno tiene su propia base real argentina y un nivel de prólogo propio. Los
otros 2 no se juegan como protagonista, pero aparecen más adelante como NPCs
heridos/perdidos: una decisión narrativa (vía `NarrativeManager`, ya
existente) determina si se intenta salvarlos; si se salvan, se unen como
companion jugable (sistema `GameState.companion`, ya existente).

| Rama | Personaje | Base real | Por qué pelea a pie en Malvinas |
|---|---|---|---|
| Aviación | Cabo Raúl Ibáñez, mecánico de pista | Brigada Aérea Córdoba (FAA) | Mecánico, no piloto — reasignado a infantería al llegar |
| Marina | Cabo 2do Walter Cabrera, marinero | Base Naval Puerto Belgrano (Bahía Blanca) | Desembarcado como refuerzo de infantería de marina |
| Infantería | Conscripto Hugo Medina | Campo de Mayo, Buenos Aires | Es infantería desde el día uno |

Nota: Mendoza (mencionada originalmente) no tiene base naval real — se
reemplazó por Puerto Belgrano, que es la base naval principal histórica.

Pendiente de decidir más adelante: si los companions ya existentes en el
código (`cabo_garcia`, `medico_rodriguez`, `cabo_pascual`) se reutilizan como
estos 2 personajes no elegidos, o si son personajes separados sin relación.
No se asume nada todavía — hay que revisar su lore actual antes de fusionar.

## Estructura narrativa (9 niveles)

### Acto 1 — Continente (2 niveles)
1. **Base de origen** (varía según personaje elegido): establece backstory,
   rutina militar, orden de movilización a Malvinas.
2. **Punto de embarque**: los 3 caminos posibles convergen acá en la misma
   escena compartida. A partir de este nivel la historia es idéntica sin
   importar qué personaje se eligió.

### Acto 2 — Malvinas, ~30-40% del juego (3 niveles)
3. **Desembarco / Trinchera** — reutiliza `campo_batalla_tileset.tres`,
   capa `Walls`, el vehículo Panhard ya generado.
4. **Combate en campo abierto** — reutiliza `area1.tscn` como base.
5. **Retirada bajo fuego** — el personaje queda gravemente herido (stat
   `artillery_used`, ya existente) y es dado por muerto en el caos. Un bote
   de evacuación lo arrastra a la deriva hasta la isla.

### Acto 3 — Isla Turbia (4 niveles)
6. **Playa / naufragio** — primeros encuentros con Empantanados, tono de
   exploración y horror inicial.
7. **La turbera** — corazón de la infección, se revela el lore de Madre
   Turba.
8. **Puesto ovejero abandonado** — punto medio narrativo (las estancias de
   kelpers/ovejeros son reales en Malvinas).
9. **Confrontación final** — final múltiple según las decisiones
   acumuladas (`NarrativeManager.get_major_decisions()`, falta implementar
   `resolve_ending()` — ya identificado en el roadmap técnico anterior).

## La entidad — "Madre Turba"

No es un monstruo único: es la turba (el pantano) de la isla, que en la
realidad preserva cuerpos por siglos (fenómeno real de "bog bodies"). Lleva
siglos consumiendo náufragos y soldados perdidos desde la época de
balleneros, y la muerte masiva de 1982 la "despierta"/alimenta de golpe.

- **Contagio:** por heridas abiertas — reutiliza el stat `wound_infection`
  ya existente en `game_state.gd`, sin necesidad de un sistema nuevo.
- **Monstruo resultante:** "Empantanado" — cuerpo parcialmente
  mineralizado por la turba, pero conserva fragmentos de entrenamiento
  militar (de ahí que peleen con tácticas, no como zombies genéricos).
- **Conexión temática:** el nombre del proyecto ("Hambre") encaja
  directamente con la naturaleza de la entidad.
- **Jefe final:** el Empantanado más antiguo de la isla (posible
  reutilización o evolución de `capitan_boss.tres`, ya existente) — a
  confirmar cuando se diseñe el Acto 3 en detalle.

## Qué se reutiliza de lo ya construido (sin reinventar)

- `wound_infection`, `artillery_used` (stats en `game_state.gd`)
- `NarrativeManager` (decisiones, falta solo `resolve_ending()`)
- `GameState.companion` (sistema de companion en combate)
- `room.gd` / `door.gd` (transición entre salas, ya probado en `area1.tscn`)
- `campo_batalla_tileset.tres`, `walls_tileset.tres`, `objetos_tileset.tres`
  (Panhard) para el Acto 2
- `capitan_boss.tres` como posible base del jefe final

## Fuera de alcance por ahora

- Selección de personaje como pantalla de menú formal (UI) — se diseña
  cuando se llegue a esa pieza.
- Diseño detallado nivel por nivel (geometría de mapas, encuentros
  específicos) — cada nivel es su propio plan de implementación, no se
  detalla acá.
- Lore completo de Madre Turba (diálogos, documentos encontrables) — se
  desarrolla en el plan del Acto 3.

## Próximo paso

Descomponer esta hoja de ruta en proyectos chicos, cada uno con su propio
plan de implementación, en este orden sugerido (de menor a mayor
dependencia):
1. Selección de personaje + las 2 bases de prólogo restantes (la de
   Infantería ya es, de hecho, lo más parecido a lo que existe hoy).
2. Nivel "Punto de embarque" (la convergencia).
3. Conectar Acto 2 reusando `area1.tscn`/tileset de batalla como nivel 3-4
   real (hoy son sandboxes de prueba, no niveles narrativos conectados).
4. Enemigo "Empantanado" + tileset/arte de la turbera (Acto 3, nivel 6-7).
5. `NarrativeManager.resolve_ending()` + escena de final.
