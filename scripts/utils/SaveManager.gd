extends Node
class_name AppSaveManager

const SAVE_FILE = "user://savegame.save"

static func save_game(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
		AppLogger.info("Jogo salvo com sucesso em " + SAVE_FILE)
	else:
		AppLogger.error("Falha ao abrir arquivo de save para gravação.")

static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		AppLogger.info("Nenhum save encontrado. Iniciando novo jogo.")
		return {}
		
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			AppLogger.info("Save carregado com sucesso.")
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				return data as Dictionary
		
		AppLogger.error("Save corrompido ou formato inválido.")
	else:
		AppLogger.error("Falha ao abrir arquivo de save para leitura.")
		
	return {}
