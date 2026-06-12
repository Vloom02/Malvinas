extends Node
## Sistema de dados estilo D&D. Autoload global "Dice".
## TODO el RNG del juego pasa por acá: acertar, esquivar, resistir infección, etc.
## En vez de números fijos, las acciones se resuelven tirando dados.

## Se emite en cada chequeo, para que la UI/efectos puedan reaccionar (animar el dado).
signal rolled(result: Dictionary)

func _ready() -> void:
	randomize() # semilla aleatoria distinta cada partida

## Tira UN dado de `sides` caras. d6 = roll(6), d20 = roll(20).
func roll(sides: int = 20) -> int:
	return randi_range(1, sides)

## Tira `count` dados de `sides` y devuelve la suma. Ej: 2d6 = roll_n(2, 6).
func roll_n(count: int, sides: int = 6) -> int:
	var total := 0
	for i in count:
		total += roll(sides)
	return total

## Chequeo estilo D&D: d20 + modificador contra una dificultad (DC).
## advantage:  1 = ventaja (tira 2d20 y toma el mayor)
##            -1 = desventaja (toma el menor)
##             0 = normal
## Devuelve un diccionario con el detalle (usar con r["die"], r["success"], etc.).
func check(modifier: int = 0, dc: int = 10, advantage: int = 0) -> Dictionary:
	var first := roll(20)
	var die := first
	if advantage > 0:
		die = maxi(first, roll(20))
	elif advantage < 0:
		die = mini(first, roll(20))

	var total := die + modifier
	var success := total >= dc
	var crit := die == 20   # 20 natural = éxito crítico
	var fumble := die == 1  # 1 natural = pifia

	if crit:
		success = true   # el crítico siempre acierta
	elif fumble:
		success = false  # la pifia siempre falla

	var result := {
		"die": die,
		"modifier": modifier,
		"total": total,
		"dc": dc,
		"success": success,
		"crit": crit,
		"fumble": fumble,
	}
	rolled.emit(result)
	return result

## Probabilidad simple: devuelve true con probabilidad `probability` (0.0 a 1.0).
func chance(probability: float) -> bool:
	return randf() < probability

## Tirada ENFRENTADA: vos y el enemigo tiran un d20 cada uno (totalmente
## aleatorio para los dos) + su modificador. Devuelve quién ganó el intercambio.
## La usa el "ataque arriesgado": ni vos ni el enemigo saben qué va a salir.
func versus(player_mod: int = 0, enemy_mod: int = 0) -> Dictionary:
	var player_die := roll(20)
	var enemy_die := roll(20)
	var player_total := player_die + player_mod
	var enemy_total := enemy_die + enemy_mod
	var result := {
		"player_die": player_die,
		"player_total": player_total,
		"enemy_die": enemy_die,
		"enemy_total": enemy_total,
		"player_wins": player_total > enemy_total,
		"tie": player_total == enemy_total,
	}
	rolled.emit(result)
	return result
