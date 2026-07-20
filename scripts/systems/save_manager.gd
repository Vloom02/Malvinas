class_name SaveManager
## Guarda y carga partida con validación de datos.
## Protege contra archivos de guardado corruptos o manipulados.

const SAVE_PATH := "user://save.json"

## Claves válidas y sus tipos esperados.
const VALID_KEYS := {
	"scene": TYPE_STRING,
	"hp": TYPE_INT, "hunger": TYPE_INT, "sanity": TYPE_INT,
	"bleeding": TYPE_INT, "cold": TYPE_INT, "infection": TYPE_INT,
	"poison": TYPE_INT, "paralysis": TYPE_INT, "blind": TYPE_INT,
	"money": TYPE_INT, "inventory": TYPE_DICTIONARY, "flags": TYPE_DICTIONARY,
	"parts": TYPE_DICTIONARY, "danger": TYPE_INT, "journal": TYPE_ARRAY,
	"game_mode": TYPE_STRING, "ambient_light": TYPE_INT,
	"time_hours": TYPE_FLOAT, "trench_foot": TYPE_INT,
	"day": TYPE_INT, "reputation": TYPE_INT,
	"light_battery": TYPE_FLOAT, "camera_zoom": TYPE_FLOAT,
	"linterna_on": TYPE_BOOL,
	"weapon_id": TYPE_STRING, "skill_mods": TYPE_DICTIONARY,
	"bonus_hp": TYPE_INT, "consequences": TYPE_DICTIONARY,
	"current_level": TYPE_INT, "current_zone": TYPE_STRING,
	"companion": TYPE_STRING, "companion_hp": TYPE_INT, "companion_hp_max": TYPE_INT,
	"concussion": TYPE_INT, "shell_shock": TYPE_INT, "burns": TYPE_INT,
	"wound_infection": TYPE_INT, "artillery_used": TYPE_BOOL,
	"weapon_states": TYPE_DICTIONARY,
}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(data: Dictionary) -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: No se pudo escribir en %s" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

func load_game() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var raw = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(raw) != TYPE_DICTIONARY:
		push_warning("SaveManager: Archivo de guardado corrupto (no es diccionario)")
		return {}
	return _validate(raw)

func _validate(data: Dictionary) -> Dictionary:
	var clean := {}
	for key in VALID_KEYS.keys():
		if not data.has(key):
			continue
		var expected_type: int = VALID_KEYS[key]
		var val = data[key]
		if typeof(val) == expected_type:
			clean[key] = val
		else:
			# Intentar conversión segura
			match expected_type:
				TYPE_INT:
					if val is float or val is int:
						clean[key] = int(val)
				TYPE_FLOAT:
					if val is float or val is int:
						clean[key] = float(val)
				TYPE_STRING:
					clean[key] = str(val)
				TYPE_DICTIONARY:
					if val is Dictionary:
						clean[key] = val
				TYPE_ARRAY:
					if val is Array:
						clean[key] = val
	return clean

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
