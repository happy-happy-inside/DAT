extends Control

enum State { INTRO, PREVIEW, COMBAT, GAME_OVER }
enum Action { ATTACK, PARRY }

var state = State.INTRO

var pattern = []
var actions_pattern = []

var beat_index = 0

var current_action
var beat_time

var input_locked = false
var combat_running = false

# ------------------------
# SETTINGS
# ------------------------

var neutral_time = 0.08
var reaction_delay = 0.18

# speed
var base_speed = 0.8
var speed_multiplier = 1.0
var speed_increase = 0.05

# player
var score = 0
var hp = 3

# shake
var shake_power = 0.0

# ------------------------
# LINKS
# ------------------------

@onready var bg = $Background
@onready var enemy = $Enemy
@onready var camera = $Camera2D

# sounds
@onready var beep = $BeepPlayer
@onready var hit_sound = $HitPlayer
@onready var score_sound = $ScorePlayer
@onready var player_hit = $PlayerHit
@onready var block_sound = $BlockPlayer

# ------------------------
# BACKGROUNDS
# ------------------------

@export var bg_attack: Texture2D
@export var bg_parry: Texture2D

@export var bg_blue: Texture2D
@export var bg_green: Texture2D
@export var bg_yellow: Texture2D

@export var bg_spawn: Texture2D
@export var bg_idle: Texture2D

@export var bg_game_over: Texture2D

# ------------------------
# READY
# ------------------------

func _ready():
	randomize()
	start_intro()

func _process(delta):
	camera_shake(delta)

# ------------------------
# CAMERA SHAKE
# ------------------------

func shake(amount):
	shake_power = float(amount)

func camera_shake(delta):

	if shake_power > 0.0:

		camera.offset = Vector2(
			randf_range(-shake_power, shake_power),
			randf_range(-shake_power, shake_power)
		)

		shake_power = lerpf(shake_power, 0.0, delta * 10.0)

		if shake_power < 0.1:
			shake_power = 0.0
			camera.offset = Vector2.ZERO

# ------------------------
# BACKGROUND
# ------------------------

func set_bg(tex):
	bg.texture = tex

# ------------------------
# INTRO
# ------------------------

func start_intro():

	state = State.INTRO

	set_bg(bg_spawn)

	enemy.visible = true
	enemy.reset()

	await get_tree().create_timer(1.0).timeout

	if state == State.GAME_OVER:
		return

	start_preview()

# ------------------------
# GENERATE PATTERN
# ------------------------

func generate_pattern():

	pattern.clear()
	actions_pattern.clear()

	for i in range(6):

		var t = (base_speed * speed_multiplier)

		t += randf_range(-0.05, 0.05)

		if t < 0.25:
			t = 0.25

		pattern.append(t)

		actions_pattern.append(
			Action.values()[randi() % 2]
		)

# ------------------------
# PREVIEW
# ------------------------

var preview_sequence = []

func start_preview():

	if state == State.GAME_OVER:
		return

	state = State.PREVIEW

	generate_pattern()

	preview_sequence.clear()

	for i in range(pattern.size()):

		var step = i % 3

		if step == 0:
			preview_sequence.append(bg_blue)

		elif step == 1:
			preview_sequence.append(bg_green)

		else:
			preview_sequence.append(bg_yellow)

	beat_index = 0

	play_preview()

func play_preview():

	if state == State.GAME_OVER:
		return

	if beat_index >= preview_sequence.size():
		start_combat()
		return

	set_bg(preview_sequence[beat_index])

	beep.play()

	var delay = pattern[beat_index]

	beat_index += 1

	await get_tree().create_timer(delay).timeout

	play_preview()

# ------------------------
# COMBAT
# ------------------------

func start_combat():

	if state == State.GAME_OVER:
		return

	state = State.COMBAT

	beat_index = 0

	combat_running = true

	play_combat()

func play_combat():

	if not combat_running:
		return

	if state == State.GAME_OVER:
		return

	if enemy.is_dead:
		combat_running = false
		on_enemy_killed()
		return

	if beat_index >= pattern.size():
		combat_running = false
		start_preview()
		return

	input_locked = false

	current_action = actions_pattern[beat_index]

	# enemy attacks
	if current_action == Action.ATTACK:

		set_bg(bg_attack)

		enemy.play_attack()

	# enemy parries
	else:

		set_bg(bg_parry)

		enemy.play_parry()

	beep.play()

	await get_tree().create_timer(reaction_delay).timeout

	if state == State.GAME_OVER:
		return

	beat_time = Time.get_ticks_msec()

	var delay = pattern[beat_index] - reaction_delay

	beat_index += 1

	await get_tree().create_timer(
		delay - neutral_time
	).timeout

	if state == State.GAME_OVER:
		return

	# no input
	if not input_locked:
		on_player_hit()

	if state == State.GAME_OVER:
		return

	set_bg(bg_idle)

	enemy.play_idle()

	await get_tree().create_timer(neutral_time).timeout

	play_combat()

# ------------------------
# INPUT
# ------------------------

func _input(event):

	# restart
	if state == State.GAME_OVER:

		if event.is_action_pressed("restart"):
			restart_game()

		return

	if state != State.COMBAT:
		return

	if event.is_action_pressed("attack"):
		check_input(Action.ATTACK)

	elif event.is_action_pressed("parry"):
		check_input(Action.PARRY)

# ------------------------
# CHECK INPUT
# ------------------------

func check_input(player_action):

	if input_locked:
		return

	if enemy.is_dead:
		return

	input_locked = true

	var reaction = (
		Time.get_ticks_msec() - beat_time
	) / 1000.0

	# wrong button
	if player_action != current_action:

		on_player_hit()

		return

	# attack enemy
	if current_action == Action.PARRY:

		if reaction <= 0.25:

			damage_enemy()

		else:

			on_player_hit()

	# defend
	else:

		if reaction <= 0.25:

			block_sound.play()

			shake(2)

		else:

			on_player_hit()

# ------------------------
# DAMAGE ENEMY
# ------------------------

func damage_enemy():

	enemy.hp -= 1

	enemy.play_damaged()

	hit_sound.play()

	shake(4)

	if enemy.hp <= 0:

		enemy.play_dead()

# ------------------------
# DAMAGE PLAYER
# ------------------------

func on_player_hit():

	if state == State.GAME_OVER:
		return

	hp -= 1

	player_hit.play()

	shake(6)

	print("PLAYER HP:", hp)

	if hp <= 0:

		game_over()

# ------------------------
# ENEMY KILLED
# ------------------------

func on_enemy_killed():

	state = State.INTRO

	score += 500

	score_sound.play()

	shake(8)

	print("ENEMY KILLED")
	print("SCORE:", score)

	# speed up
	speed_multiplier += speed_increase

	await get_tree().create_timer(1.0).timeout

	if state == State.GAME_OVER:
		return

	start_intro()

# ------------------------
# GAME OVER
# ------------------------

func game_over():

	state = State.GAME_OVER

	combat_running = false

	set_bg(bg_game_over)

	enemy.visible = false

	print("GAME OVER")

# ------------------------
# RESTART
# ------------------------

func restart_game():

	hp = 3
	score = 0

	speed_multiplier = 1.0

	combat_running = false

	enemy.visible = true

	start_intro()
