extends Control

var candidates = [
	{"id": "lula", "name": "Lula", "icon": "res://assets/sprites/cand_lula.jpg"},
	{"id": "bolsonaro", "name": "Bolsonaro", "icon": "res://assets/sprites/cand_bolsonaro.jpg"},
	{"id": "coach", "name": "Coach", "icon": "res://assets/sprites/cand_coach.jpg"},
	{"id": "juiz", "name": "Juiz", "icon": "res://assets/sprites/cand_juiz.jpg"},
	{"id": "poste", "name": "Poste", "icon": "res://assets/sprites/cand_poste.jpg"},
	{"id": "terceiravia", "name": "Terceira Via", "icon": "res://assets/sprites/cand_terceiravia.jpg"}
]

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "ESCOLHA SEU CANDIDATO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 40)
	
	var center = CenterContainer.new()
	center.add_child(grid)
	vbox.add_child(center)
	
	for c in candidates:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 150)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.text = c["name"]
		
		# Fallback se a imagem não existir onde esperamos, nós criamos um rect colorido
		var tex = null
		if ResourceLoader.exists(c["icon"]):
			tex = load(c["icon"])
		else:
			var img = Image.new()
			if img.load(c["icon"]) == OK:
				tex = ImageTexture.create_from_image(img)
				
		if tex:
			var scale_factor = 100.0 / float(max(tex.get_width(), tex.get_height()))
			var img_scaled = tex.get_image()
			img_scaled.resize(int(tex.get_width() * scale_factor), int(tex.get_height() * scale_factor))
			btn.icon = ImageTexture.create_from_image(img_scaled)
		btn.pressed.connect(_on_candidate_selected.bind(c["id"], c["name"], c["icon"]))
		grid.add_child(btn)
		
	var back_btn = Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(200, 60)
	back_btn.add_theme_font_size_override("font_size", 24)
	back_btn.pressed.connect(_on_back_pressed)
	
	var back_center = CenterContainer.new()
	back_center.add_child(back_btn)
	vbox.add_child(back_center)

func _on_candidate_selected(id: String, c_name: String, icon: String) -> void:
	if GameManager:
		GameManager.player1_name = c_name
		GameManager.player1_sprite = icon
	get_tree().change_scene_to_file("res://scenes/worms/WormsLevel.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/CityMap.tscn")
