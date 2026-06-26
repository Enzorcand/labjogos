extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for buttons in get_tree().get_nodes_in_group("buttons"):
		#buttons.connect("pressed", self, "on_button_pressed", [buttons])
		#buttons.connect("mouse_exited", self, "mouse_interaction", [buttons, "exited"])
		#buttons.connect("mouse_entered", self, "mouse_interaction", [buttons, "entered"])
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_iniciar_jogo_pressed() -> void:
	var _game: bool = get_tree().change_scene_to_file("res://level_1.tscn")


func _on_controles_pressed() -> void:
	var _controls: bool = get_tree().change_scene_to_file("res://Controles.tscn")


func _on_sair_pressed() -> void:
	get_tree().quit()
