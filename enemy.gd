extends Node2D

@onready var sprite = $Sprite2D

@export var idle_tex: Texture2D
@export var attack_tex: Texture2D
@export var parry_tex: Texture2D
@export var damaged_tex: Texture2D
@export var dead_tex: Texture2D

var max_hp = 3
var hp = 3
var is_dead = false

func reset():
	hp = max_hp
	is_dead = false
	play_idle()

func play_idle():
	sprite.texture = idle_tex
	sprite.scale = Vector2(1, 1)
	sprite.rotation = 0

func play_attack():
	sprite.texture = attack_tex
	sprite.scale = Vector2(1.2, 1.2)

	await get_tree().create_timer(0.1).timeout

	if is_dead:
		return

	sprite.scale = Vector2(1, 1)

func play_parry():
	sprite.texture = parry_tex
	sprite.rotation = 0.1

	await get_tree().create_timer(0.1).timeout

	if is_dead:
		return

	sprite.rotation = 0

func play_damaged():
	sprite.texture = damaged_tex

	await get_tree().create_timer(0.15).timeout

	if is_dead:
		return

	play_idle()

func play_dead():
	is_dead = true
	sprite.texture = dead_tex
