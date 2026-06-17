@tool
extends Resource
class_name WeaponData
## Datos de un arma (data pura). Cada arma es un .tres en data/items/.
## Las armas se encuentran dropeadas o en el mundo, NO se compran.

@export var id: String = "arma"
@export var display_name: String = "Arma"
@export var description: String = ""
@export var sprite: Texture2D

## Daño base del arma.
@export var damage: int = 10
## Modificador al dado de PULSO (mejora el pulso del jugador).
@export var pulse_mod: int = 0
## Modificador al dado de ESQUIVAR.
@export var dodge_mod: int = 0
## Modificador a tiradas de fuerza (forzar puertas, etc).
@export var force_mod: int = 0
## Modificador a tiradas de percepción (buscar items, etc).
@export var perception_mod: int = 0

## Tipo de arma: "cuchillo", "fusil", "palo", "hacha", etc.
@export var weapon_type: String = "cuchillo"
## Si es de una sola mano (permite usar otra cosa).
@export var one_handed: bool = true
## Peso (inventario tiene límite de peso opcional).
@export var weight: int = 1

## Texto especial al atacar con esta arma.
@export var attack_text: String = ""
## Texto al encontrar el arma.
@export var find_text: String = "Encontrás: %s"

## Efecto de estado que aplica al golpear (vacío = ninguno).
## Valores: "bleed", "burn", "stun", "poison".
@export var status_effect: String = ""
## Probabilidad de aplicar el efecto (0.0 a 1.0).
@export var status_chance: float = 0.0
