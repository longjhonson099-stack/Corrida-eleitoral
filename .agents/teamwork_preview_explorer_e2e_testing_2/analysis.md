# Headless E2E Testing Architecture & Layout Recommendations

This document outlines the recommendations and architecture design for a headless End-to-End (E2E) test runner and its test suite for the **Corrida Eleitoral de Brasílica** project in Godot 4.

---

## 1. E2E Test Runner Architecture Design

Running E2E tests in a headless Godot environment requires a custom class that inherits from `SceneTree` instead of `Node`. When running Godot with the `--script` (or `-s`) argument, the engine executes the script as the main loop. Inheriting from `SceneTree` allows the runner to:
1. Load, instantiate, and add the main game scene (`Game.tscn`) to the viewport/root node.
2. Control the progression of frames via `await process_frame`.
3. Sequentially execute asynchronous test cases that simulate user input and wait for game state updates.
4. Safely handle test setup and teardown, including database/save file isolation.
5. Exit the process with an appropriate status code (0 for success, 1 for failure).

We propose a two-part architecture:
*   **`tests/E2ETestRunner.gd`**: The core driver that manages CLI arguments, save game backup/restoration, test discovery, and the sequential execution loop.
*   **`tests/E2ETestCase.gd`**: A base class for test cases that provides assertion helper functions and holds contextual references to the runner and the active game instance.

### `tests/E2ETestRunner.gd` Proposed Implementation

```gdscript
# tests/E2ETestRunner.gd
extends SceneTree

const TEST_DIR = "res://tests/e2e/"
const SAVE_PATH = "user://savegame.save"
const SAVE_BACKUP_PATH = "user://savegame.save.bak"

var passed_tests: int = 0
var failed_tests: int = 0
var current_test_failed: bool = false

func _init() -> void:
	print("====================================================")
	print("  CORRIDA ELEITORAL - HEADLESS E2E TEST RUNNER")
	print("====================================================")
	
	# Step 1: Isolate and backup any pre-existing developer save file
	_backup_save()
	
	# Step 2: Discover test files
	var test_files = _discover_tests()
	print("[RUNNER] Encontrados %d arquivos de teste E2E." % test_files.size())
	
	# Step 3: Run each test sequentially
	for test_file in test_files:
		await _run_test_file(test_file)
		
	# Step 4: Restore original save game
	_restore_save()
	
	# Step 5: Report results and quit
	print("====================================================")
	print("  RESULTADOS DOS TESTES E2E:")
	print("  Passou: %d  |  Falhou: %d" % [passed_tests, failed_tests])
	print("====================================================")
	
	quit(1 if failed_tests > 0 else 0)

func _backup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_PATH, SAVE_BACKUP_PATH)
			dir.remove(SAVE_PATH)
			print("[RUNNER] Backup de save existente realizado em '%s'." % SAVE_BACKUP_PATH)

func _restore_save() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if FileAccess.file_exists(SAVE_BACKUP_PATH):
			if FileAccess.file_exists(SAVE_PATH):
				dir.remove(SAVE_PATH)
			dir.copy(SAVE_BACKUP_PATH, SAVE_PATH)
			dir.remove(SAVE_BACKUP_PATH)
			print("[RUNNER] Save original do dev restaurado com sucesso.")
		elif FileAccess.file_exists(SAVE_PATH):
			dir.remove(SAVE_PATH)

func _discover_tests() -> Array[String]:
	var files: Array[String] = []
	var dir = DirAccess.open(TEST_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".gd") and file_name.begins_with("test_"):
				files.append(TEST_DIR + file_name)
			file_name = dir.get_next()
	else:
		print("[RUNNER] [ERROR] Direotório de testes E2E não encontrado em '%s'" % TEST_DIR)
	files.sort() # Garante execução em ordem previsível
	return files

func _run_test_file(path: String) -> void:
	print("\n----------------------------------------------------")
	print("[RUNNING] Teste: %s" % path.get_file())
	print("----------------------------------------------------")
	current_test_failed = false
	
	# 1. Garante que cada teste inicie sem nenhum arquivo de save anterior
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		
	# 2. Instancia a cena principal do jogo
	var game_scene = load("res://scenes/main/Game.tscn")
	if not game_scene:
		print("[RUNNER] [FAIL] Não foi possível carregar Game.tscn")
		failed_tests += 1
		return
		
	var game = game_scene.instantiate() as Game
	root.add_child(game)
	
	# Aguarda frames de física e processos para inicializar nós e timers do jogo
	await process_frame
	await process_frame
	
	# 3. Carrega o script de teste
	var test_script = load(path)
	if not test_script:
		print("[RUNNER] [FAIL] Não foi possível carregar o arquivo de script: %s" % path)
		failed_tests += 1
		game.queue_free()
		return
		
	var test_case = test_script.new()
	if not test_case:
		print("[RUNNER] [FAIL] Erro ao instanciar teste: %s" % path)
		failed_tests += 1
		game.queue_free()
		return
		
	# Injeta dependências contextuais
	test_case.runner = self
	test_case.game = game
	root.add_child(test_case)
	
	# 4. Executa a rotina do teste
	if test_case.has_method("run"):
		await test_case.run()
	else:
		print("[RUNNER] [FAIL] O arquivo de teste não implementa a função 'run()'.")
		current_test_failed = true
		
	# 5. Avalia resultado do caso
	if current_test_failed:
		failed_tests += 1
		print("[RESULT] %s: FALHOU ❌" % path.get_file())
	else:
		passed_tests += 1
		print("[RESULT] %s: PASSOU   " % path.get_file())
		
	# 6. Desaloca as instâncias temporárias para o próximo teste
	test_case.queue_free()
	game.queue_free()
	
	# Aguarda a desalocação no frame subsequente
	await process_frame
```

### `tests/E2ETestCase.gd` Proposed Implementation

```gdscript
# tests/E2ETestCase.gd
extends Node
class_name E2ETestCase

var runner: SceneTree
var game: Game

# Função principal de teste a ser sobrescrita nas subclasses
func run() -> void:
	pass

# --- Assertions que notificam o Runner em caso de falha ---

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		print("  [PASS] %s" % msg)
	else:
		print("  [FAIL] %s (Esperava true, recebeu false)" % msg)
		runner.current_test_failed = true

func assert_false(condition: bool, msg: String) -> void:
	if not condition:
		print("  [PASS] %s" % msg)
	else:
		print("  [FAIL] %s (Esperava false, recebeu true)" % msg)
		runner.current_test_failed = true

func assert_eq(actual, expected, msg: String) -> void:
	if typeof(actual) == TYPE_FLOAT and typeof(expected) == TYPE_FLOAT:
		if abs(actual - expected) < 0.0001:
			print("  [PASS] %s" % msg)
		else:
			print("  [FAIL] %s (Esperava %s, recebeu %s)" % [msg, str(expected), str(actual)])
			runner.current_test_failed = true
	elif actual == expected:
		print("  [PASS] %s" % msg)
	else:
		print("  [FAIL] %s (Esperava %s, recebeu %s)" % [msg, str(expected), str(actual)])
		runner.current_test_failed = true

# --- Helpers de Interação Comuns ---

func wait_seconds(seconds: float) -> void:
	await runner.create_timer(seconds).timeout

func click_button(btn: Button) -> void:
	if btn == null:
		print("  [WARN] Tentou clicar em botão nulo.")
		runner.current_test_failed = true
		return
	if btn.disabled:
		print("  [WARN] Tentou clicar no botão desabilitado: %s" % btn.name)
		return
	btn.pressed.emit()
	# Dá 1 frame para as lambdas de sinal processarem
	await runner.process_frame
```

---

## 2. E2E Testing Simulation Mechanics

Para simular o comportamento de um jogador real headlessly, os testes devem emular interações do motor gráfico de forma determinística:

### A. Simulação de Cliques
Cliques em botões (`Button`) na interface (ex. `BtnGenerate`, upgrades, notícias) devem ser simulados disparando o sinal `pressed` do próprio nó (`button.pressed.emit()`). Isso garante que todas as conexões (funções lambda ou métodos conectados) rodem no mesmo contexto da thread principal.

### B. Avanço do Tempo e Esperas
Em testes E2E, interações como o spawn de notícias ou a geração passiva de recursos ocorrem ao longo de vários frames. Nós simulamos o avanço do tempo:
*   Usando `await runner.create_timer(duration).timeout` para esperar frações de segundo.
*   Manipulando o `delta` do loop do jogo indiretamente ou acelerando os `Timer` internos do jogo diretamente (ex: forçando o trigger `_simulate_enemy_faction` chamando a função correspondente para evitar esperas reais longas em testes de longa duração).

### C. Mocking do `LocalLLMClient`
Como o `LocalLLMClient` fará chamadas HTTP assíncronas para um modelo local (ex: Ollama) que pode não estar ativo durante testes locais ou em CI/CD, os testes E2E devem injetar um **Mock** no lugar da instância real na árvore de cena.

```gdscript
# tests/mocks/MockLocalLLMClient.gd
extends Node
class_name MockLocalLLMClient

signal speech_generated(text: String)
signal generation_failed(error_msg: String)

var mock_success: bool = true
var mock_response_text: String = "Discurso Satírico Mockado para Fins de Teste!"
var mock_error_msg: String = "Erro simulado do Ollama API"
var delay_seconds: float = 0.1

func generate_speech_async(topic: String, prompt: String) -> void:
	await get_tree().create_timer(delay_seconds).timeout
	if mock_success:
		speech_generated.emit(mock_response_text)
	else:
		generation_failed.emit(mock_error_msg)
```

No teste de LLM, o script de teste substituirá o cliente real do jogo:
```gdscript
# Trecho de teste injetando o mock
var mock_client = MockLocalLLMClient.new()
game.add_child(mock_client)
# Configura o script do game para apontar para o mock
game.local_llm_client = mock_client
```

---

## 3. Organization and layout of 71+ test cases

Os testes serão estruturados em arquivos separados dentro de `tests/e2e/`. Cada arquivo conterá um subgrupo focado em uma funcionalidade ou tier. 

*   `tests/e2e/test_01_manual_clicker.gd` (Casos TC-T1-MC e TC-T2-MC)
*   `tests/e2e/test_02_upgrades.gd` (Casos TC-T1-UP e TC-T2-UP)
*   `tests/e2e/test_03_prestige.gd` (Casos TC-T1-PR e TC-T2-PR)
*   `tests/e2e/test_04_fake_news.gd` (Casos TC-T1-FN e TC-T2-FN)
*   `tests/e2e/test_05_llm_speech.gd` (Casos TC-T1-LM e TC-T2-LM)
*   `tests/e2e/test_06_tug_of_war.gd` (Casos TC-T1-TW e TC-T2-TW)
*   `tests/e2e/test_07_cross_features.gd` (Casos TC-T3-COMB)
*   `tests/e2e/test_08_real_world.gd` (Casos TC-T4-SCEN)

Abaixo está o detalhamento completo dos **71 Casos de Teste**, distribuídos em 4 Tiers.

---

### Tier 1: Feature Coverage (30 Casos - 5 por Funcionalidade)

Verifica o fluxo funcional básico de cada recurso do projeto de acordo com as especificações.

| ID | Feature | Nome do Teste | Configuração / Inputs | Passos de Execução | Resultado Esperado | Rationale |
|:---|:---|:---|:---|:---|:---|:---|
| **TC-T1-MC-01** | Manual Clicker | Incremento Simples de Discursos | Jogo inicializado com saldo 0 discursos. | Clicar em `BtnGenerate` uma vez. | Discursos = 1.0 (ou prestige_multiplier * 1.0). | Valida a adição manual de recursos. |
| **TC-T1-MC-02** | Manual Clicker | Influência no Tug of War | Red score = 50.0. Blue score = 50.0. | Clicar em `BtnGenerate` uma vez. | Red score = 50.2. Bar atualizada. | Valida a influência de cliques no equilíbrio partidário. |
| **TC-T1-MC-03** | Manual Clicker | Animação de Clique | Botão `BtnGenerate` carregado na tela. | Clicar em `BtnGenerate`. | Escala do botão encolhe para 0.9 e volta para 1.0 via tween. | Garante o feedback de feedback visual do clique (juiciness). |
| **TC-T1-MC-04** | Manual Clicker | Spawn de Texto Flutuante | No FloatingTexts ativo. | Clicar em `BtnGenerate`. | Label "+1.0" é adicionada como filho de FloatingTexts. | Garante o spawn físico do texto indicativo. |
| **TC-T1-MC-05** | Manual Clicker | Cliques Bloqueados pós Game Over | `game_active = false` (Fim de Jogo). | Tentar clicar no botão `BtnGenerate`. | Saldo de discursos e pontuação não se alteram. | Impede trapaça ou clicks pós encerramento. |
| **TC-T1-UP-01** | Upgrades | Compra com Dedução de Saldo | Discursos = 15.0. Upgrade 0 custo = 10. | Chamar clique no primeiro botão da UpgradesList. | Discursos restantes = 5.0. Upgrade count = 1. | Confirma que a economia de compra subtrai saldo devidamente. |
| **TC-T1-UP-02** | Upgrades | Incremento de Nível de Upgrade | Upgrades iniciados em 0. Custo disponível. | Comprar upgrade index 0. | `economy_manager.upgrades[0].count` = 1. | Valida incremento interno de nível do upgrade específico. |
| **TC-T1-UP-03** | Upgrades | Cálculo de DPS Passivo | Upgrades 0 count = 0, DPS = 1.0. | Comprar upgrade 0 (Tia do Zap). | `discursos_por_segundo` = 1.0 * prestige_multiplier. | Valida a aplicação da taxa de DPS na economia. |
| **TC-T1-UP-04** | Upgrades | Acúmulo Passivo de Discursos | Upgrade 0 comprado (DPS=1.0). | Aguardar 1.0 segundo de process_frame. | Discursos > 1.0 (acrescido proporcionalmente ao tempo). | Testa o loop passivo rodando no process. |
| **TC-T1-UP-05** | Upgrades | Habilitação Dinâmica de Botões | Custo Upgrade 0 = 10. Saldo inicia em 0. | Adicionar discursos de 1 em 1 até 10. | Botão de compra passa de desabilitado para habilitado a 10. | Garante que a UI reflete as possibilidades econômicas do jogador. |
| **TC-T1-PR-01** | Prestige | Reset de Saldo de Discursos | Saldo discursos = 5000.0. | Chamar `economy_manager.reset_for_prestige()`. | Discursos = 0.0. | Garante limpeza total de recursos monetários no reset. |
| **TC-T1-PR-02** | Prestige | Limpeza de Upgrades Comprados | Upgrades[0].count = 5. Upgrades[1].count = 2. | Executar prestige. | `count` de todos os upgrades = 0. | Confirma a devolução de níveis ao marco zero. |
| **TC-T1-PR-03** | Prestige | Incremento do Multiplicador | Multiplicador atual = 1.0. | Chamar prestige. | Multiplicador atual = 1.5. | Garante recompensa correta pelo prestige. |
| **TC-T1-PR-04** | Prestige | Recálculo de DPS Pós-Reset | DPS ativo = 24.0. | Executar prestige. | `discursos_por_segundo` = 0.0. | Evita a manutenção de DPS fantasma após perda de upgrades. |
| **TC-T1-PR-05** | Prestige | Persistência do Multiplicador | Estado prestigiado (mult = 1.5). | Chamar save_game e load_game no SaveManager. | Carrega com sucesso `prestige_multiplier` em 1.5. | Garante persistência da recompensa chave. |
| **TC-T1-FN-01** | Fake News | Spawn Aleatório do Botão | news_timer configurado e ativado. | Aguardar timeout do news_timer. | `BtnUrgentNews` é exibido na tela em posição válida. | Garante que eventos aleatórios aparecem dinamicamente. |
| **TC-T1-FN-02** | Fake News | Clique com Bônus Econômico | Botão Urgent News ativo. DPS = 0.0. | Clicar em `BtnUrgentNews`. | Saldo recebe bônus de 100.0 (floor). | Garante pagamento correto do prêmio de fake news. |
| **TC-T1-FN-03** | Fake News | Texto de Feedback Visual | Botão Urgent News ativo. Bônus = 100. | Clicar em `BtnUrgentNews`. | Label com texto contendo "FAKE NEWS! +100" surge na tela. | Garante resposta visual apropriada para eventos rápidos. |
| **TC-T1-FN-04** | Fake News | Despawn por Inação (Timeout) | Botão Urgent News ativo. | Aguardar 3.1 segundos. | Botão modula a transparência, some da tela e reinicia o timer. | Evita que botões de urgência durem eternamente na tela. |
| **TC-T1-FN-05** | Fake News | Reinício do Timer de Spawning | news_timer ativo. | Clicar em `BtnUrgentNews` ativamente. | Timer é resetado com nova duração randômica (20 a 40s). | Garante a continuidade do ciclo de jogo dinâmico. |
| **TC-T1-LM-01** | LLM Speech | Transição para Estado Pensando | Jogo ativo, botão Speech pressionado. | Solicitar discurso chamando API. | UI de fala indica "Pensando..." e bloqueia novos cliques na área. | Previne disparos repetitivos ou travamento de UI. |
| **TC-T1-LM-02** | LLM Speech | Geração Bem-Sucedida | MockLocalLLMClient configurado com sucesso. | Emitir sinal `speech_generated` com texto satirical. | O texto do discurso é renderizado na UI e UI é desbloqueada. | Garante exibição do conteúdo gerado na UI. |
| **TC-T1-LM-03** | LLM Speech | Falha de API com Fallback Procedural | Mock configurado para falhar. | Acionar geração de discurso. | `generation_failed` é disparado; fallback escreve discurso offline. | Blindagem do jogo contra quedas na API do Ollama. |
| **TC-T1-LM-04** | LLM Speech | Estouro de Timeout (5s) | Conexão de rede bloqueada/congelada. | Iniciar geração. Aguardar 5.1s. | Conexão cancela e ativa o gerador de fala offline. | Garante experiência sem gargalos ou congelamento da interface. |
| **TC-T1-LM-05** | LLM Speech | Recompensa de Discurso Entregue | Jogo ativo, speech concluída. | Emitir `speech_generated` com sucesso. | Adiciona recompensa de discursos e impulsiona Tug of War. | Integra a mecânica de fala no ecossistema central do jogo. |
| **TC-T1-TW-01** | Tug of War | Expansão Oponente (Enemy Turn) | Jogo iniciado, enemy_timer configurado. | Aguardar timeout de 1 segundo da facção adversária. | `global_score_blue` recebe incremento passivo de 0.5. | Garante pressão oponente contra a passividade do jogador. |
| **TC-T1-TW-02** | Tug of War | Pressão Passiva do Jogador | DPS ativo = 20.0. Red score = 50. | Passar process frames por delta. | `global_score_red` aumenta baseado em `dps * delta * 0.05`. | Valida acúmulo de influência de upgrades no cabo de guerra. |
| **TC-T1-TW-03** | Tug of War | Sincronia da Barra de Progresso | `global_score_red` = 80, `global_score_blue` = 20. | Chamar `_update_tug_of_war()`. | Valor da `TugOfWarBar` é atualizado para exatamente 80.0%. | Garante o feedback visual correto de domínio partidário. |
| **TC-T1-TW-04** | Tug of War | Condição de Vitória (100% Red) | Red score = 999.0, Blue score = 1.0. | Chamar `_update_tug_of_war()`. | Game Over ativado; EndGamePanel mostra "VITÓRIA!". | Valida a terminação de sucesso do ciclo de jogo. |
| **TC-T1-TW-05** | Tug of War | Condição de Derrota (0% Red) | Red score = 1.0, Blue score = 999.0. | Chamar `_update_tug_of_war()`. | Game Over ativado; EndGamePanel mostra "DERROTA!". | Valida a terminação de fracasso do ciclo de jogo. |

---

### Tier 2: Boundary & Corner Cases (30 Casos - 5 por Funcionalidade)

Verifica a robustez do jogo em condições extremas, limites numéricos ou inputs inesperados.

| ID | Feature | Nome do Teste | Configuração / Inputs | Passos de Execução | Resultado Esperado | Rationale |
|:---|:---|:---|:---|:---|:---|:---|
| **TC-T2-MC-01** | Manual Clicker | Cliques Ultra Rápidos (Burst) | Simulação de 200 cliques no mesmo frame. | Disparar 200 sinais de pressionado em loop direto. | Saldo e pontuação incrementam em exatamente 200x. Sem travamento. | Protege contra input spam e macros do usuário. |
| **TC-T2-MC-02** | Manual Clicker | Multiplicador de Prestige Nulo | `prestige_multiplier` alterado para 0.0. | Clicar em `BtnGenerate` uma vez. | Saldo de discursos = 0.0, mas Red score aumenta em 0.2. | Protege contra comportamento indefinido ou crash em multiplicadores erráticos. |
| **TC-T2-MC-03** | Manual Clicker | Liberação de Memória Sob Clicks | 1000 clicks em sucessão rápida. | Simular cliques e processar frames até fim das durações dos tweens. | Todos os nós temporários de texto flutuante são liberados. | Previne vazamento de memória por excesso de nós na árvore. |
| **TC-T2-MC-04** | Manual Clicker | Click em Botão Deletado | Botão `BtnGenerate` é deletado da árvore. | Chamar função de animação `_animate_button(null)`. | Código retorna imediatamente sem lançar Null Pointer Exception. | Segurança do runner contra UI instável ou carregamento tardio. |
| **TC-T2-MC-05** | Manual Clicker | Input Concorrente com Encerramento | Fim de jogo acionado no mesmo frame que o clique. | Chamar `_end_game` e clicar no `BtnGenerate` no mesmo process cycle. | Clique é desconsiderado. O status do jogo permanece inativo. | Garante o congelamento dos inputs imediatamente no fim do jogo. |
| **TC-T2-UP-01** | Upgrades | Compra com Saldo Exato | Discursos = 10.0. Custo upgrade = 10. | Comprar upgrade. | Saldo final = exatamente 0.0. Compra efetuada. | Valida condições inclusivas de fronteira da transação financeira. |
| **TC-T2-UP-02** | Upgrades | Insuficiência de Saldo Crítica | Discursos = 9.99. Custo upgrade = 10. | Tentar comprar upgrade. | Compra rejeitada. Saldo continua 9.99. Upgrades não alteram. | Garante estrito cumprimento das regras financeiras sem brechas de precisão float. |
| **TC-T2-UP-03** | Upgrades | Índice de Upgrade Inexistente | Chamada com índice fora dos limites (ex. -1, 99). | Executar `buy_upgrade(-1)` ou `get_upgrade_cost(99)`. | Retorna false / 9999999 e loga um aviso no AppLogger. | Evita estouro de limites de arrays (out-of-bounds crash). |
| **TC-T2-UP-04** | Upgrades | Custo de Upgrade Muito Alto (Overflow) | Nível de upgrade simulado em 1000. | Calcular custo de upgrade de nível 1000. | Custo retorna valor com limite de ponto flutuante seguro, sem NaN/Infinity. | Impede que progressão infinita quebre o código por estouro matemático. |
| **TC-T2-UP-05** | Upgrades | Duplo Clique de Compra | Multi-cliques simultâneos em botão de upgrade. | Clicar consecutivamente no mesmo frame. | Apenas a primeira transação é processada se o saldo zerar. | Evita compra em duplicidade com saldo inadequado. |
| **TC-T2-PR-01** | Prestige | Estresse de Prestige Recorrente | Ciclo contínuo de prestiges rápidos (100 vezes). | Executar prestige 100 vezes seguidas no runner. | Multiplicador = exatamente 51.0 (1.0 + 100 * 0.5) sem derivar. | Garante integridade matemática em cenários avançados do jogo. |
| **TC-T2-PR-02** | Prestige | Falha de Escrita Física no Save | Arquivo de save bloqueado ou sem permissão. | Chamar reset de prestige com mock de falha no FileAccess. | O jogo processa o reset normalmente em memória RAM. | Garante resiliência: falhas de gravação física não travam o jogo ativo. |
| **TC-T2-PR-03** | Prestige | Retorno Imediato a Níveis Iniciais | DPS anterior alto. Prestige acionado. | Executar prestige. Esperar tick do timer inimigo. | O cálculo de poder inimigo volta ao mínimo instantaneamente. | Impede desequilíbrio imediato do cabo de guerra pós-reset. |
| **TC-T2-PR-04** | Prestige | Compra no Frame do Reset | Compra e prestige agendados concorrentemente. | Enviar requisições no mesmo frame. | Sistema executa sequencialmente de forma que saldo e upgrades resetados fiquem consistentes. | Garante atômica consistência da transição de reset. |
| **TC-T2-PR-05** | Prestige | Formatação de Rótulos Gigantes | `prestige_multiplier` alterado para 1,000,000.5. | Atualizar UI. | O texto se adequa aos limites visuais do Label sem crash ou quebra. | Impede distorções visuais extremas de layout no game. |
| **TC-T2-FN-01** | Fake News | Spawn na Borda Direta da UI | Janela redimensionada para resoluções mínimas. | timeout do timer de notícias urgentes. | Posição randômica calculada fica estritamente visível dentro da tela. | Evita spawns inacessíveis fora da visão do jogador. |
| **TC-T2-FN-02** | Fake News | Clique no Frame Limite de Despawn | Botão Urgent News quase invisível (`modulate.a = 0.01`). | Disparar clique no botão de fake news. | Clique aceito com sucesso e bônus é pago ao jogador. | Garante ausência de race conditions no frame limite de timeout. |
| **TC-T2-FN-03** | Fake News | Coexistência de Popups | Forçar múltiplos spawns concorrentes na mesma tela. | Desencadear eventos de spawn sem intervalo. | Popups calculam posições diferentes sem se sobrepor na mesma coordenada. | Evita que notícias urgentes fiquem empilhadas e ocultem umas às outras. |
| **TC-T2-FN-04** | Fake News | Limite de Bônus Mínimo Garantido | DPS = 0.0. | Clicar em notícia urgente. | Bônus creditado = exatamente 100.0 discursos. | Protege contra multiplicação por zero no estágio inicial do jogo. |
| **TC-T2-FN-05** | Fake News | Spam de Cliques na Notícia Urgente | Clicar rapidamente no botão de fake news 10 vezes. | Disparar cliques simultâneos. | O botão é ocultado no primeiro clique e apenas 1 bônus é somado. | Previne ganho excessivo de bônus explorando latência de sumiço do nó. |
| **TC-T2-LM-01** | LLM Speech | Inputs de Texto Vazios / Nulos | Tópico = "", Prompt = "". | Chamar `generate_speech_async("", "")`. | Fallback procedural é ativado gerando discurso genérico estável. | Impede que a ausência de inputs de texto quebre o processamento. |
| **TC-T2-LM-02** | LLM Speech | Servidor Remoto Indisponível | Ollama fora do ar (erro de conexão física). | Iniciar geração de discurso. | Erro de conexão capturado instantaneamente, caindo no fallback offline. | Garante que o jogo funcione em modo avião sem problemas. |
| **TC-T2-LM-03** | LLM Speech | Payload de API Corrompido | Servidor retorna string não-JSON ou erro HTTP 500. | Simular resposta malformada HTTP da API. | Cliente trata o parser JSON falho e entrega o fallback offline. | Evita exceções de parser no script de integração com Ollama. |
| **TC-T2-LM-04** | LLM Speech | Cliques Simultâneos de Solicitação | Clicar 5 vezes seguidas no botão de discursar. | Simular requisições concorrentes antes do primeiro retorno. | Apenas a primeira chamada segue ativa; as demais são descartadas. | Impede estouro de conexões ativas na máquina cliente. |
| **TC-T2-LM-05** | LLM Speech | Reset de Estado com Requisição Ativa | Chamada de API pendente. Botão Restart clicado. | Reiniciar jogo enquanto aguarda resposta assíncrona. | A resposta que chega após o restart é ignorada e não altera saldo. | Evita injeção de saldo fantasma em novas partidas. |
| **TC-T2-TW-01** | Tug of War | Prevenção de Divisão por Zero | Pontuações Red e Blue forçadas a 0. | Chamar `_update_tug_of_war()`. | Red percent padrão = 50.0%. Erro capturado de forma limpa. | Evita crash clássico do motor ao lidar com porcentagens de scores nulos. |
| **TC-T2-TW-02** | Tug of War | Scores Massivos com Alta Precisão | Red = 500,000,000, Blue = 500,000,000. | Clicar para adicionar Red score (+0.2). | Cálculo de percentual reflete a alteração de forma correta e sem overflow. | Assegura estabilidade em partidas longas e números extremos. |
| **TC-T2-TW-03** | Tug of War | Interrupção Total Pós-Fim de Jogo | `game_active = false`. | Chamar timer inimigo e ticks de processamento de score. | Pontuações permanecem estáticas e não sofrem alteração. | Garante que a tela de vitória/derrota não sofra oscilações. |
| **TC-T2-TW-04** | Tug of War | Transição Concorrente de Limiares | Fazer Red bater 99.9% e Blue 0.1% na mesma atualização. | Forçar limiares máximos e mínimos simultâneos. | O jogo encerra baseado no primeiro check sem gerar conflito. | Previne a abertura concomitante de telas de vitória e derrota. |
| **TC-T2-TW-05** | Tug of War | Clamping da Barra de Progresso | Red score = 1000, Blue = -10 (corrupção). | Atualizar progress bar. | Valor final da UI progress bar é limitado entre 0% e 100%. | Protege a UI contra bugs de layout e estouro gráfico da barra. |

---

### Tier 3: Cross-Feature Combinations (6 Casos - Pairwise)

Testes de integração que verificam a consistência quando duas ou mais mecânicas operam em conjunto.

| ID | Nome do Teste | Relação de Funcionalidades | Configuração / Inputs | Passos de Execução | Resultado Esperado | Rationale |
|:---|:---|:---|:---|:---|:---|:---|
| **TC-T3-COMB-01** | Clicks Concorrentes com DPS Ativo | Manual Clicker ↔ Upgrades | DPS = 10.0. Saldo = 0. | Clicar em gerar discursos 5 vezes enquanto o process delta corre por 1.0s. | Saldo = 15.0 (5 de cliques + 10 do DPS acumulado). | Garante acúmulo paralelo e sem interrupções de recursos ativos e passivos. |
| **TC-T3-COMB-02** | Upgrade Pós Prestige | Upgrades ↔ Prestige | Prestige realizado (mult=1.5x). Upgrades zerados. | Comprar 1 upgrade (Tia do Zap). | Custo = base (10). DPS resultante = 1.5 (1.0 * 1.5). | Garante aplicação imediata do novo multiplicador de prestígio nas novas compras. |
| **TC-T3-COMB-03** | Cabo de Guerra sob Clique Intenso | Manual Clicker ↔ Tug-of-War | Enemy power = 0.5/s. Jogador clica a 10 Hz (10x por segundo). | Iniciar jogo e clicar continuamente por 2 segundos. | Red percentage aumenta progressivamente. | Garante que o input manual é rápido e forte o suficiente para superar a IA adversária inicial. |
| **TC-T3-COMB-04** | Escalonamento do Bônus de Notícias | Upgrades ↔ Fake News | Upgrades comprados até DPS = 100.0. | Spawnar notícia urgente e clicar nela. | Bônus = 3000.0 discursos (`dps * 30`). | Valida a integração progressiva do prêmio de notícias conforme a economia escala. |
| **TC-T3-COMB-05** | Recompensa de Fala Prestigiada | LLM Speech ↔ Prestige | Prestige ativo (mult=2.0x). LLM Speech concluído. | Receber discurso satirical gerado. | Recompensa de discursos creditada = base * 2.0. | Verifica se os bônus gerados pelo LLM respeitam a progressão global do prestígio. |
| **TC-T3-COMB-06** | Reset de Influência Pós Prestige | Prestige ↔ Tug-of-War | Cabo de guerra desequilibrado. Prestige acionado. | Chamar reset de prestígio. | Red e Blue scores voltam para 50.0; taxa de ganho passivo zera. | Valida a limpeza de influência ativa para iniciar um ciclo neutro de prestígio. |

---

### Tier 4: Real-World Application Scenarios (5 Casos - Partidas Completas)

Simulações completas de caminhos possíveis de jogadores do início ao fim (Vitória ou Derrota).

*   **`TC-T4-SCEN-01: Manual Speedrun to Victory (Caminho do Clicker Exclusivo)`**
    *   *Descrição*: Um jogador com cliques extremamente rápidos tenta vencer o jogo imediatamente sem comprar nenhum upgrade.
    *   *Configuração/Setup*: Jogo inicializado em estado original neutro.
    *   *Passos de Execução*:
        1. Emular clique em `BtnGenerate` continuamente (a 20 cliques por segundo).
        2. Aguardar frames até que a pontuação vermelha avance gradualmente.
        3. Ignorar qualquer notificação de Fake News ou botões de upgrades.
    *   *Resultado Esperado*: A barra atinge >= 99.9%. Tela de Vitória é exibida. Saldo de upgrades permanece zerado.
    *   *Rationale*: Testa a viabilidade lógica de ganhar o jogo usando exclusivamente cliques mecânicos sob pressão da IA inimiga padrão.

*   **`TC-T4-SCEN-02: Passive-Only Automation Victory (Caminho Idle)`**
    *   *Descrição*: Um jogador "idle" que apenas acumula discursos passivamente e investe tudo em upgrades de alta escala assim que se tornam acessíveis.
    *   *Configuração/Setup*: Injetar saldo inicial de discursos suficiente para acelerar as compras iniciais do teste.
    *   *Passos de Execução*:
        1. Comprar upgrades de forma escalonada (10 Tia do Zap, 5 Robôs, 2 Vazamento de Dossiê).
        2. Não efetuar cliques manuais na tela.
        3. Deixar a simulação rodar por tempo equivalente a 20 ticks do timer.
    *   *Resultado Esperado*: O acúmulo de DPS passivo eleva a pontuação vermelha de forma exponencial até empurrar a oposição a zero. Tela de Vitória ativa com 0 cliques manuais registrados.
    *   *Rationale*: Garante que a economia autônoma (DPS) consegue guiar o jogador à vitória sem intervenções mecânicas constantes.

*   **`TC-T4-SCEN-03: Prestige-Focused Progression Playthrough (Caminho Estratégico)`**
    *   *Descrição*: Simulação de gameplay de longo prazo onde o jogador joga ativamente, atinge um gargalo, executa o prestige para obter o bônus de 1.5x e então progride rapidamente para a vitória definitiva.
    *   *Configuração/Setup*: Estado inicial neutro.
    *   *Passos de Execução*:
        1. Acumular 1000 discursos usando cliques e upgrades básicos.
        2. Executar reset para Prestige. Multiplicador vai a 1.5x.
        3. Utilizar o multiplicador de 1.5x para recomprar upgrades a um custo inicial baixo.
        4. Acumular DPS massivo e derrotar a oposição.
    *   *Resultado Esperado*: Vitória conquistada no segundo ciclo. O multiplicador final de prestígio é salvo como 1.5x. O tempo de vitória no segundo ciclo é sensivelmente menor.
    *   *Rationale*: Valida o ciclo central (core loop) e a integridade de persistência do progresso estratégico.

*   **`TC-T4-SCEN-04: Fake News Opportunist Path (Caminho Sensacionalista)`**
    *   *Descrição*: O jogador mantém investimentos mínimos em upgrades, mas monitora a tela para clicar em todos os popups de fake news que surgem, usando esse fluxo financeiro para ganhar o cabo de guerra.
    *   *Configuração/Setup*: Configurar o Timer de notícias urgentes com um wait_time artificialmente curto (ex. 1.0s) para acelerar a simulação.
    *   *Passos de Execução*:
        1. Manter upgrades no nível 0 ou 1.
        2. Aguardar spawn de `BtnUrgentNews`.
        3. Clicar imediatamente no popup assim que ele for adicionado e exibido na tela.
        4. Usar o bônus de discursos acumulado para comprar upgrades maciços.
    *   *Resultado Esperado*: Cada clique de Fake News gera grandes bônus que mudam o equilíbrio do Tug of War a favor do jogador. Vitória obtida primariamente através dos prêmios de notícias urgentes.
    *   *Rationale*: Garante que o balanceamento dos eventos randômicos de fake news é recompensador e funcional no fluxo geral.

*   **`TC-T4-SCEN-05: Satirical Speechwriter Path (Caminho Oratório)`**
    *   *Descrição*: O jogador aposta no engajamento político por meio do gerador de discursos assíncronos do LLM para acumular grandes massas de seguidores e fechar o jogo.
    *   *Configuração/Setup*: Injetar o `MockLocalLLMClient` configurado para responder com sucesso após um curto delay.
    *   *Passos de Execução*:
        1. Clicar no botão para iniciar discursos sob tópicos específicos.
        2. Aguardar a resposta assíncrona do LLM mockado.
        3. Aceitar o discurso gerado, recebendo o bônus de discurso e o impulso no Tug of War.
        4. Repetir o processo consecutivamente.
    *   *Resultado Esperado*: Vitória atingida pela via oratória. A interface mostra as falas satíricas atualizadas sucessivamente.
    *   *Rationale*: Garante que a nova mecânica principal de IA (Milestone 2 e 4) está totalmente amarrada à vitória econômica e ao cabo de guerra.

---

## 4. Suggested File Layout and Execution Guidelines

Propomos a organização física dos arquivos de teste e utilitários da seguinte forma dentro do projeto:

```
CorridaEleitoral/
├── tests/
│   ├── E2ETestRunner.gd          # O SceneTree Runner principal
│   ├── E2ETestCase.gd            # Classe base de assertions E2E
│   ├── MicroTestRunner.gd        # Runner de testes unitários legados
│   ├── TestEconomy.gd            # Testes unitários de economia legados
│   ├── TestSaveSystem.gd         # Testes unitários do save legados
│   ├── mocks/
│   │   └── MockLocalLLMClient.gd # Mock utilitário para chamadas de IA
│   └── e2e/                      # Diretório de descoberta do Runner
│       ├── test_01_manual_clicker.gd
│       ├── test_02_upgrades.gd
│       ├── test_03_prestige.gd
│       ├── test_04_fake_news.gd
│       ├── test_05_llm_speech.gd
│       ├── test_06_tug_of_war.gd
│       ├── test_07_cross_features.gd
│       └── test_08_real_world.gd
```

### Comandos de Execução Recomendados

Para executar a suíte inteira de forma automatizada (por exemplo, em um terminal local ou servidor de Integração Contínua/CI):

```powershell
# Execução da suíte completa de testes E2E em modo Headless
C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd
```

Caso o desenvolvedor precise filtrar a execução de um teste específico na depuração, o script do Runner pode ser estendido para ler argumentos passados por CLI:

```powershell
# Exemplo de extensão futura para filtrar um arquivo específico
Godot_console.exe --headless -s tests/E2ETestRunner.gd --test-file=test_01_manual_clicker.gd
```
