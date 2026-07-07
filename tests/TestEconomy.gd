extends MicroTestRunner
class_name TestEconomy

func run_tests() -> void:
	print("--- Testando EconomyManager ---")
	test_upgrade_cost_scaling()
	test_dps_calculation()
	test_prestige_reset()

func test_upgrade_cost_scaling() -> void:
	var economy = EconomyManager.new()
	
	# Upgrade 0 (Tia do Zap) base_cost = 10
	var cost_lvl0 = economy.get_upgrade_cost(0)
	assert_eq(cost_lvl0, 10, "Custo do upgrade nível 0 deve ser o base (10)")
	
	economy.upgrades[0].count = 1
	var cost_lvl1 = economy.get_upgrade_cost(0)
	assert_eq(cost_lvl1, 11, "Custo do upgrade nível 1 deve ser 11 (10 * 1.15 = 11.5 -> int)")
	
	economy.free()

func test_dps_calculation() -> void:
	var economy = EconomyManager.new()
	
	# Compra 2 Tias do Zap (dps = 1.0) e 1 Robô (dps = 12.0)
	economy.upgrades[0].count = 2
	economy.upgrades[1].count = 1
	
	economy._recalculate_dps()
	
	assert_eq(economy.discursos_por_segundo, 14.0, "DPS deve ser 14.0 (2*1.0 + 1*12.0)")
	
	economy.free()

func test_prestige_reset() -> void:
	var economy = EconomyManager.new()
	
	economy.discursos = 5000.0
	economy.upgrades[0].count = 5
	economy.prestige_multiplier = 1.0
	
	economy.reset_for_prestige()
	
	assert_eq(economy.discursos, 0.0, "Discursos devem zerar após prestige")
	assert_eq(economy.upgrades[0].count, 0, "Upgrades devem zerar após prestige")
	assert_eq(economy.prestige_multiplier, 1.5, "Multiplicador deve subir para 1.5")
	
	economy.free()
