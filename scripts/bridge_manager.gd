extends Node2D

# Stores all active bridges using a unique key format: "IslandA_IslandB"
# Value is the Line2D node representing the bridge
var bridges: Dictionary = {}


# BRIDGE GENERATION

func create_bridges_between(island_nodes: Dictionary):
	# Remove existing bridges before generating new ones
	clear_bridges()

	# Get list of island names
	var island_names = island_nodes.keys()

	# Create random bridges between island pairs
	for i in range(island_names.size()):
		for j in range(i + 1, island_names.size()):
			# 50% chance to create a bridge between two islands
			if randf() < 0.5:
				create_bridge_between(island_names[i], island_names[j], island_nodes)


func create_bridge_between(a: String, b: String, island_nodes: Dictionary) -> void:
	# Get entrance positions of both islands
	var start_pos = island_nodes[a].get_node("EntranceArea").global_position
	var end_pos = island_nodes[b].get_node("EntranceArea").global_position

	# Draw the bridge visually using Line2D
	var line = draw_bridge(start_pos, end_pos)

	# Generate a unique key for the bridge (order-independent)
	var key = get_bridge_key(a, b)

	# Assign name and store bridge reference
	line.name = key
	bridges[key] = line

	print("🌉 Created bridge:", key)


# VISUAL BRIDGE DRAWING

func draw_bridge(start_pos: Vector2, end_pos: Vector2) -> Line2D:
	# Create a Line2D node to represent the bridge
	var line = Line2D.new()
	add_child(line)

	# Visual properties of the bridge
	line.width = 25
	line.default_color = Color(1, 1, 1)
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Apply bridge texture if available
	var tex = load("res://assets/bridge_texture.png")
	if tex:
		line.texture = tex
		line.texture_mode = Line2D.LINE_TEXTURE_TILE

	# Draw bridge between island entrances
	line.add_point(to_local(start_pos))
	line.add_point(to_local(end_pos))

	return line

# BRIDGE MANAGEMENT

func clear_bridges():
	# Remove all bridge nodes from the scene
	for child in get_children():
		child.queue_free()

	# Clear bridge dictionary
	bridges.clear()


func get_bridge_key(a: String, b: String) -> String:
	# Sort island names so "A_B" and "B_A" are treated as the same bridge
	var pair = [a, b]
	pair.sort()
	return "%s_%s" % [pair[0], pair[1]]


func has_bridge(a: String, b: String) -> bool:
	# Check if a bridge exists between two islands
	var key = get_bridge_key(a, b)
	return bridges.has(key)


func remove_bridge(a: String, b: String):
	# Remove a bridge after the player uses it
	var key = get_bridge_key(a, b)

	if bridges.has(key):
		var line = bridges[key]

		# Animate bridge disappearance
		var tween = get_tree().create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.5)
		tween.tween_property(line, "width", 0.0, 0.5)
		tween.tween_callback(Callable(line, "queue_free"))

		# Remove bridge from dictionary so it can't be reused
		bridges.erase(key)

		print("❌ Removed bridge:", key)


func has_any_bridge(island: String) -> bool:
	# Checks if an island still has at least one connected bridge
	for key in bridges.keys():
		if island in key.split("_"):
			return true
	return false


func total_bridges_left() -> int:
	# Returns number of remaining bridges (used for win condition)
	return bridges.size()


# GRAPH REPRESENTATION

# Converts bridges into an adjacency list graph
# Format: { "IslandA": ["IslandB", "IslandC"], ... }
func get_graph_copy(island_nodes: Dictionary) -> Dictionary:
	var graph = {}

	# Initialize empty neighbor list for each island
	for island_name in island_nodes.keys():
		graph[island_name] = []

	# Add connections based on existing bridges
	for key in bridges.keys():
		var parts = key.split("_")
		var a = parts[0]
		var b = parts[1]

		# Undirected graph: add both directions
		graph[a].append(b)
		graph[b].append(a)

	return graph
