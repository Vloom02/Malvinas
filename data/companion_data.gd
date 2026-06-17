@tool
extends Resource
class_name CompanionData
## Datos de un compañero reclutable (data pura).
## Cada companion es un .tres en data/companions/.

@export var id: String = "companion"
@export var display_name: String = "Compañero"
@export var description: String = ""
@export var sprite: Texture2D
@export var portrait: Texture2D

## Stats del compañero en combate.
@export var hp: int = 60
@export var hp_max: int = 60
@export var attack: int = 8
@export var defense: int = 1
@export var heal_power: int = 0  ## Cuánto cura si tiene acción de curar.

## Texto que dice al reclutarse.
@export var recruit_text: String = "Te acompaño, soldado."
## Texto de muerte del compañero.
@export var death_text: String = "No puede seguir..."
## Flag que se necesita para reclutarlo (ej: "found_cabo").
@export var recruit_flag: String = ""
## Flag que se marca al reclutarlo.
@export var recruited_flag: String = ""

## Habilidades especiales del compañero.
@export var can_heal: bool = false
@export var can_scout: bool = false  ## Detecta enemigos/tesoros ocultos.
@export var can_force: bool = false  ## Ayuda a forzar puertas (+mod al dado).
