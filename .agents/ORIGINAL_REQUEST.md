# Original User Request

## Initial Request — 2026-07-03T23:56:14Z

# Teamwork Project Prompt — Final

O projeto é evoluir o MVP do jogo "Corrida Eleitoral de Brasílica" (desenvolvido em Godot 4.3) para uma qualidade visual e técnica "AAA". O jogo ganhará integração com Inteligência Artificial (LLMs Locais) nativa dentro do Godot para gerar discursos dinâmicos e sátiras políticas, operando como um produto robusto sem depender de APIs externas.

Working directory: c:\Users\joaoc\OneDrive\Documentos\CorridaEleitoral
Integrity mode: development

## Requirements

### R1. Qualidade AAA e Direção de Arte AI (ai-creative-director)
Implementar polimento de UI/UX utilizando Shaders, Temas personalizados e micro-animações suculentas ("juicy") na engine Godot. O visual deve parecer altamente profissional, abolindo componentes padrão cinzas do sistema.

### R2. Integração LLM Local Nativa no Godot (godot-llm-integration / ai-wrapper-product)
Implementar um sistema de LLM Local (via arquitetura estilo NobodyWho ou integração com Ollama API) diretamente no Godot para que a funcionalidade de "Gerar Discurso" traga textos reais, gerados proceduralmente off-line.

### R3. Estabilidade e Código Assíncrono (godot-development)
Refatorar as chamadas para não bloquear a thread principal do Godot durante a inferência do modelo local. Garantir tratamento de erros e tempos de espera aceitáveis.

## Acceptance Criteria

### Arte e Polimento
- [ ] O arquivo `Game.tscn` (ou um novo tema aplicado globalmente) não pode conter controles UI padrão não-estilizados.
- [ ] Devem existir animações via `Tween` ou `AnimationPlayer` acionadas nos principais eventos da economia (ex: comprar upgrade, gerar discurso).

### Integração LLM Local
- [ ] Deve haver uma classe (script) separada responsável unicamente pela interface com o LLM Local, rodando de forma assíncrona.
- [ ] O texto retornado pela inferência deve ser capturado com sucesso e injetado nos `Labels` ou caixas de diálogo da UI do jogador.

### Estabilidade
- [ ] A execução via testes Headless (ou abertura do projeto no editor) deve ocorrer sem erros de parsing ou type mismatches no console (`red errors`).

## Follow-up — 2026-07-04T00:05:18Z

Atenção equipe: o usuário relatou erros no Windows. Vi que vocês modificaram o `Game.gd` para referenciar o `LocalLLMClient`, mas o script `LocalLLMClient.gd` ainda não foi criado na pasta `scripts/managers/` ou `scripts/utils/`. Por favor, criem a classe `LocalLLMClient` (que deve extender `HTTPRequest` ou `Node`) para que o Godot pare de exibir erros de compilação. Continuem o bom trabalho!
