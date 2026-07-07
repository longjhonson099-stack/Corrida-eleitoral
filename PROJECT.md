# Project: Corrida Eleitoral de Brasílica AAA Evolved

## Architecture
The project is built on Godot 4.3/4.6, using a modular architecture:
- **Game.tscn / Game.gd**: Main scene controller, manages UI event handling, timers, and game loop.
- **EconomyManager.gd**: Data-driven core economy, handles upgrades, discursos count, prestige, and save/load state.
- **AppSaveManager.gd**: Global save system helper (JSON serialization to user directory).
- **AppLogger.gd**: Autoload logger for structured trace output.
- **LocalLLMClient.gd (New)**: Async local LLM interface (Ollama API HTTP client + offline procedural template fallback) to generate satirical speeches without blocking the main thread.
- **AAA UI (New Theme & Shaders)**: Applied globally to Game.tscn to replace default gray controls with high-fidelity styled UI, micro-animations (Tweens), and screen shaders.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | E2E Test Infra & Cases | Design E2E test runner, define features, and write Tiers 1-4 test cases. Publish `TEST_READY.md`. | None | IN_PROGRESS (Conv: 7a80ffb9-a844-40e1-9ebd-4dc100712022) |
| 2 | Local LLM Integration Module | Create async `LocalLLMClient` with Ollama API HTTP interface and robust offline template fallback. | None | IN_PROGRESS (Conv: 8e81e443-4210-47fb-a0bc-f5319503740d) |
| 3 | AAA UI/UX & Juiciness | Design and apply custom theme, CRT/glitch/glow shaders, and Tween micro-animations. | None | PLANNED |
| 4 | Integration & Async Refactor | Connect LLM client to Game.gd, ensure non-blocking UI (thinking state), handle timeouts. | M2, M3 | PLANNED |
| 5 | Final E2E Pass & Hardening | Pass 100% E2E tests, execute Tier 5 adversarial tests, and perform final audit. | M1, M4 | PLANNED |

## Interface Contracts
### `LocalLLMClient` ↔ `Game`
- **Function**: `generate_speech_async(topic: String, prompt: String) -> void`
- **Signal**: `speech_generated(text: String)`
- **Signal**: `generation_failed(error_msg: String)`
- **Behavior**: Calls Ollama HTTP endpoint `/api/generate` or `/api/chat` with 5s timeout. If fails or times out, falls back to local procedural generator. All operations run on background Thread or via non-blocking HTTPRequest node.

## Code Layout
- `scenes/main/Game.tscn` - Main game screen.
- `scenes/main/Game.gd` - Main game script.
- `scripts/managers/EconomyManager.gd` - Economy backend.
- `scripts/managers/LocalLLMClient.gd` - LLM interface class (new).
- `scripts/utils/SaveManager.gd` - Save logic.
- `scripts/utils/Logger.gd` - Logging.
- `tests/` - Unit tests and E2E tests.
- `assets/shaders/` - Custom UI shaders (new).
- `assets/themes/` - Custom AAA theme files (new).
