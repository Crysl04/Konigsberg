extends Area2D

signal island_clicked(island_name: String)

func _ready():
	input_pickable = true  # So it can detect clicks

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("island_clicked", get_parent().name)
