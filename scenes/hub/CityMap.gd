extends Control

var votes_label: Label
var funds_label: Label

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
	
	votes_label = Label.new()
	votes_label.add_theme_font_size_override("font_size", 32)
	hbox.add_child(votes_label)
	
	funds_label = Label.new()
	funds_label.add_theme_font_size_override("font_size", 32)
	hbox.add_child(funds_label)
	
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
	
	var btn_campaign = Button.new()
	btn_campaign.text = "ENTRAR EM CAMPANHA"
	btn_campaign.custom_minimum_size = Vector2(400, 100)
	btn_campaign.add_theme_font_size_override("font_size", 36)
	btn_campaign.pressed.connect(_on_campaign_pressed)
	main_vbox.add_child(btn_campaign)
	
	var btn_hq = Button.new()
	btn_hq.text = "SEDE DE CAMPANHA (Upgrades)"
	btn_hq.custom_minimum_size = Vector2(400, 100)
	btn_hq.add_theme_font_size_override("font_size", 36)
	btn_hq.pressed.connect(_on_hq_pressed)
	main_vbox.add_child(btn_hq)
	
func update_currencies() -> void:
	if GameManager:
		votes_label.text = "Votos: " + str(GameManager.votos_soft_currency)
		funds_label.text = "Fundos: $" + str(GameManager.fundos_hard_currency)

func _on_campaign_pressed() -> void:
	GameManager.is_campaign = true
	GameManager.setup_campaign_match()
	get_tree().change_scene_to_file("res://scenes/worms/WormsLevel.tscn")

func _on_hq_pressed() -> void:
	print("Abrindo Sede de Campanha... (Em breve)")
