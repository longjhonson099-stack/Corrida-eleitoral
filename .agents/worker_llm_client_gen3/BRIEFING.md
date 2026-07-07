# BRIEFING — 2026-07-04T01:24:20Z

## Mission
Implement robust offline template-based satirical speech generation fallback in LocalLLMClient.gd and verify compilation.

## 🔒 My Identity
- Archetype: worker
- Roles: implementer, qa, specialist
- Working directory: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\worker_llm_client_gen3
- Original parent: 23bf21c9-85a4-4ff4-bf22-659934fdd51b
- Milestone: Milestone 2

## 🔒 Key Constraints
- CODE_ONLY network mode: No external network access.
- Minimal change principle.
- No dummy/facade implementations or cheating.

## Current Parent
- Conversation ID: 23bf21c9-85a4-4ff4-bf22-659934fdd51b
- Updated: not yet

## Task Summary
- **What to build**: Robust offline template-based speech generator fallback in LocalLLMClient.gd.
- **Success criteria**: Ollama HTTP request fallback to Satirical Speech template generation. Handling of error != OK, HTTP code != 200, and HTTP request timeout (3.0s). Signal `speech_generated` emitted with generated speech. Verify compilation using Godot headless scan.
- **Interface contracts**: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\scripts\managers\LocalLLMClient.gd
- **Code layout**: Scripts are under scripts/managers/

## Key Decisions Made
- [TBD]

## Artifact Index
- [TBD]
