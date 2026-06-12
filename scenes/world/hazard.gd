extends Area2D
class_name Hazard
## Peligro ambiental que MARCA EL CUERPO (pilar de diseño). Ejemplo: una
## enredadera con espinas. Al pisarlo, tirás un dado de reflejos para esquivar;
## si fallás, te cortás y empezás a sangrar (y la pantalla se pone roja).
##
## Junta los tres pilares en una interacción: dado (D&D) + cuerpo (sangrado)
## + estado diegético (la viñeta roja, sin HUD).

## Texto que sale en consola al pisarlo.
@export var message: String = "¡Una enredadera con espinas!"
## Cuánto sangrado agrega si fallás la tirada.
@export var bleed_stacks: int = 2
## Dificultad de la tirada para esquivar (DC, estilo D&D).
@export var dodge_dc: int = 12
## Modificador de reflejos del jugador.
@export var reflex_mod: int = 2
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

	var r := Dice.check(reflex_mod, dodge_dc)
	print("[Peligro] %s  (dado %d + %d = %d  vs  DC %d)" % [
		message, r["die"], r["modifier"], r["total"], r["dc"]])

	if r["success"]:
		if r["crit"]:
			print("[Peligro] ¡CRÍTICO! Saltás la enredadera con elegancia.")
		else:
			print("[Peligro] La esquivás. Sin daño.")
	else:
		GameState.apply_bleeding(bleed_stacks)
		if r["fumble"]:
			print("[Peligro] ¡PIFIA! Te enredás feo y te clavás las espinas.")
		print("[Peligro] Te cortás: empezás a SANGRAR (mirá los bordes en rojo).")
