# Cómo trabajamos en equipo

El objetivo de estas reglas es **evitar conflictos de Git** y que varias
personas puedan tocar el proyecto sin pisarse. Godot lo permite, pero solo
si seguimos disciplina de escenas chicas y datos separados.

## 1. Flujo de ramas (igual que siempre)

- Nunca commitear directo a `main`.
- Una rama por tarea: `feat/inventario`, `fix/combate-cabeza`, `art/sprites-necrofago`.
- Push → Pull Request → review → merge. `main` siempre tiene que abrir y correr.

## 2. La regla de oro: escenas CHICAS y modulares

El 90% de los conflictos feos en Godot vienen de **dos personas editando la
misma escena grande**. Para evitarlo:

- Cada cosa = su propia escena (`.tscn`): el jugador, cada enemigo, cada
  pieza de UI, cada item. Se componen **instanciando** unas dentro de otras.
- Un mapa NO contiene enemigos "dibujados a mano" con toda su lógica: instancia
  la escena `enemy.tscn` y le asigna datos.
- Si una escena se está volviendo gigante, partila antes de que duela.

## 3. Los DATOS van en `.tres`, no en escenas ni hardcodeados

- Stats de enemigos, items, diálogos → archivos `.tres` (Resources) en `data/`.
- Así un diseñador balancea editando un `.tres` sin tocar código ni escenas,
  y dos personas editan dos enemigos distintos sin conflicto.
- Ejemplo ya incluido: `data/enemies/ghoul.tres` usa `data/enemy_data.gd`.

## 4. Coordinación humana (lo más importante)

- **Avisá qué escena vas a tocar** antes de empezar (canal del equipo / issue).
  Las escenas `.tscn` se pueden mergear, pero es incómodo. Mejor no solaparse.
- PRs chicos y frecuentes > un PR gigante una vez por semana.
- `git pull` antes de empezar a trabajar, siempre.

## 5. Binarios = Git LFS

- Arte, audio y fuentes (`.png`, `.ogg`, `.ttf`, etc.) van por **Git LFS**
  (ya configurado en `.gitattributes`). Corré `git lfs install` una vez.
- No metas binarios sueltos fuera de `assets/`.

## 6. Estilo de código GDScript

- `snake_case` para variables y funciones, `PascalCase` para `class_name`.
- Tipá todo lo que puedas: `var hp: int = 10`, `func atacar(parte: String) -> void:`.
- Comentarios con `##` arriba de clases/funciones (los toma la documentación de Godot).
- Una clase = un archivo. Scripts en `scripts/`, scripts de escena al lado de su `.tscn`.

## 7. Qué NO commitear

- La carpeta `.godot/` (cache, se regenera — ya ignorada).
- Exports/builds (`.exe`, `.pck`, etc. — ya ignorados).
- Los `*.import` SÍ se commitean (le dicen a Godot cómo importar cada asset).
