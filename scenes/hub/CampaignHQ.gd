extends Control

@onready var cards_container = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var votes_label = $MarginContainer/VBoxContainer/Header/VotesLabel
@onready var back_btn = $MarginContainer/VBoxContainer/Header/BtnBack

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	update_ui()

func update_ui() -> void:
	if not GameManager: return
	
	votes_label.text = "Votos disponíveis: " + str(GameManager.votos_soft_currency)
	
	# Clear previous cards
	for child in cards_container.get_children():
		child.queue_free()
		
	# Populate cards
	var card_costs = {
		"fake_news": 50,
		"cpi": 100,
		"dossie": 150,
		"comicio": 200
	}
	
	for item_id in GameManager.inventory.keys():
		var inv_item = GameManager.inventory[item_id]
		var level = inv_item.get("level", 1) if typeof(inv_item) == TYPE_DICTIONARY else 1
		
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
		p_style.border_width_bottom = 4
		p_style.border_color = Color.DARK_SLATE_BLUE
		p_style.corner_radius_top_left = 8
		p_style.corner_radius_top_right = 8
		p_style.corner_radius_bottom_left = 8
		p_style.corner_radius_bottom_right = 8
		panel.add_theme_stylebox_override("panel", p_style)
		panel.custom_minimum_size = Vector2(250, 300)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 10)
		panel.add_child(vbox)
		
		var title = Label.new()
		title.text = item_id.capitalize()
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 24)
		vbox.add_child(title)
		
		var lvl_label = Label.new()
		lvl_label.text = "Nível: " + str(level)
		lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_label.add_theme_color_override("font_color", Color.YELLOW)
		vbox.add_child(lvl_label)
		
		var desc = Label.new()
		desc.text = "Dano: +" + str((level - 1) * 20) + "%\nRaio: +" + str((level - 1) * 10) + "%"
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(desc)
		
		var btn = Button.new()
		var cost = card_costs.get(item_id, 100) * level
		btn.text = "Melhorar (" + str(cost) + " Votos)"
		btn.custom_minimum_size = Vector2(200, 50)
		btn.add_theme_font_size_override("font_size", 18)
		
		if GameManager.votos_soft_currency >= cost:
			btn.pressed.connect(_on_upgrade_pressed.bind(item_id, cost))
		else:
			btn.disabled = true
			
		vbox.add_child(btn)
		
		cards_container.add_child(panel)

func _on_upgrade_pressed(item_id: String, cost: int) -> void:
	if GameManager.votos_soft_currency >= cost:
		GameManager.votos_soft_currency -= cost
		var inv_item = GameManager.inventory[item_id]
		if typeof(inv_item) == TYPE_DICTIONARY:
			inv_item["level"] += 1
		else:
			GameManager.inventory[item_id] = {"level": 2, "amount": int(inv_item)}
		
		GameManager.save_game()
		update_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/CityMap.tscn")
