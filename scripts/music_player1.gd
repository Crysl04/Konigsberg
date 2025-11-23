extends AudioStreamPlayer

var player: AudioStreamPlayer

func _ready():
	player = get_node_or_null("AudioStreamPlayer")
	if player == null:
		push_warning("AudioStreamPlayer missing in MusicPlayer autoload scene!")
		return

	# Connect to scene change signal
	get_tree().scene_changed.connect(_on_scene_changed)

	# Run once on startup
	_on_scene_changed(get_tree().current_scene)


func _on_scene_changed(new_scene):
	if new_scene == null:
		return

	var scene_name = new_scene.name

	# play only for these scenes
	if scene_name == "main_menus1" or scene_name == "ChooseLevel":
		if not player.playing:
			player.play()
	else:
		player.stop()
