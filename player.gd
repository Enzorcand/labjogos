extends CharacterBody2D

# Preload bullet scenes
const BULLET_SCENE = preload("res://TiroDefault.tscn")
const CHARGED_BULLET_SCENE = preload("res://TiroCarregado.tscn")

@export var shoot_spawn_point: Marker2D # Placement marker on player sprite

# Charging variables
var charge_time: float = 0.0
const MAX_CHARGE_TIME: float = 1.5 # Seconds needed for full charge
var facing_direction: float = 1.0 # Keep track of last moved direction (1 or -1)

@onready var sprite = $AnimatedSprite2D
const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction != 0:
		facing_direction = sign(direction)

	handle_shooting(delta)
	animate()
	move_and_slide()
	
func animate():
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
	# Case 1: Player holding the button down -> Increment charge
	if Input.is_action_pressed("Shoot"):
		charge_time += delta
		if charge_time >= MAX_CHARGE_TIME:
			# Dica: Você pode mudar o "Modulate" do sprite aqui para fazê-lo piscar azul/verde como o Mega Man clássico!
			pass

	# Case 2: Player releases the button -> Determine shot type
	if Input.is_action_just_released("Shoot"):
		if charge_time >= MAX_CHARGE_TIME:
			fire_bullet(CHARGED_BULLET_SCENE)
		else:
			fire_bullet(BULLET_SCENE)
		
		charge_time = 0.0 # Reset tracking loop

func fire_bullet(bullet_scene: PackedScene) -> void:
	var bullet_instance = bullet_scene.instantiate()
	
	# CORRIGIDO: Removido os caracteres 'zz' que travavam o código
	bullet_instance.global_position = shoot_spawn_point.global_position
	# Pass player orientation to bullet
	bullet_instance.direction = facing_direction
	
	# Adjust bullet visual orientation if your sprite needs mirroring
	if facing_direction < 0:
		bullet_instance.scale.x = -1
		
	# Spawn bullet into main game tree hierarchy 
	get_tree().current_scene.add_child(bullet_instance)
