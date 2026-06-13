extends Area2D
class_name Hazard
## Peligro ambiental que MARCA EL CUERPO. Al pisarlo, tirás un dado (save) para
## resistirlo; si fallás, sufrís el efecto (sangrado o frío). Junta los pilares:
## dado (save) + cuerpo (estado) + diegético (la pantalla/el sprite reaccionan).

## Tipo de efecto si fallás: "bleed" (sangrado) o "cold" (hipotermia).
@export var effect: String = "bleed"
## Texto que sale al pisarlo.
@export var message: String = "¡Alambre de púas!"
## Etiqueta de la tirada (Reflejos, Resistencia...).
@export var save_label: String = "Reflejos"
## Cuánto sangrado agrega si fallás (effect = "bleed").
@export var bleed_stacks: int = 2
## Cuánto frío agrega si fallás (effect = "cold").
@export var cold_amount: int = 30
## Dificultad de la tirada para resistir (DC).
@export var save_dc: int = 12
## Modificador del jugador en la tirada.
@export var save_mod: int = 2
## Si es true, se gasta tras dispararse una vez.
@export var one_shot: bool = true

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used and one_shot:
		return
	if not body.is_in_group("player"):
		return
	_used = true

	var r := Dice.check(save_mod, save_dc)
	var text := "%s\n\n%s: [ d20 %d + %d = %d ]  vs  %d" % [
		message, save_label, r["die"], r["modifier"], r["total"], save_dc]

	if r["success"]:
		if r["crit"]:
			text += "\n¡Crítico! Lo sorteás sin un rasguño."
		else:
			text += "\nLo resistís. Sin daño."
	else:
		_apply_effect()
		if r["fumble"]:
			text += "\n¡Pifia!"
		text += "\n" + _fail_text()

	Dialogue.say(text)

func _apply_effect() -> void:
	match effect:
		"cold":
			GameState.cold = clampi(GameState.cold + cold_amount, 0, 100)
			GameState.body_changed.emit()
		_:
			GameState.apply_bleeding(bleed_stacks)

func _fail_text() -> String:
	match effect:
		"cold":
			return "El agua helada te cala los huesos. El FRÍO se te mete adentro."
		_:
			return "Te clavás las púas: empezás a SANGRAR."
