extends Node2D

@export var island_name: String
signal island_clicked(island_name)

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("island_clicked", island_name)
