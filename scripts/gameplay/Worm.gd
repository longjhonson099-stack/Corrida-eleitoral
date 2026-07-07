# Esqueleto básico da classe Worm para Godot (GDScript)
# Baseado na estrutura de Worm.ts do Worms-Armageddon-HTML5-Clone

extends CharacterBody2D

class_name Worm

var health: int = 100
var team_id: int
var is_active: bool = false

func _ready():
    # Inicialização básica
    pass

func _physics_process(delta):
    # Lógica de movimentação inspirada na física do Worms
    pass

func take_damage(amount: int):
    health -= amount
    if health <= 0:
        die()

func die():
    queue_free()
