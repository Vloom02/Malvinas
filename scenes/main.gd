extends Node2D
## Escena raíz de arranque. Por ahora solo prueba que todo el andamiaje
## funciona: arranca una partida nueva y conecta las señales del enemigo
## y del estado global para imprimir en consola.
##
## Cuando crezca, esta escena va a cargar el menú principal o el primer mapa.

@onready var enemy: Enemy = $Enemy

func _ready() -> void:
	GameState.new_game()
	GameState.hunger_changed.connect(_on_hunger_changed)
	GameState.player_died.connect(func(): print("[GameState] El jugador murió de hambre."))

	if enemy:
		enemy.part_destroyed.connect(func(p): print("[Combate] Parte destruida: %s" % p))
		enemy.died.connect(func(): print("[Combate] El enemigo cayó."))

		print("[Test] Golpeo la cabeza del enemigo...")
		enemy.take_damage("cabeza", 25)

	print("[Test] Camino 5 pasos (baja el hambre)...")
	for i in 5:
		GameState.spend_step()

func _on_hunger_changed(value: int) -> void:
	print("[GameState] Hambre: %d/%d" % [value, GameState.HUNGER_MAX])
