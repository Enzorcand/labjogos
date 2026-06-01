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

# Definindo os estados possíveis (unindo os seus com os de movimento)
enum Estado {
	PATROL,
	CHASE,
	IDLE,
	SHORT_ATTACK,
	LONG_ATTACK,
	ENDURE,
	UP,
	LASER_ATTACK
}

# Estado inicial
var estado_atual = Estado.PATROL

# Variáveis de controle
var direction: int = 1
var player_ref: CharacterBody2D = null

func _ready() -> void:

	vida_atual = vida_maxima
	health_bar.max_value = vida_maxima
	health_bar.value = vida_atual
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		if body.has_method("hit_kill"):
			body.hit_kill()

func _physics_process(delta: float) -> void:
	# Aplica gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Executa a lógica dependendo do estado atual
	match estado_atual:
		Estado.PATROL:
			_patrol_behavior()
		Estado.CHASE:
			_chase_behavior()
		_: 
			# Se estiver atacando, usando laser ou "endure", ele para de andar
			velocity.x = move_toward(velocity.x, 0, patrol_speed)

	# Aplica o movimento
	move_and_slide()
	
	# Atualiza a direção do sprite e as animações
	atualizar_animacao()

# --- COMPORTAMENTOS DE MOVIMENTO ---

func _patrol_behavior() -> void:
	# Bateu na parede ou chegou no fim do chão
	if is_on_wall() or (is_on_floor() and not edge_checker.is_colliding()):
		direction *= -1
		edge_checker.position.x *= -1 # Ajusta o RayCast

	velocity.x = direction * patrol_speed

func _chase_behavior() -> void:
	if player_ref != null:
		var direction_to_player = sign(player_ref.global_position.x - global_position.x)
		
		if direction_to_player != 0:
			direction = direction_to_player
			edge_checker.position.x = abs(edge_checker.position.x) * direction
		
		velocity.x = direction * chase_speed

# --- CONTROLE DE ANIMAÇÕES E ESTADOS ---

func atualizar_animacao():
	# Vira o sprite para a direção do movimento
	if direction == 1:
		sprite.flip_h = false
	elif direction == -1:
		sprite.flip_h = true

	# Reproduz a animação de acordo com o estado
	match estado_atual:
		Estado.PATROL:
			sprite.play("idle") # Substitua por "walk" ou "andar" se você tiver essa animação
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

func mudar_estado(novo_estado: int):
	if estado_atual != novo_estado:
		estado_atual = novo_estado

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
	queue_free() # Remove o Golem do jogo
		
func receber_dano_percentual(porcentagem: float) -> void:
	# Calcula o valor do dano baseado na vida máxima
	var dano_calculado = (vida_maxima * porcentagem) / 100.0
	
	vida_atual -= int(dano_calculado) # Converte para inteiro caso dê número quebrado
	health_bar.value = vida_atual
	
	# Efeito visual opcional de piscar em vermelho poderia entrar aqui
	
	if vida_atual <= 0:
		morrer()
