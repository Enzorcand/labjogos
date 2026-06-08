extends Area2D

@export var speed: float = 300.0
var direction: int = 1 # 1 para direita, -1 para esquerda

func _physics_process(delta: float) -> void:
	# Move o tiro horizontalmente
	position.x += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	print("acertou")
	if body.is_in_group("Player") or body.name == "Player":
		if body.has_method("hit_kill"):
			body.hit_kill()
		
	queue_free()
