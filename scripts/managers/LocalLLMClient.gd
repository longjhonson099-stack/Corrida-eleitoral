extends Node
class_name LocalLLMClient

signal speech_generated(text: String)
signal generation_failed(error_msg: String)

var http_request: HTTPRequest
var url: String = "http://127.0.0.1:11434/api/chat" # Atualizado para API de Chat do Ollama
var model: String = "llama3"

# Persistindo a conversa (Diretriz: "Persist conversations across scenes")
var conversation_history: Array = []

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# System prompt pre-carregado
	conversation_history.append({
		"role": "system",
		"content": "Você é um político satírico no universo do jogo 'Corrida Eleitoral'. Mantenha o contexto do debate. Responda sempre com uma frase muito curta e ácida, como uma provocação."
	})

func generate_speech_async(speaker_name: String, action_prompt: String) -> void:
	# Adiciona a ação do turno atual na história
	var user_msg = "O candidato " + speaker_name + " " + action_prompt + ". O que ele grita ao atacar?"
	conversation_history.append({
		"role": "user",
		"content": user_msg
	})
	
	var data = {
		"model": model,
		"messages": conversation_history,
		"stream": false
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		generation_failed.emit("Falha ao iniciar requisição HTTP.")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		generation_failed.emit("Erro na requisição. Código: " + str(response_code))
		return
		
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		generation_failed.emit("Falha no parse do JSON de resposta.")
		return
		
	var response = json.data
	if typeof(response) == TYPE_DICTIONARY and response.has("message"):
		var text_response = response["message"]["content"]
		# Adiciona a resposta do assistente (personagem) ao histórico
		conversation_history.append({
			"role": "assistant",
			"content": text_response
		})
		speech_generated.emit(text_response)
	else:
		generation_failed.emit("Formato de resposta inválido do LLM.")
