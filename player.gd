extends CharacterBody2D

# Preload bullet scenes
const BULLET_SCENE = preload("res://TiroDefault.tscn")
const CHARGED_BULLET_SCENE = preload("res://TiroCarregado.tscn")

@onready var charge_bar = $ChargeBar
@onready var shoot_spawn_point: Marker2D = $Marker2D 

var is_dead: bool = false
@export var forca_pulo_morte: float = -400.0 # Ajuste para o quão alto ele deve pular ao morrer

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
		
	if is_dead:
		move_and_slide()
		return

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not Input.is_action_pressed("Lock"):
		velocity.y = JUMP_VELOCITY

	var input_x := Input.get_axis("ui_left", "ui_right")
	var input_y := Input.get_axis("ui_up", "ui_down")
	
	var current_input = Vector2(input_x, input_y)
	
	if current_input != Vector2.ZERO:
		aiming_direction = current_input.normalized()
		if input_x != 0:
			facing_direction = sign(input_x)

	
	if Input.is_action_pressed("Lock"):
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		if input_x != 0:
			velocity.x = input_x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

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
			if Input.is_action_pressed("Lock") and aiming_direction.y < 0:
				if sprite.sprite_frames.has_animation("idle_up"):
					sprite.play("idle_up")
			else:
				sprite.play("idle")

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
			sprite.play("idle")

func handle_shooting(delta: float) -> void:
	if Input.is_action_pressed("Shoot"):
		charge_time += delta
		
		if charge_time > 0.1:
			charge_bar.visible = true
			charge_bar.value = charge_time 
			
		if charge_time >= MAX_CHARGE_TIME:
			charge_bar.value = MAX_CHARGE_TIME

	if Input.is_action_just_released("Shoot"):
		if charge_time >= MAX_CHARGE_TIME:
			fire_bullet(CHARGED_BULLET_SCENE)
		else:
			fire_bullet(BULLET_SCENE)
		
		charge_time = 0.0
		charge_bar.value = 0.0
		charge_bar.visible = false

func fire_bullet(bullet_scene: PackedScene) -> void:
	var bullet_instance = bullet_scene.instantiate()
	
	bullet_instance.global_position = shoot_spawn_point.global_position
	
	bullet_instance.direction = aiming_direction
	
	bullet_instance.rotation = aiming_direction.angle()
	
	get_tree().current_scene.add_child(bullet_instance)
	
func hit_kill() -> void:
	
	if is_dead:
		return 
	is_dead = true
	velocity.y = forca_pulo_morte
	
	# 2. Zera a velocidade horizontal para ele cair reto (opcional)
	velocity.x = 0
	
	# 3. Desabilita as colisões para atravessar o chão e paredes
	# O uso do 'set_deferred' é obrigatório aqui para a Godot não dar erro na física
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	# 4. Tocar animação de morte (opcional)
	# $AnimatedSprite2D.play("morte")
	
	# 5. Reinicia a cena após um tempo (exemplo: 2 segundos)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
