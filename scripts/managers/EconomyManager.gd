extends Node
class_name EconomyManager

signal discursos_changed(new_value: float)
signal dps_changed(new_dps: float)
signal prestige_changed(new_multiplier: float)

var discursos: float = 0.0
var discursos_por_segundo: float = 0.0
var prestige_multiplier: float = 1.0

# Upgrades Dicionário (Data-driven)
var upgrades: Array[Dictionary] = [
	{
		"id": "tia_do_zap",
		"name": "Tia do Zap",
		"base_cost": 10.0,
		"dps": 1.0,
		"count": 0
	},
	{
		"id": "robos",
		"name": "Exército de Robôs",
		"base_cost": 100.0,
		"dps": 12.0,
		"count": 0
	},
	{
		"id": "influenciador",
		"name": "Influenciador Cancelado",
		"base_cost": 1000.0,
		"dps": 150.0,
		"count": 0
	},
	{
		"id": "dossie",
		"name": "Vazamento de Dossiê",
		"base_cost": 10000.0,
		"dps": 2000.0,
		"count": 0
	}
]

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	if discursos_por_segundo > 0.0:
		add_discursos(discursos_por_segundo * delta)

func add_discursos(amount: float) -> void:
	if amount <= 0.0:
		return
	discursos += amount * prestige_multiplier
	discursos_changed.emit(discursos)

func get_upgrade_cost(index: int) -> int:
	if index < 0 or index >= upgrades.size():
		AppLogger.error("EconomyManager: get_upgrade_cost chamado com index inválido (%d)" % index)
		return 9999999 # Custo impossível para evitar bugs
		
	var upg = upgrades[index]
	var base = upg.get("base_cost", 10.0) as float
	var count = upg.get("count", 0) as int
	return int(base * pow(1.15, float(count)))

func can_afford_upgrade(index: int) -> bool:
	if index < 0 or index >= upgrades.size():
		return false
	return discursos >= float(get_upgrade_cost(index))

func buy_upgrade(index: int) -> bool:
	if index < 0 or index >= upgrades.size():
		AppLogger.error("EconomyManager: buy_upgrade chamado com index inválido (%d)" % index)
		return false
		
	var cost = get_upgrade_cost(index)
	if discursos >= float(cost):
		discursos -= float(cost)
		upgrades[index].count += 1
		_recalculate_dps()
		discursos_changed.emit(discursos)
		AppLogger.info("Upgrade comprado: %s (Novo count: %d)" % [upgrades[index].name, upgrades[index].count])
		save_game()
		return true
		
	AppLogger.warning("Tentativa de comprar upgrade sem saldo suficiente.")
	return false

func _recalculate_dps() -> void:
	var total_dps: float = 0.0
	for upg in upgrades:
		var count = upg.get("count", 0) as int
		var dps = upg.get("dps", 0.0) as float
		total_dps += float(count) * dps
	
	discursos_por_segundo = total_dps * prestige_multiplier
	dps_changed.emit(discursos_por_segundo)

func reset_for_prestige() -> void:
	AppLogger.info("Realizando Prestige. Multiplicador atual: %f" % prestige_multiplier)
	discursos = 0.0
	discursos_por_segundo = 0.0
	for i in range(upgrades.size()):
		upgrades[i].count = 0
	
	prestige_multiplier += 0.5 
	_recalculate_dps()
	discursos_changed.emit(discursos)
	prestige_changed.emit(prestige_multiplier)
	AppLogger.info("Prestige concluído. Novo multiplicador: %f" % prestige_multiplier)
	save_game()

# --- SISTEMA DE SAVE ---

func save_game() -> void:
	var upgrade_counts = []
	for upg in upgrades:
		upgrade_counts.append(upg.count)
		
	var data = {
		"discursos": discursos,
		"prestige_multiplier": prestige_multiplier,
		"upgrades_counts": upgrade_counts
	}
	AppSaveManager.save_game(data)

func load_game() -> void:
	var data = AppSaveManager.load_game()
	if data.is_empty():
		return
		
	discursos = float(data.get("discursos", 0.0))
	prestige_multiplier = float(data.get("prestige_multiplier", 1.0))
	
	var counts = data.get("upgrades_counts", [])
	if typeof(counts) == TYPE_ARRAY:
		for i in range(min(counts.size(), upgrades.size())):
			upgrades[i].count = int(counts[i])
			
	_recalculate_dps()
	
	# Delay emissão de sinais para garantir que os nós filhos do Game.tscn existam se recarregado via _ready
	call_deferred("_emit_loaded_state")

func _emit_loaded_state() -> void:
	discursos_changed.emit(discursos)
	dps_changed.emit(discursos_por_segundo)
	prestige_changed.emit(prestige_multiplier)
