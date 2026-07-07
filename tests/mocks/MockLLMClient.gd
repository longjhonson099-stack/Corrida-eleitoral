extends Node

signal speech_generated(text: String)
signal generation_failed(error_msg: String)

var simulate_delay: float = 0.05 # low delay for fast tests
var should_fail: bool = false
var last_topic: String = ""
var last_prompt: String = ""
var is_generating: bool = false

func generate_speech_async(topic: String, prompt: String) -> void:
	last_topic = topic
	last_prompt = prompt
	is_generating = true
	
	# Simulate network/async delay
	await get_tree().create_timer(simulate_delay).timeout
	
	is_generating = false
	if should_fail:
		generation_failed.emit("Mock LLM failed to connect or timed out.")
	else:
		speech_generated.emit("Mock Speech about %s: %s" % [topic, prompt])
