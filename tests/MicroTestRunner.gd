extends Node
class_name MicroTestRunner

var passed_tests = 0
var failed_tests = 0

func _ready() -> void:
	print("==================================")
	print(" Iniciando Suíte de Testes (QA)   ")
	print("==================================")
	
	run_tests()
	
	print("==================================")
	print(" Resultados do Teste:")
	print(" Passou: %d | Falhou: %d" % [passed_tests, failed_tests])
	print("==================================")
	
	# Aguardar 2 frames para os logs serem printados antes de fechar a janela, se rodado com F6
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if failed_tests > 0 else 0)

func run_tests() -> void:
	pass # Sobrescrito nas subclasses

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed_tests += 1
		print("[PASS] " + msg)
	else:
		failed_tests += 1
		print("[FAIL] " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	if typeof(actual) == TYPE_FLOAT and typeof(expected) == TYPE_FLOAT:
		# Floating point tolerance
		if abs(actual - expected) < 0.001:
			passed_tests += 1
			print("[PASS] " + msg)
		else:
			failed_tests += 1
			print("[FAIL] %s - Recebeu %s, Esperava %s" % [msg, str(actual), str(expected)])
	elif actual == expected:
		passed_tests += 1
		print("[PASS] " + msg)
	else:
		failed_tests += 1
		print("[FAIL] %s - Recebeu %s, Esperava %s" % [msg, str(actual), str(expected)])
