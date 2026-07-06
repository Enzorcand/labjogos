extends Area2D

@export var speed: float = 200.0 # Velocidade de perseguição
@export var turn_speed: float = 1.0 # Velocidade FIXA de rotação em radianos/segundo
var direction: int = 1 
var player_ref: Node2D = null

func _ready() -> void:
	var players_na_cena = get_tree().get_nodes_in_group("Player")
	if players_na_cena.size() > 0:
		player_ref = players_na_cena[0]
		print("GolemArm: Jogador encontrado - ", player_ref.name)
	else:
		print("GolemArm: Nenhum jogador encontrado no grupo 'Player'")
		
	await get_tree().create_timer(15.0).timeout
	if not is_queued_for_deletion():
		queue_free()

func _physics_process(delta: float) -> void:
	speed = speed * 1.01
	turn_speed = turn_speed * 1.005
	if player_ref == null:
		var players_na_cena = get_tree().get_nodes_in_group("Player")
		if players_na_cena.size() > 0:
			player_ref = players_na_cena[0]
	
	if player_ref != null and not player_ref.is_queued_for_deletion():
		# 1. Descobre o ângulo até o jogador
		var direction_to_player = global_position.direction_to(player_ref.global_position)
		var target_angle = direction_to_player.angle()
		
		# 2. Calcula a diferença de ângulo
		var angle_diff = angle_difference(rotation, target_angle)
		
		# 3. Aplica a rotação FIXA
		var rotation_step = turn_speed * delta
		
		# Se a diferença for maior que o passo, roda a uma velocidade constante
		if abs(angle_diff) > rotation_step:
			# sign() retorna 1 ou -1, decidindo se roda para a esquerda ou direita
			rotation += sign(angle_diff) * rotation_step
		else:
			# Se estiver muito perto do ângulo perfeito, fixa no alvo para não tremer
			rotation += angle_diff
		
		# 4. Move o projétil na direção em que está a olhar
		var forward_vector = Vector2.RIGHT.rotated(rotation)
		position += forward_vector * speed * delta
		
	else:
		# Continua na direção atual se não houver jogador
		var forward_vector = Vector2.RIGHT.rotated(rotation)
		position += forward_vector * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("hit_kill"):
		body.hit_kill()
	queue_free()

func angle_difference(from: float, to: float) -> float:
	var diff = to - from
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff
