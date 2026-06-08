extends Area2D
class_name ProjétilBase

@export var speed: float = 600.0
@export var damage: int = 1

# Mudamos de float para Vector2 para aceitar diagonais e verticais
var direction: Vector2 = Vector2.RIGHT 

func _physics_process(delta: float) -> void:
	# Move o tiro na direção do vetor normalizado
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.name == "Player": 
		return 
	
	if body.has_method("receber_dano_percentual"):
		body.receber_dano_percentual(damage)
		
	queue_free()
	
	
