extends Area2D

@export var speed: float = 200.0 # Velocidade lenta de perseguição
@export var max_angular_speed: float = 3.0 # Velocidade máxima de rotação em radianos/segundo
var direction: int = 1 # 1 para direita, -1 para esquerda
var player_ref: Node2D = null

func _ready() -> void:
	# Procura o jogador na cena usando o grupo "Player"
	var players_na_cena = get_tree().get_nodes_in_group("Player")
	if players_na_cena.size() > 0:
		player_ref = players_na_cena[0] # Guarda o jogador como alvo
		print("GolemArm: Jogador encontrado - ", player_ref.name)
	else:
		print("GolemArm: Nenhum jogador encontrado no grupo 'Player'")
		
	# Destrói o tiro após 15 segundos se não atingir ninguém
	await get_tree().create_timer(15.0).timeout
	if not is_queued_for_deletion():
		queue_free()

func _physics_process(delta: float) -> void:
	# Sempre procura o jogador a cada frame (caso o grupo tenha mudado)
	if player_ref == null:
		var players_na_cena = get_tree().get_nodes_in_group("Player")
		if players_na_cena.size() > 0:
			player_ref = players_na_cena[0]
	
	# Persegue o jogador
	if player_ref != null and not player_ref.is_queued_for_deletion():
		var direction_to_player = global_position.direction_to(player_ref.global_position)
		position += direction_to_player * speed * delta
		
		# Rotação suave limitada
		var target_angle = direction_to_player.angle()
		var angle_diff = angle_difference(rotation, target_angle)
		var max_rotation_change = max_angular_speed * delta
		
		rotation += clamp(angle_diff, -max_rotation_change, max_rotation_change)
	else:
		# Só vai reto se não encontrar jogador
		position.x += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Se bater no jogador, causa dano
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
