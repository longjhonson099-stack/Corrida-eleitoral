class_name TurnManager
extends Node

enum State {
	START_TURN,
	PLAYER_MOVING,
	AIMING,
	PROJECTILE_IN_AIR,
	RESOLVING_DAMAGE,
	END_TURN
}

var current_state: State = State.START_TURN
var active_candidate: Candidate
var candidates: Array = []
var turn_index: int = 0
var turn_timer: Timer
var wind_force: Vector2 = Vector2.ZERO

signal turn_changed(new_candidate)
signal state_changed(new_state)

func _ready() -> void:
	turn_timer = Timer.new()
	turn_timer.one_shot = true
	turn_timer.timeout.connect(_on_turn_timeout)
	add_child(turn_timer)

func register_candidates(c_list: Array) -> void:
	candidates = c_list
	for c in candidates:
		c.died.connect(_on_candidate_died.bind(c))
	
	if candidates.size() > 0:
		start_match()

func start_match() -> void:
	turn_index = -1
	_next_turn()

func _next_turn() -> void:
	if candidates.size() <= 1:
		print("Game Over!")
		
		# Recompensas
		if GameManager:
			var player_won = false
			if candidates.size() == 1 and not candidates[0].is_bot:
				player_won = true
				
			if player_won:
				GameManager.votos_soft_currency += 100
				GameManager.influencia += 30
				print("Vitória! +100 Votos, +30 Influência")
			else:
				GameManager.influencia = maxi(0, GameManager.influencia - 20)
				print("Derrota! -20 Influência")
				
			GameManager.save_game()
			
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/hub/CityMap.tscn")
		return
		
	turn_index = (turn_index + 1) % candidates.size()
	active_candidate = candidates[turn_index]
	wind_force = Vector2(randf_range(-10.0, 10.0), 0)
	
	_transition_to(State.START_TURN)

func _transition_to(new_state: State) -> void:
	current_state = new_state
	emit_signal("state_changed", current_state)
	
	match current_state:
		State.START_TURN:
			print("Turno de: ", active_candidate.candidate_name)
			emit_signal("turn_changed", active_candidate)
			active_candidate.is_active_turn = true
			turn_timer.start(15.0) # 15 seconds turn
			_transition_to(State.PLAYER_MOVING)
			
		State.PLAYER_MOVING:
			pass
			
		State.PROJECTILE_IN_AIR:
			turn_timer.stop()
			active_candidate.is_active_turn = false
			
		State.RESOLVING_DAMAGE:
			# wait for physics to settle
			await get_tree().create_timer(1.5).timeout
			_transition_to(State.END_TURN)
			
		State.END_TURN:
			_next_turn()

func _on_turn_timeout() -> void:
	if current_state == State.PLAYER_MOVING or current_state == State.AIMING:
		active_candidate.is_active_turn = false
		_transition_to(State.END_TURN)

func fire_projectile(projectile_class, spawn_pos: Vector2, impulse: Vector2, wind: Vector2 = Vector2.ZERO, weapon_type: String = "basic", shooter: Node = null, weapon_level: int = 1) -> void:
	var proj = projectile_class.new()
	proj.global_position = spawn_pos
	if "wind_force" in proj:
		proj.wind_force = wind
	if "weapon_type" in proj:
		proj.weapon_type = weapon_type
	if "weapon_level" in proj:
		proj.weapon_level = weapon_level
	if shooter:
		proj.add_collision_exception_with(shooter)
		if "attacker" in proj:
			proj.attacker = shooter
	get_parent().add_child(proj)
	proj.apply_impulse(impulse)
	
	proj.exploded.connect(_on_projectile_exploded)
	_transition_to(State.PROJECTILE_IN_AIR)

func _on_projectile_exploded() -> void:
	_transition_to(State.RESOLVING_DAMAGE)

func _on_candidate_died(c: Candidate) -> void:
	candidates.erase(c)
	if c == active_candidate:
		_transition_to(State.END_TURN)
