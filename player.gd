extends CharacterBody2D

@onready var anim = $AnimationPlayer
@onready var pivot = $Pivot
@onready var particules_pas = $Particules_Pas

const WALK_SPEED = 75.0
const SPEED = 150.0
const RUN_SPEED = 200.0
const SPRINT_SPEED = 350.0
const JUMP_VELOCITY = -400.0
const WALL_JUMP_VELOCITY = -350.0
const WALL_PUSHBACK = 500.0
const DASH_SPEED = 250.0
const ROLL_SPEED = 100.0

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
var is_invisible = false
var is_ledge_grabbing = false
var is_landing = false
var was_on_floor = true
var facing_direction = 1

var coyote_time = 0.0
var jump_buffer = 0.0

# NOUVEAU : Le chrono pour la fenêtre de parade parfaite
var parry_timer = 0.0

func _physics_process(delta: float) -> void:
	if is_dead or is_ledge_grabbing:
		return

	if is_on_floor():
		coyote_time = 0.15
	else:
		coyote_time -= delta

	if Input.is_action_just_pressed("ui_up"):
		jump_buffer = 0.15
	elif jump_buffer > 0:
		jump_buffer -= delta

	if not is_on_floor() and not is_invisible:
		velocity += get_gravity() * delta

	if is_on_floor() and not was_on_floor and velocity.y >= 0 and not is_hurt and not is_attacking and not is_invisible:
		trigger_land()

	if wall_jump_lock > 0:
		wall_jump_lock -= delta

	if combo_timer > 0:
		combo_timer -= delta
	else:
		combo_step = 0

	is_blocking = Input.is_action_pressed("block") and is_on_floor() and not is_rolling and not is_dashing and not is_attacking and not is_hurt and not is_teleporting
	is_crouching = Input.is_action_pressed("ui_down") and is_on_floor() and not is_blocking and not is_rolling and not is_dashing and not is_attacking and not is_hurt and not is_teleporting

	if Input.is_action_just_pressed("block") and is_on_floor() and not is_rolling and not is_dashing and not is_attacking and not is_hurt and not is_teleporting:
		parry_timer = 0.2
		
	if parry_timer > 0:
		parry_timer -= delta

	if Input.is_action_just_pressed("teleport") and not is_teleporting and not is_hurt and not is_dead:
		teleport()

	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling and not is_dashing and not is_hurt and not is_teleporting:
		start_roll()

	if Input.is_action_just_pressed("dash") and not is_dashing and not is_rolling and not is_hurt and not is_teleporting:
		start_dash()

	if Input.is_action_just_pressed("ui_select") and not is_crouching and not is_blocking and not is_dashing and not is_hurt and not is_teleporting:
		if is_rolling:
			roll_attack()
		elif not is_attacking:
			cancel_actions()
			attack()
		else:
			next_attack_queued = true

	if jump_buffer > 0 and not is_crouching and not is_rolling and not is_dashing and not is_hurt and not is_teleporting:
		if coyote_time > 0:
			cancel_actions()
			velocity.y = JUMP_VELOCITY
			jump_buffer = 0.0
			coyote_time = 0.0
		elif is_on_wall_only():
			cancel_actions()
			velocity.y = WALL_JUMP_VELOCITY
			velocity.x = get_wall_normal().x * WALL_PUSHBACK
			wall_jump_lock = 0.3
			jump_buffer = 0.0

	if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right")) and not is_crouching and not is_rolling and not is_dashing and not is_hurt and not is_teleporting:
		cancel_actions()

	var direction := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")
	
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
	elif not is_attacking and not is_crouching and not is_blocking and not is_hurt and not is_landing and not is_teleporting:
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
	elif is_teleporting:
		if is_invisible:
			if direction:
				velocity.x = direction * current_speed
			else:
				velocity.x = move_toward(velocity.x, 0, current_speed)
				
			if direction_y:
				velocity.y = direction_y * current_speed
			else:
				velocity.y = move_toward(velocity.y, 0, current_speed)
		else:
			if direction:
				velocity.x = direction * current_speed
			else:
				velocity.x = move_toward(velocity.x, 0, current_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	was_on_floor = is_on_floor()
	move_and_slide()

	if is_on_floor() and velocity.x != 0 and not is_dashing and not is_rolling and not is_attacking and not is_hurt and not is_teleporting:
		particules_pas.emitting = true
	else:
		particules_pas.emitting = false

	update_animations(direction)

func cancel_actions():
	is_attacking = false
	is_blocking = false
	is_landing = false
	is_teleporting = false
	next_attack_queued = false
	combo_step = 0

func trigger_land():
	is_landing = true
	anim.play("Land")
	await anim.animation_finished
	is_landing = false

func start_roll():
	cancel_actions()
	is_rolling = true
	anim.play("Roll")
	await anim.animation_finished
	is_rolling = false

func start_dash():
	cancel_actions()
	is_dashing = true
	anim.play("Dash")
	if get_tree().has_group("Camera"):
		get_tree().call_group("Camera", "secouer", 0.7, 0.4)
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
			
	if get_tree().has_group("Camera"):
		get_tree().call_group("Camera", "secouer", 0.7, 0.2)
	await anim.animation_finished
	
	if next_attack_queued:
		next_attack_queued = false
		attack()
	else:
		is_attacking = false

func take_damage(attaquant = null):
	if is_dead or is_rolling or is_dashing:
		return
		
	if is_blocking:
		if parry_timer > 0:
			Engine.time_scale = 0.1
			await get_tree().create_timer(0.02, true, false, true).timeout
			Engine.time_scale = 1.0
			if get_tree().has_group("Camera"):
				get_tree().call_group("Camera", "secouer", 1.0, 0.3)
			
			if attaquant and attaquant.has_method("etre_etourdi"):
				attaquant.etre_etourdi()
			return
		else:
			velocity.x = -facing_direction * 200
			return

	is_hurt = true
	is_attacking = false
	is_blocking = false
	anim.play("Hit")
	await anim.animation_finished
	is_hurt = false

func teleport():
	cancel_actions()
	is_teleporting = true
	is_invisible = true
	velocity = Vector2.ZERO
	
	var old_layer = collision_layer
	var old_mask = collision_mask
	collision_layer = 0
	collision_mask = 1
	
	var pos_initiale = pivot.global_position
	pivot.top_level = true
	pivot.global_position = pos_initiale
	anim.play("Jump_Teleport")
	
	await anim.animation_finished
	
	is_invisible = false
	pivot.top_level = false
	pivot.position = Vector2.ZERO
	
	collision_layer = old_layer
	collision_mask = old_mask
	
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

func _on_hitbox_epee_body_entered(body):
	if body.is_in_group("Ennemis"):
		body.prendre_degats(10, global_position.x)
