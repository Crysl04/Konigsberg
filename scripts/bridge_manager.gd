extends Node2D

# Stores bridges as {"IslandA_IslandB": Line2D}
var bridges: Dictionary = {}

func create_bridges_between(island_nodes: Dictionary):
	clear_bridges()
	var island_names = island_nodes.keys()
	for i in range(island_names.size()):
		for j in range(i + 1, island_names.size()):
			if randf() < 0.5:  # 50% chance to create a bridge
				create_bridge_between(island_names[i], island_names[j], island_nodes)

func create_bridge_between(a: String, b: String, island_nodes: Dictionary) -> void:
	var start_pos = island_nodes[a].get_node("EntranceArea").global_position
	var end_pos = island_nodes[b].get_node("EntranceArea").global_position
	var line = draw_bridge(start_pos, end_pos)
	var key = get_bridge_key(a, b)
	line.name = key
	bridges[key] = line
	print("🌉 Created bridge:", key)

func draw_bridge(start_pos: Vector2, end_pos: Vector2) -> Line2D:
	var line = Line2D.new()
	add_child(line)

	line.width = 25
	line.default_color = Color(1, 1, 1)
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND

	var tex = load("res://assets/bridge_texture.png")
	if tex:
		line.texture = tex
		line.texture_mode = Line2D.LINE_TEXTURE_TILE

	line.add_point(to_local(start_pos))
	line.add_point(to_local(end_pos))
	return line

func clear_bridges():
	for child in get_children():
		child.queue_free()
	bridges.clear()

func get_bridge_key(a: String, b: String) -> String:
	var pair = [a, b]
	pair.sort()
	return "%s_%s" % [pair[0], pair[1]]

func has_bridge(a: String, b: String) -> bool:
	var key = get_bridge_key(a, b)
	return bridges.has(key)

func remove_bridge(a: String, b: String):
	var key = get_bridge_key(a, b)
	if bridges.has(key):
		var line = bridges[key]
		var tween = get_tree().create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.5)
		tween.tween_property(line, "width", 0.0, 0.5)
		tween.tween_callback(Callable(line, "queue_free"))
		bridges.erase(key)
		print("❌ Removed bridge:", key)

func has_any_bridge(island: String) -> bool:
	for key in bridges.keys():
		if island in key.split("_"):
			return true
	return false

func total_bridges_left() -> int:
	return bridges.size()

# Returns a copy of the current bridge graph {island: [connected islands]}
func get_graph_copy(island_nodes: Dictionary) -> Dictionary:
	var graph = {}
	for island_name in island_nodes.keys():
		graph[island_name] = []

	for key in bridges.keys():
		var parts = key.split("_")
		var a = parts[0]
		var b = parts[1]
		graph[a].append(b)
		graph[b].append(a)
	return graph
