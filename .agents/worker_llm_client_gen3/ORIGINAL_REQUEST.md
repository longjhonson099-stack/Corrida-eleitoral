## 2026-07-04T01:24:20Z

You are a teamwork_preview_worker.
Your working directory is: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\.agents\worker_llm_client_gen3
Your parent is: 23bf21c9-85a4-4ff4-bf22-659934fdd51b (Orchestrator)

Your mission is to complete Milestone 2:
1. Read `c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral\scripts\managers\LocalLLMClient.gd`.
2. Modify `LocalLLMClient.gd` to implement a robust, offline, template-based procedural speech generator as a fallback.
   - When `generate_speech_async(topic, prompt)` is called, it must try the Ollama HTTP request.
   - If the request fails (e.g. `error != OK` or HTTP status code is not 200, or it times out, wait, you can use a Timer node or `get_tree().create_timer(3.0)` to handle timeouts), it must fall back to generating a satirical political speech locally using predefined templates containing the topic, and emit the `speech_generated` signal.
   - The templates should be short, satirical political speeches tailored to the "Corrida Eleitoral de Brasílica" theme. For example:
     * "Companheiros, o projeto [Topic] vai beneficiar todos os cidadãos de Brasílica! Não aceitaremos provocações!"
     * "Nossos adversários tremem quando falamos de [Topic]! Nós venceremos este debate!"
     * "A verdade sobre [Topic] será revelada! Nossa campanha é movida pelo povo de Brasílica!"
     * "Querem abafar nossa voz sobre [Topic], mas o clamor do povo é maior! Vamos à vitória!"
   - Make sure all edge cases are handled without crashing the engine.
3. Verify that the file compiles by running the Godot editor headless scan:
   `C:\Users\joaoc\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral --editor --quit`
4. Provide a handoff report when complete.

**MANDATORY INTEGRITY WARNING**:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
