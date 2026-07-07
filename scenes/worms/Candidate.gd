class_name Candidate
extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_active_turn = false
var max_hp = 100
var hp = 100
var candidate_name = "Político"
var is_bot = false

# Visuals
var sprite: Sprite2D
var aim_line: Line2D
var hp_label: Label
var hp_bar: ProgressBar
var name_label: Label
var weapon_sprite: Sprite2D

# Aiming
var aim_angle: float = -PI/4
var aim_power: float = 500.0

signal turn_ended
signal died

var texture_path: String = ""

func _ready() -> void:
	# Visuals
	sprite = Sprite2D.new()
	if texture_path != "":
		var tex = load(texture_path)
		if tex is Texture2D:
			sprite.texture = tex
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(0.1, 0.1)
	else:
		var img = Image.create(32, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.BLUE if not is_bot else Color.RED)
		sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
	# Collision
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 64)
	shape.shape = rect
	add_child(shape)
	
	# Audio setup
	var jump_snd = AudioStreamPlayer.new()
	jump_snd.name = "JumpSound"
	var j_file = FileAccess.open("res://assets/audio/jump.wav", FileAccess.READ)
	if j_file:
		var stream = AudioStreamWAV.new()
		stream.data = j_file.get_buffer(j_file.get_length())
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 44100
		jump_snd.stream = stream
	add_child(jump_snd)
	
	var shoot_snd = AudioStreamPlayer.new()
	shoot_snd.name = "ShootSound"
	var s_file = FileAccess.open("res://assets/audio/shoot.wav", FileAccess.READ)
	if s_file:
		var stream = AudioStreamWAV.new()
		stream.data = s_file.get_buffer(s_file.get_length())
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 44100
		shoot_snd.stream = stream
	add_child(shoot_snd)
	
	# UI
	name_label = Label.new()
	name_label.text = candidate_name
	name_label.position = Vector2(-40, -90)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 4)
	add_child(name_label)
	
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(-30, -60)
	hp_bar.size = Vector2(60, 10)
	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_bar.show_percentage = false
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.2, 0.2, 0.2, 1)
	hp_bar.add_theme_stylebox_override("background", sb_bg)
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color.GREEN
	hp_bar.add_theme_stylebox_override("fill", sb_fill)
	add_child(hp_bar)
	
	hp_label = Label.new()
	hp_label.text = str(hp)
	hp_label.position = Vector2(-15, -55)
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_label.add_theme_constant_override("outline_size", 3)
	hp_label.modulate = Color.GREEN
	add_child(hp_label)
	
	# Aim line / Weapon sprite
	aim_line = Line2D.new()
	aim_line.width = 2.0
	aim_line.default_color = Color.YELLOW
	aim_line.visible = false
	add_child(aim_line)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.visible = false
	add_child(weapon_sprite)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_active_turn:
		if is_bot:
			_process_bot_turn(delta)
		else:
			_process_player_turn(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if global_position.y > 1500:
		take_damage(999)

func _process_player_turn(delta: float) -> void:
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_key_pressed(KEY_X) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_animate_jump()
		
	# Aiming (Up/Down arrows to change angle)
	if Input.is_action_pressed("ui_up"):
		aim_angle -= 0.05
	if Input.is_action_pressed("ui_down"):
		aim_angle += 0.05
		
	# Power Charging
	if Input.is_key_pressed(KEY_SPACE):
		aim_power += delta * 600.0
		if aim_power > 1200.0:
			aim_power = 1200.0
	else:
		if aim_power > 200.0:
			_animate_shoot()
			get_parent()._fire_weapon()
			aim_power = 200.0
			
	_update_aim_line()

func _animate_jump() -> void:
	var snd = get_node_or_null("JumpSound")
	if snd: snd.play()
	
	var tween = create_tween()
	var original_scale = Vector2(0.1, 0.1) if texture_path != "" else Vector2(1,1)
	tween.tween_property(sprite, "scale", original_scale * Vector2(0.5, 1.5), 0.1)
	tween.tween_property(sprite, "scale", original_scale, 0.2)

func _animate_shoot() -> void:
	var snd = get_node_or_null("ShootSound")
	if snd: snd.play()
	
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", deg_to_rad(-30), 0.1)
	tween.tween_property(sprite, "rotation", 0.0, 0.2)

func _process_bot_turn(delta: float) -> void:
	# Bot auto fire is handled in WormsLevel now
	_update_aim_line()

var active_weapon: String = "basic"

func set_weapon(weapon_type: String) -> void:
	active_weapon = weapon_type
	var tex = null
	if weapon_type == "super_mala": tex = load("res://assets/sprites/weapon_mala.png")
	elif weapon_type == "dossie": tex = load("res://assets/sprites/weapon_dossie.png")
	elif weapon_type == "robo_disparo": tex = load("res://assets/sprites/weapon_robo.png")
	elif weapon_type == "emenda": tex = load("res://assets/sprites/weapon_emenda.png")
	
	if tex:
		weapon_sprite.texture = tex
		weapon_sprite.scale = Vector2(32.0 / tex.get_width(), 32.0 / tex.get_height())
	else:
		weapon_sprite.texture = null

func _update_aim_line() -> void:
	aim_line.visible = true
	var end_pos = Vector2(cos(aim_angle), sin(aim_angle)) * 50.0
	aim_line.points = PackedVector2Array([Vector2.ZERO, end_pos])
	
	if weapon_sprite.texture != null:
		weapon_sprite.visible = true
		weapon_sprite.position = end_pos
		weapon_sprite.rotation = aim_angle
	else:
		weapon_sprite.visible = false

func end_turn_action() -> void:
	is_active_turn = false
	aim_line.visible = false
	weapon_sprite.visible = false
	emit_signal("turn_ended")

func take_damage(amount: int) -> void:
	hp -= amount
	hp_label.text = str(hp)
	if hp_bar:
		hp_bar.value = hp
	if hp <= 0:
		emit_signal("died")
		queue_free()
