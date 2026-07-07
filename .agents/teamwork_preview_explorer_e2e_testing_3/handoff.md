# E2E Testing Architecture Handoff Report

## 1. Observation
- The project layout consists of the following key files:
  - `project.godot`: Engine configuration declaring autoloads for `Logger` and `SaveManager`.
  - `scenes/main/Game.gd`: Controls game loop, enemy simulation (`_simulate_enemy_faction()`), and fake news spawning (`_spawn_urgent_news()`).
  - `scripts/managers/EconomyManager.gd`: Handles prestige reset (`reset_for_prestige()`), upgrade purchases (`buy_upgrade()`), and saving (`save_game()`).
  - `scripts/utils/SaveManager.gd`: Static file utility reading/writing to `user://savegame.save`.
  - `tests/`: Contains `MicroTestRunner.gd` (inheriting from `Node`), `TestEconomy.gd`, and `TestSaveSystem.gd`.
- Save files: `EconomyManager.gd` writes directly to `user://savegame.save` on upgrades purchase and prestige reset.
- Headless execution: The project specifies headless Godot console execution via:
  ```powershell
  C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd
  ```

## 2. Logic Chain
- Running a script in Godot via the `-s` flag bypasses normal scene loading and starts the script as a custom `MainLoop`/`SceneTree`. Thus, the test runner must inherit from `SceneTree` to manage the engine lifecycle.
- To execute E2E tests, the runner must instantiate the UI scene `Game.tscn` and add it as a child to the root viewport (`root`), executing user inputs (e.g. emitting signals like `pressed` on buttons) and yielding execution via `await` to handle asynchronous operations.
- State isolation: Because the game auto-saves, E2E tests would overwrite developers' local save games. Thus, the runner must back up `user://savegame.save` to `user://savegame.save.backup` at startup, wipe the active save for test runs, and restore the backup upon termination.
- 71 test cases are organized across:
  - **Tier 1 (Feature Coverage)**: Happy path checks for the 6 features (30 cases).
  - **Tier 2 (Boundary & Corner Cases)**: Boundaries, inputs post-game-over, division by zero, float precision, client timeout (30 cases).
  - **Tier 3 (Cross-Feature Combinations)**: Interactions such as clicker pacing during active LLM async generation, prestige resets clearing active fake news buttons (6 cases).
  - **Tier 4 (Real-World Application Scenarios)**: Simulated full player runs (5 cases).
- A mock `LocalLLMClient` is designed to simulate async LLM signals (`speech_generated` / `generation_failed`) without invoking a real Ollama instance.

## 3. Caveats
- The `LocalLLMClient` class/node is planned and not yet present in the codebase. Testing it relies on the provided interface contracts: `generate_speech_async`, `speech_generated`, and `generation_failed`.
- UI Shader rendering cannot be visually asserted in headless mode because Godot disables rendering pipelines in headless mode. The tests check node state and tween structures instead.
- If the game introduces stateful autoload singletons that are not static classes, they must be manually instantiated by the custom `SceneTree` test runner.

## 4. Conclusion
- The E2E test runner design (`tests/E2ETestRunner.gd`) and directory layout proposed in `analysis.md` provide a robust, non-blocking, isolated testing pipeline. Implementing this runner and the 71 test cases will satisfy Milestone 1.

## 5. Verification Method
- Execute the test suite via the command line:
  ```powershell
  C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless -s tests/E2ETestRunner.gd
  ```
- Inspect console output logs to confirm proper discovery, execution of all test cases, and preservation of the user's `user://savegame.save` file.
- Verify that the exit code is `0` when all tests pass, and `1` if any test fails.
