class_name CivilianNPC
extends RigidBody2D

var hp: int = 30
var pop_penalty: int = 15

func _ready() -> void:
	# Sprite
	var sprite = Sprite2D.new()
	var img = Image.create(24, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.ORANGE) # Civilian color
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)
	
	# Collision
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(24, 48)
	shape.shape = rect
	add_child(shape)
	
	# Floating label for feedback
	var label = Label.new()
	label.text = "Civil"
	label.position = Vector2(-20, -40)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)

func take_damage(amount: int, attacker: Candidate = null) -> void:
	hp -= amount
	if hp <= 0:
		if attacker != null:
			# Visual feedback for popularity loss
			var main = get_tree().current_scene
			if main and main.has_method("_spawn_floating_text"):
				main._spawn_floating_text("Civis atingidos! -%d Popularidade" % pop_penalty, global_position)
		queue_free()
