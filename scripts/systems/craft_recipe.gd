@tool
extends Resource
class_name CraftRecipe

@export var result_id: String = ""
@export var result_name: String = "Item"
@export var result_qty: int = 1
@export var ingredients: Dictionary = {}
