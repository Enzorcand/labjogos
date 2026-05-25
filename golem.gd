extends CharacterBody2D

# Referência ao nó de animação
@onready var sprite = $AnimatedSprite2D

# Definindo os estados possíveis
enum Estado {
	IDLE,
	SHORT_ATTACK,
	LONG_ATTACK,
	ENDURE,
	UP,
	LASER_ATTACK
}

# Estado inicial
var estado_atual = Estado.IDLE

func _physics_process(delta):
	# Lógica de movimentação, IA e gravidade entrariam aqui
	
	# Atualiza o sprite baseado no estado atual
	atualizar_animacao()

func atualizar_animacao():
	match estado_atual:
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

# Função auxiliar para ser chamada quando a IA decidir mudar o comportamento
func mudar_estado(novo_estado: int):
	if estado_atual != novo_estado:
		estado_atual = novo_estado
