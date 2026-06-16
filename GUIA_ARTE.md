# Guía de arte para Alan — Cómo dibujar y modificar sprites

Guía práctica para crear o modificar sprites sin saber dibujar de cero.
Tres caminos según lo que necesités hacer: **modificar algo que ya existe**,
**generar con IA** y **dibujar vos mismo**.

---

## 🗺 ¿Qué querés hacer?

```
¿Necesitás cambiar algo del jugador o un enemigo ya existente?
  → Sección 1: Modificar sprites existentes con Pixelorama/Aseprite

¿Necesitás un sprite nuevo (enemigo, prop, NPC)?
  → Sección 2: Generar con PixelLab (IA)
  
¿Querés aprender a dibujar píxel a píxel?
  → Sección 3: Primeros pasos en pixel art
```

---

## Sección 1 — Modificar sprites existentes

### Herramienta: Pixelorama (gratis, no necesitás instalar nada extra)

1. **Descargá Pixelorama:** pixelorama.io → "Download" → versión Windows portable.
2. **Abrí el sprite:** Archivo → Abrir → navegá a `assets/sprites/`.
3. Ejemplo: querés agregarle sangre al jugador.
   - Abrí `assets/sprites/lpc_soldado/standard/walk.png`
   - Seleccioná el **Lápiz** (B) con un rojo oscuro (`#5C0A0A`)
   - Pintá manchas pequeñas e irregulares en el torso o el brazo
   - Guardá como PNG (mismo nombre, sobreescribir)
   - Godot reimporta automáticamente la próxima vez que abras el editor

### Cambios rápidos que podés hacer ahora mismo

| Cambio | Cómo |
|---|---|
| Cambiar color de ropa del jugador | Herramienta "Reemplazar color" (paleta → click en color viejo → elegir nuevo) |
| Añadir máscara de gas o casco | Dibujar encima con el lápiz en los frames correspondientes |
| Oscurecer un enemigo | Ajustar brillo/contraste (Imagen → Ajustes → Brillo/Contraste) |
| Cambiar el color del espectro | Reemplazar el color base por otro tono espectral |
| Añadir detalle (cicatriz, parche) | Lápiz, 1-2 píxeles, color oscuro |

### Estructura de los sheets LPC del jugador

El archivo `walk.png` tiene esta estructura:
```
Fila 0 (row 0) = Norte  (camina hacia arriba)
Fila 1 (row 1) = Oeste  (camina hacia la izquierda)
Fila 2 (row 2) = Sur    (camina hacia abajo)  ← la más visible
Fila 3 (row 3) = Este   (camina hacia la derecha)

Columna 0 = Pose estática (idle)
Columnas 1-8 = Frames de caminata (se leen de izquierda a derecha)
Cada frame = 64×64 píxeles
```

Si modificás el frame sur (fila 2), es lo que más se va a notar.

---

## Sección 2 — Generar sprites con PixelLab (IA)

Ya tenemos el MCP de PixelLab configurado. Se puede usar desde el asistente de código
directamente. Si el crédito se agota, la alternativa es **Leonardo.ai** (gratis
con cuenta).

### Fórmula de prompts para este juego

Siempre incluir estos elementos en este orden:

```
[estilo base] + [tamaño] + [sujeto] + [contexto Malvinas] + [paleta] + [fondo]
```

**Ejemplo completo:**
```
top-down pixel art, 64x64, tired Argentine soldier in green military jacket
and helmet, holding a FAL rifle, Falklands 1982, cold muted colors,
dark greens and browns, transparent background
```

### Prompts listos para usar

**NPC Sargento (frente, 64×64):**
```
top-down pixel art, 64x64, Argentine army sergeant, weathered face,
green military uniform, sitting behind wooden crate, Falklands War 1982,
cold muted palette, transparent background
```

**Oficial fantasmal (jefe, 96×96 para combate):**
```
pixel art, 96x96, spectral Argentine officer ghost, tattered uniform with rank
insignia, hollow eyes glowing pale blue, decomposed hands, Malvinas 1982,
dark horror atmosphere, transparent background
```

**Prop — casco tirado en el suelo (32×32):**
```
top-down pixel art, 32x32, abandoned Argentine military helmet lying in mud,
Falklands 1982, cold muted colors, transparent background
```

**Tileset campo abierto (pasto Malvinas):**
```
top-down tileset tile, 16x16, tussock grass patch, brown dead grass,
Falkland Islands terrain, cold muted palette, no outline, seamless
```

**Agua del barco (nave hundiéndose):**
```
pixel art, 64x64, dark rising seawater tile, cold blue-gray, slight foam,
interior of sinking ship, animated frame, transparent background
```

### Consejos para mejores resultados

- Si el resultado tiene fondo blanco o negro: agregar `transparent background`
  o limpiar con la herramienta "varita mágica" en Pixelorama.
- Si el personaje mira para el lado equivocado: agregar `facing left` o
  `facing forward`.
- Si el estilo no pega con el resto: agregar `matching LPC pixel art style`
  o `same style as classic RPG sprites`.
- Si querés algo más oscuro/opresivo: agregar `horror atmosphere, dark shadows`.

### Después de generar con PixelLab

1. Guardá el PNG en la carpeta correcta:
   - Enemigos mundo: `assets/sprites/enemies/`
   - Props: `assets/props/`
   - NPCs: `assets/sprites/npcs/` (crear si no existe)
2. En Godot: si es enemigo, actualizá el campo `sprite` en el `.tres` del enemigo
   (Inspector → enemigo.tres → sprite → cargar el nuevo PNG).
3. Si es prop decorativo, agregalo a la escena como `Sprite2D`.

---

## Sección 3 — Aprender a dibujar pixel art (desde cero)

### Herramienta recomendada: Aseprite

Aseprite (USD 19.99 en Steam) es el estándar. Si no querés pagar,
**Pixelorama** (gratis) hace el 90% de lo mismo.

### Conceptos básicos para empezar

**1. Empezá pequeño**
No intentes un personaje de 64×64 de entrada. Hacé algo de 16×16 primero
(un cofre, una piedra, una vela). Con 16×16 tenés menos decisiones.

**2. Limitá la paleta**
Elegí 4-6 colores antes de empezar. Para Malvinas:
- Fondo oscuro: `#1A1A1F`
- Tierra/barro: `#4A3728`
- Ropa militar: `#3D4A2E`
- Metal: `#6B7280`
- Piel: `#C4956A`
- Acento frío: `#7BA3C4`

**3. Sin antialiasing**
En Aseprite/Pixelorama: asegurate de usar el lápiz sin suavizado.
El pixel art se hace con píxeles duros, no con bordes difuminados.

**4. Iluminación simple**
Elegí UNA dirección de luz (arriba-izquierda es el estándar).
- Cara iluminada = 1-2 tonos más claro que el base
- Cara en sombra = 1-2 tonos más oscuro
- Solo 3 valores: sombra / base / luz

**5. Outline**
Un borde de 1 píxel de color más oscuro que el objeto hace que el sprite
"lea" bien contra cualquier fondo. Para que el soldado se vea bien en el
barro, su outline tiene que ser más oscuro que el barro.

### Tutorial de 30 minutos: hacer un prop de Malvinas

**Objetivo:** una vaina de bala (32×32)

1. Nuevo archivo 32×32 en Pixelorama
2. Dibujá el contorno con el lápiz (color dorado oscuro `#8B6914`)
3. Rellená el interior (balde de pintura) con dorado base `#C4921C`
4. Sumá píxeles de luz (1-2 píxeles, color `#E8B84B`) en la parte superior
5. Sumá sombra (1-2 píxeles, `#5C4010`) en la parte inferior
6. Guardá como PNG en `assets/props/vaina_bala.png`
7. En Godot, agregalo como `Sprite2D` en la escena

### Modificar los personajes LPC existentes

La ventaja del LPC es que los personajes son modulares (capas).
Para cambiar el look del jugador sin recomponer desde cero:

1. Abrí `assets/sprites/lpc_soldado/standard/walk.png` en Pixelorama
2. Usá "Reemplazar color" para cambiar el uniforme (verde oscuro → marrón
   o camuflaje)
3. Dibujá detalles extra con el lápiz: parches, manchas, heridas
4. Guardá — Godot reimporta automáticamente

Para recomponer el personaje desde las capas LPC originales
(cambiar el cuerpo base, la ropa, el cabello):
→ Usar el script `lpc_compose.py` que ya tenemos.
→ Pedile al asistente que corra el script con las capas que querés.

### Recursos de aprendizaje gratuitos

| Recurso | Link | Para qué |
|---|---|---|
| Pixelart.com tutorials | pixelart.com/tutorials | Fundamentos visuales |
| Lospec Palette List | lospec.com/palette-list | Elegir paletas de color |
| Pedro Medeiros (Pedro's Pixel Art Tutorials) | saint11.org/blog/pixel-art-tutorials | El mejor tutorial cortito |
| GDQuest pixel art | youtube/@GDQuest | Integración con Godot |
| Brandon James Greer | youtube/@BJG | Dibujar sprites de juego paso a paso |

---

## 🎨 Paleta oficial de Codename Malvinas

Guardala en Pixelorama/Aseprite para que todos los sprites sean consistentes.

```
Nombre            Hex        Uso
─────────────────────────────────────────────────────
Oscuro profundo   #0F0F14    Fondo de noche / sombras extremas
Tierra húmeda     #2A1E14    Suelo de barro
Suelo base        #4A3728    Tierra, madera vieja
Uniforme oscuro   #2C3320    Ropa militar (dark)
Uniforme base     #3D4A2E    Ropa militar (base)
Uniforme luz      #5A6B42    Ropa militar (iluminado)
Metal oscuro      #3C4147    Acero en sombra
Metal base        #6B7280    Acero
Metal luz         #9CA3AF    Reflejo metálico
Piel sombra       #8B6045    Cara/manos en sombra
Piel base         #C4956A    Cara/manos
Piel luz          #DDB48A    Frente iluminada
Frío / niebla     #7BA3C4    Tinte azul de frío, agua
Sangre seca       #5C0A0A    Heridas, rastros
Rojo sangre       #8B1515    Sangre fresca
Hueso / papel     #D4C9A8    Documentos, madera clara
```

Podés importar esta paleta en Pixelorama desde Archivo → Importar paleta.
