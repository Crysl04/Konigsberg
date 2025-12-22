extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_easy_pressed():
	get_tree().change_scene_to_file("res://scenes/EasyGame.tscn")

func _on_medium_pressed():
	get_tree().change_scene_to_file("res://scenes/MediumGame.tscn")

func _on_hard_pressed():
	get_tree().change_scene_to_file("res://scenes/HardGame.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menus1.tscn")
