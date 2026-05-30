extends Area2D
class_name ProjétilBase # Isso transforma esse script em um tipo global

# Usamos @export para que cada tiro possa ter um valor diferente no Inspetor
@export var speed: float = 600.0
@export var damage: int = 1

var direction: float = 1.0

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.name == "Player": 
		return 
	
	if body.has_method("take_damage"):
		body.take_damage(damage) # Usa o dano específico da cena filha
		
	queue_free()
