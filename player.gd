extends CharacterBody2D

# Preload bullet scenes
const BULLET_SCENE = preload("res://TiroDefault.tscn")
const CHARGED_BULLET_SCENE = preload("res://TiroCarregado.tscn")

@onready var shoot_spawn_point: Marker2D = $Marker2D 

# Charging variables
var charge_time: float = 0.0
const MAX_CHARGE_TIME: float = 1.5 # Seconds needed for full charge
var facing_direction: float = 1.0 # Keep track of last moved direction (1 or -1)

@onready var sprite = $AnimatedSprite2D
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var aiming_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Captura o input do WASD
	var input_x := Input.get_axis("ui_left", "ui_right")
	var input_y := Input.get_axis("ui_up", "ui_down")
	
	# Cria o vetor de mira atual do jogador
	var current_input = Vector2(input_x, input_y)
	
	# Se o jogador estiver apertando alguma direção, atualiza a mira salva
	if current_input != Vector2.ZERO:
		aiming_direction = current_input.normalized()
		if input_x != 0:
			facing_direction = sign(input_x)

	# VERIFICAÇÃO DE TRAVA: O jogador está segurando o botão de mirar parado?
	if Input.is_action_pressed("Lock"):
		# Zera a velocidade para o personagem não andar enquanto você mira
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Se NÃO estiver travado, ele anda normalmente usando as teclas laterais
		if input_x:
			velocity.x = input_x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Faz a posição do marcador orbitar ao redor do player com base na mira
	shoot_spawn_point.position = aiming_direction * 20.0

	handle_shooting(delta)
	animate()
	move_and_slide()

func animate():
	if facing_direction > 0:
		sprite.flip_h = false
	elif facing_direction < 0:
		sprite.flip_h = true

	if not is_on_floor():
		sprite.play("jump")
	else:
		if velocity.x != 0:
			sprite.play("run")
		else:
			# Se estiver parado e segurando o botão de trava olhando para cima
			if Input.is_action_pressed("Lock") and aiming_direction.y < 0:
				# Caso você tenha criado uma animação chamada "idle_up"
				if sprite.sprite_frames.has_animation("idle_up"):
					sprite.play("idle_up")
			else:
				sprite.play("idle")

	# Define a direção do sprite baseado na última direção que o jogador se moveu
	if facing_direction > 0:
		sprite.flip_h = false
	elif facing_direction < 0:
		sprite.flip_h = true

	# Prioridade de Animação: Ar vs Chão
	if not is_on_floor():
		sprite.play("jump")
	else:
		if velocity.x != 0:
			sprite.play("run") # Alterado de "walk" para "run" para unificar com o seu script
		else:
			sprite.play("idle")

func handle_shooting(delta: float) -> void:
	if Input.is_action_pressed("Shoot"):
		charge_time += delta

	if Input.is_action_just_released("Shoot"):
		if charge_time >= MAX_CHARGE_TIME:
			fire_bullet(CHARGED_BULLET_SCENE)
		else:
			fire_bullet(BULLET_SCENE)
		
		charge_time = 0.0

func fire_bullet(bullet_scene: PackedScene) -> void:
	var bullet_instance = bullet_scene.instantiate()
	
	# Posiciona o tiro no marcador
	bullet_instance.global_position = shoot_spawn_point.global_position
	
	# Passa o vetor completo de 8 direções para o tiro
	bullet_instance.direction = aiming_direction
	
	# ROTATACÃO AUTOMÁTICA: Faz o tiro apontar visualmente para onde está viajando
	bullet_instance.rotation = aiming_direction.angle()
	
	# Adiciona o tiro na cena
	get_tree().current_scene.add_child(bullet_instance)
