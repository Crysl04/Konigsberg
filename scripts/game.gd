extends Node2D

# Nodes
@onready var islands_parent = $Islands
@onready var bridge_manager = $BridgeManager
@onready var player = $Player

# Buttons
@onready var hint_button = $UI/HintPopupMenu/Control/VBoxContainer/HintButton
@onready var auto_solve_button = $UI/HintPopupMenu/Control/VBoxContainer/AutoSolveButton
@onready var check_button =$UI/HintPopupMenu/Control/VBoxContainer/CheckButton

# Popups
@onready var settings_popup_menu = $UI/SettingsPopupMenu
@onready var hint_popup_menu = $UI/HintPopupMenu
@onready var gameover_popup = $UI/GameOverPopup
@onready var gamecomplete_popup = $UI/GameCompletePopup
@onready var message_popup = $UI/MessagePopup
# Labels
@onready var message_popup_label = $UI/MessagePopup/Label


# Variables
var island_nodes = {}
var current_island: String
var moving := false

# Store original puzzle state for restart
var original_start_island: String
var original_bridges: Array = []

# Hint Dictionaries
var hint_messages_easy := {
	"IslandA": "Move to the Forest Island",
	"IslandB": "Move to the Snowy Island",
	"IslandC": "Move to the Volcanic Island",
	"IslandD": "Move to the Deserted Island"
}

var hint_messages_medium := {
	"IslandA": "Move to the Top Forest Island",
	"IslandB": "Move to the Top Snowy Island",
	"IslandC": "Move to the Volcanic Island",
	"IslandD": "Move to the Deserted Island",
	"IslandE": "Move to the Bottom Forest Island",
	"IslandF": "Move to the Bottom Snowy Island"
}

var hint_messages_hard := {
	"IslandA": "Move to the Bottom Forest Island",
	"IslandB": "Move to the Bottom Snowy Island",
	"IslandC": "Move to the Left Volcanic Island",
	"IslandD": "Move to the Bottom Deserted Island",
	"IslandE": "Move to the Top Forest Island",
	"IslandF": "Move to the Top Snowy Island",
	"IslandG": "Move to the Right Volcanic Island",
	"IslandH": "Move to the Top Deserted Island"
}

# Current difficulty: "easy", "medium", or "hard"
var current_difficulty := "easy"

# Ready
func _ready():
	
	# Detect difficulty from current scene name
	var scene_path = get_tree().current_scene.scene_file_path

	if scene_path.find("Easy") != -1:
		current_difficulty = "easy"
	elif scene_path.find("Medium") != -1:
		current_difficulty = "medium"
	elif scene_path.find("Hard") != -1:
		current_difficulty = "hard"
	else:
		current_difficulty = "easy" 

	print("📌 Difficulty set to:", current_difficulty)

	# Store islands by name
	for island in islands_parent.get_children():
		island_nodes[island.name] = island
		var entrance = island.get_node_or_null("EntranceArea")
		if entrance:
			entrance.island_clicked.connect(Callable(self, "_on_island_clicked"))

	# Create bridges
	bridge_manager.create_bridges_between(island_nodes)

	# Pick a random starting island
	randomize()

	var max_attempts := 100
	var attempts := 0

	while attempts < max_attempts:
		bridge_manager.clear_bridges()
		bridge_manager.create_bridges_between(island_nodes)

		current_island = island_nodes.keys().pick_random()

		if is_puzzle_solvable():
			break

		attempts += 1

	if attempts >= max_attempts:
		push_error("❌ Failed to generate a solvable puzzle!")
		return

	player.global_position = island_nodes[current_island].get_node("EntranceArea").global_position
	print("🎮 Solvable puzzle generated. Start island:", current_island)


	# Store original state
	original_start_island = current_island
	original_bridges = []
	for key in bridge_manager.bridges.keys():
		original_bridges.append(key)

	# GameOver
	var new_game_btn = gameover_popup.get_node("Control/NewGame")
	var quit_btn = gameover_popup.get_node("Control/Quit")
	if new_game_btn:
		new_game_btn.pressed.connect(Callable(self, "_on_new_game_pressed"))
	if quit_btn:
		quit_btn.pressed.connect(Callable(self, "_on_quit_pressed"))

	# GameComplete
	var next_level_btn = gamecomplete_popup.get_node("GameCompleteControl/Next")
	var quit_btn_win = gamecomplete_popup.get_node("GameCompleteControl/Quit")
	if next_level_btn:
		next_level_btn.pressed.connect(Callable(self, "_on_next_pressed"))
	if quit_btn_win:
		quit_btn_win.pressed.connect(Callable(self, "_on_quit_pressed"))

	# Connect buttons
	if hint_button:
		hint_button.pressed.connect(Callable(self, "_on_hint_pressed"))
	if auto_solve_button:
		auto_solve_button.pressed.connect(Callable(self, "_on_auto_solve_pressed"))

# Player Movement
func _on_island_clicked(target_island: String) -> void:
	if moving:
		SoundEffects.ui_sfx_play("wrong_move")

		return
	if target_island == current_island:
		SoundEffects.ui_sfx_play("wrong_move")

		return
	if not bridge_manager.has_bridge(current_island, target_island):
		print("⛔ No valid bridge from %s to %s" % [current_island, target_island])

		# Shake the island the player clicked
		if island_nodes.has(target_island):
			shake_island(island_nodes[target_island])
			
			SoundEffects.ui_sfx_play("wrong_move")

		return
	await move_to_island(target_island)
	

func move_to_island(target_island: String) -> void:
	moving = true
	
	var target_pos = island_nodes[target_island].get_node("EntranceArea").global_position
	SoundEffects.ui_sfx_play("correct")

	print("🚶 Moving from %s to %s" % [current_island, target_island])

	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# Update bridges and current island
	moving = false
	bridge_manager.remove_bridge(current_island, target_island)
	current_island = target_island
	print("🏝️ Arrived at:", current_island)

	check_game_state()

# Game State
func check_game_state() -> void:
	if bridge_manager.total_bridges_left() == 0:
		gamecomplete_popup.popup_centered()
		SoundEffects.ui_sfx_play("game_complete")

	elif not bridge_manager.has_any_bridge(current_island):
		gameover_popup.popup_centered()
		SoundEffects.ui_sfx_play("game_over")


# Messages
func show_message(text: String, duration: float = 2.5) -> void:
	message_popup_label.text = text
	message_popup.popup_centered()

	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	add_child(timer)
	timer.start()

	await timer.timeout
	message_popup.hide()
	timer.queue_free()

func _on_hint_pressed() -> void:
	var graph_copy = bridge_manager.get_graph_copy(island_nodes)
	var solution = get_eulerian_path(graph_copy, current_island)

	if solution.size() <= 1:
		show_message("💡 No moves available!")
		hint_popup_menu.hide()
		return

	var next_island = solution[1]

	# Pick dictionary based on difficulty
	var dict
	if current_difficulty == "easy":
		dict = hint_messages_easy
	elif current_difficulty == "medium":
		dict = hint_messages_medium
	else:
		dict = hint_messages_hard

	# Get the message
	var msg = dict.get(next_island, "Move to " + next_island)

	show_message("💡 " + msg)
	hint_popup_menu.hide()

func _on_auto_solve_pressed() -> void:
	var solution = get_eulerian_path({}, current_island)
	await animate_solution(solution)
	hint_popup_menu.hide()

# Eulerian Logic
func is_puzzle_solvable() -> bool:
	var graph = bridge_manager.get_graph_copy(island_nodes)
		
	var odd_nodes = []
	for island in graph.keys():
		if graph[island].size() % 2 != 0:
			odd_nodes.append(island)
	if odd_nodes.size() != 0 and odd_nodes.size() != 2:
		return false
	if odd_nodes.size() == 2 and not odd_nodes.has(current_island):
		return false
		
	var visited = {}
	for island in graph.keys():
		if graph[island].size() > 0:
			dfs(island, graph, visited)
			break
	for island in graph.keys():
		if graph[island].size() > 0 and not visited.has(island):
			return false
			
	var total_edges = 0
	for island in graph.keys():
		total_edges += graph[island].size()
	total_edges /= 2  # each edge counted twice
	if total_edges == 0:
		return false
		
	return true

#Checks connectivity between islands
func dfs(node: String, graph: Dictionary, visited: Dictionary) -> void:
	visited[node] = true
	for neighbor in graph[node]:
		if not visited.has(neighbor):
			dfs(neighbor, graph, visited)

func shake_island(island: Node, intensity := 10.0, duration := 0.15):
	var tween = create_tween()
	var original_pos = island.position

	tween.tween_property(
		island, "position",
		original_pos + Vector2(intensity, 0),
		duration * 0.25
	)
	tween.tween_property(
		island, "position",
		original_pos - Vector2(intensity, 0),
		duration * 0.5
	)
	tween.tween_property(
		island, "position",
		original_pos,
		duration * 0.25
	)

# Returns the optimal path for the puzzle. Used for Hints and Auto-Solver
func get_eulerian_path(graph_param: Dictionary = {}, start_island: String = "") -> Array:
	var graph = {}
	if graph_param.size() == 0:
		graph = bridge_manager.get_graph_copy(island_nodes)
	else:
		for key in graph_param.keys():
			graph[key] = graph_param[key].duplicate()

	var start = start_island if start_island != "" else current_island
	var path = []
	var stack = [start]

	while stack.size() > 0:
		var v = stack[-1] # returns the top element of stack
		if graph[v].size() > 0:
			var u = graph[v].pop_front()
			graph[u].erase(v) 
			stack.append(u)
		else:
			path.append(stack.pop_back()) # appends the Island at the path array and removes it in the stack array
	path.reverse()
	return path

func animate_solution(path: Array) -> void:
	if path.size() < 2:
		return
	for i in range(path.size() - 1):
		await move_to_island(path[i + 1])
	print("✅ Solution animation complete!")

# UI BUTTONS
func _on_setting_button_pressed():
	settings_popup_menu.popup_centered()

func _on_hint_icon_pressed():
	hint_popup_menu.popup_centered()

# Setting Popup buttons
func _on_restart_pressed():
	# Clear existing bridges
	bridge_manager.clear_bridges()

	# Restore original bridges
	for key in original_bridges:
		var parts = key.split("_")
		bridge_manager.create_bridge_between(parts[0], parts[1], island_nodes)

	# Reset player position
	current_island = original_start_island
	player.global_position = island_nodes[current_island].get_node("EntranceArea").global_position
	moving = false

	settings_popup_menu.hide()


	print("🔄 Puzzle restarted!")

func _on_new_game_pressed():	
	var current_scene_path = get_tree().current_scene.scene_file_path
	var next_scene_path = ""
	match current_scene_path:
		"res://scenes/EasyGame.tscn":
			next_scene_path = "res://scenes/EasyGame.tscn"
		"res://scenes/MediumGame.tscn":
			next_scene_path = "res://scenes/MediumGame.tscn"
		"res://scenes/HardGame.tscn":
			next_scene_path = "res://scenes/HardGame.tscn"
		_:
			print("Unknown scene: cannot determine next difficulty")
			return
	get_tree().change_scene_to_file(next_scene_path)
	
	settings_popup_menu.hide()


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menus1.tscn")
	settings_popup_menu.hide()
