extends Control

var votes_label: Label
var funds_label: Label
var back_btn: Button

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	var bg = TextureRect.new()
	bg.texture = load("res://assets/backgrounds/shop_background.jpg")
	if not bg.texture:
		var rect = ColorRect.new()
		rect.color = Color(0.1, 0.1, 0.2)
		rect.anchor_right = 1.0
		rect.anchor_bottom = 1.0
		add_child(rect)
	else:
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.anchor_right = 1.0
		bg.anchor_bottom = 1.0
		add_child(bg)
		
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	back_btn = Button.new()
	back_btn.text = " Voltar ao Hub "
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	votes_label = Label.new()
	votes_label.add_theme_font_size_override("font_size", 24)
	header.add_child(votes_label)
	
	funds_label = Label.new()
	funds_label.add_theme_font_size_override("font_size", 24)
	header.add_child(funds_label)
	
	# Espaço entre header e loja
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(header_spacer)
	
	var title = Label.new()
	title.text = "MERCADO NEGRO"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var shop_vbox = VBoxContainer.new()
	shop_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_vbox.add_theme_constant_override("separation", 60)
	scroll.add_child(shop_vbox)
	
	_build_daily_offers(shop_vbox)
	_build_chests(shop_vbox)
	
	update_ui()

func _build_daily_offers(parent: Control) -> void:
	var lbl = Label.new()
	lbl.text = "OFERTAS DIÁRIAS"
	lbl.add_theme_font_size_override("font_size", 32)
	parent.add_child(lbl)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	parent.add_child(hbox)
	
	var cards = ["fake_news", "dossie", "cpi"]
	var costs = [200, 300, 500]
	
	for i in range(3):
		var card_id = cards[i]
		var cost = costs[i]
		
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.15, 0.15, 0.2)
		p_style.corner_radius_top_left = 10
		p_style.corner_radius_top_right = 10
		p_style.corner_radius_bottom_left = 10
		p_style.corner_radius_bottom_right = 10
		panel.add_theme_stylebox_override("panel", p_style)
		panel.custom_minimum_size = Vector2(250, 300)
		hbox.add_child(panel)
		
		var cvbox = VBoxContainer.new()
		cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(cvbox)
		
		var ctitle = Label.new()
		ctitle.text = card_id.capitalize()
		ctitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cvbox.add_child(ctitle)
		
		var cbtn = Button.new()
		cbtn.text = "Comprar por %d Votos" % cost
		cbtn.pressed.connect(func(): _buy_card(card_id, cost))
		cvbox.add_child(cbtn)

func _build_chests(parent: Control) -> void:
	var lbl = Label.new()
	lbl.text = "MALAS DE DINHEIRO"
	lbl.add_theme_font_size_override("font_size", 32)
	parent.add_child(lbl)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	parent.add_child(hbox)
	
	var chest1 = _create_chest_panel("Mala Básica", "100 Votos", func(): _buy_chest(100, 0))
	var chest2 = _create_chest_panel("Mala Épica", "50 Fundos", func(): _buy_chest(0, 50))
	
	hbox.add_child(chest1)
	hbox.add_child(chest2)

func _create_chest_panel(title_text: String, cost_text: String, callback: Callable) -> PanelContainer:
	var panel = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.3, 0.2, 0.1)
	panel.add_theme_stylebox_override("panel", p_style)
	panel.custom_minimum_size = Vector2(300, 250)
	
	var cvbox = VBoxContainer.new()
	cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(cvbox)
	
	var ctitle = Label.new()
	ctitle.text = title_text
	ctitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(ctitle)
	
	var cbtn = Button.new()
	cbtn.text = cost_text
	cbtn.pressed.connect(callback)
	cvbox.add_child(cbtn)
	return panel

func update_ui() -> void:
	if GameManager:
		votes_label.text = "Votos: " + str(GameManager.votos_soft_currency)
		funds_label.text = "  Fundos: $" + str(GameManager.fundos_hard_currency)

func _buy_card(card_id: String, cost: int) -> void:
	if GameManager and GameManager.votos_soft_currency >= cost:
		GameManager.votos_soft_currency -= cost
		if GameManager.inventory.has(card_id):
			GameManager.inventory[card_id]["amount"] += 1
		else:
			GameManager.inventory[card_id] = {"level": 1, "amount": 1}
		GameManager.save_game()
		update_ui()
		print("Comprado: " + card_id)

func _buy_chest(votos_cost: int, fundos_cost: int) -> void:
	if not GameManager: return
	
	if votos_cost > 0 and GameManager.votos_soft_currency >= votos_cost:
		GameManager.votos_soft_currency -= votos_cost
		_open_chest()
	elif fundos_cost > 0 and GameManager.fundos_hard_currency >= fundos_cost:
		GameManager.fundos_hard_currency -= fundos_cost
		_open_chest()

func _open_chest() -> void:
	print("Mala aberta! Você ganhou cartas aleatórias.")
	if GameManager.inventory.has("fake_news"):
		GameManager.inventory["fake_news"]["amount"] += 3
	GameManager.save_game()
	update_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/CityMap.tscn")
