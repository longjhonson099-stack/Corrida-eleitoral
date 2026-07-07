extends Control

var votes_label: Label
var funds_label: Label
var cargo_label: Label
var influencia_bar: ProgressBar

func _ready() -> void:
	# Configurar a tela do Hub
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	var bg = TextureRect.new()
	bg.texture = load("res://assets/backgrounds/main_menu_bg.jpg")
	if bg.texture == null: # Fallback case
		var rect = ColorRect.new()
		rect.color = Color(0.1, 0.2, 0.4)
		rect.anchor_right = 1.0
		rect.anchor_bottom = 1.0
		add_child(rect)
	else:
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		add_child(bg)
		
	# UI Superior: Moedas
	var top_panel = Panel.new()
	top_panel.custom_minimum_size = Vector2(0, 80)
	top_panel.anchor_right = 1.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	top_panel.add_theme_stylebox_override("panel", style)
	add_child(top_panel)
	
	var hbox = HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 50)
	top_panel.add_child(hbox)
	
	var vbox_influencia = VBoxContainer.new()
	vbox_influencia.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_influencia)
	
	cargo_label = Label.new()
	cargo_label.add_theme_font_size_override("font_size", 24)
	cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_influencia.add_child(cargo_label)
	
	influencia_bar = ProgressBar.new()
	influencia_bar.custom_minimum_size = Vector2(300, 25)
	influencia_bar.show_percentage = true
	vbox_influencia.add_child(influencia_bar)
	
	var vbox_moedas = VBoxContainer.new()
	vbox_moedas.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox_moedas)
	
	votes_label = Label.new()
	votes_label.add_theme_font_size_override("font_size", 28)
	vbox_moedas.add_child(votes_label)
	
	funds_label = Label.new()
	funds_label.add_theme_font_size_override("font_size", 28)
	vbox_moedas.add_child(funds_label)
	
	update_currencies()
	
	# Botões Principais
	var main_vbox = VBoxContainer.new()
	main_vbox.anchor_left = 0.5
	main_vbox.anchor_top = 0.5
	main_vbox.anchor_right = 0.5
	main_vbox.anchor_bottom = 0.5
	main_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	main_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	main_vbox.add_theme_constant_override("separation", 30)
	add_child(main_vbox)
	
	var title = Label.new()
	title.text = "MAPA DA CIDADE"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)
	
	var btn_campaign = TextureButton.new()
	var img_camp = Image.new()
	if img_camp.load("res://assets/ui/btn_campaign.jpg") == OK:
		btn_campaign.texture_normal = ImageTexture.create_from_image(img_camp)
		btn_campaign.ignore_texture_size = true
		btn_campaign.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		btn_campaign = Button.new() # type casting fallback workaround
		btn_campaign.text = "ENTRAR EM CAMPANHA"
		btn_campaign.add_theme_font_size_override("font_size", 36)
	btn_campaign.custom_minimum_size = Vector2(400, 100)
	btn_campaign.pressed.connect(_on_campaign_pressed)
	main_vbox.add_child(btn_campaign)
	
	var btn_multi = TextureButton.new()
	var img_multi = Image.new()
	if img_multi.load("res://assets/ui/btn_multiplayer.jpg") == OK:
		btn_multi.texture_normal = ImageTexture.create_from_image(img_multi)
		btn_multi.ignore_texture_size = true
		btn_multi.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		btn_multi = Button.new()
		btn_multi.text = "MULTIPLAYER (Em breve)"
		btn_multi.add_theme_font_size_override("font_size", 36)
	btn_multi.custom_minimum_size = Vector2(400, 100)
	btn_multi.pressed.connect(func(): pass) # Placeholder
	main_vbox.add_child(btn_multi)
	
	var btn_free = TextureButton.new()
	var img_free = Image.new()
	if img_free.load("res://assets/ui/btn_freeplay.jpg") == OK:
		btn_free.texture_normal = ImageTexture.create_from_image(img_free)
		btn_free.ignore_texture_size = true
		btn_free.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		btn_free = Button.new()
		btn_free.text = "MODO LIVRE / TREINO"
		btn_free.add_theme_font_size_override("font_size", 36)
	btn_free.custom_minimum_size = Vector2(400, 100)
	btn_free.pressed.connect(func(): pass) # Placeholder
	main_vbox.add_child(btn_free)
	
	var btn_hq = Button.new()
	btn_hq.text = "SEDE DE CAMPANHA (Upgrades)"
	btn_hq.custom_minimum_size = Vector2(400, 100)
	btn_hq.add_theme_font_size_override("font_size", 36)
	btn_hq.pressed.connect(_on_hq_pressed)
	main_vbox.add_child(btn_hq)
	
	var btn_shop = Button.new()
	btn_shop.text = "LOJA (Mercado Negro)"
	btn_shop.custom_minimum_size = Vector2(400, 100)
	btn_shop.add_theme_font_size_override("font_size", 36)
	btn_shop.pressed.connect(_on_shop_pressed)
	main_vbox.add_child(btn_shop)
	
	var btn_pass = Button.new()
	btn_pass.text = "PASSE ELEITORAL"
	btn_pass.custom_minimum_size = Vector2(400, 100)
	btn_pass.add_theme_font_size_override("font_size", 36)
	btn_pass.pressed.connect(_on_pass_pressed)
	main_vbox.add_child(btn_pass)
	
	var btn_team = Button.new()
	btn_team.text = "EQUIPE DE CAMPANHA (Talentos)"
	btn_team.custom_minimum_size = Vector2(400, 100)
	btn_team.add_theme_font_size_override("font_size", 36)
	btn_team.pressed.connect(_on_team_pressed)
	main_vbox.add_child(btn_team)
	
func update_currencies() -> void:
	if GameManager:
		votes_label.text = "Votos: " + str(GameManager.votos_soft_currency)
		funds_label.text = "Fundos: $" + str(GameManager.fundos_hard_currency)
		
		var cargo = GameManager.get_cargo()
		var inf = GameManager.influencia
		var next_goal = GameManager.get_next_cargo_goal()
		
		cargo_label.text = cargo + " (" + str(inf) + " / " + str(next_goal) + " Influência)"
		influencia_bar.max_value = next_goal
		influencia_bar.value = inf

func _on_campaign_pressed() -> void:
	GameManager.is_campaign = true
	GameManager.setup_campaign_match()
	get_tree().change_scene_to_file("res://scenes/hub/CharacterSelection.tscn")

func _on_hq_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/CampaignHQ.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/Shop.tscn")

func _on_pass_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/SeasonPass.tscn")

func _on_team_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/TeamTalents.tscn")
