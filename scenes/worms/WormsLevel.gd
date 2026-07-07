class_name WormsLevel
extends Node2D

var turn_manager: TurnManager
var terrain: DestructibleTerrain
var llm_client: Node

var hud_turn_label: Label
var hud_timer_label: Label
var floating_texts: Node2D

var attack_energy_costs = {
	"basic": 10,
	"super_mala": 30,
	"vento_divino": 20,
	"dossie": 35,
	"robo_disparo": 40,
	"emenda": 25,
	"fake_news": 40,
	"comicio": 70,
	"cpi": 100
}

func _ready() -> void:
	# LLM
	var LlmClass = load("res://scripts/managers/LocalLLMClient.gd")
	if LlmClass:
		llm_client = LlmClass.new()
		add_child(llm_client)
		llm_client.speech_generated.connect(_on_speech_generated)
		llm_client.generation_failed.connect(_on_speech_failed)
	
	# Floating texts parent
	floating_texts = Node2D.new()
	add_child(floating_texts)

	# Background Image (Parallax)
	var parallax_bg = ParallaxBackground.new()
	var parallax_layer = ParallaxLayer.new()
	parallax_layer.motion_scale = Vector2(0.5, 0.5)
	parallax_bg.add_child(parallax_layer)
	
	var bg_sprite = Sprite2D.new()
	if GameManager and GameManager.map_bg != "":
		var tex = load(GameManager.map_bg)
		if tex is Texture2D:
			bg_sprite.texture = tex
	bg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_sprite.position = Vector2(576, 324)
	parallax_layer.add_child(bg_sprite)
	add_child(parallax_bg)

	# Camera with Shake
	var cam = Camera2D.new()
	cam.position = Vector2(576, 324)
	cam.name = "MainCamera"
	add_child(cam)

	# Terrain
	terrain = DestructibleTerrain.new()
	add_child(terrain)

	# Turn Manager
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	turn_manager.turn_changed.connect(_on_turn_changed)
	turn_manager.state_changed.connect(_on_state_changed)
	
	# Spawn Candidates
	if GameManager and GameManager.is_campaign:
		GameManager.setup_campaign_match()
		
	var p1 = Candidate.new()
	p1.global_position = Vector2(200, 300)
	if GameManager:
		# Aplicar cor baseada na facção
		p1.modulate = Color.RED if GameManager.player_faction == "Vermelho" else Color.GREEN
		p1.candidate_name = GameManager.player1_name
		p1.texture_path = GameManager.player1_sprite
	add_child(p1)
	
	var p2 = Candidate.new()
	p2.global_position = Vector2(900, 300)
	p2.is_bot = true
	if GameManager:
		p2.candidate_name = GameManager.player2_name
		p2.texture_path = GameManager.player2_sprite
		if GameManager.is_campaign:
			var cur_league = GameManager.current_league
			var cur_level = GameManager.campaign_levels.get(cur_league, 1)
			var league_data = GameManager.campaign_leagues.get(cur_league, [])
			if league_data.size() > 0:
				var idx = clampi(cur_level - 1, 0, league_data.size() - 1)
				var opp_data = league_data[idx]
				if opp_data.get("is_boss", false):
					p2.max_hp = 300
					p2.hp = 300
	add_child(p2)

	p1.died.connect(func(): _end_game(p2.candidate_name, false))
	p2.died.connect(func(): _end_game(p1.candidate_name, true))
	
	# Spawn Civilians
	for i in range(3):
		var civ = CivilianNPC.new()
		civ.global_position = Vector2(randf_range(300, 800), 100)
		add_child(civ)
	
	# UI HUD
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var hud_panel = TextureRect.new()
	var img_hud = Image.new()
	if img_hud.load("res://assets/ui/hud_frame_aaa.jpg") == OK:
		hud_panel.texture = ImageTexture.create_from_image(img_hud)
		hud_panel.ignore_texture_size = true
		hud_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_panel.custom_minimum_size = Vector2(0, 80)
	canvas.add_child(hud_panel)
	
	var hud_hbox = HBoxContainer.new()
	hud_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_hbox.add_theme_constant_override("separation", 50)
	hud_panel.add_child(hud_hbox)
	
	# Portrait P1
	var p1_portrait = TextureRect.new()
	p1_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p1_portrait.custom_minimum_size = Vector2(60, 60)
	if ResourceLoader.exists(p1.texture_path):
		var p1_tex = load(p1.texture_path)
		if p1_tex: p1_portrait.texture = p1_tex
	else:
		var img = Image.new()
		if img.load(p1.texture_path) == OK:
			p1_portrait.texture = ImageTexture.create_from_image(img)
	hud_hbox.add_child(p1_portrait)
	
	hud_turn_label = Label.new()
	hud_turn_label.add_theme_font_size_override("font_size", 24)
	hud_turn_label.add_theme_color_override("font_color", Color.CYAN)
	hud_hbox.add_child(hud_turn_label)
	
	hud_timer_label = Label.new()
	hud_timer_label.add_theme_font_size_override("font_size", 24)
	hud_timer_label.add_theme_color_override("font_color", Color.YELLOW)
	hud_hbox.add_child(hud_timer_label)
	
	var hud_controls_label = Label.new()
	hud_controls_label.text = "Setas: Mover/Mirar | X: Pular | ESPAÇO: Atirar | 1-5: Armas"
	hud_controls_label.add_theme_font_size_override("font_size", 18)
	hud_controls_label.add_theme_color_override("font_color", Color.WHITE)
	hud_hbox.add_child(hud_controls_label)
	
	# Portrait P2
	var p2_portrait = TextureRect.new()
	p2_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p2_portrait.custom_minimum_size = Vector2(60, 60)
	p2_portrait.flip_h = true
	if ResourceLoader.exists(p2.texture_path):
		var p2_tex = load(p2.texture_path)
		if p2_tex: p2_portrait.texture = p2_tex
	else:
		var img = Image.new()
		if img.load(p2.texture_path) == OK:
			p2_portrait.texture = ImageTexture.create_from_image(img)
	hud_hbox.add_child(p2_portrait)
	
	# Weapon Selection HUD (Bottom)
	var weapon_panel = PanelContainer.new()
	weapon_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	weapon_panel.custom_minimum_size = Vector2(0, 80)
	var wp_style = StyleBoxFlat.new()
	wp_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	wp_style.border_width_top = 4
	wp_style.border_color = Color.CYAN
	weapon_panel.add_theme_stylebox_override("panel", wp_style)
	canvas.add_child(weapon_panel)
	
	var weapon_scroll = ScrollContainer.new()
	weapon_panel.add_child(weapon_scroll)
	
	var weapon_hbox = HBoxContainer.new()
	weapon_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_hbox.add_theme_constant_override("separation", 20)
	weapon_scroll.add_child(weapon_hbox)
	
	var dev_weapons = ["basic", "fake_news", "cpi", "dossie", "comicio", "super_mala", "robo_disparo", "emenda"]
	
	var shortcut_key = 1
	for item_id in dev_weapons:
		var item_name = item_id.capitalize()
		var icon_tex = null
		if item_id == "fake_news": item_name = "Fake News"
		elif item_id == "cpi": item_name = "CPI"
		elif item_id == "dossie": 
			item_name = "Dossiê"
			icon_tex = load("res://assets/sprites/weapon_dossie.png")
		elif item_id == "comicio": item_name = "Super Comício"
		elif item_id == "super_mala": 
			item_name = "Super Mala"
			icon_tex = load("res://assets/sprites/weapon_mala.png")
		elif item_id == "robo_disparo": 
			item_name = "Robô Disparo"
			icon_tex = load("res://assets/sprites/weapon_robo.png")
		elif item_id == "emenda":
			item_name = "Emenda"
			icon_tex = load("res://assets/sprites/weapon_emenda.png")
		
		# Fake infinite count for dev
		_add_weapon_btn(weapon_hbox, item_id, item_name, -1, icon_tex, shortcut_key)
		shortcut_key += 1
				
	# Start
	turn_manager.register_candidates([p1, p2])

var current_weapon: String = "basic"

func _add_weapon_btn(parent: Node, id: String, item_name: String, count: int, icon_tex: Texture2D, shortcut_key: int = -1) -> void:
	var btn = Button.new()
	var text = item_name
	if count >= 0:
		text += " (" + str(count) + ")"
	if shortcut_key > 0 and shortcut_key <= 9:
		text = "[" + str(shortcut_key) + "] " + text
		
	btn.text = text
	if icon_tex:
		btn.icon = icon_tex
		btn.expand_icon = true
	btn.add_theme_font_size_override("font_size", 18)
	btn.custom_minimum_size = Vector2(180, 60)
	btn.focus_mode = Control.FOCUS_NONE # Evita roubar o espaço do tiro
	btn.pressed.connect(_on_weapon_selected.bind(id))
	parent.add_child(btn)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.keycode
		if key >= KEY_1 and key <= KEY_9:
			var index = key - KEY_1
			var dev_weapons = ["basic", "fake_news", "cpi", "dossie", "comicio", "super_mala", "robo_disparo", "emenda"]
			if index < dev_weapons.size():
				_on_weapon_selected(dev_weapons[index])

func _on_weapon_selected(id: String) -> void:
	current_weapon = id
	_spawn_floating_text("Selecionado: " + id, Vector2(576, 500))
	if turn_manager and turn_manager.active_candidate:
		turn_manager.active_candidate.set_weapon(id)

func _process(_delta: float) -> void:
	if turn_manager.current_state == TurnManager.State.PLAYER_MOVING or turn_manager.current_state == TurnManager.State.AIMING:
		var c = turn_manager.active_candidate
		var wind_str = "Vento: " + str(snapped(turn_manager.wind_force.x, 0.1))
		var pow_str = " Força: " + str(int(c.aim_power)) if c else ""
		hud_timer_label.text = "Tempo: %d | %s | %s | Arma: %s" % [int(turn_manager.turn_timer.time_left), wind_str, pow_str, current_weapon]
		
		# Shooting logic (Bot only, Player is in Candidate.gd)
		if c != null and c.is_bot:
			# Bot auto fire logic
			if turn_manager.turn_timer.time_left < 13.0 and turn_manager.turn_timer.time_left > 12.0:
				c.aim_angle = -PI + randf_range(-0.5, 0.5)
				c.aim_power = 800.0
				c._animate_shoot()
				current_weapon = "basic"
				_fire_weapon()
				turn_manager.turn_timer.stop() # wait for shot to land
				
func _fire_weapon() -> void:
	var c = turn_manager.active_candidate
	
	var cost = attack_energy_costs.get(current_weapon, 10)
	if c.energy < cost:
		_spawn_floating_text("Sem energia política!", c.global_position + Vector2(0, -50))
		current_weapon = "basic"
		turn_manager.turn_timer.start(turn_manager.turn_time)
		return
		
	c.energy -= cost
	c.energy_bar.value = c.energy
	
	if current_weapon == "vento_divino":
		if GameManager and GameManager.inventory["vento_divino"] > 0:
			GameManager.inventory["vento_divino"] -= 1
			GameManager.save_game()
		turn_manager.wind_force = Vector2.ZERO
		_spawn_floating_text("VENTO ZERADO!", Vector2(576, 300))
		current_weapon = "basic"
		turn_manager.end_turn()
		return
		
	# Não consome mais do inventário, pois agora as armas são baseadas em Energia
	var weapon_level = 1
	if current_weapon != "basic" and GameManager and GameManager.inventory.has(current_weapon):
		var inv_item = GameManager.inventory[current_weapon]
		if typeof(inv_item) == TYPE_DICTIONARY:
			weapon_level = inv_item.get("level", 1)
			
	var spawn_pos = c.global_position + Vector2(cos(c.aim_angle), sin(c.aim_angle)) * 40.0
	var impulse = Vector2(cos(c.aim_angle), sin(c.aim_angle)) * c.aim_power
	
	# Generate insult via LLM
	if llm_client:
		llm_client.generate_speech_async(c.candidate_name, "está atirando com " + current_weapon)
	
	turn_manager.fire_projectile(Projectile, spawn_pos, impulse, turn_manager.wind_force, current_weapon, c, weapon_level)
	current_weapon = "basic"

func _on_turn_changed(c: Candidate) -> void:
	hud_turn_label.text = "Turno: " + c.candidate_name
	current_weapon = "basic"
	c.set_weapon("basic")
	
	# Regenerar energia política
	c.energy = min(c.energy + 20, c.max_energy)
	if c.energy_bar:
		c.energy_bar.value = c.energy

func _on_state_changed(state) -> void:
	if state == TurnManager.State.PROJECTILE_IN_AIR:
		hud_timer_label.text = "Fogo!"

func _on_speech_generated(text: String) -> void:
	if turn_manager.active_candidate != null:
		_spawn_floating_text(text, turn_manager.active_candidate.global_position + Vector2(0, -70))

func _on_speech_failed(err: String) -> void:
	print("LLM Error: ", err)

func _spawn_floating_text(text_val: String, pos: Vector2 = Vector2.ZERO) -> void:
	var lbl = Label.new()
	lbl.text = text_val
	lbl.add_theme_color_override("font_color", Color.YELLOW)
	lbl.add_theme_font_size_override("font_size", 28) # Maior tamanho
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.global_position = pos if pos != Vector2.ZERO else get_global_mouse_position()
	floating_texts.add_child(lbl)
	
	var tween = create_tween()
	if tween:
		tween.tween_property(lbl, "global_position", lbl.global_position + Vector2(0, -100), 2.0)
		tween.parallel().tween_property(lbl, "modulate:a", 0.0, 2.0)
		tween.tween_callback(lbl.queue_free)

func _end_game(winner_name: String, player_won: bool = false) -> void:
	_spawn_floating_text(winner_name + " VENCEU!", Vector2(576, 324))
	
	var next_scene = "res://scenes/worms/MainMenu.tscn"
	
	if GameManager:
		if player_won:
			var base_votos = 100
			var mult = 1.0 + (0.1 * GameManager.team_talents.get("cabo_eleitoral", 0))
			GameManager.votos_soft_currency += int(base_votos * mult)
			if GameManager.is_campaign:
				var league_id = GameManager.current_league
				if not GameManager.campaign_levels.has(league_id):
					GameManager.campaign_levels[league_id] = 1
					
				GameManager.campaign_levels[league_id] += 1
				var max_levels = GameManager.campaign_leagues[league_id].size()
				
				if GameManager.campaign_levels[league_id] > max_levels:
					_spawn_floating_text("VOCÊ VENCEU A LIGA!", Vector2(576, 400))
					GameManager.campaign_levels[league_id] = 1 # Reset
				else:
					next_scene = "res://scenes/worms/WormsLevel.tscn"
		else:
			GameManager.votos_soft_currency += 10 # consolo
			
		GameManager.save_game()
		
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file(next_scene)

func shake_camera(intensity: float = 20.0, duration: float = 0.5) -> void:
	var cam = get_node_or_null("MainCamera") as Camera2D
	if not cam: return
	
	var tween = create_tween()
	var loops = int(duration / 0.05)
	for i in range(loops):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(cam, "offset", offset, 0.05)
		intensity *= 0.8
	tween.tween_property(cam, "offset", Vector2.ZERO, 0.05)
