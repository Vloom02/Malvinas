extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var list: VBoxContainer = $Panel/Scroll/List
@onready var info: Label = $Panel/Info
@onready var cerrar_btn: Button = $Panel/CerrarBtn

func _ready() -> void:
	visible = false
	cerrar_btn.pressed.connect(_close)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("inventory") or event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()

func _close() -> void:
	visible = false
	get_tree().paused = false

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	var avail := GameState.get_available_recipes()
	if avail.is_empty():
		var l := Label.new()
		l.text = "(No tenés los materiales para craftear nada.)"
		list.add_child(l)
		info.text = ""
		return
	for recipe in avail:
		var ingredients_text := ""
		var first := true
		for ing_id in recipe.ingredients.keys():
			var item: ItemData = GameState.items_by_id.get(str(ing_id))
			if not first:
				ingredients_text += ", "
			first = false
			if item != null:
				ingredients_text += "%s x%d" % [item.display_name, recipe.ingredients[ing_id]]
			else:
				ingredients_text += "%s x%d" % [ing_id, recipe.ingredients[ing_id]]
		var b := Button.new()
		b.text = "%s  ←  %s" % [recipe.result_name, ingredients_text]
		b.pressed.connect(_craft.bind(recipe))
		list.add_child(b)

func _craft(recipe: CraftRecipe) -> void:
	if GameState.craft(recipe):
		_refresh()
		info.text = "Crafteaste: %s." % recipe.result_name
	else:
		info.text = "No tenés los materiales."
