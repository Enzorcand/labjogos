extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
