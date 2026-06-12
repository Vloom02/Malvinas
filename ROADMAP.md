# Hoja de ruta — Codename Malvinas

RPG survival horror por turnos, ambientado en la Guerra de Malvinas (1982).
Tono turbio estilo *Fear & Hunger* / *Trench Face*, enfoque **antibélico**.
Este documento es la lista viva: vamos tildando `[x]` lo que se completa.

---

## 🎯 Pilares de diseño (no negociables)

1. **Sin HUD.** El estado no se muestra con barras: se ve en el **personaje y la
   pantalla** (diegético). Frío/hambre, cordura, sangre y heridas se reflejan en
   el sprite, en la viñeta, en el color, en cómo camina.
2. **El cuerpo refleja todo.** Las interacciones marcan el cuerpo: pisás una
   enredadera → sangrás → se ve. Heridas, fracturas, infección, hipotermia, locura
   son estados persistentes que cambian la partida.
3. **RNG por dado (estilo D&D) SOLO en momentos de tensión.** El combate normal
   es determinista; el dado NO resuelve cada ataque. Aparece en acciones
   arriesgadas e inciertas: esquivar poderes de jefes, firmar el pulso al atacar
   herido, peligros del mundo (enredadera, grietas), saves (infección, frío,
   cordura), primeros auxilios bajo presión, forzar/sigilo. Como el coin-flip de
   F&H pero con peso.
4. **Horror antibélico y respetuoso.** El enemigo es el horror de la guerra (frío,
   trauma, criaturas), NO "matar británicos". Tema real y sensible: se trata con peso.
5. **Escasez y consecuencias permanentes.** Inventario limitado, guardar es un
   recurso caro, perder un brazo te cambia la run. Tensión, no power fantasy.

---

## ✅ Estado actual (ya hecho)

- [x] Repo + Git LFS + arquitectura modular + CONTRIBUTING
- [x] Exploración top-down: caminar, paredes sólidas, interactuar (E)
- [x] `GameState` (autoload) con hambre/cordura/vida y señales
- [x] Combate por turnos con **desmembramiento** (atacar partes del cuerpo)
- [x] Consecuencia de cordura en 0 (pesadilla forzada)
- [x] Sprite del conscripto (PixelLab) caminando en 4 direcciones
- [x] Tileset de trinchera + piso de la sala
- [x] Viñeta de oscuridad opresiva (shader) estilo F&H
- [x] Pipeline de arte por IA (PixelLab MCP) funcionando

---

## 🔧 FASE 1 — Rediseño core según los pilares nuevos

> Esto va PRIMERO porque cambia las bases. Sin esto, sumar contenido es al pedo.

- [ ] **Sistema de dados** (`lib/dice.gd`): d20/d6, tiradas con modificadores,
      ventaja/desventaja, resultados (crítico, éxito, fallo, pifia). Central a todo.
- [ ] **Sacar el HUD.** Quitar el cartel de hambre/cordura.
- [ ] **Estado diegético**: reflejar hambre/cordura/heridas en el sprite y la
      pantalla (tinte, viñeta que se cierra con el miedo, paso tambaleante, etc.).
- [ ] **Modelo de cuerpo** (`BodyState`): miembros con HP, sangrado, fractura,
      infección, hipotermia. Persistente entre escenas.
- [ ] **Peligros ambientales** que marcan el cuerpo (enredadera → sangra; charco
      helado → hipotermia; alambre de púas → herida). Reutilizable como `Hazard`.
- [ ] **Efectos de estado por turno/tiempo** (sangrado que drena vida, infección
      que empeora, frío que sube).
- [ ] **Inventario + items** (vendas, torniquete, ración, morfina) con uso limitado.

## ⚙️ FASE 2 — Profundidad de sistemas

- [x] **Dado en combate (momentos puntuales)**: esquivar poderes de jefe, y firmar
      el pulso al atacar herido. El combate base sigue determinista.
- [ ] **Más usos del dado**: saves (infección/frío/cordura), forzar/sigilo, primeros
      auxilios bajo presión.
- [ ] **IA enemiga**: el enemigo elige qué parte tuya atacar; comportamientos.
- [x] **Caja de diálogos base** (autoload `Dialogue`, mensajes con E). Falta:
      diálogos con NPCs, ramas/elecciones, retratos.
- [ ] **Guardar/cargar**, con el guardado como **recurso escaso** (no autosave libre).
- [ ] **Transición entre salas** → mapa/dungeon explorable de verdad.
- [ ] **Loot y crafteo** básico.

## 🎨 FASE 3 — Producción de contenido (el juego en sí)

- [ ] **Guion y narrativa**: la historia de Malvinas, NPCs, **múltiples finales**.
- [ ] **Diseño de niveles**: arrancar por **Infantería** (trincheras/turba/niebla);
      después Naval (barco que se hunde), por último Aviación.
- [ ] **Arte definitivo** (PixelLab + Leonardo): conscripto pulido, enemigos
      (espectro y más), retratos pintados, tilesets, props, ambientes.
- [ ] **Audio**: ambiente (viento, frío), SFX, música opresiva.
- [ ] **Bestiario / NPCs / items** (data-driven en `.tres`).
- [ ] **Finales múltiples y secretos**.

## ✨ FASE 4 — Pulido y UX

- [ ] **Menús**: principal, pausa, opciones.
- [ ] **Configuración**: volumen, controles remapeables, accesibilidad.
- [ ] **Soporte de joystick/control**.
- [ ] **Localización** español / inglés (clave para vender afuera).
- [ ] **Game feel**: screen shake, partículas (sangre, niebla), transiciones.
- [ ] **Optimización y build** estable (PC primero; quizá APK después).

## 🚀 FASE 5 — Shipping (volverlo vendible)

- [ ] **Estructura legal/fiscal**: monotributo o empresa, datos bancarios, impuestos.
- [ ] **Steam Direct**: USD 100 por juego (se recuperan tras USD 1.000 de ventas).
- [ ] **Verificación de Valve**: documentación fiscal (W-8BEN para no-USA) + banco.
- [ ] **Espera de 30 días** entre pagar el fee y poder publicar (planificarlo).
- [ ] **⚠️ Declarar contenido generado por IA** (obligatorio en Steam — usamos
      PixelLab/Leonardo). Hay que llenar el disclosure honestamente.
- [ ] **Clasificación por edad** (gore/violencia → Mature/+17).
- [ ] **Página de Steam**: capsule art, screenshots reales, **trailer**, descripción,
      tags, idiomas. Los assets tienen que reflejar el juego real.
- [ ] **Demo** = vertical slice de **15–30 min** que muestre el loop y termine con
      "agregá a wishlist".
- [ ] **Campaña de wishlists** 6–8 semanas antes (las wishlists previas son lo que
      más correlaciona con el éxito).
- [ ] **Steam Next Fest**: publicar la demo 2–4 semanas antes del fest; el nicho de
      F&H/Trench Face es ideal para esto.
- [ ] **Prensa, streamers y comunidad** (Reddit r/feariswar, YouTubers de horror RPG).
- [ ] **QA / beta testing** (que la demo no esté rota es decisivo).
- [ ] **Precio, EULA, política de privacidad**.

## 🔁 FASE 6 — Post-lanzamiento

- [ ] Parches y soporte de comunidad.
- [ ] Expansión/contenido gratis (como hizo Trench Face) para mantener el envión.

---

## 📌 Notas

- **Tema sensible:** en marketing y narrativa, tratar Malvinas con respeto (honrar el
  sufrimiento, no glorificar). Es lo que hace fuerte al juego, pero hay que cuidarlo.
- **Monetización/Mercado Pago:** para el final, igual que en los otros proyectos.
- **Prioridad personal de Alan:** Stockly sigue siendo lo primero; esto es hobby en
  paralelo. Avanzamos cuando hay tiempo.

### Fuentes consultadas (publicación)
- Steam Direct: fee y requisitos — https://partner.steamgames.com/doc/gettingstarted/appfee
- Guía publicar en Steam 2026 — https://pixune.com/blog/how-to-publish-a-game-on-steam/
- Datos de Steam Next Fest 2026 — https://ziva.sh/blogs/steam-next-fest-2026
- Estrategias Next Fest — https://www.biggamesmachine.com/steam-next-fest-marketing-strategies/
