extends Node
class_name Stealth
## Sistema de sigilo. Permite esquivar enemigos en el mundo sin entrar en
## combate. Usa dados para determinar si te detectan.
##
## Integrado con enemy_encounter: cada enemigo tiene un nivel de consciencia.

## Mod base para sigilo.
const STEALTH_MOD := 3
## DC base para pasar desapercibido.
const STEALTH_DC := 10

## Intenta pasar desapercibido junto a un enemigo.
## Devuelve: { "success": bool, "die": int, "total": int, "dc": int, "text": String }
static func try_stealth(nearby_enemies: Array) -> Dictionary:
	var mod := STEALTH_MOD + GameState.get_stealth_mod()
	# Piernas rotas = más ruido.
	mod -= GameState.broken_legs() * 2
	# Sangrando = más visible.
	if GameState.bleeding > 0:
		mod -= 1
	# Oscuridad = ventaja.
	var light_t := float(GameState.effective_light()) / 100.0
	if light_t < 0.3:
		mod += 2  # en la oscuridad es más fácil esconderse

	var dc := STEALTH_DC
	# Más enemigos = más difícil.
	dc += nearby_enemies.size() * 2

	var r := Dice.check(mod, dc)
	var text := ""
	if r["success"]:
		text = "Te movés entre las sombras... nadie te ve. [d20 %d+%d=%d vs %d]" % [
			r["die"], r["modifier"], r["total"], dc]
	else:
		text = "Pisás un cascarón... ¡te detectan! [d20 %d+%d=%d vs %d]" % [
			r["die"], r["modifier"], r["total"], dc]
		if r["fumble"]:
			text += "\n¡Pifia! Hacés un ruido terrible."

	return {
		"success": r["success"],
		"die": r["die"],
		"total": r["total"],
		"dc": dc,
		"text": text,
		"crit": r["crit"],
		"fumble": r["fumble"],
	}

## Busca en cadáveres/objeto del mundo. Devuelve item o null.
## Tirada de Percepción.
static func search_body(search_dc: int = 10) -> Dictionary:
	var mod := 2
	# Linterna encendida = ventaja.
	if GameState.linterna_on:
		mod += 2
	# Cordura alta = mejor percepción.
	if GameState.sanity > 50:
		mod += 1

	var r := Dice.check(mod, search_dc)
	return {
		"success": r["success"],
		"die": r["die"],
		"total": r["total"],
		"dc": search_dc,
		"crit": r["crit"],
		"fumble": r["fumble"],
	}
