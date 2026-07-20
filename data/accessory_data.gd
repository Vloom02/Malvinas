@tool
extends Resource
class_name AccessoryData
## Accesorio/mejora de un arma (data pura). Cada accesorio es un .tres en data/items/.
## Se acopla a un WeaponInstance en una ranura (slot). Solo correa/trípode/mira
## son VISIBLES en el arma; el resto solo afecta stats.

@export var id: String = "accesorio"
@export var display_name: String = "Accesorio"
@export var description: String = ""
@export var sprite: Texture2D

## Ranura que ocupa. Debe coincidir con un valor de WeaponData.accepted_slots.
@export var slot_type: String = "optic"

## True si se ve acoplado en el sprite del arma (solo optic/tripod/sling).
@export var visible: bool = false

## --- Modificadores a los stats del arma ---
@export var damage_mod: int = 0
@export var pulse_mod: int = 0
@export var dodge_mod: int = 0
@export var reliability_mod: float = 0.0
## Modificador de munición por cargador/cinta (informativo, lo usa el sistema de ammo).
@export var ammo_mod: int = 0
## Bonus de pulso extra solo si estás quieto/apoyado (bípode, trípode).
@export var pulse_mod_mounted: int = 0

@export var weight: int = 1
@export var find_text: String = "Encontrás: %s"
