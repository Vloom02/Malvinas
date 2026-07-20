# Codename Malvinas — Features

RPG survival horror por turnos ambientado en la Guerra de Malvinas (1982).
Referencias: Fear & Hunger 1/2, CONSCRIPT, Trench Face, This War of Mine,
Pathologic, Silent Hill 2, Amnesia: The Bunker, World of Horror.

Lista viva de todo lo implementado, agrupado por sistema. Los archivos clave
van entre paréntesis.

## Campaña y tiempo
- Reloj día/noche: 24h de juego = 20 min reales; de noche la luz ambiente se
  reduce a la mitad (`scripts/autoload/game_state.gd`).
- Calendario de campaña: 1 al 14 de junio. Cada amanecer sube el peligro; el
  14 llega la rendición → final forzado.
- Dormir en el fogón hasta el amanecer (25% de pesadilla: −cordura).
- Fecha y hora visibles en el HUD y en el menú de estado.

## Supervivencia (el cuerpo es el HUD)
- Vitales: HP, hambre, cordura, sangrado, frío, infección, quemaduras,
  shock de batalla, miembros rotos (tablilla + rama para entablillar).
- Pie de trinchera: se acumula caminando por ambientes mojados; frena la
  velocidad y avisa por etapas. Se cura con medias secas o secándose al fogón.
- Frío: sube de noche/mojado; se baja al fogón.
- Cordura: drenajes por horrores, alucinaciones (susurros/sombras/pantalla),
  tiradas de salvación con d20 (`sanity_save`).
- Comida: raciones, carne cruda de oveja (25% de infección) que se cocina al
  fogón, carne podrida.
- Inventario por espacios: 24 ítems distintos; los stacks no ocupan lugar
  extra (`scripts/systems/inventory_manager.gd`).

## Armas y economía de disparo
- 6 armas reales argentinas: FAL, FAP, FN MAG, FMK-3, Browning HP, escopeta.
  Datos en `.tres` (`data/items/`), instancias con desgaste (`WeaponInstance`).
- Munición por cargadores: cargadores llenos/vacíos, cinta de MAG, recarga
  con R, click seco sin balas.
- Trabas (jam): probabilidad por condición/mugre/frío/barro; destrabar
  manteniendo R (círculo + tilde/cruz sobre el arma, cartel TRABADO);
  período de gracia de 12 s tras destrabar; kit de limpieza.
- Accesorios crafteables con efecto real y visible: mira, correa, trípode,
  bípode, cargador ampliado, etc. (mesa de crafteo).
- Puntería sostenida: apuntar acumula precisión (barra de carga).
- Melee con desgaste del arma y daño escalado por condición.
- Disparo libre en el mundo (F / click) con fogonazo, retroceso y sacudida
  de cámara; blancos de práctica para el tutorial de tiro.

## Combate por turnos (Fear & Hunger)
- Menú jerárquico; apuntado por parte del cuerpo; munición real por turno.
- Trabas en combate; culatazo como alternativa sin balas; recarga en turno.
- "Hablar": rendirse, intimidar (d20 Fuerza) a británicos, calmar desertores.
- Captura POW: los británicos no te matan, te capturan → despertás en la
  celda, forzás la reja con d20 (`scenes/world/celda.gd`).
- Ataques especiales enemigos con telegraph.

## Mundo y eventos (componentes para armar mapas)
- `fogon.tscn` — guardar, calentarse, cocinar, dormir.
- `bombardeo.tscn` — sirena + cuenta regresiva + refugio (respeta la pausa).
- `linea_fuego.tscn` — MAG/francotirador que bate una zona; pasás cuerpo a
  tierra o agachado (perfil bajo).
- `patrulla.tscn` — ronda por waypoints, cono de visión, persigue al verte.
- `evento_aleatorio.tscn` — viñeta al azar estilo World of Horror (mochila,
  cadáver, panfleto, artillería, munición) con elección y consecuencia.
- `desafio.tscn` — desafío genérico con d20 (fuerza puertas, mueve escombros).
- `maquina_item.tscn` — consume ítem → flag (generador + gasoil → radio final).
- `deposito.tscn` — robar suministros (de noche casi no te ven; de día 50%).
- `colimba_hambriento.tscn` — compartir o negar ración (reputación/cordura).
- `radio_noticias.tscn` — ruleta de noticias (40/40/20 sobre la cordura).
- `oveja.gd` — huye; se puede carnear (35% de que te agarren → estaqueo).
- `cofre.tscn`, `item_pickup.tscn`, `interactable.tscn`, `door.tscn`,
  `hazard.tscn`, `icy_bog.tscn`, `ending.gd` (finales con requisito de flag).
- Marea/niebla (`fog.tscn`), oscuridad con linterna (`darkness.tscn`).

## Terror por proximidad (ronda Silent Hill / Amnesia)
- Radio con estática: crepita cuando hay enemigos a <160 px, más fuerte
  cuanto más cerca — aunque no los veas (`scripts/systems/radio_peligro.gd`,
  estática procedural en `assets/audio/estatica.wav`).
- El ruido atrae: disparos (220 px), cerrojo (90 px) y hasta la traba (70 px)
  emiten `ruido_mundo`; las patrullas van a investigar ("¿?") y si fue muy
  cerca se alertan directo ("¡!").
- Carteles del mundo con vida: los nombres y el [E] aparecen con fade recién
  al acercarte y flotan suavemente (`scripts/systems/world_labels.gd`,
  fuente Creepster). Los avisos de alerta enemiga quedan exentos.

## Moralidad y batallón
- Reputación 0–100: afecta precios de la tienda y reacciones.
- Estaqueo: castigo de campo (6 h estaqueado, +frío, −cordura, −reputación).
- Diario de culpa (`journal`): las decisiones quedan escritas.
- Clases por prólogo estilo Trench Face: infantería / marina / aviación,
  cada una con bonus de origen.
- Plata = cigarrillos; tienda de campaña con precios por reputación.

## Presentación
- Menú de título: fondo del soldado (arte Gemini), FAL gore como cursor
  flanqueando la opción enfocada de ambos lados, esquineras de retícula
  que laten como indicador de foco (`scenes/ui/title.gd`).
- Transiciones estilo Doom: al salir el mapa se derrite hacia abajo (melt
  clásico) y al entrar el mapa nuevo cae en columnas hasta armarse (melt
  inverso) (`scenes/ui/melt.gdshader`, `transition.gd`).
- HUD estilo The Punisher (PS2): monitor de vitales con ECG (el ritmo se
  dispara con poca vida), render del arma abajo a la derecha con munición,
  4 íconos de condición en las esquinas (sangrado, frío, pie, infección);
  se oculta ante cualquier pausa o diálogo (`scenes/ui/vitals_hud.gd`).
- Diálogos estilo F&H con opciones y ramas (`Dialogue`), mueren al volver
  al menú.

## Infraestructura
- Save/load completo (vitales, armas, munición, trabas, hora, día,
  reputación, pie de trinchera, flags) (`scripts/systems/save_manager.gd`).
- Cheat de pruebas: F10 da todas las armas; cofre de sandbox con arsenal.
- Mapa sandbox con todos los componentes instanciados para probar.
- Tilesets: campo de batalla LPC, paredes, objetos (Pucará, Unimog...),
  mapa de hangar armado programáticamente.

## Pendiente (bloqueado por cuota de PixelLab)
- Props, animaciones ambientales, UI kit y criaturas de la lista maestra
  (en memoria del asistente) + re-render del FN MAG.
- Planos v2 de la isla (naufragio, turbera) — esperan intro + Malvinas.

## Ideas anotadas (ronda 4, sin implementar)
- Clima dinámico (lluvia/viento que moja, traba y tapa el ruido).
- Aflicciones por cordura baja estilo Darkest Dungeon.
- Morse en la radio con intel real.
