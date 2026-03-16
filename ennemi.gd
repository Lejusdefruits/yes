extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEATH, STUNNED }
var current_state = State.PATROL

@onready var pivot = $Pivot
@onready var detecteur_sol = $Pivot/Detecteur_Sol
@onready var zone_vision = $Pivot/Vision
@onready var zone_attaque = $Pivot/Attack
@onready var anim = $AnimationPlayer

@export var pv: int = 100
@export var vitesse_patrouille: float = 50.0
@export var vitesse_chasse: float = 120.0
@export var distance_attaque: float = 60.0

var direction = -1
var joueur_cible = null
var is_attacking = false

func _ready():
	add_to_group("Ennemis")
	pivot.scale.x = direction

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if current_state == State.DEATH or current_state == State.HURT or current_state == State.STUNNED:
		velocity.x = move_toward(velocity.x, 0, 800 * delta)
		move_and_slide()
		return

	match current_state:
		State.PATROL:
			patrouiller()
		State.CHASE:
			chasser()
		State.ATTACK:
			attaquer()
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, vitesse_patrouille)
			anim.play("Idle")

	move_and_slide()

func patrouiller():
	anim.play("Walk")
	if is_on_floor():
		if is_on_wall() or not detecteur_sol.is_colliding():
			direction *= -1
			pivot.scale.x = direction
	
	velocity.x = direction * vitesse_patrouille

func chasser():
	anim.play("Walk")
	if joueur_cible:
		var dir_vers_joueur = sign(joueur_cible.global_position.x - global_position.x)
		if dir_vers_joueur != 0:
			direction = dir_vers_joueur
			pivot.scale.x = direction
			
		var dist = global_position.distance_to(joueur_cible.global_position)
		
		if dist < distance_attaque:
			changer_etat(State.ATTACK)
		else:
			velocity.x = direction * vitesse_chasse
	else:
		changer_etat(State.PATROL)

func attaquer():
	if is_attacking: return
	is_attacking = true
	velocity.x = 0
	anim.play("Attack")
	
	await anim.animation_finished
	
	is_attacking = false
	if joueur_cible:
		changer_etat(State.CHASE)
	else:
		changer_etat(State.PATROL)

func changer_etat(nouveau_etat):
	if current_state == State.DEATH: return
	if is_attacking and nouveau_etat != State.DEATH and nouveau_etat != State.HURT and nouveau_etat != State.STUNNED: return
	current_state = nouveau_etat

func prendre_degats(degats: int, attaquant_x: float):
	if current_state == State.DEATH: return
	
	pv -= degats
	changer_etat(State.HURT)
	anim.play("Idle")
	modulate = Color(10, 10, 10)
	
	var dir_recul = 1 if global_position.x > attaquant_x else -1
	velocity.x = dir_recul * 150
	velocity.y = -100
	
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.05, true, false, true).timeout
	Engine.time_scale = 1.0
	
	await get_tree().create_timer(0.2).timeout
	modulate = Color(1, 1, 1)
	
	if pv <= 0:
		changer_etat(State.DEATH)
		mourir()
	else:
		is_attacking = false
		changer_etat(State.CHASE)

func etre_etourdi():
	changer_etat(State.STUNNED)
	is_attacking = false
	anim.play("Idle")
	
	velocity.x = -direction * 150
	velocity.y = -150
	
	for i in range(10):
		if current_state != State.STUNNED:
			break
		modulate = Color(5, 5, 5) if i % 2 == 0 else Color(1, 1, 1)
		await get_tree().create_timer(0.2).timeout
	
	if current_state == State.STUNNED:
		modulate = Color(1, 1, 1)
		changer_etat(State.CHASE)

func mourir():
	velocity.x = 0
	anim.play("Die")
	await anim.animation_finished
	queue_free()

func _on_attack_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(self)

func _on_vision_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		joueur_cible = body
		changer_etat(State.CHASE)

func _on_vision_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		joueur_cible = null
		changer_etat(State.PATROL)
