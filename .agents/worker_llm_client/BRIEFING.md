# BRIEFING — 2026-07-04T00:05:49Z

## Mission
Implement LocalLLMClient.gd in scripts/managers/ to resolve compilation errors and fulfill Milestone 2, ensuring proper Ollama communication and a satirical offline procedural speech generator fallback.

## 🔒 My Identity
- Archetype: teamwork_preview_worker
- Roles: implementer, qa, specialist
- Working directory: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\worker_llm_client
- Original parent: 23bf21c9-85a4-4ff4-bf22-659934fdd51b
- Milestone: Milestone 2

## 🔒 Key Constraints
- Must extend Node/HTTPRequest and declare class_name LocalLLMClient
- Define signals: speech_generated(text: String), generation_failed(error_msg: String)
- Implement generate_speech_async(topic: String, prompt: String) -> void
- Must run asynchronously using HTTPRequest node
- Target localhost:11434/api/generate (Ollama)
- Offline procedural fallback (satirical speech on topic) if Ollama fails/times out (2-3s)/non-200
- Clean up resources and handle errors gracefully
- Verify compilation and functionality using Godot editor headless scan
- DO NOT CHEAT (no hardcoded test results, dummy implementations, or facade logic)

## Current Parent
- Conversation ID: 23bf21c9-85a4-4ff4-bf22-659934fdd51b
- Updated: not yet

## Task Summary
- **What to build**: LocalLLMClient class in scripts/managers/LocalLLMClient.gd
- **Success criteria**: The class compiles cleanly via Godot editor headless scan; it handles async Ollama generation; it has a robust, creative satirical political speech generator fallback when offline.
- **Interface contracts**: scripts/managers/LocalLLMClient.gd
- **Code layout**: scripts/managers/

## Key Decisions Made
- [TBD]

## Artifact Index
- c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\worker_llm_client\ORIGINAL_REQUEST.md — Original request instructions

## Change Tracker
- **Files modified**: None
- **Build status**: Untested
- **Pending issues**: None

## Quality Status
- **Build/test result**: Untested
- **Lint status**: Untested
- **Tests added/modified**: None

## Loaded Skills
- None
