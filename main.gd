extends Control

enum State {
	WARNING,
	MENU,
	TUTORIAL,
	INTRO,
	RHYTHM,
	COMBAT,
	GAME_OVER
}

enum Action {
	ATTACK,
	PARRY
}

@onready var back_bg = $BackBackground
@onready var front_bg = $FrontBackground

@onready var enemy = $Enemy
@onready var camera = $Camera2D

@onready var ui = $UI

@onready var heart1 = $UI/Heart1
@onready var heart2 = $UI/Heart2
@onready var heart3 = $UI/Heart3

@onready var beep = $BeepPlayer
@onready var hit_sound = $HitPlayer
@onready var parry_sound = $ParryPlayer
@onready var score_sound = $ScorePlayer
@onready var player_hit = $PlayerHit
@onready var block_sound = $BlockPlayer
@onready var short_violin = $ShortViolin
@onready var long_violin = $LongViolin

# BACKGROUND

@export var back_idle: Texture2D
@export var back_attack: Texture2D
@export var back_parry: Texture2D
@export var back_spawn: Texture2D
@export var back_game_over: Texture2D
@export var back_rhythm_black: Texture2D
@export var back_rhythm_white: Texture2D

@export var front_idle: Texture2D
@export var front_attack: Texture2D
@export var front_parry: Texture2D
@export var front_spawn: Texture2D
@export var front_game_over: Texture2D
@export var front_rhythm_black: Texture2D
@export var front_rhythm_white: Texture2D

@onready var warning_screen = $WarningScreen
@onready var menu_screen = $MenuScreen
@onready var tutorial_screen = $TutorialScreen

@onready var score_label = $UI/ScoreLabel

@onready var game_over_stats = $GameOverStats
@onready var best_score_label = $GameOverStats/BestScoreLabel
@onready var final_score_label = $GameOverStats/ScoreLabel
@onready var kills_label = $GameOverStats/KillsLabel
@onready var time_label = $GameOverStats/TimeLabel

var state = State.INTRO

var score = 0
var hp = 3

var kills = 0
var best_score = 0

var game_time = 0.0

var shake_power = 0.0
var heart_time = 0.0

var back_move = 0.0
var front_move = 0.0

var rhythm = []
var rhythm_types = []
var combat_pattern = []

var note_index = 0
var current_action

var awaiting_input = false

var beat_speed = 0.45
var global_speed_mult = 1.0

var mistakes = 0



var rhythm_values = [
	1.0, # короткая
	2.0, # средняя
	3.0  # длинная
]

func _ready():

	randomize()

	refresh_hp_ui()
	refresh_score_ui()

	game_over_stats.hide()

	state = State.WARNING

	warning_screen.show()
	menu_screen.hide()
	tutorial_screen.hide()

	ui.hide()
	enemy.hide()

func _process(delta):

	update_background_motion(delta)

	camera_shake(delta)

	update_hearts(delta)
	
	if state != State.GAME_OVER \
	and state != State.WARNING \
	and state != State.MENU \
	and state != State.TUTORIAL:
			game_time += delta

# ---------------------
# HEARTS
# ---------------------

func update_hearts(delta):

	heart_time += delta

	var beat = fmod(heart_time, 1.0)

	var scale_value = 1.0

	if beat < 0.08:
		scale_value = 1.12
	elif beat < 0.16:
		scale_value = 1.05
	elif beat < 0.24:
		scale_value = 1.15

	if hp >= 1:
		heart1.scale = Vector2.ONE * scale_value

	if hp >= 2:
		heart2.scale = Vector2.ONE * scale_value

	if hp >= 3:
		heart3.scale = Vector2.ONE * scale_value

func refresh_hp_ui():

	heart1.visible = hp >= 1
	heart2.visible = hp >= 2
	heart3.visible = hp >= 3

func refresh_score_ui():

	score_label.text = str(score)
# ---------------------
# BACKGROUND
# ---------------------

func update_background_motion(delta):

	back_move += delta * 0.5

	back_bg.position = Vector2(
		sin(back_move) * 12,
		cos(back_move) * 12
	)

func set_backgrounds(back_tex, front_tex):

	back_bg.texture = back_tex
	front_bg.texture = front_tex

# ---------------------
# SHAKE
# ---------------------

func shake(amount):

	shake_power = amount

func camera_shake(delta):

	if shake_power <= 0:
		return

	camera.offset = Vector2(
		randf_range(-shake_power, shake_power),
		randf_range(-shake_power, shake_power)
	)

	shake_power = lerpf(
		shake_power,
		0.0,
		delta * 10.0
	)

	if shake_power < 0.1:

		shake_power = 0.0
		camera.offset = Vector2.ZERO

# ---------------------
# ENEMY SPAWN
# ---------------------

func spawn_enemy_type():

	var roll = randi() % 100

	if roll < 50:

		enemy.setup(enemy.EnemyType.STANDARD)

		beat_speed = 0.65

	elif roll < 75:

		enemy.setup(enemy.EnemyType.SCOUT)

		beat_speed = 0.50

	else:

		enemy.setup(enemy.EnemyType.TANK)

		beat_speed = 0.80

	beat_speed *= global_speed_mult

# ---------------------
# INTRO
# ---------------------

func start_intro():

	awaiting_input = false

	note_index = 0

	state = State.INTRO

	set_backgrounds(
		back_spawn,
		front_spawn
	)

	enemy.show()

	spawn_enemy_type()

	await get_tree().create_timer(1.0).timeout

	if state == State.GAME_OVER:
		return

	start_rhythm()

# ---------------------
# RHYTHM
# ---------------------

func generate_round():

	rhythm.clear()
	rhythm_types.clear()
	combat_pattern.clear()

	var notes = randi_range(4, 6)

	for i in range(notes):

		var is_long = randf() < 0.35

		if is_long:

			rhythm.append(2.0 * beat_speed)
			rhythm_types.append("long")

		else:

			rhythm.append(1.0 * beat_speed)
			rhythm_types.append("short")

		combat_pattern.append(
			Action.values()[randi() % 2]
		)

	mistakes = 0

func start_rhythm():

	state = State.RHYTHM

	generate_round()

	for i in range(rhythm.size()):

		if i % 2 == 0:

			set_backgrounds(
				back_rhythm_black,
				front_rhythm_black
			)

		else:

			set_backgrounds(
				back_rhythm_white,
				front_rhythm_white
			)

		if rhythm_types[i] == "long":

			long_violin.play()

		else:

			short_violin.play()

		await get_tree().create_timer(
			rhythm[i]
		).timeout

		if state == State.GAME_OVER:
			return

	set_backgrounds(
		back_idle,
		front_idle
	)

	await get_tree().create_timer(0.5).timeout

	if state == State.GAME_OVER:
		return

	start_combat()

# ---------------------
# COMBAT
# ---------------------

func start_combat():

	state = State.COMBAT

	note_index = 0

	play_next_note()
func play_next_note():

	if state == State.GAME_OVER:
		return

	if enemy.is_dead:

		on_enemy_killed()
		return

	if note_index >= combat_pattern.size():

		if mistakes == 0:

			damage_enemy()

		await get_tree().create_timer(0.6).timeout

		if state == State.GAME_OVER:
			return

		if enemy.is_dead:

			on_enemy_killed()

		else:

			start_rhythm()

		return

	current_action = combat_pattern[note_index]

	if current_action == Action.ATTACK:

		set_backgrounds(
			back_attack,
			front_attack
		)

		enemy.play_attack()

	else:

		set_backgrounds(
			back_parry,
			front_parry
		)

		enemy.play_parry()

	awaiting_input = true

	var note_length = rhythm[note_index]

	var action_time = note_length * 0.7
	var rest_time = note_length * 0.3

	await get_tree().create_timer(
		action_time
	).timeout

	if state == State.GAME_OVER:
		return

	enemy.play_idle()

	set_backgrounds(
		back_idle,
		front_idle
	)

	await get_tree().create_timer(
		rest_time
	).timeout

	if state == State.GAME_OVER:
		return

	if awaiting_input:

		awaiting_input = false

		mistakes += 1

		on_player_hit()

	note_index += 1

	if state != State.GAME_OVER:

		play_next_note()

# ---------------------
# INPUT
# ---------------------

func _input(event):

	# WARNING SCREEN

	if state == State.WARNING:

		if (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed):

			warning_screen.hide()

			menu_screen.show()

			state = State.MENU

		return

	# MENU SCREEN

	if state == State.MENU:

		if (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed):

			menu_screen.hide()

			tutorial_screen.show()

			state = State.TUTORIAL

		return

	# TUTORIAL SCREEN

	if state == State.TUTORIAL:

		if (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed):

			tutorial_screen.hide()

			ui.show()
			enemy.show()

			start_intro()

		return

	# GAME OVER

	if state == State.GAME_OVER:

		if event.is_action_pressed("restart"):

			restart_game()

		return

	# ONLY COMBAT ACCEPTS INPUT

	if state != State.COMBAT:
		return

	# KEYBOARD

	if event.is_action_pressed("attack"):

		check_input(Action.ATTACK)

	elif event.is_action_pressed("parry"):

		check_input(Action.PARRY)

	# MOBILE

	elif event is InputEventScreenTouch:

		if not event.pressed:
			return

		var screen_center = get_viewport_rect().size.x / 2.0

		if event.position.x < screen_center:

			check_input(Action.PARRY)

		else:

			check_input(Action.ATTACK)

func check_input(player_action):

	if not awaiting_input:
		return

	if enemy.is_dead:
		return

	awaiting_input = false

	var correct = false

	if current_action == Action.ATTACK:

		correct = (
			player_action == Action.PARRY
		)

	else:

		correct = (
			player_action == Action.ATTACK
		)

	if not correct:

		mistakes += 1

		on_player_hit()

	else:

		shake(2)

		if current_action == Action.ATTACK:

			block_sound.play()

		else:

			parry_sound.play()

# ---------------------
# DAMAGE
# ---------------------

func damage_enemy():

	enemy.hp -= 1

	enemy.play_damaged()

	hit_sound.play()

	shake(4)

	if enemy.hp <= 0:

		enemy.play_dead()

func on_player_hit():

	if state == State.GAME_OVER:
		return

	hp -= 1

	refresh_hp_ui()

	player_hit.play()

	shake(6)

	if hp <= 0:

		game_over()

# ---------------------
# KILL
# ---------------------

func on_enemy_killed():

	score += 500
	kills += 1

	refresh_score_ui()

	score_sound.play()

	shake(8)

	global_speed_mult *= 0.985

	await get_tree().create_timer(1.0).timeout

	if state == State.GAME_OVER:
		return

	start_intro()

# ---------------------
# GAME OVER
# ---------------------

func game_over():

	state = State.GAME_OVER

	if score > best_score:
		best_score = score

	set_backgrounds(
		back_game_over,
		front_game_over
	)

	enemy.hide()
	ui.hide()

	game_over_stats.show()

	best_score_label.text = str(best_score)
	final_score_label.text = str(score)
	kills_label.text = str(kills)

	time_label.text = str(int(game_time))

# ---------------------
# RESTART
# ---------------------

func restart_game():

	score = 0

	hp = 3

	global_speed_mult = 1.0

	awaiting_input = false

	note_index = 0

	refresh_hp_ui()

	enemy.hide()
	ui.hide()

	warning_screen.hide()
	tutorial_screen.hide()

	menu_screen.show()

	score = 0
	kills = 0
	game_time = 0.0

	refresh_score_ui()

	game_over_stats.hide()

	state = State.MENU
