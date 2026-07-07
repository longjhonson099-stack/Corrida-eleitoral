class_name MainMenu
extends Control

var candidates = [
	{"name": "O Velho Raposa", "sprite": "res://assets/sprites/cand_raposa.png"},
	{"name": "O Lulista", "sprite": "res://assets/sprites/cand_lula.png"},
	{"name": "O Patriota", "sprite": "res://assets/sprites/cand_bolsonaro.png"},
	{"name": "O Juiz", "sprite": "res://assets/sprites/cand_juiz.png"},
	{"name": "O Influencer", "sprite": "res://assets/sprites/cand_influencer.png"},
	{"name": "A Terceira Via", "sprite": "res://assets/sprites/cand_terceiravia.png"},
	{"name": "O Poste", "sprite": "res://assets/sprites/cand_poste.png"},
	{"name": "O Coach", "sprite": "res://assets/sprites/cand_coach.png"},
	{"name": "A Ambiental", "sprite": "res://assets/sprites/cand_ambiental.png"},
	{"name": "O Libertário", "sprite": "res://assets/sprites/cand_libertario.png"}
]

var scenarios = [
	{"name": "Debate na TV", "bg": "res://assets/backgrounds/scenario_tv_debate.jpg"},
	{"name": "Protesto na Paulista", "bg": "res://assets/backgrounds/scenario_protest.jpg"},
	{"name": "Fazenda O Curral", "bg": "res://assets/backgrounds/scenario_fazenda.jpg"},
	{"name": "Bunker do STF", "bg": "res://assets/backgrounds/scenario_bunker_stf.jpg"},
	{"name": "Plenário do Congresso", "bg": "res://assets/backgrounds/scenario_plenario.jpg"},
	{"name": "Esplanada", "bg": "res://assets/backgrounds/scenario_esplanada.jpg"}
]

var p1_selected_idx: int = 0
var p2_selected_idx: int = 1
var map_selected_idx: int = 0

var p1_label: Label
var p2_label: Label
var map_label: Label

var audio_click: AudioStreamPlayer
var faction_popup: Panel
var league_popup: Panel
var tug_of_war_bar: ProgressBar

func _ready() -> void:
	# Audio setup
	audio_click = AudioStreamPlayer.new()
	var snd = AudioStreamWAV.new()
	var file = FileAccess.open("res://assets/audio/click.wav", FileAccess.READ)
	if file:
		snd.data = file.get_buffer(file.get_length())
		snd.format = AudioStreamWAV.FORMAT_16_BITS
		snd.mix_rate = 44100
		audio_click.stream = snd
	add_child(audio_click)

	# Background
	var bg_sprite = TextureRect.new()
	var tex = load("res://assets/backgrounds/main_menu_bg.jpg")
	if tex is Texture2D:
		bg_sprite.texture = tex
	bg_sprite.set_anchors_preset(PRESET_FULL_RECT)
	bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg_sprite)
	
	# We DO NOT use MOUSE_FILTER_STOP overlay here, as it blocks everything.
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	# Main Layout VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_vbox)
	
	var title = Label.new()
	title.text = "CORRIDA ELEITORAL:\nA BATALHA FINAL"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	# Faction Tug of War
	var faction_vbox = VBoxContainer.new()
	faction_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(faction_vbox)
	
	var faction_title = Label.new()
	faction_title.text = "CABO DE GUERRA GLOBAL"
	faction_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faction_vbox.add_child(faction_title)
	
	tug_of_war_bar = ProgressBar.new()
	tug_of_war_bar.custom_minimum_size = Vector2(800, 30)
	tug_of_war_bar.min_value = 0
	tug_of_war_bar.max_value = 100
	tug_of_war_bar.value = 50 # 50% is tie
	# Stying for Tug of War (Red vs Green)
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color.DARK_GREEN
	tug_of_war_bar.add_theme_stylebox_override("background", sb_bg)
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color.DARK_RED
	tug_of_war_bar.add_theme_stylebox_override("fill", sb_fill)
	faction_vbox.add_child(tug_of_war_bar)
	
	# Fetch Global Scores Mock
	_fetch_global_faction_scores()
	
	# Panels HBox
	var panels_hbox = HBoxContainer.new()
	panels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panels_hbox.add_theme_constant_override("separation", 50)
	main_vbox.add_child(panels_hbox)
	
	# P1
	var vbox_p1 = VBoxContainer.new()
	panels_hbox.add_child(vbox_p1)
	
	p1_label = Label.new()
	p1_label.text = "JOGADOR 1:\n" + candidates[p1_selected_idx]["name"]
	p1_label.add_theme_font_size_override("font_size", 24)
	p1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_p1.add_child(p1_label)
	
	var grid_p1 = GridContainer.new()
	grid_p1.columns = 3
	vbox_p1.add_child(grid_p1)
	
	for i in range(candidates.size()):
		var btn = _create_char_btn(candidates[i]["sprite"])
		btn.pressed.connect(_select_p1.bind(i))
		grid_p1.add_child(btn)
		
	# Map
	var vbox_map = VBoxContainer.new()
	panels_hbox.add_child(vbox_map)
	
	map_label = Label.new()
	map_label.text = "CENÁRIO:\n" + scenarios[map_selected_idx]["name"]
	map_label.add_theme_font_size_override("font_size", 24)
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_map.add_child(map_label)
	
	var grid_map = GridContainer.new()
	grid_map.columns = 3
	vbox_map.add_child(grid_map)
	
	for i in range(scenarios.size()):
		var btn = _create_char_btn(scenarios[i]["bg"])
		btn.pressed.connect(_select_map.bind(i))
		grid_map.add_child(btn)
		
	# P2
	var vbox_p2 = VBoxContainer.new()
	panels_hbox.add_child(vbox_p2)
	
	p2_label = Label.new()
	p2_label.text = "OPONENTE (CPU):\n" + candidates[p2_selected_idx]["name"]
	p2_label.add_theme_font_size_override("font_size", 24)
	p2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_p2.add_child(p2_label)
	
	var grid_p2 = GridContainer.new()
	grid_p2.columns = 3
	vbox_p2.add_child(grid_p2)
	
	for i in range(candidates.size()):
		var btn = _create_char_btn(candidates[i]["sprite"])
		btn.pressed.connect(_select_p2.bind(i))
		grid_p2.add_child(btn)
		
	# Buttons HBox
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_vbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(buttons_vbox)
	
	var btn_campaign = Button.new()
	btn_campaign.text = "MODO CAMPANHA"
	btn_campaign.add_theme_font_size_override("font_size", 32)
	btn_campaign.add_theme_color_override("font_color", Color.GOLD)
	btn_campaign.custom_minimum_size = Vector2(400, 50)
	btn_campaign.pressed.connect(_on_campaign_pressed)
	buttons_vbox.add_child(btn_campaign)
	
	var btn_play = Button.new()
	btn_play.text = "JOGO LIVRE"
	btn_play.add_theme_font_size_override("font_size", 32)
	btn_play.add_theme_color_override("font_color", Color.WHITE)
	btn_play.custom_minimum_size = Vector2(400, 50)
	btn_play.pressed.connect(_on_play_pressed.bind(false))
	buttons_vbox.add_child(btn_play)
	
	var btn_treino = Button.new()
	btn_treino.text = "MODO TREINO"
	btn_treino.add_theme_font_size_override("font_size", 32)
	btn_treino.pressed.connect(_on_play_pressed.bind(false)) # Conectado ao Jogo Livre por enquanto
	buttons_vbox.add_child(btn_treino)
	
	var btn_shop = Button.new()
	btn_shop.text = "🛒 MERCADO ELEITORAL (LOJA)"
	btn_shop.add_theme_font_size_override("font_size", 24)
	btn_shop.add_theme_color_override("font_color", Color.CYAN)
	btn_shop.custom_minimum_size = Vector2(400, 50)
	btn_shop.pressed.connect(_on_shop_pressed)
	buttons_vbox.add_child(btn_shop)
	
	# League Selection Popup
	league_popup = Panel.new()
	league_popup.set_anchors_preset(PRESET_CENTER)
	league_popup.position = Vector2(576 - 300, 324 - 200)
	league_popup.size = Vector2(600, 400)
	league_popup.visible = false
	add_child(league_popup)
	
	var lp_vbox = VBoxContainer.new()
	lp_vbox.set_anchors_preset(PRESET_FULL_RECT)
	lp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lp_vbox.add_theme_constant_override("separation", 20)
	league_popup.add_child(lp_vbox)
	
	var lp_title = Label.new()
	lp_title.text = "ESCOLHA SUA LIGA"
	lp_title.add_theme_font_size_override("font_size", 32)
	lp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lp_vbox.add_child(lp_title)
	
	var btn_mun = Button.new()
	btn_mun.text = "1. Eleições Municipais (Fácil)"
	btn_mun.custom_minimum_size = Vector2(400, 50)
	btn_mun.pressed.connect(_start_league.bind("municipal"))
	lp_vbox.add_child(btn_mun)
	
	var btn_pres = Button.new()
	btn_pres.text = "2. Corrida Presidencial (Média)"
	btn_pres.custom_minimum_size = Vector2(400, 50)
	btn_pres.pressed.connect(_start_league.bind("presidencial"))
	lp_vbox.add_child(btn_pres)
	
	var btn_sup = Button.new()
	btn_sup.text = "3. O Juízo Final (Difícil)"
	btn_sup.custom_minimum_size = Vector2(400, 50)
	btn_sup.pressed.connect(_start_league.bind("suprema"))
	lp_vbox.add_child(btn_sup)
	
	var btn_lp_close = Button.new()
	btn_lp_close.text = "VOLTAR"
	btn_lp_close.custom_minimum_size = Vector2(200, 40)
	btn_lp_close.pressed.connect(func(): league_popup.visible = false; audio_click.play())
	lp_vbox.add_child(btn_lp_close)
	
	# Faction Selection Popup
	faction_popup = Panel.new()
	faction_popup.set_anchors_preset(PRESET_CENTER)
	faction_popup.position = Vector2(576 - 300, 324 - 200)
	faction_popup.size = Vector2(600, 400)
	faction_popup.visible = false
	add_child(faction_popup)
	
	var fp_vbox = VBoxContainer.new()
	fp_vbox.set_anchors_preset(PRESET_FULL_RECT)
	fp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	fp_vbox.add_theme_constant_override("separation", 30)
	faction_popup.add_child(fp_vbox)
	
	var fp_title = Label.new()
	fp_title.text = "ESCOLHA SUA FACÇÃO!"
	fp_title.add_theme_font_size_override("font_size", 32)
	fp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_vbox.add_child(fp_title)
	
	var fp_desc = Label.new()
	fp_desc.text = "Sua escolha definirá seu lado no\nCabo de Guerra Global. Escolha com sabedoria!"
	fp_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fp_vbox.add_child(fp_desc)
	
	var fp_hbox = HBoxContainer.new()
	fp_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	fp_hbox.add_theme_constant_override("separation", 50)
	fp_vbox.add_child(fp_hbox)
	
	var btn_red = Button.new()
	btn_red.text = "LADO VERMELHO"
	btn_red.add_theme_color_override("font_color", Color.RED)
	btn_red.custom_minimum_size = Vector2(200, 60)
	btn_red.pressed.connect(_on_faction_chosen.bind("Vermelho"))
	fp_hbox.add_child(btn_red)
	
	var btn_green = Button.new()
	btn_green.text = "LADO VERDE/AMARELO"
	btn_green.add_theme_color_override("font_color", Color.GREEN)
	btn_green.custom_minimum_size = Vector2(200, 60)
	btn_green.pressed.connect(_on_faction_chosen.bind("Verde"))
	fp_hbox.add_child(btn_green)
	
	# Check if player needs to choose faction
	if GameManager and GameManager.player_faction == "":
		faction_popup.visible = true

func _create_char_btn(tex_path: String) -> TextureButton:
	var btn = TextureButton.new()
	var tex = load(tex_path)
	if tex is Texture2D:
		btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(80, 80)
	
	# Background for button
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bg)
	btn.move_child(bg, 0) # behind texture
	
	var border = ReferenceRect.new()
	border.editor_only = false
	border.border_color = Color.GOLD
	border.border_width = 2.0
	border.set_anchors_preset(PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(border)
	
	return btn

func _select_p1(idx: int) -> void:
	audio_click.play()
	p1_selected_idx = idx
	p1_label.text = "JOGADOR 1:\n" + candidates[p1_selected_idx]["name"]

func _select_p2(idx: int) -> void:
	audio_click.play()
	p2_selected_idx = idx
	p2_label.text = "OPONENTE (CPU):\n" + candidates[p2_selected_idx]["name"]

func _select_map(idx: int) -> void:
	audio_click.play()
	map_selected_idx = idx
	map_label.text = "CENÁRIO:\n" + scenarios[map_selected_idx]["name"]

func _on_campaign_pressed() -> void:
	audio_click.play()
	league_popup.visible = true

func _start_league(league_id: String) -> void:
	audio_click.play()
	if GameManager:
		GameManager.current_league = league_id
	_on_play_pressed(true)

func _on_play_pressed(is_campaign: bool) -> void:
	audio_click.play()
	if GameManager:
		GameManager.player1_name = candidates[p1_selected_idx]["name"]
		GameManager.player1_sprite = candidates[p1_selected_idx]["sprite"]
		
		GameManager.player2_name = candidates[p2_selected_idx]["name"]
		GameManager.player2_sprite = candidates[p2_selected_idx]["sprite"]
		
		GameManager.map_bg = scenarios[map_selected_idx]["bg"]
		GameManager.is_campaign = is_campaign
		
	get_tree().change_scene_to_file("res://scenes/worms/WormsLevel.tscn")

func _on_shop_pressed() -> void:
	audio_click.play()
	get_tree().change_scene_to_file("res://scenes/worms/ShopMenu.tscn")

func _on_faction_chosen(faction: String) -> void:
	audio_click.play()
	faction_popup.visible = false
	if GameManager:
		GameManager.player_faction = faction
		GameManager.save_game()

func _fetch_global_faction_scores() -> void:
	# Mock SilentWolf implementation for leaderboard / Tug of War
	# Imagine SilentWolf.Scores.get_scores() is called here
	# For now, we simulate a global score where Red has 4500 and Green has 5500
	var red_score = 4500.0
	var green_score = 5500.0
	var total = red_score + green_score
	if total > 0:
		var red_percentage = (red_score / total) * 100.0
		tug_of_war_bar.value = red_percentage
		tug_of_war_bar.tooltip_text = "Vermelho: %d | Verde: %d" % [int(red_score), int(green_score)]
