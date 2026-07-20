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

## Varianza de daño: el daño real varía ±variance.
## 0 = daño fijo, 2 = ±2, 5 = ±5, 10 = ±10, etc.
@export var variance: int = 0

## Carpeta + prefijo del sprite SOSTENIDO en el mundo (sin "_dir.png").
## OBSOLETO: el arma ahora se hornea en el sprite del personaje (character state
## de PixelLab). Se conserva por compatibilidad, pero no se usa para el nuevo
## sistema. Vacío = sin overlay.
@export var held_sprite_base: String = ""

## --- Balística en el mapa (disparo con click izquierdo / F) ---
## Cadencia: segundos entre disparos. Ametralladora ~0.12, escopeta de corredera ~1.0.
@export var fire_cooldown: float = 0.45
## Alcance efectivo en px: hasta acá el daño es completo; más lejos decae lineal
## hasta el alcance máximo del disparo (200 px), donde queda en el 40%.
@export var effective_range: float = 120.0
## Balas que entran en el arma (cargador/tubo/cinta). Recargar (R) consume un
## cargador/cinta LLENO del inventario (la escopeta carga cartuchos sueltos).
@export var mag_size: int = 20

## --- Sistema de confiabilidad / clima (Malvinas: el FAL se trababa en el barro) ---
## Confiabilidad base (0-1): probabilidad de NO trabarse en condiciones ideales.
@export_range(0.0, 1.0) var reliability: float = 0.9
## Cuánto le afecta el barro a la confiabilidad (0 = inmune, 1 = muy sensible).
@export_range(0.0, 1.0) var mud_sensitivity: float = 0.5
## Tipo de munición ("7.62", "9mm", "12.70", "cartucho", ...). Informativo/agrupador.
@export var ammo_type: String = ""

## --- Accesorios / mejoras ---
## Ranuras que acepta esta arma. Valores: optic, bipod, tripod, magazine, sling,
## muzzle, grip, stock, holster, flashlight, ammo_container, shell_holder, slide_mod.
@export var accepted_slots: Array[String] = []
## True si requiere estar prono/apoyado en superficie para disparar (trípode, MAG).
@export var needs_mount: bool = false

## Devuelve true si es un arma de fuego (se puede disparar en el mapa con F).
func is_firearm() -> bool:
	return weapon_type in ["fusil", "pistola", "escopeta", "subfusil", "ametralladora"]
