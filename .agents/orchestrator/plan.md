# Plan: Corrida Eleitoral de Brasílica AAA Evolved

## Overview
We will execute the project using the Project Pattern.
We will spawn:
- **E2E Testing Track Orchestrator** to implement the E2E tests (Milestone 1) and output `TEST_READY.md`.
- **Implementation Track Orchestrator** (or sub-orchestrators) to implement Milestones 2, 3, 4, 5.
- We will use the Explorer -> Worker -> Reviewer -> Challenger -> Forensic Auditor -> Gate flow for each milestone.

## Phase 1: Test Suite Development (Milestone 1)
1. Spawn E2E Testing Orchestrator.
2. Build E2E test runner that can run Godot headless scripts properly (handling the `SceneTree` inheritance limitation).
3. Implement Tiers 1-4 tests covering clicker, upgrades, prestige, news, LLM integration, and win/loss.
4. Output `TEST_READY.md`.

## Phase 2: Implementation (Milestones 2, 3, 4)
1. **Milestone 2: LLM Client** - Implement `LocalLLMClient` with HTTPRequest and robust offline generation.
2. **Milestone 3: AAA UI** - Design UI styling, Custom Theme, Shaders, and Tweens for clicking/economy events.
3. **Milestone 4: Async Integration** - Connect LLM Client to UI, add dialog box, implement async handling, and fix any console errors.

## Phase 3: Verification & Hardening (Milestone 5)
1. Run and pass all E2E tests (Tiers 1-4).
2. Generate Tier 5 adversarial tests using White-box coverage analysis.
3. Audit the work using the Forensic Auditor to verify clean integration and zero violations.
