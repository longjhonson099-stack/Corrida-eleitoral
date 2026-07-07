class_name ShopMenu
extends Control

var label_votos: Label
var label_fundos: Label
var audio_click: AudioStreamPlayer

var weapon_items = [
	{"id": "super_mala", "name": "Super Mala (Dano x2)", "price": 500, "currency": "votos"},
	{"id": "vento_divino", "name": "Vento Divino (Zera o Vento)", "price": 300, "currency": "votos"},
	{"id": "dossie", "name": "Dossiê (Revela Segredos - Stun)", "price": 800, "currency": "votos"},
	{"id": "robo_disparo", "name": "Robô de Disparo (Metralhadora)", "price": 1000, "currency": "votos"}
]

var gacha_items = [
	{"id": "gacha_votos", "name": "Sorteio de Candidato (Comum)", "price": 2500, "currency": "votos"},
	{"id": "gacha_fundos", "name": "Sorteio de Candidato (Raro)", "price": 500, "currency": "fundos"}
]

var iap_items = [
	{"id": "iap_1k", "name": "1.000 Fundos", "price": "R$ 4.90", "currency": "real"},
	{"id": "iap_5k", "name": "5.000 Fundos", "price": "R$ 19.90", "currency": "real"}
]

func _ready() -> void:
	# Audio Setup
	audio_click = AudioStreamPlayer.new()
	var snd = AudioStreamWAV.new()
	var file = FileAccess.open("res://assets/audio/click.wav", FileAccess.READ)
	if file:
		snd.data = file.get_buffer(file.get_length())
		snd.format = AudioStreamWAV.FORMAT_16_BITS
		snd.mix_rate = 44100
		audio_click.stream = snd
	add_child(audio_click)

	# Background
	var bg_sprite = TextureRect.new()
	var tex = load("res://assets/backgrounds/shop_bg.jpg")
	if tex is Texture2D:
		bg_sprite.texture = tex
	bg_sprite.set_anchors_preset(PRESET_FULL_RECT)
	bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg_sprite)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	add_child(overlay)
	
	# Header
	var title = Label.new()
	title.text = "LOJA - FUNDO ELEITORAL"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position.y = 20
	add_child(title)
	
	# Balances
	var panel = Panel.new()
	panel.position = Vector2(800, 20)
	panel.size = Vector2(320, 100)
	add_child(panel)
	
	label_votos = Label.new()
	label_votos.position = Vector2(10, 10)
	label_votos.add_theme_font_size_override("font_size", 24)
	label_votos.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	panel.add_child(label_votos)
	
	label_fundos = Label.new()
	label_fundos.position = Vector2(10, 50)
	label_fundos.add_theme_font_size_override("font_size", 24)
	label_fundos.add_theme_color_override("font_color", Color.GOLD)
	panel.add_child(label_fundos)
	
	_update_balances()
	
	# Tabs
	var tab_container = TabContainer.new()
	tab_container.position = Vector2(100, 150)
	tab_container.size = Vector2(700, 420)
	add_child(tab_container)
	
	_create_tab(tab_container, "Arsenal (Consumíveis)", weapon_items)
	_create_tab(tab_container, "Gacha (Personagens)", gacha_items)
	_create_tab(tab_container, "Comprar Fundos (IAP)", iap_items)
		
	# Back Button
	var btn_back = Button.new()
	btn_back.text = "VOLTAR"
	btn_back.add_theme_font_size_override("font_size", 32)
	btn_back.set_anchors_preset(PRESET_BOTTOM_RIGHT)
	btn_back.position = Vector2(-200, -80)
	btn_back.size = Vector2(180, 60)
	btn_back.pressed.connect(_on_back_pressed)
	add_child(btn_back)

func _create_tab(parent: TabContainer, title: String, items_list: Array) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = title
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)
	parent.add_child(scroll)
	
	for i in range(items_list.size()):
		var item = items_list[i]
		var hbox = HBoxContainer.new()
		
		var label = Label.new()
		label.text = item["name"]
		label.custom_minimum_size = Vector2(400, 40)
		label.add_theme_font_size_override("font_size", 24)
		hbox.add_child(label)
		
		var label_owned = Label.new()
		if GameManager and GameManager.inventory.has(item["id"]):
			label_owned.text = " (Possui: %d)" % GameManager.inventory[item["id"]]
		else:
			label_owned.text = ""
		label_owned.custom_minimum_size = Vector2(120, 40)
		hbox.add_child(label_owned)
		
		var btn = Button.new()
		if item["currency"] == "real":
			btn.text = "COMPRAR (" + str(item["price"]) + ")"
			btn.add_theme_color_override("font_color", Color.CYAN)
		else:
			btn.text = "COMPRAR (" + str(item["price"]) + " " + item["currency"].to_upper() + ")"
			
		btn.add_theme_font_size_override("font_size", 24)
		btn.custom_minimum_size = Vector2(250, 40)
		btn.pressed.connect(_on_buy_pressed.bind(item, label_owned))
		hbox.add_child(btn)
		
		vbox.add_child(hbox)

func _update_balances() -> void:
	if GameManager:
		label_votos.text = "VOTOS: " + str(GameManager.votos_soft_currency)
		label_fundos.text = "FUNDOS: " + str(GameManager.fundos_hard_currency)

func _on_buy_pressed(item: Dictionary, label_owned: Label) -> void:
	audio_click.play()
	
	if item["currency"] == "real":
		print("Iniciando fluxo do Google Play Billing para " + item["id"])
		# TODO: Call Godot Google Play Billing plugin
		return
		
	var can_buy = false
	if item["currency"] == "votos" and GameManager.votos_soft_currency >= item["price"]:
		GameManager.votos_soft_currency -= item["price"]
		can_buy = true
	elif item["currency"] == "fundos" and GameManager.fundos_hard_currency >= item["price"]:
		GameManager.fundos_hard_currency -= item["price"]
		can_buy = true
		
	if can_buy:
		if item["id"].begins_with("gacha_"):
			# Sorteio de personagem
			_do_gacha()
		else:
			# Compra de item
			if GameManager.inventory.has(item["id"]):
				GameManager.inventory[item["id"]] += 1
				label_owned.text = " (Possui: %d)" % GameManager.inventory[item["id"]]
		
		GameManager.save_game()
		print("Comprado: " + item["name"])
		_update_balances()
	else:
		print("Saldo insuficiente!")

func _do_gacha() -> void:
	print("Sorteando novo candidato...")
	# Exemplo simplificado. Na prática você abre uma animação e mostra qual ganhou.
	var possible_candidates = ["O Juiz", "O Influencer", "A Terceira Via", "O Poste", "O Coach", "A Ambiental", "O Libertário"]
	var result = possible_candidates[randi() % possible_candidates.size()]
	
	if not GameManager.unlocked_characters.has(result):
		GameManager.unlocked_characters.append(result)
		print("VOCÊ DESBLOQUEOU: " + result)
	else:
		print("VOCÊ TIROU REPETIDO: " + result + " (Convertido em 100 Votos)")
		GameManager.votos_soft_currency += 100

func _on_back_pressed() -> void:
	audio_click.play()
	get_tree().change_scene_to_file("res://scenes/worms/MainMenu.tscn")
