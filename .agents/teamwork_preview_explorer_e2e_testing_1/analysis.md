# Architecture and Layout Recommendations for Headless Godot E2E Test Runner

This document outlines the architecture, layout, design, and specific test cases for a headless End-to-End (E2E) testing framework for the "Corrida Eleitoral de Brasílica" project.

---

## 1. Executive Summary

The "Corrida Eleitoral de Brasílica" project is a polarizing idle clicker game structured around:
1. **`Game.gd`**: The main controller managing UI nodes (`BtnGenerate`, `BtnUrgentNews`, progress bars, overlays), game loop states, and timer events.
2. **`EconomyManager.gd`**: A data-driven manager tracking speeches (discursos), upgrade counts (e.g. Tia do Zap, Exército de Robôs), and prestige levels, utilizing automatic saving via `AppSaveManager`.
3. **`AppSaveManager` & `AppLogger`**: Utility autoload singletons facilitating disk persistence (`user://savegame.save`) and structured logging.

Currently, the project contains micro-tests (`tests/TestEconomy.gd`, `tests/TestSaveSystem.gd`) that extend `MicroTestRunner` (which inherits from `Node`). Running these via the command-line `-s` switch fails because Godot requires scripts executed with `-s` to inherit from `SceneTree` or `MainLoop`.

To address this, we propose an **E2E test suite** architecture driven by `tests/E2ETestRunner.gd` (inheriting from `SceneTree`), executing tests inside a headless environment. The E2E tests will instantiate `Game.tscn` in a clean, isolated root viewport, mock asynchronous systems (like the planned LocalLLMClient), run tests sequentially, and exit cleanly with proper shell exit codes.

---

## 2. Headless Godot SceneTree Runner Design

### 2.1 Why SceneTree over Node?
In Godot, running a script from the console via `-s <script_path>` replaces the default main loop. If the script extends `Node`, Godot throws:
`ERROR: Can't load the script "..." as it doesn't inherit from SceneTree or MainLoop.`

By extending `SceneTree`, the test runner script acts as the main program controller. We can programmatically instantiate the actual game scenes, add them to the root viewport, simulate frames, handle signals asynchronously, and invoke `quit(exit_code)` to communicate results back to CI/CD pipelines or local command scripts.

### 2.2 Constructor Coroutine Workaround
GDScript constructors (`_init()`) cannot act as coroutines; using `await` inside `_init()` throws runtime errors. To run asynchronous E2E tests (which require waiting for process frames, timers, and signals), the runner delegates the test execution using `call_deferred("_run_all_tests")`. This postpones execution to the first frame of the active main loop, allowing full coroutine support via `await`.

### 2.3 Proposed `tests/E2ETestRunner.gd` Script

```gdscript
extends SceneTree

# E2ETestRunner.gd
# Entry point for headless/console E2E test runs.
# Execute via:
# <Godot_Executable> --headless -s tests/E2ETestRunner.gd

const E2E_TEST_DIR = "res://tests/e2e/"
var passed_cases: int = 0
var failed_cases: int = 0

func _init() -> void:
	# Workaround: constructor cannot yield/await. Defer to the first active frame.
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	print("==================================================")
	print("🚦 STARTING HEADLESS E2E TEST RUNNER")
	print("==================================================")
	
	# Clear pre-existing save files before starting the suite
	_delete_save_file()
	
	var dir = DirAccess.open(E2E_TEST_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".gd") and file_name != "E2ETestBase.gd":
				var full_path = E2E_TEST_DIR + file_name
				await _run_test_file(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("❌ [ERROR] Could not open E2E test directory: ", E2E_TEST_DIR)
		failed_cases += 1
		
	print("==================================================")
	print("🏁 E2E RUN COMPLETE")
	print("Passed Cases: %d | Failed Cases: %d" % [passed_count_from_runs(), failed_count_from_runs()])
	print("==================================================")
	
	# Final cleanup
	_delete_save_file()
	
	# Propagate exit code to shell (0 = success, 1 = failure)
	quit(0 if failed_cases == 0 else 1)

func _run_test_file(path: String) -> void:
	print("\n📦 Running Test Suite: %s" % path)
	var script = load(path)
	if not script:
		print("  ❌ [ERROR] Failed to load test script: ", path)
		failed_cases += 1
		return
		
	var test_instance = script.new()
	if not test_instance.has_method("run_test_cases"):
		print("  ❌ [ERROR] Test script lacks 'run_test_cases' method.")
		failed_cases += 1
		return
		
	# Inject SceneTree runner reference into the test script
	test_instance.runner = self
	
	# Run async test cases
	await test_instance.run_test_cases()
	
	passed_cases += test_instance.passed_cases
	failed_cases += test_instance.failed_cases

func _delete_save_file() -> void:
	var save_path = "user://savegame.save"
	if FileAccess.file_exists(save_path):
		var err = DirAccess.remove_absolute(save_path)
		if err != OK:
			push_error("Failed to delete save file " + save_path)

func passed_count_from_runs() -> int:
	return passed_cases

func failed_count_from_runs() -> int:
	return failed_cases
```

---

## 3. Test Suite Structure and Isolation

### 3.1 Save File State Pollution & Cleanup
`EconomyManager.gd` invokes `load_game()` inside `_ready()`, loading any state from `user://savegame.save`. In addition, purchasing upgrades triggers an immediate `save_game()`. 

To prevent cross-test contamination, the E2E framework enforces **strict state isolation** by deleting `user://savegame.save` before and after every single test case. This guarantees that every test case begins with a clean slate (0 speeches, level 0 upgrades, and 1.0x prestige).

### 3.2 Viewport Bounds and Safe Resizing
Headless Godot sets a default window viewport size. E2E tests checking elements like random spawning of urgent news (which calculates coordinates using `size.x` and `size.y`) require standard screen sizes to prevent UI overflow exceptions or negative coordinates. The runner/setup initializes the main scene with a standard mobile canvas aspect ratio (e.g., 1080x1920) before executing tests.

### 3.3 Proposed `tests/e2e/E2ETestBase.gd` Base Class

```gdscript
extends RefCounted
class_name E2ETestBase

var runner: SceneTree
var passed_cases: int = 0
var failed_cases: int = 0

# Set up clean game scene inside runner root
func setup_game() -> Node:
	# Delete save file to prevent EconomyManager.gd from loading existing dev state
	_clear_save_file()
	
	var game_scene = load("res://scenes/main/Game.tscn")
	if not game_scene:
		push_error("E2ETestBase: Failed to load Game.tscn")
		return null
		
	var game = game_scene.instantiate()
	
	# Resize viewport mock sizes if needed before adding to tree
	game.size = Vector2(1080, 1920)
	
	runner.root.add_child(game)
	# Await process frame to resolve _ready() and deferred calls
	await runner.process_frame
	return game

# Clean up game scene and local saves
func teardown_game(game: Node) -> void:
	if game and is_instance_valid(game):
		runner.root.remove_child(game)
		game.queue_free()
	
	# Force tree resolution and garbage collection
	await runner.process_frame
	_clear_save_file()

func _clear_save_file() -> void:
	var save_path = "user://savegame.save"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

# Assertion helpers
func assert_eq(actual, expected, msg: String) -> void:
	if typeof(actual) == TYPE_FLOAT and typeof(expected) == TYPE_FLOAT:
		if abs(actual - expected) < 0.001:
			passed_cases += 1
			print("  [PASS] %s" % msg)
		else:
			failed_cases += 1
			print("  [FAIL] %s - Expected: %s, Got: %s" % [msg, str(expected), str(actual)])
	elif actual == expected:
		passed_cases += 1
		print("  [PASS] %s" % msg)
	else:
		failed_cases += 1
		print("  [FAIL] %s - Expected: %s, Got: %s" % [msg, str(expected), str(actual)])

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed_cases += 1
		print("  [PASS] %s" % msg)
	else:
		failed_cases += 1
		print("  [FAIL] %s - Expected true, got false" % msg)

func assert_false(condition: bool, msg: String) -> void:
	if not condition:
		passed_cases += 1
		print("  [PASS] %s" % msg)
	else:
		failed_cases += 1
		print("  [FAIL] %s - Expected false, got true" % msg)
```

---

## 4. Feature Mocking: Asynchronous LLM Speech Generation

### 4.1 Mocking Strategy (Node-Swapping before Tree Entry)
The planned `LocalLLMClient` will call models asynchronously. To test LLM speech integration without relying on active network interfaces or background LLM services, we use a **Dependency Injection / Node-Swapping** technique.

Because `@onready` variables inside `Game.gd` (e.g. `llm_client = $LocalLLMClient`) only resolve when the node enters the scene tree, we can instantiate the scene, locate the production `LocalLLMClient` node, remove it, and add a subclass `MockLocalLLMClient` with the same node name. When `runner.root.add_child(game)` is subsequently called, `@onready` variables bind directly to the mock instance.

### 4.2 Proposed Mock Class (`tests/mocks/MockLocalLLMClient.gd`)

```gdscript
extends Node
class_name MockLocalLLMClient

signal speech_generated(text: String)
signal generation_failed(error_msg: String)

var should_fail: bool = false
var mock_response_delay: float = 0.05
var mock_speech_text: String = "Discurso do Candidato: Ordem, Progresso e Internet mais rápida!"
var last_topic: String = ""
var last_prompt: String = ""

func generate_speech_async(topic: String, prompt: String) -> void:
	last_topic = topic
	last_prompt = prompt
	
	# Simulate latency asynchronously using scene tree timers
	await get_tree().create_timer(mock_response_delay).timeout
	
	if should_fail:
		generation_failed.emit("Modelo local indisponível (HTTP 503)")
	else:
		speech_generated.emit(mock_speech_text)
```

---

## 5. Specification of 71+ E2E Test Cases

We structure the test suite into 4 levels of testing, totaling 71 detailed cases.

### Tier 1: Feature Coverage (30 Cases)
Provides deep base coverage ensuring that every primary feature behaves as expected under standard conditions.

#### Feature 1: Manual Clicker (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 1.1 | Click Increment | Click generate button increases speeches | Instantiate game, click `BtnGenerate` once | Speeches count = `1.0 * prestige_multiplier` (1.0 initially) |
| 1.2 | Click Tug of War | Click generate button increases Red score | Click `BtnGenerate` once | `global_score_red` increases by 0.2 |
| 1.3 | Click Animation | Click triggers scale tween animation on button | Click `BtnGenerate` once | Button scale is modified (tweens to 0.9 then to 1.0) |
| 1.4 | Click Floating Text | Click spawns a visual floating label | Click `BtnGenerate` once | Label node added to `$FloatingTexts` with "+1.0" text |
| 1.5 | Continuous Clicking | High frequency manual clicks accumulate values correctly | Simulate 10 sequential clicks with short frame yields | Speeches = 10.0, Red score = 52.0 |

#### Feature 2: Upgrades (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 2.1 | Upgrade Purchase | Buy Tia do Zap at index 0 when affording | Set speeches = 10.0, call `buy_upgrade(0)` | Speeches = 0.0, Tia do Zap level = 1 |
| 2.2 | DPS Recalculation | Purchase updates total DPS correctly | Set Tia do Zap count = 2, call `_recalculate_dps()` | `discursos_por_segundo` = 2.0 |
| 2.3 | Multiple Upgrade Types | Accumulate different upgrade types | Set Tia do Zap = 1, Exército de Robôs = 1, recalculate | `discursos_por_segundo` = 13.0 (1.0 + 12.0) |
| 2.4 | Passive Speech Income | Process delta accumulates speeches passively | Set `discursos_por_segundo` = 10.0, await 1 second | Speeches count is approximately 10.0 |
| 2.5 | UI Button State | Upgrades UI button text and disabled status update | Buy Tia do Zap, check button at index 0 | Button text shows new level/cost; button disabled if speeches < new cost |

#### Feature 3: Prestige (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 3.1 | Prestige Reset Speeches | Prestige clears accumulated speeches | Set speeches = 1000.0, call `reset_for_prestige()` | Speeches resets to 0.0 |
| 3.2 | Prestige Reset Upgrades | Prestige clears all purchased upgrades | Set upgrades count = [2, 1, 0, 0], call `reset_for_prestige()` | All upgrades counts reset to 0 |
| 3.3 | Prestige Multiplier Rise | Prestige increments fanatismo multiplier | Initial multiplier = 1.0, call `reset_for_prestige()` | `prestige_multiplier` = 1.5 |
| 3.4 | Prestige Click Scaling | Clicks scale with prestige multiplier | Prestige = 1.5, click `BtnGenerate` once | Speeches count = 1.5 |
| 3.5 | Prestige Passive Scaling | Passive income scales with prestige multiplier | Set base DPS = 10.0, prestige = 1.5, recalculate | `discursos_por_segundo` = 15.0 |

#### Feature 4: Fake News (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 4.1 | Urgent News Spawn | Timer trigger displays the Urgent News button | Force trigger `_spawn_urgent_news()` | `btn_urgent_news` becomes visible |
| 4.2 | Urgent News Bounds | Spawns inside standard viewport safe margins | Force trigger `_spawn_urgent_news()` | Button X and Y coordinates fit inside safe boundaries |
| 4.3 | Urgent News Click Reward | Clicking adds correct bonus to speeches | Force trigger, press `btn_urgent_news` | Speeches increases by `max(100.0, dps * 30.0)` |
| 4.4 | Urgent News Click Hide | Button disappears upon user click | Force trigger, press `btn_urgent_news` | `btn_urgent_news` is hidden |
| 4.5 | Urgent News Timer Reset | Timer restarts with random wait time after click | Click urgent news button | `news_timer` starts running with wait time between 20s and 40s |

#### Feature 5: LLM Speech Generation (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 5.1 | LLM Success Flow | Successful speech generation emits success | Trigger `generate_speech_async` (should_fail=false) | `speech_generated` signal is emitted with mock text |
| 5.2 | LLM Failure Flow | Failed speech generation emits failure | Trigger `generate_speech_async` (should_fail=true) | `generation_failed` signal emitted with error details |
| 5.3 | LLM Success Reward | Speech generation success awards player speeches | Setup Mock client, call game speech trigger | Speeches increases (e.g. +500) upon completion |
| 5.4 | LLM Failure Feedback | Speech generation failure logs error / shows UI notification | Trigger failure, check logs/UI | Speeches do not change, error logged via AppLogger |
| 5.5 | LLM UI Update | Generated text displays in the UI console | Complete successful generation | UI panel shows the exact speech text |

#### Feature 6: Tug-of-War Win/Loss (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 6.1 | Victory Condition | Red percent >= 99.9% triggers victory | Set red score = 999.0, blue score = 1.0, call `_update_tug_of_war()` | `end_game_panel` shows, `game_active` = false |
| 6.2 | Defeat Condition | Red percent <= 0.1% triggers defeat | Set red score = 1.0, blue score = 999.0, call `_update_tug_of_war()` | `end_game_panel` shows, `game_active` = false |
| 6.3 | Victory Panel Text | Victory shows correct color and text label | Trigger victory, check `label_result` | Text = "VITÓRIA...", font color is Green |
| 6.4 | Defeat Panel Text | Defeat shows correct color and text label | Trigger defeat, check `label_result` | Text = "DERROTA...", font color is Red |
| 6.5 | Restart Campaign | Clicking restart resets scores and resumes game loop | Click restart button while on end-game panel | red/blue scores = 50.0, panel hidden, `game_active` = true |

---

### Tier 2: Boundary & Corner Cases (30 Cases)
Verifies resilience against extreme states, unexpected inputs, race conditions, and error states.

#### Feature 1: Manual Clicker (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 1.6 | Click post Game Over | Clicking after game ends is ignored | Set `game_active` = false, click `BtnGenerate` | Speeches count and scores remain unchanged |
| 1.7 | High Frequency Load | Autoclicker simulation (100 clicks/sec) | Send 100 pressed signals in single process loop | Speeches and Tug-of-war update correctly without crashing |
| 1.8 | Negative Bounds Check | Clicks when viewport is resized to minimum size | Set size to (1,1), click generate button | Coordinates do not throw exceptions, safely handles bounds |
| 1.9 | Underflow Prevention | Click score increments when red score is near 0% | Set red score = 0.05%, click generate button | Red score increments safely, preventing division by zero |
| 1.10 | Extreme Prestige Click | Click with prestige multiplier = 1,000,000 | Set prestige multiplier = 1M, click generate button | Speeches = 1,000,000, UI formatted without text truncation |

#### Feature 2: Upgrades (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 2.6 | Exact Balance Buy | Buy upgrade when balance equals cost exactly | Set speeches = 10.0, cost = 10.0, buy upgrade | Purchase succeeds, speeches = 0.0, upgrade level = 1 |
| 2.7 | Insufficient Balance Buy | Buy upgrade when balance is slightly below cost | Set speeches = 9.99, cost = 10.0, buy upgrade | Purchase fails, speeches remains 9.99, level remains 0 |
| 2.8 | Level 100 Cost Scaling | Exponentiation cost check at level 100 | Set upgrade level = 100, read cost | Cost scales using `base_cost * pow(1.15, 100)` correctly, no float overflow |
| 2.9 | Invalid Index Buy | Call buy upgrade with out-of-bounds index | Call `buy_upgrade(-1)` and `buy_upgrade(99)` | Returns false, logs warning, no engine crash |
| 2.10 | Multi-Purchase Race | Buy upgrade at the exact frame of passive generation | Simulate purchase during process delta callback | Speeches deduction and passive addition resolve cleanly |

#### Feature 3: Prestige (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 3.6 | Zero-Progress Prestige | Trigger prestige with 0 speeches and 0 upgrades | Call `reset_for_prestige()` immediately on startup | Prestige multiplier increases to 1.5, resets perform normally |
| 3.7 | Mid-Enemy Sim Prestige | Prestige reset during active enemy faction generation | Enemy timer timeout fires during `reset_for_prestige()` frame | Reset resolves cleanly, enemy cannot win during reset |
| 3.8 | Double Prestige Click | Multi-clicking restart/prestige button | Emit pressed signal on `BtnRestart` twice in the same frame | Only 1 prestige level is awarded, second call ignored |
| 3.9 | Extreme Multiplier Scaling | Recalculate DPS at prestige multiplier 1,000.0 | Set prestige multiplier = 1,000.0, upgrade count = 1 | `discursos_por_segundo` is computed correctly without float overflow |
| 3.10 | Button Rebuild Integrity | Rebuilding upgrades UI after prestige when buttons are disabled | Disable UI, call prestige reset | Buttons list is rebuilt and buttons are enabled |

#### Feature 4: Fake News (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 4.6 | Fake News post End Game | Click Urgent News when game is inactive | Set `game_active` = false, spawn, click | No bonus awarded, button hides, returns early |
| 4.7 | Fade-Out Race Condition | Click Urgent news at the exact moment it fades out | Simulate pressed signal and timeout simultaneously | Safe execution, button hides, no double timer start |
| 4.8 | Tiny Viewport Spawn | Safe bounds calculation on tiny window | Resize viewport to 200x300, spawn urgent news | Button spawns inside the tiny safe area, no negative margins |
| 4.9 | Zero DPS Click | Urgent news click when passive DPS is 0 | Passive DPS = 0, click urgent news | Awards the minimum fallback bonus of 100.0 speeches |
| 4.10 | Multiple Fake News Spawns | Fast subsequent spawn triggers | Trigger spawn twice before fade-out completes | Existing tween is overridden or completed, preventing orphan buttons |

#### Feature 5: LLM Speech Generation (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 5.6 | Empty Prompt / Topic | Request speech generation with empty string inputs | Call `generate_speech_async("", "")` | Client rejects prompt immediately, emits failure signal |
| 5.7 | LLM Timeout Mock | Network timeout simulated | Configure Mock client delay = 10s, timeout limit = 3s | Generates timeout failure signal, app doesn't freeze |
| 5.8 | Closed Loop Mid-Generation | Quit game scene while LLM generation is pending | Trigger async generation, free the game node next frame | No memory leaks or orphaned timers, callbacks safely discarded |
| 5.9 | Injection/Special Characters | Topic containing code injection or emojis | Call `generate_speech_async("<script>", "😊")` | Input is parsed safely without UI breakage or script errors |
| 5.10 | Giant Generated Response | Receive speech of 10,000 characters | Emit `speech_generated` with 10k character string | Text container wraps/scrolls, no text overlap in UI |

#### Feature 6: Tug-of-War Win/Loss (5 cases)
| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 6.6 | Division by Zero Protection | Red and Blue scores both equal 0 | Set red score = 0.0, blue score = 0.0, call `_update_tug_of_war()` | Function exits early, error logged, no crash |
| 6.7 | Victory Threshold | Score red is just below threshold vs threshold | Set red = 99.89% then 99.9% | No victory at 99.89%, victory triggers at 99.9% |
| 6.8 | Defeat Threshold | Score red is just above threshold vs threshold | Set red = 0.11% then 0.1% | No defeat at 0.11%, defeat triggers at 0.1% |
| 6.9 | Simultaneous Win/Loss | Massive player and enemy scores added at same frame | Set red = 1000, blue = 1000 at once | Calculated percentages resolve cleanly and game continues |
| 6.10 | Post-Game State Update | Call update tug of war after game ended | Set `game_active` = false, call `_update_tug_of_war()` | Returns immediately without modifying panel state |

---

### Tier 3: Cross-Feature Combinations (6 Cases)
Validates interactions between different systems.

| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 7.1 | Prestige Cost Reset | Prestige resets upgrades count, which must reset scaling cost | Buy 5 upgrades (cost increases), trigger prestige reset | Verify Tia do Zap cost is reset back to base (10.0) |
| 7.2 | Upgraded Fake News | Upgrades increase DPS, which must increase Fake News bonus | Buy 2 Robôs (DPS = 24.0), click Urgent News | Speeches increases by `24.0 * 30 = 720.0` (greater than base 100.0) |
| 7.3 | LLM Speech influence on Tug of War | Successful LLM generation shifts Tug of War bar | Complete LLM speech generation | `global_score_red` is boosted, shifting Tug of War balance to player |
| 7.4 | Click Scaling post Prestige | Click yield scales correctly under active prestige | Prestige once (multiplier = 1.5), click `BtnGenerate` | Speeches increases by exactly 1.5 |
| 7.5 | Concurrent LLM & Passive generation | Async LLM generation does not halt passive income | Start LLM generation, await 0.5s while DPS = 10.0 | Passive speeches accumulate concurrently with the LLM task |
| 7.6 | Fake News Tug of War Shift | Clicking Fake news button increases Tug of War control | Click urgent news button | `global_score_red` increases by bonus amount, updating progress bar |

---

### Tier 4: Real-World Application Scenarios (5 Cases)
Simulates end-to-end user playthroughs from initiation to victory or exit.

| ID | Name | Description | Inputs/Setup | Expected Outcome |
|---|---|---|---|---|
| 8.1 | "The Speedy Dictator" (Speedrun) | High-speed clicks and immediate upgrades | Simulate fast clicks, buy upgrades immediately when affordable, push to win | Victory screen appears in minimum frames, game halts |
| 8.2 | "From Rags to Riches" (Prestige Run) | Accumulate speeches, buy upgrades, prestige, and confirm faster second run | Play to 100 speeches -> prestige -> play to 100 speeches again | Multiplier becomes 1.5. Second run takes 33% fewer clicks/seconds |
| 8.3 | "The Comeback Campaign" (Recovery) | Opponent is winning, user triggers Fake News and LLM to recover | Allow enemy to push bar to 10% red -> spawn Urgent News -> trigger LLM | Tug of War bar recovers to >50%, avoiding defeat |
| 8.4 | "The Idle Campaigner" (Passive Run) | User clicks only to buy automation upgrades, then waits for passive victory | Click to buy 5 Zap Aunties and 2 Robots -> let engine run | Speeches accumulate passively and push red score to 100% for victory |
| 8.5 | "Save State Resilience" | Save, quit game, reload, and verify progression integrity | Buy upgrades -> prestige -> call `save_game()` -> recreate scene -> `load_game()` | Speeches, prestige multiplier, and upgrade counts restored; passive income resumes |

---

## 6. Project Layout and Location Recommendations

To comply with the project layout (e.g. keeping agent folders only for metadata, and structuring tests cleanly), we recommend the following file layout:

```
CorridaEleitoral/
├── project.godot
├── scenes/
│   └── main/
│       ├── Game.tscn
│       └── Game.gd
├── scripts/
│   └── managers/
│       └── EconomyManager.gd
├── tests/
│   ├── E2ETestRunner.gd             <-- Proposed E2E main entry point
│   ├── MicroTestRunner.gd           <-- Existing unit test runner
│   ├── TestEconomy.gd               <-- Existing economy unit tests
│   ├── TestSaveSystem.gd            <-- Existing save unit tests
│   ├── e2e/                         <-- Folder for E2E tests
│   │   ├── E2ETestBase.gd           <-- Base class for E2E assertion/setup
│   │   ├── test_manual_clicker.gd   <-- Manual Clicker E2E tests
│   │   ├── test_upgrades.gd         <-- Upgrades E2E tests
│   │   ├── test_prestige.gd         <-- Prestige E2E tests
│   │   ├── test_fake_news.gd        <-- Fake News E2E tests
│   │   ├── test_llm_speech.gd       <-- LLM speech generation E2E tests
│   │   └── test_tug_of_war.gd       <-- Tug-of-War E2E tests
│   └── mocks/
│       └── MockLocalLLMClient.gd    <-- Local LLM Mock Implementation
```

This layout keeps E2E tests grouped logically while maintaining full compatibility with the command-line execution:
`C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd`
