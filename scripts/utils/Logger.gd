extends Node
class_name AppLogger

# Um Singleton (Autoload) simples para blindagem de logs
# Facilita debugar falhas lógicas remotamente sem fechar o app

enum LogLevel {
	INFO,
	WARNING,
	ERROR
}

static func info(message: String) -> void:
	_log(LogLevel.INFO, message)

static func warning(message: String) -> void:
	_log(LogLevel.WARNING, message)

static func error(message: String) -> void:
	_log(LogLevel.ERROR, message)
	# Aqui no futuro poderíamos enviar o log de erro para um servidor, Crashlytics, etc.

static func _log(level: LogLevel, message: String) -> void:
	var time_str = Time.get_time_string_from_system()
	var prefix = ""
	
	match level:
		LogLevel.INFO:
			prefix = "[INFO]"
		LogLevel.WARNING:
			prefix = "[WARN]"
			push_warning(message)
		LogLevel.ERROR:
			prefix = "[ERROR]"
			push_error(message)
			
	print("%s %s: %s" % [time_str, prefix, message])
