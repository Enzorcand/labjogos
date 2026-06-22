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
	if not is_on_floor():
		velocity.y += gravity * delta

	match estado_atual:
		Estado.PATROL:
			_patrol_behavior()
		Estado.CHASE:
			_chase_behavior()
		_: 
			velocity.x = move_toward(velocity.x, 0, patrol_speed)

	move_and_slide()
	
	if estado_atual != Estado.DIE: 
		atualizar_animacao()


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
	
	# Desliga a hitbox e a área de deteção de forma segura para não haver erros de física
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
	
	# Usamos um timer simples via código para esperar a animação "armar" o tiro (ex: 0.5s)
	await get_tree().create_timer(1).timeout
	# Só atira se ainda estiver no estado de ataque longo (caso não tenha morrido/tomado stun nesse meio tempo)
	if estado_atual == Estado.LONG_ATTACK:
		_disparar_projetil()
	
	# Espera a animação de ataque terminar (ajuste esse tempo para o tamanho da sua animação)
	await get_tree().create_timer(0.5).timeout
	
	# Volta a perseguir o jogador
	mudar_estado(Estado.CHASE)
	
	# Inicia o tempo de recarga para poder atirar de novo
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _disparar_projetil() -> void:
	if cena_tiro:
		var tiro = cena_tiro.instantiate()
		
		# Adicionamos o tiro ao cenário (pai do golem) para ele não se mover junto com o corpo do boss
		get_parent().add_child(tiro)
		
		# Define de onde o tiro sai (global_position do boss + um avanço para frente, afastado da hitbox)
		tiro.global_position = global_position + Vector2(direction * 60, -30) 
		
		# Usa set() para atribuir a variável de script do nó
		tiro.set("direction", direction)
