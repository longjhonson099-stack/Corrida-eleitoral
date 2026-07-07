class_name Projectile
extends RigidBody2D

var explosion_radius: float = 60.0
var damage: int = 25
var wind_force: Vector2 = Vector2.ZERO
var weapon_type: String = "basic"

var trail: Line2D
var explosion_snd: AudioStreamPlayer

signal exploded

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	
	if weapon_type == "super_mala":
		damage = 50
		explosion_radius = 90.0
	elif weapon_type == "dossie":
		damage = 40
		explosion_radius = 80.0
	elif weapon_type == "robo_disparo":
		damage = 15
		explosion_radius = 40.0
		
	# Visual
	var sprite = Sprite2D.new()
	var tex = null
	
	if weapon_type == "super_mala":
		tex = load("res://assets/sprites/weapon_mala.png")
	elif weapon_type == "dossie":
		tex = load("res://assets/sprites/weapon_dossie.png")
	elif weapon_type == "robo_disparo":
		tex = load("res://assets/sprites/weapon_robo.png")
	elif weapon_type == "emenda":
		tex = load("res://assets/sprites/weapon_emenda.png")
		
	if tex == null:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.BLACK)
		tex = ImageTexture.create_from_image(img)
		
	sprite.texture = tex
	# scale sprite if needed
	if tex.get_width() > 32:
		sprite.scale = Vector2(32.0 / tex.get_width(), 32.0 / tex.get_height())
		
	add_child(sprite)
	
	# Trail
	trail = Line2D.new()
	trail.width = 4.0
	trail.default_color = Color(1, 1, 1, 0.5)
	trail.top_level = true # detach transform from rigid body
	add_child(trail)
	
	# Audio
	explosion_snd = AudioStreamPlayer.new()
	var snd = AudioStreamWAV.new()
	var file = FileAccess.open("res://assets/audio/explosion.wav", FileAccess.READ)
	if file:
		snd.data = file.get_buffer(file.get_length())
		snd.format = AudioStreamWAV.FORMAT_16_BITS
		snd.mix_rate = 44100
		explosion_snd.stream = snd
	add_child(explosion_snd)
	
	# Collision
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)

func _physics_process(delta: float) -> void:
	if wind_force != Vector2.ZERO:
		apply_force(wind_force * 10.0)
	
	if trail.get_point_count() > 20:
		trail.remove_point(0)
	trail.add_point(global_position)
	
	if global_position.y > 1500:
		emit_signal("exploded")
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Particles
	var p = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 30 if weapon_type != "super_mala" else 60
	p.spread = 180
	p.gravity = Vector2(0, 500)
	p.initial_velocity_min = 100
	p.initial_velocity_max = 300
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0 if weapon_type != "super_mala" else 15.0
	p.color = Color(1, 0.5, 0) if weapon_type != "dossie" else Color(0.5, 0, 1)
	p.global_position = global_position
	get_parent().add_child(p)
	p.emitting = true
	
	# Shake
	if get_parent().has_method("shake_camera"):
		get_parent().shake_camera(15.0 if weapon_type != "super_mala" else 30.0, 0.5)
	
	# Sound
	explosion_snd.play()
	explosion_snd.reparent(get_parent()) # keep sound alive
	
	# Trigger explosion
	if body is DestructibleTerrain:
		body.clip_circle(global_position, explosion_radius)
	
	# Deal damage in radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = global_transform
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider is Candidate:
			collider.take_damage(damage)
			# Apply knockback
			var knock_force = 600.0 if weapon_type != "super_mala" else 1000.0
			var dir = (collider.global_position - global_position).normalized()
			collider.velocity += dir * knock_force
			
	# Cluster logic for Robo Disparo
	if weapon_type == "robo_disparo":
		for i in range(3):
			var sub_proj = Projectile.new()
			sub_proj.weapon_type = "basic" # prevent infinite
			sub_proj.damage = 10
			sub_proj.explosion_radius = 30.0
			sub_proj.global_position = global_position + Vector2(0, -20)
			get_parent().call_deferred("add_child", sub_proj)
			sub_proj.call_deferred("apply_impulse", Vector2(randf_range(-300, 300), randf_range(-500, -200)))
	
	emit_signal("exploded")
	queue_free()
