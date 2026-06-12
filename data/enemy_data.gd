@tool
extends Resource
class_name EnemyData
## Recurso de datos de un enemigo. Esto es DATA pura, no lógica.
##
## Por qué importa para el trabajo en equipo: definir los stats de cada
## enemigo en un .tres separado (en vez de hardcodearlos en una escena)
## hace que un diseñador pueda balancear sin tocar escenas ni código.
## Dos personas pueden editar dos enemigos distintos sin conflictos de Git.
##
## Cada enemigo del juego es un archivo data/enemies/<nombre>.tres

@export var display_name: String = "Enemigo"
@export var sprite: Texture2D

## Partes del cuerpo atacables, estilo Fear & Hunger.
## Clave = nombre de la parte, valor = HP de esa parte.
@export var body_parts: Dictionary = {
	"cabeza": 20,
	"torso": 40,
	"brazo_izq": 15,
	"brazo_der": 15,
	"pierna_izq": 15,
	"pierna_der": 15,
}

@export var attack: int = 8
@export var defense: int = 2

## Items que puede soltar al morir (ids que resuelve el sistema de loot).
@export var loot_table: Array[String] = []

## --- Jefe / poderes (el dado se usa para ESQUIVARLOS) ---
@export var is_boss: bool = false
## Nombre del poder especial (vacío = no tiene).
@export var power_name: String = ""
## Daño si NO lo esquivás.
@export var power_damage: int = 20
## Dificultad de la tirada para esquivar (DC).
@export var power_dc: int = 12
## Probabilidad de que el jefe use el poder en su turno (0.0 a 1.0).
@export var power_chance: float = 0.4
