extends Control

var exp_label: Label
var premium_btn: Button

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	var rect = ColorRect.new()
	rect.color = Color(0.1, 0.4, 0.2)
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	add_child(rect)
	
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
	
	var back_btn = Button.new()
	back_btn.text = " Voltar ao Hub "
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	exp_label = Label.new()
	exp_label.add_theme_font_size_override("font_size", 24)
	header.add_child(exp_label)
	
	var header_spacer = Control.new()
	header_spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(header_spacer)
	
	var title = Label.new()
	title.text = "PASSE ELEITORAL"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	premium_btn = Button.new()
	premium_btn.text = "Comprar Passe Premium (Desbloqueado)" if GameManager.has_premium_pass else "Comprar Passe Premium ($500 Fundos)"
	premium_btn.custom_minimum_size = Vector2(400, 60)
	premium_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	premium_btn.pressed.connect(_on_buy_premium)
	vbox.add_child(premium_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var hbox_tiers = HBoxContainer.new()
	hbox_tiers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_tiers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox_tiers.add_theme_constant_override("separation", 20)
	scroll.add_child(hbox_tiers)
	
	for i in range(1, 11):
		_build_tier(hbox_tiers, i)
		
	update_ui()

func _build_tier(parent: Control, tier_num: int) -> void:
	var panel = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.2, 0.2, 0.2)
	p_style.corner_radius_top_left = 10
	p_style.corner_radius_top_right = 10
	p_style.corner_radius_bottom_left = 10
	p_style.corner_radius_bottom_right = 10
	if GameManager.season_tier >= tier_num:
		p_style.bg_color = Color(0.4, 0.5, 0.1) # Highlight reached tiers
	
	panel.add_theme_stylebox_override("panel", p_style)
	panel.custom_minimum_size = Vector2(200, 300)
	parent.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	var lbl_tier = Label.new()
	lbl_tier.text = "Tier " + str(tier_num)
	lbl_tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tier.add_theme_font_size_override("font_size", 24)
	vbox.add_child(lbl_tier)
	
	var lbl_free = Label.new()
	lbl_free.text = "Grátis: 100 Votos"
	lbl_free.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_free)
	
	var lbl_prem = Label.new()
	lbl_prem.text = "Premium: 1 Mala"
	lbl_prem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_prem.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(lbl_prem)

func update_ui() -> void:
	if GameManager:
		exp_label.text = "Nível Atual: " + str(GameManager.season_tier) + " | XP: " + str(GameManager.season_exp)
		premium_btn.text = "Passe Premium Ativo" if GameManager.has_premium_pass else "Comprar Passe Premium ($500 Fundos)"

func _on_buy_premium() -> void:
	if not GameManager.has_premium_pass and GameManager.fundos_hard_currency >= 500:
		GameManager.fundos_hard_currency -= 500
		GameManager.has_premium_pass = true
		GameManager.save_game()
		update_ui()
		print("Passe Premium Adquirido!")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/CityMap.tscn")
