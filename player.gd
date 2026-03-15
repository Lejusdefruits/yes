extends CharacterBody2D

@onready var anim = $AnimationPlayer
@onready var pivot = $Pivot

const WALK_SPEED = 150.0
const SPEED = 200.0
const RUN_SPEED = 300.0
const SPRINT_SPEED = 500.0
const JUMP_VELOCITY = -400.0
const WALL_JUMP_VELOCITY = -350.0
const WALL_PUSHBACK = 500.0
const DASH_SPEED = 800.0
const ROLL_SPEED = 450.0

var is_attacking = false
var next_attack_queued = false
var wall_jump_lock = 0.0
var combo_step = 0
var combo_timer = 0.0
var is_crouching = false
var is_dead = false
var is_rolling = false
var is_blocking = false
var is_dashing = false
var is_hurt = false
var is_teleporting = false
var is_ledge_grabbing = false
var is_landing = false
var was_on_floor = true
var facing_direction = 1

func _physics_process(delta: float) -> void:
	if is_dead or is_teleporting or is_ledge_grabbing:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor() and not was_on_floor and velocity.y >= 0 and not is_hurt and not is_attacking:
		trigger_land()

	if wall_jump_lock > 0:
		wall_jump_lock -= delta

	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_step = 0

	is_blocking = Input.is_action_pressed("block") and is_on_floor() and not is_rolling and not is_dashing and not is_attacking and not is_hurt
	is_crouching = Input.is_action_pressed("ui_down") and is_on_floor() and not is_blocking and not is_rolling and not is_dashing and not is_attacking and not is_hurt

	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling and not is_dashing and not is_attacking and not is_blocking and not is_hurt:
		start_roll()

	if Input.is_action_just_pressed("dash") and not is_dashing and not is_rolling and not is_blocking and not is_attacking and not is_hurt:
		start_dash()

	if Input.is_action_just_pressed("ui_select") and not is_crouching and not is_blocking and not is_dashing and not is_hurt:
		if is_rolling:
			roll_attack()
		elif not is_attacking:
			attack()
		else:
			next_attack_queued = true

	if Input.is_action_just_pressed("ui_up") and not is_attacking and not is_crouching and not is_rolling and not is_blocking and not is_dashing and not is_hurt:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_only():
			velocity.y = WALL_JUMP_VELOCITY
			velocity.x = get_wall_normal().x * WALL_PUSHBACK
			wall_jump_lock = 0.3

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		facing_direction = sign(direction)

	var current_speed = RUN_SPEED
	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED
	elif Input.is_action_pressed("walk"):
		current_speed = WALK_SPEED

	if is_dashing:
		velocity.x = facing_direction * DASH_SPEED
		velocity.y = 0
	elif is_rolling:
		velocity.x = facing_direction * ROLL_SPEED
	elif not is_attacking and not is_crouching and not is_blocking and not is_hurt and not is_landing:
		if is_on_wall_only():
			facing_direction = 1 if get_wall_normal().x < 0 else -1
			pivot.scale.x = facing_direction
		elif direction and wall_jump_lock <= 0:
			pivot.scale.x = facing_direction

		if wall_jump_lock > 0:
			velocity.x = move_toward(velocity.x, direction * SPEED, 1000 * delta)
		elif direction:
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	was_on_floor = is_on_floor()
	move_and_slide()
	update_animations(direction)

func trigger_land():
	is_landing = true
	anim.play("Land")
	await anim.animation_finished
	is_landing = false

func start_roll():
	is_rolling = true
	anim.play("Roll")
	await anim.animation_finished
	is_rolling = false

func start_dash():
	is_dashing = true
	anim.play("Dash")
	await anim.animation_finished
	is_dashing = false

func roll_attack():
	is_rolling = false
	is_attacking = true
	anim.play("Roll_Attack")
	await anim.animation_finished
	is_attacking = false

func attack():
	is_attacking = true
	combo_timer = 1.0
	
	if not is_on_floor():
		if Input.is_action_pressed("ui_down"):
			anim.play("Slam_Attack")
		else:
			anim.play("Fall_Attack")
	else:
		combo_step += 1
		if combo_step == 1:
			anim.play("Slash_1")
		elif combo_step == 2:
			anim.play("Slash_2")
		elif combo_step >= 3:
			anim.play("Spin_Attack")
			combo_step = 0
			
	await anim.animation_finished
	
	if next_attack_queued:
		next_attack_queued = false
		attack()
	else:
		is_attacking = false

func take_damage():
	if is_dead or is_rolling or is_dashing:
		return
	is_hurt = true
	is_attacking = false
	is_blocking = false
	anim.play("Hit")
	await anim.animation_finished
	is_hurt = false

func teleport():
	is_teleporting = true
	anim.play("Jump_Teleport")
	await anim.animation_finished
	anim.play("Appear_From_Teleport")
	await anim.animation_finished
	is_teleporting = false

func grab_ledge():
	is_ledge_grabbing = true
	anim.play("Ledge_Grab")

func die():
	is_dead = true
	anim.play("Death")

func update_animations(direction):
	if is_dead or is_teleporting or is_ledge_grabbing or is_hurt or is_dashing or is_rolling or is_attacking or is_landing:
		return

	if is_blocking:
		anim.play("Block")
		return

	if is_crouching:
		if anim.current_animation != "Crouch" and anim.current_animation != "Stand_To_Crouch":
			anim.play("Stand_To_Crouch")
			anim.queue("Crouch")
		return

	if not is_on_floor():
		if is_on_wall_only():
			if velocity.y > 10:
				anim.play("Wall_Slide")
			elif velocity.y >= 0 and velocity.y <= 10:
				anim.play("Wall_Slide_Stop")
			elif velocity.y < 0:
				anim.play("Static_Wall_To_Slide")
			else:
				anim.play("Static_Wall_Hold")
		elif velocity.y < -50:
			anim.play("Jump")
		elif velocity.y >= -50 and velocity.y < 50:
			anim.play("Jump_To_Fall")
		else:
			anim.play("Fall")
		return

	if direction != 0:
		if Input.is_action_pressed("sprint"):
			anim.play("Run_Fast")
		elif Input.is_action_pressed("walk"):
			anim.play("Walk")
		else:
			anim.play("Run")
	else:
		anim.play("Idle")
