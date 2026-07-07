## 2026-07-04T00:05:49Z

You are a teamwork_preview_worker.
Your working directory is: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\worker_llm_client
Your parent is: 23bf21c9-85a4-4ff4-bf22-659934fdd51b (Orchestrator)

Your mission is to implement `LocalLLMClient.gd` in `scripts/managers/` to resolve compilation errors and fulfill Milestone 2.
Here are the specifications for the class:
1. File Path: `c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\scripts\managers\LocalLLMClient.gd`
2. It must extend `Node` (or `HTTPRequest`) and declare `class_name LocalLLMClient`.
3. It must define these two signals:
   - `signal speech_generated(text: String)`
   - `signal generation_failed(error_msg: String)`
4. It must implement the function:
   - `func generate_speech_async(topic: String, prompt: String) -> void`
5. The implementation must:
   - Run asynchronously (using HTTPRequest node).
   - Attempt to connect to a local Ollama instance (`http://localhost:11434/api/generate` or similar).
   - Have a fallback to a local procedural template-based speech generator (offline) if the request fails, times out (e.g. 2-3 seconds), or returns a non-200 code. This fallback should generate a satirical political speech related to the topic (e.g., using pre-defined satirical phrases and templates combined with the topic name) and emit the `speech_generated` signal.
   - Clean up any resources and handle all potential errors gracefully.
6. Verify the file compiles and works by running the Godot editor headless scan:
   `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral --editor --quit`
7. Provide a handoff report when complete.

**MANDATORY INTEGRITY WARNING**:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
