extends "res://tests/e2e/BaseE2ETest.gd"

# Tier 1: Feature Coverage (5 tests)

func test_01_upgrade_list_count() -> void:
	var list_children = game.upgrades_list.get_child_count()
	var upgrades_size = game.economy_manager.upgrades.size()
	assert_eq(list_children, upgrades_size, "UI upgrades list has the correct number of buttons")

func test_02_upgrade_costs() -> void:
	# base_cost for upgrade index 0 (Tia do Zap) is 10.0
	game.economy_manager.upgrades[0].count = 0
	var cost0 = game.economy_manager.get_upgrade_cost(0)
	assert_eq(cost0, 10, "Base cost of Tia do Zap is 10")
	
	game.economy_manager.upgrades[0].count = 1
	var cost1 = game.economy_manager.get_upgrade_cost(0)
	assert_eq(cost1, 11, "Cost at level 1 is 11 (10 * 1.15 = 11.5 -> int)")

func test_03_buy_upgrade_success() -> void:
	game.economy_manager.discursos = 10.0
	game.economy_manager.upgrades[0].count = 0
	var success = game.economy_manager.buy_upgrade(0)
	assert_true(success, "Buying upgrade succeeds when having enough discursos")
	assert_eq(game.economy_manager.upgrades[0].count, 1, "Count of upgrade increases to 1")
	assert_eq(game.economy_manager.discursos, 0.0, "Discursos deducted by upgrade cost")

func test_04_buy_upgrade_recalculates_dps() -> void:
	game.economy_manager.discursos = 110.0
	game.economy_manager.upgrades[0].count = 0
	game.economy_manager.upgrades[1].count = 0
	game.economy_manager.prestige_multiplier = 1.0
	
	game.economy_manager.buy_upgrade(0) # cost 10, count 1, dps 1.0
	game.economy_manager.buy_upgrade(1) # cost 100, count 1, dps 12.0
	
	assert_eq(game.economy_manager.discursos_por_segundo, 13.0, "DPS is recalculated: 1*1.0 + 1*12.0 = 13.0")

func test_05_cannot_buy_if_insufficient_funds() -> void:
	game.economy_manager.discursos = 5.0
	game.economy_manager.upgrades[0].count = 0
	var success = game.economy_manager.buy_upgrade(0)
	assert_true(not success, "Buying upgrade fails if discursos < cost")
	assert_eq(game.economy_manager.upgrades[0].count, 0, "Count of upgrade remains 0")
	assert_eq(game.economy_manager.discursos, 5.0, "Discursos remain unchanged")

# Tier 2: Boundary & Corner Cases (5 tests)

func test_06_buy_upgrade_with_exact_funds() -> void:
	game.economy_manager.discursos = 10.0
	game.economy_manager.upgrades[0].count = 0
	var success = game.economy_manager.buy_upgrade(0)
	assert_true(success, "Purchase succeeds with exact funds")
	assert_eq(game.economy_manager.discursos, 0.0, "Discursos is exactly 0.0")

func test_07_upgrade_cost_rounding() -> void:
	# Custo a nível 2: 10 * 1.15^2 = 10 * 1.3225 = 13.225 -> int = 13
	game.economy_manager.upgrades[0].count = 2
	var cost = game.economy_manager.get_upgrade_cost(0)
	assert_eq(cost, 13, "Cost at level 2 is correctly truncated to 13")

func test_08_dps_multiplier_application() -> void:
	for upg in game.economy_manager.upgrades:
		upg.count = 0
	game.economy_manager.upgrades[0].count = 2 # dps = 2.0
	game.economy_manager.prestige_multiplier = 2.5
	game.economy_manager._recalculate_dps()
	assert_eq(game.economy_manager.discursos_por_segundo, 5.0, "DPS multiplied by prestige multiplier: 2.0 * 2.5 = 5.0")

func test_09_invalid_upgrade_index() -> void:
	var success1 = game.economy_manager.buy_upgrade(-1)
	var success2 = game.economy_manager.buy_upgrade(99)
	var cost1 = game.economy_manager.get_upgrade_cost(-1)
	var cost2 = game.economy_manager.get_upgrade_cost(99)
	
	assert_true(not success1, "Cannot buy upgrade with index -1")
	assert_true(not success2, "Cannot buy upgrade with index 99")
	assert_eq(cost1, 9999999, "Cost of invalid upgrade -1 is 9999999")
	assert_eq(cost2, 9999999, "Cost of invalid upgrade 99 is 9999999")

func test_10_upgrade_purchase_saves_state() -> void:
	game.economy_manager.discursos = 20.0
	game.economy_manager.upgrades[0].count = 0
	game.economy_manager.buy_upgrade(0)
	
	# Load from save file to check
	var saved_data = AppSaveManager.load_game()
	assert_true(not saved_data.is_empty(), "Save file is not empty")
	var counts = saved_data.get("upgrades_counts", [])
	assert_true(counts.size() > 0, "Save contains upgrades count array")
	if counts.size() > 0:
		assert_eq(int(counts[0]), 1, "Saved upgrade 0 count is 1")
