extends Control

@onready var economy_manager = $EconomyManager
@onready var label_discursos = $UI/TopBar/LabelDiscursos
@onready var label_prestige = $UI/TopBar/LabelPrestige
@onready var tug_of_war_bar = $UI/TugOfWarBar
@onready var btn_generate = $UI/CenterArea/BtnGenerate
@onready var upgrades_list = $UI/UpgradesScroll/UpgradesList
@onready var floating_texts = $FloatingTexts
@onready var btn_urgent_news = $BtnUrgentNews
@onready var end_game_panel = $EndGamePanel
@onready var label_result = $EndGamePanel/VBoxContainer/LabelResult

var global_score_red: float = 50.0
var global_score_blue: float = 50.0
var game_active: bool = true
var enemy_timer: Timer
var news_timer: Timer

var llm_client: Node = null
var is_llm_thinking: bool = false
var last_generated_speech: String = ""
var llm_error_message: String = ""

func _ready() -> void:
	# Programação Defensiva: Asserts para garantir que a UI não foi corrompida
	assert(economy_manager != null, "EconomyManager node is missing!")
	assert(label_discursos != null, "LabelDiscursos node is missing!")
	assert(tug_of_war_bar != null, "TugOfWarBar node is missing!")
	assert(btn_generate != null, "BtnGenerate node is missing!")
	assert(upgrades_list != null, "UpgradesList node is missing!")
	
	AppLogger.info("Game.gd _ready() inicializado com sucesso.")
	
	economy_manager.discursos_changed.connect(_on_discursos_changed)
	economy_manager.dps_changed.connect(_on_dps_changed)
	economy_manager.prestige_changed.connect(_on_prestige_changed)
	
	_build_upgrades_ui()
	_update_ui()
	
	enemy_timer = Timer.new()
	enemy_timer.wait_time = 1.0
	enemy_timer.autostart = true
	enemy_timer.timeout.connect(_simulate_enemy_faction)
	add_child(enemy_timer)
	
	news_timer = Timer.new()
	news_timer.wait_time = randf_range(20.0, 40.0)
	news_timer.one_shot = true
	news_timer.timeout.connect(_spawn_urgent_news)
	add_child(news_timer)
	news_timer.start()

	if has_node("LocalLLMClient"):
		llm_client = get_node("LocalLLMClient")
		_connect_llm_client()

func _process(_delta: float) -> void:
	if not game_active:
		return
	
	if upgrades_list.get_child_count() != economy_manager.upgrades.size():
		AppLogger.warning("Número de botões de upgrade não bate com os dados da economia!")
		return
		
	for i in range(economy_manager.upgrades.size()):
		var btn = upgrades_list.get_child(i) as Button
		if btn == null: continue
		
		var upg = economy_manager.upgrades[i]
		var cost = economy_manager.get_upgrade_cost(i)
		btn.text = "%s (Nível %d)\nCusto: %d | Gera: %.1f/s" % [upg.name, upg.count, cost, upg.dps]
		btn.disabled = not economy_manager.can_afford_upgrade(i)

func _build_upgrades_ui() -> void:
	for child in upgrades_list.get_children():
		child.queue_free()
		
	for i in range(economy_manager.upgrades.size()):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 100)
		btn.add_theme_font_size_override("font_size", 24)
		# Atenção: Passando variável por cópia via bind/função lambda protegida
		btn.pressed.connect(func(): _on_upgrade_pressed(i))
		upgrades_list.add_child(btn)

func _on_btn_generate_pressed() -> void:
	if not game_active: 
		AppLogger.warning("Tentativa de clique de geração após game over.")
		return
	
	economy_manager.add_discursos(1.0)
	global_score_red += 0.2
	_update_tug_of_war()
	_animate_button(btn_generate)
	_spawn_floating_text("+%.1f" % economy_manager.prestige_multiplier)

func _on_upgrade_pressed(index: int) -> void:
	if not game_active: return
	if economy_manager.buy_upgrade(index):
		_update_ui()

func _on_discursos_changed(amount: float) -> void:
	if not game_active: return
	if economy_manager.discursos_por_segundo > 0.0:
		global_score_red += (economy_manager.discursos_por_segundo * get_process_delta_time()) * 0.05
		_update_tug_of_war()
	_update_ui()

func _on_dps_changed(_new_dps: float) -> void:
	pass

func _on_prestige_changed(mult: float) -> void:
	if label_prestige != null:
		label_prestige.text = "Multiplicador de Fanatismo: %.1fx" % mult

func _update_ui() -> void:
	if label_discursos != null and economy_manager != null:
		label_discursos.text = "Discursos Gerados: %d\n(%.1f /s)" % [floor(economy_manager.discursos), economy_manager.discursos_por_segundo]

func _simulate_enemy_faction() -> void:
	if not game_active: return
	
	var enemy_power: float = 0.5 + (economy_manager.discursos_por_segundo * 0.04)
	global_score_blue += enemy_power
	_update_tug_of_war()

func _update_tug_of_war() -> void:
	var total: float = global_score_red + global_score_blue
	if total <= 0.0:
		AppLogger.error("Divisão por zero prevenida no cálculo de Tug Of War!")
		return
		
	var red_percent: float = (global_score_red / total) * 100.0
	
	if tug_of_war_bar != null:
		tug_of_war_bar.value = red_percent
		
	# Win/Lose condition
	if red_percent >= 99.9:
		_end_game(true)
	elif red_percent <= 0.1:
		_end_game(false)

func _end_game(player_won: bool) -> void:
	if not game_active: return # Evitar múltiplos disparos
	
	AppLogger.info("Fim de Jogo. Jogador Venceu? " + str(player_won))
	game_active = false
	
	if end_game_panel != null and label_result != null:
		end_game_panel.show()
		if player_won:
			label_result.text = "VITÓRIA!\nVocê calou a oposição!"
			label_result.add_theme_color_override("font_color", Color(0, 1, 0))
		else:
			label_result.text = "DERROTA!\nEles dominaram a narrativa."
			label_result.add_theme_color_override("font_color", Color(1, 0, 0))

func _on_btn_restart_pressed() -> void:
	AppLogger.info("Reiniciando mandato...")
	if end_game_panel != null:
		end_game_panel.hide()
		
	global_score_red = 50.0
	global_score_blue = 50.0
	economy_manager.reset_for_prestige()
	game_active = true
	
	if news_timer != null:
		news_timer.start()

# --- SISTEMAS ADICIONAIS ---

func _animate_button(btn: BaseButton) -> void:
	if btn == null: return
	var tween = create_tween()
	if tween == null: return # Validação extra
	
	btn.scale = Vector2(0.9, 0.9)
	btn.pivot_offset = btn.size / 2
	tween.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BOUNCE)

func _spawn_floating_text(text_val: String) -> void:
	if floating_texts == null: return
	
	var lbl = Label.new()
	lbl.text = text_val
	lbl.add_theme_color_override("font_color", Color(1, 1, 0))
	lbl.add_theme_font_size_override("font_size", 32)
	
	var mouse_pos = get_global_mouse_position()
	lbl.global_position = mouse_pos + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	floating_texts.add_child(lbl)
	
	var tween = create_tween()
	if tween:
		tween.tween_property(lbl, "global_position", lbl.global_position + Vector2(0, -100), 0.5)
		tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
		tween.tween_callback(lbl.queue_free)
	else:
		lbl.queue_free() # Fallback se o tween falhar

func _spawn_urgent_news() -> void:
	if not game_active or btn_urgent_news == null or news_timer == null: 
		return
	
	# Evitar UI exceptions de posições negativas
	var max_x = max(100.0, size.x - 400.0)
	var max_y = max(200.0, size.y - 200.0)
	
	btn_urgent_news.global_position = Vector2(randf_range(50, max_x), randf_range(200, max_y))
	btn_urgent_news.show()
	
	var tween = create_tween()
	if tween:
		tween.tween_property(btn_urgent_news, "modulate:a", 0.0, 3.0)
		tween.tween_callback(func():
			if btn_urgent_news != null:
				btn_urgent_news.hide()
				btn_urgent_news.modulate.a = 1.0
			if news_timer != null:
				news_timer.wait_time = randf_range(20.0, 40.0)
				news_timer.start()
		)

func _on_btn_urgent_news_pressed() -> void:
	if btn_urgent_news != null:
		btn_urgent_news.hide()
		btn_urgent_news.modulate.a = 1.0
	
	var bonus: float = max(100.0, economy_manager.discursos_por_segundo * 30.0)
	economy_manager.add_discursos(bonus)
	_spawn_floating_text("FAKE NEWS! +%d" % int(bonus))
	AppLogger.info("Notícia urgente clicada. Bônus ganho: %f" % bonus)
	
	# Disparar a IA para gerar o texto da Fake News
	generate_speech("Fake News Escandalosa", "Crie uma manchete sensacionalista e humorística curtíssima de 1 linha sobre a oposição.")
	
	if news_timer != null:
		news_timer.wait_time = randf_range(20.0, 40.0)
		news_timer.start()

func _connect_llm_client() -> void:
	if llm_client != null:
		if not llm_client.speech_generated.is_connected(_on_speech_generated):
			llm_client.speech_generated.connect(_on_speech_generated)
		if not llm_client.generation_failed.is_connected(_on_speech_generation_failed):
			llm_client.generation_failed.connect(_on_speech_generation_failed)

func generate_speech(topic: String, prompt: String) -> void:
	if not game_active: return
	if llm_client == null:
		AppLogger.warning("LLM Client não configurado.")
		return
	is_llm_thinking = true
	llm_error_message = ""
	llm_client.generate_speech_async(topic, prompt)

func _on_speech_generated(text: String) -> void:
	is_llm_thinking = false
	last_generated_speech = text
	economy_manager.add_discursos(50.0)
	_spawn_floating_text("Speech: " + text.left(15) + "...")

func _on_speech_generation_failed(error_msg: String) -> void:
	is_llm_thinking = false
	llm_error_message = error_msg
	AppLogger.error("LLM Error: " + error_msg)
	_spawn_floating_text("Falha na IA: " + error_msg)
