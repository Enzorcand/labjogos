extends CanvasLayer

@onready var titulo_label: Label = $CenterContainer/VBoxContainer/TituloLabel
@onready var btn_reiniciar: Button = $CenterContainer/VBoxContainer/BtnReiniciar
@onready var btn_menu: Button = $CenterContainer/VBoxContainer/BtnMenu

func _ready() -> void:
	# Conecta os sinais dos botões via código de forma segura
	btn_reiniciar.pressed.connect(_on_btn_reiniciar_pressed)
	btn_menu.pressed.connect(_on_btn_menu_pressed)

# Função chamada para configurar se o jogador ganhou ou perdeu
func configurar_tela(vitoria: bool) -> void:
	if vitoria:
		titulo_label.text = "VITÓRIA!\nO Golem foi destruído!"
		titulo_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		titulo_label.text = "GAME OVER\nVocê foi derrotado!"
		titulo_label.add_theme_color_override("font_color", Color.RED)

func _on_btn_reiniciar_pressed() -> void:
	get_tree().paused = false # Despausa o jogo caso tenhas pausado
	get_tree().reload_current_scene() # Reinicia a fase

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	# Certifica-te de que o caminho para o teu menu está correto aqui:
	get_tree().change_scene_to_file("res://menu.tscn")
