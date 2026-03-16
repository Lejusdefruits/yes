extends Camera2D

@export var joueur : Node2D

var force_secousse : float = 0.0
var temps_secousse : float = 0.0

func _ready():
	add_to_group("Camera")

func _physics_process(delta):
	if joueur:
		global_position.x = joueur.get_node("Pivot").global_position.x
		
	if temps_secousse > 0:
		temps_secousse -= delta
		offset = Vector2(randf_range(-force_secousse, force_secousse), randf_range(-force_secousse, force_secousse))
	else:
		offset = Vector2.ZERO

func secouer(intensite: float, duree: float):
	force_secousse = intensite
	temps_secousse = duree
