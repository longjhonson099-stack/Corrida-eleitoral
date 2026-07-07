extends Node

var player1_sprite: String = "res://assets/sprites/cand_raposa.png"
var player1_name: String = "O Velho Raposa"

var player2_sprite: String = "res://assets/sprites/cand_lula.png"
var player2_name: String = "O Lulista"

var map_bg: String = "res://assets/backgrounds/scenario_tv_debate.jpg"

# --- Progression & Monetization ---
var is_campaign: bool = false
var current_league: String = "municipal"
var campaign_levels: Dictionary = {
	"municipal": 1,
	"presidencial": 1,
	"suprema": 1
}
var player_faction: String = "" # "Vermelho" ou "Verde"

var votos_soft_currency: int = 0
var fundos_hard_currency: int = 0
var influencia: int = 0
var season_exp: int = 0
var season_tier: int = 1
var has_premium_pass: bool = false

var team_talents: Dictionary = {
	"cabo_eleitoral": 0,
	"marqueteiro": 0,
	"advogado": 0
}

func get_cargo() -> String:
	if influencia < 500: return "Vereador"
	if influencia < 1500: return "Prefeito"
	if influencia < 3000: return "Deputado"
	if influencia < 5000: return "Governador"
	return "Presidente"

func get_next_cargo_goal() -> int:
	if influencia < 500: return 500
	if influencia < 1500: return 1500
	if influencia < 3000: return 3000
	if influencia < 5000: return 5000
	return 5000

var unlocked_characters: Array = ["O Velho Raposa", "O Lulista", "O Patriota"]
var inventory: Dictionary = {
	"fake_news": {"level": 1, "amount": 0},
	"cpi": {"level": 1, "amount": 0},
	"dossie": {"level": 1, "amount": 0},
	"comicio": {"level": 1, "amount": 0}
}

const SAVE_PATH = "user://player_save.dat"

# The Campaign Leagues
var campaign_leagues = {
	"municipal": [
		{"name": "O Poste", "sprite": "res://assets/sprites/cand_poste.png", "bg": "res://assets/backgrounds/scenario_protest.jpg", "ai_difficulty": 1.0, "is_boss": false},
		{"name": "O Coach", "sprite": "res://assets/sprites/cand_coach.png", "bg": "res://assets/backgrounds/scenario_tv_debate.jpg", "ai_difficulty": 1.2, "is_boss": false},
		{"name": "A Ambiental", "sprite": "res://assets/sprites/cand_ambiental.png", "bg": "res://assets/backgrounds/scenario_fazenda.jpg", "ai_difficulty": 1.5, "is_boss": true}
	],
	"presidencial": [
		{"name": "A Terceira Via", "sprite": "res://assets/sprites/cand_terceiravia.png", "bg": "res://assets/backgrounds/scenario_tv_debate.jpg", "ai_difficulty": 1.8, "is_boss": false},
		{"name": "O Libertário", "sprite": "res://assets/sprites/cand_libertario.png", "bg": "res://assets/backgrounds/scenario_protest.jpg", "ai_difficulty": 2.0, "is_boss": false},
		{"name": "O Patriota", "sprite": "res://assets/sprites/cand_bolsonaro.png", "bg": "res://assets/backgrounds/scenario_esplanada.jpg", "ai_difficulty": 2.5, "is_boss": false},
		{"name": "O Lulista", "sprite": "res://assets/sprites/cand_lula.png", "bg": "res://assets/backgrounds/scenario_fazenda.jpg", "ai_difficulty": 3.0, "is_boss": true}
	],
	"suprema": [
		{"name": "O Influencer", "sprite": "res://assets/sprites/cand_influencer.png", "bg": "res://assets/backgrounds/scenario_tv_debate.jpg", "ai_difficulty": 3.5, "is_boss": false},
		{"name": "O Juiz", "sprite": "res://assets/sprites/cand_juiz.png", "bg": "res://assets/backgrounds/scenario_plenario.jpg", "ai_difficulty": 4.0, "is_boss": false},
		{"name": "O Supremo Xandão", "sprite": "res://assets/sprites/cand_juiz.png", "bg": "res://assets/backgrounds/scenario_bunker_stf.jpg", "ai_difficulty": 6.0, "is_boss": true}
	]
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"votos": votos_soft_currency,
			"fundos": fundos_hard_currency,
			"influencia": influencia,
			"season_exp": season_exp,
			"season_tier": season_tier,
			"has_premium_pass": has_premium_pass,
			"campaign_levels": campaign_levels,
			"player_faction": player_faction,
			"unlocked_characters": unlocked_characters,
			"inventory": inventory,
			"current_league": current_league,
			"team_talents": team_talents
		}
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var json = JSON.new()
			if json.parse(text) == OK:
				var data = json.get_data()
				votos_soft_currency = data.get("votos", 0)
				fundos_hard_currency = data.get("fundos", 0)
				influencia = data.get("influencia", 0)
				season_exp = data.get("season_exp", 0)
				season_tier = data.get("season_tier", 1)
				has_premium_pass = data.get("has_premium_pass", false)
				current_league = data.get("current_league", "municipal")
				if data.has("campaign_levels"):
					campaign_levels = data["campaign_levels"]
				elif data.has("campaign_level"): # legacy fallback
					campaign_levels["municipal"] = data["campaign_level"]
				player_faction = data.get("player_faction", "")
				if data.has("unlocked_characters"):
					unlocked_characters = data["unlocked_characters"]
				if data.has("inventory"):
					for key in data["inventory"].keys():
						var val = data["inventory"][key]
						if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
							inventory[key] = {"level": 1, "amount": int(val)}
						else:
							inventory[key] = val
				if data.has("team_talents"):
					for key in data["team_talents"].keys():
						team_talents[key] = data["team_talents"][key]

func setup_campaign_match() -> void:
	if not campaign_leagues.has(current_league):
		current_league = "municipal"
		
	var league = campaign_leagues[current_league]
	var level = campaign_levels.get(current_league, 1)
	
	# Ensure index does not go out of bounds
	var idx = clampi(level - 1, 0, league.size() - 1)
	var opponent = league[idx]
	
	player2_name = opponent["name"]
	player2_sprite = opponent["sprite"]
	map_bg = opponent["bg"]
