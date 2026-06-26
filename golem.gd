extends CharacterBody2D

# Configurações de Movimento
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 90.0
@export var gravity: float = 980.0
@export var vida_maxima: int = 100
var vida_atual: int

@onready var health_bar = $ProgressBar # Se usou TextureProgressBar, troque o nome aqui
@onready var sprite = $AnimatedSprite2D
@onready var edge_checker = $RayCast2D
@onready var detection_area = $DetectionArea
@onready var hitbox = $Hitbox
@onready var colision = $colision

# Configurações de Flutuação
@export var amplitude_flutuacao: float = 5.0 # Quantos pixels ele sobe e desce
@export var velocidade_flutuacao: float = 3.0 # A rapidez do sobe e desce
var tempo_flutuacao: float = 0.0
var sprite_original_y: float = 0.0
var hitbox_original_y: float = 0.0
var detection_area_original_y: float = 0.0
var colision_original_y: float = 0.0

# Variáveis do Ataque
@export var attack_cooldown: float = 3.0
var can_attack: bool = true

# Carrega a cena do tiro (Verifique se o caminho e o nome estão exatos!)
var cena_tiro = preload("res://golem_arm.tscn")

# Definindo os estados possíveis (unindo os seus com os de movimento)
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

# Estado inicial
var estado_atual = Estado.PATROL

# Variáveis de controle
var direction: int = 1
var player_ref: CharacterBody2D = null

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	vida_atual = vida_maxima
	health_bar.max_value = vida_maxima
	health_bar.value = vida_atual
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
	# Aplica gravidade
	match estado_atual:
		Estado.PATROL:
			_patrol_behavior()
		Estado.CHASE:
			_chase_behavior()
		_: 
			velocity.x = move_toward(velocity.x, 0, patrol_speed)
	# ... (O teu código de gravidade, match estado e move_and_slide continuam iguais aqui) ...

	move_and_slide()
	atualizar_animacao()
	
	# EFEITO DE FLUTUAR (Para o Sprite e para as Hitboxes/Áreas)
	if estado_atual != Estado.DIE:
		tempo_flutuacao += delta
		# Calcula o desvio usando a onda Seno
		var movimento_onda = sin(tempo_flutuacao * velocidade_flutuacao) * amplitude_flutuacao
		
		# Aplica o movimento aos três elementos de forma sincronizada
		sprite.position.y = sprite_original_y + movimento_onda
		hitbox.position.y = hitbox_original_y + movimento_onda
		detection_area.position.y = detection_area_original_y + movimento_onda


func _patrol_behavior() -> void:
	if is_on_wall() or (is_on_floor() and not edge_checker.is_colliding()):
		direction *= -1
		edge_checker.position.x *= -1 

	velocity.x = direction * patrol_speed

func _chase_behavior() -> void:
	if player_ref != null:
		var distance_to_player = abs(player_ref.global_position.x - global_position.x)
		var direction_to_player = sign(player_ref.global_position.x - global_position.x)
		
		if direction_to_player != 0:
			direction = direction_to_player
			edge_checker.position.x = abs(edge_checker.position.x) * direction
		
		# Se estiver a uma certa distância (ex: maior que 100 pixels) e o ataque estiver recarregado
		if distance_to_player > 100.0 and can_attack:
			iniciar_ataque_longo()
		else:
			# Só anda se não for atirar
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
			sprite.play("idle") # Substitua por "run" ou "correr" se tiver
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
		mudar_estado(Estado.CHASE)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		mudar_estado(Estado.PATROL)

func receber_dano(quantidade: int) -> void:
	vida_atual -= quantidade
	health_bar.value = vida_atual
	
	
	if vida_atual <= 0:
		morrer()

func morrer() -> void:
	print("Golem foi derrotado!")
	mudar_estado(Estado.DIE)
	
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)
	detection_area.set_deferred("monitorable", false)
		
func receber_dano_percentual(porcentagem: float) -> void:
	var dano_calculado = (vida_maxima * porcentagem) / 100.0
	
	vida_atual -= int(dano_calculado)
	health_bar.value = vida_atual
	
	
	if vida_atual <= 0:
		
		morrer()
		

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
		
		tiro.set("direction", direction)
