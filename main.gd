extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_death_zone_body_entered() -> void:
	print("Player Morreu")
	get_tree().change_scene_to_file("res://game_over.tscn")
	pass # Replace with function body.
