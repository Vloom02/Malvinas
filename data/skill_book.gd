@tool
extends Resource
class_name SkillBook
## Libro/informe que desbloquea una habilidad al leerlo.
## Los personajes aprenden de informes, no de XP.
## Cada libro es un .tres en data/items/.

@export var id: String = "libro"
@export var display_name: String = "Informe"
@export var description: String = ""
@export var sprite: Texture2D

## Tipo de habilidad que desbloquea.
enum SkillType {
	MOD_PULSE,      ## +mod al dado de pulso
	MOD_DODGE,      ## +mod al dado de esquivar
	MOD_FORCE,      ## +mod a tiradas de fuerza
	MOD_PERCEPTION, ## +mod a tiradas de percepción
	MOD_STEALTH,    ## +mod a tiradas de sigilo
	BONUS_HP,       ## +HP máximo permanente
	BONUS_DAMAGE,   ## +daño base permanente
	SPECIAL,        ## habilidad especial (text custom)
}
@export var skill_type: SkillType = SkillType.MOD_PULSE
## Cuánto suma al mod (o cuánto HP bonus, etc).
@export var skill_value: int = 1
## Texto que se muestra al leer el libro.
@export var read_text: String = "Leés el informe. Algo se te queda grabado."
## Flag que se marca al leerlo (para no re-leer).
@export var read_flag: String = ""
