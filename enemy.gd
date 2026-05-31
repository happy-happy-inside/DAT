extends Node2D

enum EnemyType {
	STANDARD,
	SCOUT,
	TANK
}

@onready var sprite = $Sprite2D

# STANDARD

@export var standard_idle: Texture2D
@export var standard_attack: Texture2D
@export var standard_parry: Texture2D
@export var standard_damaged: Texture2D
@export var standard_dead: Texture2D

# SCOUT

@export var scout_idle: Texture2D
@export var scout_attack: Texture2D
@export var scout_parry: Texture2D
@export var scout_damaged: Texture2D
@export var scout_dead: Texture2D

# TANK

@export var tank_idle: Texture2D
@export var tank_attack: Texture2D
@export var tank_parry: Texture2D
@export var tank_damaged: Texture2D
@export var tank_dead: Texture2D

var idle_tex: Texture2D
var attack_tex: Texture2D
var parry_tex: Texture2D
var damaged_tex: Texture2D
var dead_tex: Texture2D

var enemy_type = EnemyType.STANDARD

var max_hp = 3
var hp = 3

var is_dead = false

func setup(type):

	enemy_type = type

	match type:

		EnemyType.STANDARD:

			max_hp = 3

			idle_tex = standard_idle
			attack_tex = standard_attack
			parry_tex = standard_parry
			damaged_tex = standard_damaged
			dead_tex = standard_dead

		EnemyType.SCOUT:

			max_hp = 1

			idle_tex = scout_idle
			attack_tex = scout_attack
			parry_tex = scout_parry
			damaged_tex = scout_damaged
			dead_tex = scout_dead

		EnemyType.TANK:

			max_hp = 5

			idle_tex = tank_idle
			attack_tex = tank_attack
			parry_tex = tank_parry
			damaged_tex = tank_damaged
			dead_tex = tank_dead

	reset()

func reset():

	hp = max_hp
	is_dead = false

	play_idle()

func play_idle():

	if is_dead:
		return

	sprite.texture = idle_tex
	sprite.scale = Vector2.ONE
	sprite.rotation = 0

func play_attack():

	if is_dead:
		return

	sprite.texture = attack_tex
	sprite.scale = Vector2(1.1, 1.1)

	await get_tree().create_timer(0.08).timeout

	if is_dead:
		return

	sprite.scale = Vector2.ONE

func play_parry():

	if is_dead:
		return

	sprite.texture = parry_tex

	sprite.rotation = -0.08

	await get_tree().create_timer(0.08).timeout

	if is_dead:
		return

	sprite.rotation = 0

func play_damaged():

	if is_dead:
		return

	sprite.texture = damaged_tex

	sprite.scale = Vector2(1.15, 1.15)

	await get_tree().create_timer(0.15).timeout

	if is_dead:
		return

	sprite.scale = Vector2.ONE

	play_idle()

func play_dead():

	is_dead = true

	sprite.texture = dead_tex

	sprite.scale = Vector2.ONE

	sprite.rotation = 0
