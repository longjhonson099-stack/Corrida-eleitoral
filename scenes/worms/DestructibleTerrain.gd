class_name DestructibleTerrain
extends StaticBody2D

@export var terrain_color: Color = Color(0.4, 0.25, 0.1)

var polygon2d: Polygon2D
var collision_polygon: CollisionPolygon2D

func _ready() -> void:
	polygon2d = Polygon2D.new()
	polygon2d.color = terrain_color
	add_child(polygon2d)
	
	collision_polygon = CollisionPolygon2D.new()
	add_child(collision_polygon)
	
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.005
	
	var initial_poly = PackedVector2Array()
	initial_poly.append(Vector2(0, 648))
	for x in range(0, 1153, 32):
		var y = 450 + noise.get_noise_1d(x) * 150
		initial_poly.append(Vector2(x, y))
	initial_poly.append(Vector2(1152, 648))
	
	polygon2d.polygon = initial_poly
	collision_polygon.polygon = initial_poly
	
	# Texture mapping
	if GameManager and GameManager.map_bg != "":
		var tex = load(GameManager.map_bg)
		if tex is Texture2D:
			polygon2d.texture = tex
		polygon2d.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func clip_circle(center: Vector2, radius: float) -> void:
	var circle = _create_circle_polygon(center, radius, 16)
	
	var current_poly = polygon2d.polygon
	var result = Geometry2D.clip_polygons(current_poly, circle)
	
	if result.size() > 0:
		polygon2d.polygon = result[0]
		collision_polygon.polygon = result[0]
		# TODO: handle multi-polygon (floating islands) if time permits

func _create_circle_polygon(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	var angle_step = (PI * 2) / segments
	for i in range(segments):
		var angle = i * angle_step
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
