extends Node

var candidates_data: Dictionary = {}
var cards_data: Dictionary = {}

func _ready() -> void:
	load_all_data()

func load_all_data() -> void:
	candidates_data = _load_json_file("res://data/candidates.json")
	cards_data = _load_json_file("res://data/cards.json")

func _load_json_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var err = json.parse(content)
		if err == OK:
			return json.get_data()
		else:
			print("JSON Parse Error in ", file_path, ": ", json.get_error_message())
	else:
		print("Failed to open file: ", file_path)
	return {}

func get_candidate_info(candidate_id: String) -> Dictionary:
	return candidates_data.get(candidate_id, {})

func get_card_info(card_id: String) -> Dictionary:
	return cards_data.get(card_id, {})
