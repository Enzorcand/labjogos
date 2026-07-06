extends CharacterBody2D

# Configurações de Movimento
@export var patrol_speed: float = 70.0 
@export var chase_speed: float = 90.0
@export var gravity: float = 980.0
@export var vida_maxima: int = 100
var vida_atual: int

@onready var health_bar = $ProgressBar 
@onready var sprite = $AnimatedSprite2D
@onready var edge_checker = $RayCast2D
@onready var detection_area = $DetectionArea
@onready var hitbox = $Hitbox
@onready var colision = $colision

# Configurações de Flutuação
@export var amplitude_flutuacao: float = 5.0 
@export var velocidade_flutuacao: float = 3.0 
var tempo_flutuacao: float = 0.0
var sprite_original_y: float = 0.0
var hitbox_original_y: float = 0.0
var detection_area_original_y: float = 0.0
var colision_original_y: float = 0.0

# Configurações de Voo (Boss Voador)
@export var altura_baixa: float = 450.0 # Posição Y no andar de baixo
@export var altura_alta: float = 300.0  # Posição Y no andar de cima
@export var velocidade_voo: float = 120.0
@export var aceleracao: float = 400.0 
@export var distancia_ataque_x: float = 150.0 

# Limiar do andar: Se o Y do jogador for MAIOR que 360, o Boss desce para procurá-lo.
@export var altura_limiar_andar: float = 360.0 

# Controle da Altura
var alvo_y: float = 0.0

# Variáveis do Ataque
@export var attack_cooldown: float = 3.0
var can_attack: bool = true

# Carrega a cena do tiro e da tela final
var cena_tiro = preload("res://golem_arm.tscn")
var cena_tela_final = preload("res://tela_final.tscn")

# Definindo os estados possíveis
enum Estado {
	PATROL,
	CHASE,
	IDLE,
	SHORT_ATTACK,
	LONG_ATTACK,
	ENDURE,
	UP,
	LASER_ATTACK,
	DIE
}

# MODIFICADO: O estado inicial agora é SEMPRE o de perseguição (CHASE)!
var estado_atual = Estado.CHASE

# Variáveis de controle
var direction: int = 1
var player_ref: CharacterBody2D = null

func _ready() -> void:
	collision_mask = 0 
	alvo_y = altura_baixa
	
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	vida_atual = vida_maxima
	health_bar.max_value = vida_maxima
	health_bar.value = vida_atual
	
	# Ainda conectamos caso precise de alguma referência extra no futuro, mas sem mudar para PATROL
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	sprite_original_y = sprite.position.y
	hitbox_original_y = hitbox.position.y
	detection_area_original_y = detection_area.position.y
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	print("ALERTA: Algo bateu na Hitbox do Golem! Nome: ", body.name)
	
	if body.is_in_group("Player") or body.name == "Player":
		print("SUCESSO: A engine reconheceu que é o Player!")
		
		if body.has_method("hit_kill"):
			print("SUCESSO: A função hit_kill foi encontrada. Chamando agora...")
			body.hit_kill()
		else:
			print("ERRO: O script do Player NÃO tem a função 'hit_kill' ou o nome está escrito errado.")

func _physics_process(delta: float) -> void:
	# Atualiza a altura alvo dinamicamente a cada frame enquanto estiver vivo
	if estado_atual != Estado.DIE:
		_atualizar_altura_alvo()

	match estado_atual:
		Estado.PATROL:
			_voo_patrol_behavior(delta)
		Estado.CHASE:
			_voo_chase_behavior(delta)
		Estado.DIE:
			velocity.x = move_toward(velocity.x, 0, aceleracao * delta)
			if not is_on_floor():
				velocity.y += 980.0 * delta 
		_: 
			velocity = velocity.move_toward(Vector2.ZERO, aceleracao * delta)

	move_and_slide()
	atualizar_animacao()
	
	if estado_atual != Estado.DIE:
		tempo_flutuacao += delta
		var movimento_onda = sin(tempo_flutuacao * velocidade_flutuacao) * amplitude_flutuacao
		
		sprite.position.y = sprite_original_y + movimento_onda
		hitbox.position.y = hitbox_original_y + movimento_onda
		detection_area.position.y = detection_area_original_y + movimento_onda

# Busca sempre pelo jogador globalmente (garante que nunca perde o alvo)
func _obter_jogador_global() -> Node2D:
	if player_ref != null:
		return player_ref
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		return players[0]
	return get_tree().root.find_child("Player", true, false)

func _atualizar_altura_alvo() -> void:
	var jogador = _obter_jogador_global()
			
	if jogador:
		# Se a posição Y do jogador for MAIOR que o limite (360), ele está fisicamente abaixo
		if jogador.global_position.y > altura_limiar_andar:
			alvo_y = altura_baixa # O boss voa baixo no andar inferior
		else:
			alvo_y = altura_alta  # O boss voa alto no andar superior
	else:
		alvo_y = altura_baixa 

func virar_boss(nova_direcao: int) -> void:
	if nova_direcao != 0 and direction != nova_direcao:
		direction = nova_direcao
		atualizar_animacao()
		if detection_area:
			detection_area.scale.x = direction
		if hitbox:
			hitbox.scale.x = direction
		if edge_checker:
			edge_checker.scale.x = direction

func _patrol_behavior() -> void:
	if is_on_wall() or (is_on_floor() and not edge_checker.is_colliding()):
		virar_boss(direction * -1)
	velocity.x = direction * patrol_speed

func _chase_behavior() -> void:
	var jogador = _obter_jogador_global()
	if jogador != null:
		var distance_to_player = abs(jogador.global_position.x - global_position.x)
		var direction_to_player = sign(jogador.global_position.x - global_position.x)
		
		if direction_to_player != 0:
			direction = direction_to_player
			if edge_checker:
				edge_checker.position.x = abs(edge_checker.position.x) * direction
		
		if distance_to_player > 100.0 and can_attack:
			iniciar_ataque_longo()
		else:
			velocity.x = direction * chase_speed

func atualizar_animacao():
	if direction == 1:
		sprite.flip_h = false
	elif direction == -1:
		sprite.flip_h = true

	match estado_atual:
		Estado.PATROL:
			sprite.play("idle")
		Estado.CHASE:
			sprite.play("idle") # Coloque "run" ou "fly" aqui se tiver a animação
		Estado.IDLE:
			sprite.play("idle")
		Estado.SHORT_ATTACK:
			sprite.play("short_attack")
		Estado.LONG_ATTACK:
			sprite.play("long_attack")
		Estado.ENDURE:
			sprite.play("endure")
		Estado.UP:
			sprite.play("up")
		Estado.LASER_ATTACK:
			sprite.play("laser_attack")
		Estado.DIE:
			sprite.play("die")

func mudar_estado(novo_estado: int):
	if estado_atual != novo_estado:
		estado_atual = novo_estado
		atualizar_animacao()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		# MODIFICADO: Não voltamos mais para o estado de PATROL quando o jogador sai da área!

func receber_dano(quantidade: int) -> void:
	vida_atual -= quantidade
	health_bar.value = vida_atual
	
	if vida_atual <= 0:
		morrer()

func morrer() -> void:
	print("Golem foi derrotado!")
	mudar_estado(Estado.DIE)
	collision_mask = 1 
	
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)
	detection_area.set_deferred("monitorable", false)
	
	await get_tree().create_timer(2.0).timeout
	if cena_tela_final:
		var tela = cena_tela_final.instantiate()
		get_tree().current_scene.add_child(tela)
		if tela.has_method("configurar_tela"):
			tela.configurar_tela(true)
		
func receber_dano_percentual(porcentagem: float) -> void:
	var dano_calculado = (vida_maxima * porcentagem) / 100.0
	vida_atual -= int(dano_calculado)
	health_bar.value = vida_atual
	
	if vida_atual <= 0:
		morrer()
		
func _voo_patrol_behavior(delta: float) -> void:
	# Como o boss agora fica sempre em CHASE, esta função só roda se você forçar o estado via código
	var ponto_alvo_2d = Vector2(global_position.x, alvo_y)
	var direcao_movimento = global_position.direction_to(ponto_alvo_2d)
	
	if global_position.distance_to(ponto_alvo_2d) > 10.0:
		velocity = velocity.move_toward(direcao_movimento * patrol_speed, aceleracao * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, aceleracao * delta)

# MODIFICADO: Perseguição de voo contínua e global
func _voo_chase_behavior(delta: float) -> void:
	var jogador = _obter_jogador_global()
	
	if jogador != null:
		# 1. Vira o boss sempre para o lado do jogador em tempo real
		var direcao_x = sign(jogador.global_position.x - global_position.x)
		virar_boss(direcao_x)
		
		# 2. Define o "Ponto Alvo" ideal no ar para manter a distância de ataque
		var alvo_x = jogador.global_position.x - (direction * distancia_ataque_x)
		var ponto_alvo_2d = Vector2(alvo_x, alvo_y)
		
		# 3. Calcula a distância e voa suavemente até o ponto de combate
		var distancia_para_alvo = global_position.distance_to(ponto_alvo_2d)
		var direcao_movimento = global_position.direction_to(ponto_alvo_2d)
		
		if distancia_para_alvo > 10.0:
			velocity = velocity.move_toward(direcao_movimento * velocidade_voo, aceleracao * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, aceleracao * delta)
		
		# 4. Ataca sem parar sempre que o tempo de recarga permitir
		if can_attack:
			iniciar_ataque_longo()

func iniciar_ataque_longo() -> void:
	can_attack = false
	mudar_estado(Estado.LONG_ATTACK)
	
	await get_tree().create_timer(1).timeout
	
	if estado_atual == Estado.LONG_ATTACK:
		_disparar_projetil()
	
	await get_tree().create_timer(0.5).timeout
	
	mudar_estado(Estado.CHASE)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _disparar_projetil() -> void:
	if cena_tiro:
		var tiro = cena_tiro.instantiate()
		get_parent().add_child(tiro)
		tiro.global_position = global_position + Vector2(direction * 60, -30) 
		
		var direcao_vetor = Vector2(direction, 0)
		tiro.set("direction", direcao_vetor)
		
		if direction == -1:
			tiro.rotation = PI 
		else:
			tiro.rotation = 0
