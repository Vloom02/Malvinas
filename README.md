# Hambre (título provisional)

RPG de terror/supervivencia por turnos, inspirado en *Fear & Hunger*.
Hecho en **Godot 4.4** con **GDScript**.

## Requisitos para desarrollar

1. **Godot 4.4** (versión estándar, NO la .NET/Mono) — https://godotengine.org/download
2. **Git** + **Git LFS** (los binarios —arte, audio, fuentes— van por LFS).

## Cómo clonar y abrir

```bash
git lfs install            # una sola vez por máquina
git clone <url-del-repo>
cd Hambre
# Abrir Godot -> "Importar" -> seleccionar este project.godot
```

> La primera vez que abrís el proyecto, Godot genera la carpeta `.godot/`
> (cache). Está ignorada en git; no la subas.

## Estructura

```
scenes/      Escenas .tscn (player, enemies, ui, maps). Una por "cosa", chicas.
scripts/     Lógica reutilizable.
  autoload/  Singletons globales (GameState).
  systems/   Sistemas (combate, inventario, save...).
data/        Recursos de datos .tres (enemigos, items, diálogos) + sus scripts.
assets/      Arte, audio, fuentes (binarios -> Git LFS).
```

## Probar que anda

Abrí el proyecto y dale **F5** (Play). En la consola de Godot deberías ver
mensajes de prueba: daño a una parte del enemigo y el hambre bajando. Eso
confirma que autoload + recursos + escenas modulares están bien conectados.

Las reglas para trabajar entre varios están en **[CONTRIBUTING.md](CONTRIBUTING.md)**.
