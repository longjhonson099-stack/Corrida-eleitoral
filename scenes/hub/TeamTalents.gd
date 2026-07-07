extends Control

var talents = [
	{
		"id": "cabo_eleitoral",
		"name": "Cabo Eleitoral",
		"desc": "+10% Votos ao vencer",
		"base_cost": 50
	},
	{
		"id": "marqueteiro",
		"name": "Marqueteiro",
		"desc": "+5% Dano das Armas",
		"base_cost": 75
	},
	{
		"id": "advogado",
		"name": "Advogado",
		"desc": "+5% Vida (HP)",
		"base_cost": 100
	}
]

var funds_label: Label
var talent_containers = {}

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var back_btn = Button.new()
	back_btn.text = " Voltar ao Hub "
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	funds_label = Label.new()
	funds_label.add_theme_font_size_override("font_size", 24)
	funds_label.add_theme_color_override("font_color", Color.GOLD)
	header.add_child(funds_label)
	
	var title = Label.new()
	title.text = "EQUIPE DE CAMPANHA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Contrate especialistas para fortalecer sua campanha. Custa Fundos ($)."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	var margin_spacer = Control.new()
	margin_spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(margin_spacer)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(hbox)
	
	for t in talents:
		var panel = _create_talent_panel(t)
		hbox.add_child(panel)
		
	update_ui()

func _create_talent_panel(t_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.15, 0.2, 0.15)
	p_style.corner_radius_top_left = 15
	p_style.corner_radius_top_right = 15
	p_style.corner_radius_bottom_left = 15
	p_style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", p_style)
	panel.custom_minimum_size = Vector2(300, 400)
	
	var cvbox = VBoxContainer.new()
	cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(cvbox)
	
	var title = Label.new()
	title.text = t_data["name"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	cvbox.add_child(title)
	
	var desc = Label.new()
	desc.text = t_data["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(desc)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	cvbox.add_child(spacer1)
	
	var lvl_lbl = Label.new()
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 24)
	cvbox.add_child(lvl_lbl)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	cvbox.add_child(spacer2)
	
	var buy_btn = Button.new()
	buy_btn.add_theme_font_size_override("font_size", 20)
	buy_btn.pressed.connect(func(): _upgrade_talent(t_data["id"], t_data["base_cost"]))
	cvbox.add_child(buy_btn)
	
	talent_containers[t_data["id"]] = {
		"lvl_label": lvl_lbl,
		"buy_btn": buy_btn
	}
	
	return panel

func update_ui() -> void:
	if not GameManager: return
	
	funds_label.text = "Fundos: $" + str(GameManager.fundos_hard_currency)
	
	for t in talents:
		var id = t["id"]
		var current_lvl = GameManager.team_talents.get(id, 0)
		var cost = int(t["base_cost"] * pow(1.5, current_lvl))
		
		var container = talent_containers[id]
		container["lvl_label"].text = "Nível Atual: " + str(current_lvl)
		container["buy_btn"].text = "Evoluir ($" + str(cost) + ")"
		container["buy_btn"].disabled = (GameManager.fundos_hard_currency < cost)

func _upgrade_talent(id: String, base_cost: int) -> void:
	var current_lvl = GameManager.team_talents.get(id, 0)
	var cost = int(base_cost * pow(1.5, current_lvl))
	
	if GameManager.fundos_hard_currency >= cost:
		GameManager.fundos_hard_currency -= cost
		GameManager.team_talents[id] = current_lvl + 1
		GameManager.save_game()
		update_ui()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/CityMap.tscn")
