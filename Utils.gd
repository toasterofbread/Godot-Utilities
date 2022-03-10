# Singleton containing various utility functions
extends Node

# Path of Godot-Utilities folder
var utils_path: String = get_script().resource_path.get_base_dir()

var RNG: RandomNumberGenerator = RandomNumberGenerator.new() setget set_RNG, get_RNG
var anchor: Node = null setget set_anchor, get_anchor
var canvaslayer: CanvasLayer = null setget set_canvaslayer, get_canvaslayer

# Returns the RNG object (a RandomNumberGenerator created and randomised on init).
func get_RNG() -> RandomNumberGenerator:
	return RNG

# Returns the anchor node (an Node added to the Utils singleton on ready).
func get_anchor() -> Node:
	if anchor == null:
		assert(is_inside_tree())
		anchor = Node.new()
		add_child(anchor)
	return anchor

func get_canvaslayer() -> CanvasLayer:
	if canvaslayer == null:
		assert(is_inside_tree())
		canvaslayer = CanvasLayer.new()
		add_child(canvaslayer)
	return canvaslayer

# Creates a new node with the passed type, adds it to the anchor, and returns it
func get_unique_anchor(type = Node) -> Node:
	var ret: Node = type.new()
	anchor.add_child(ret)
	return ret

# Prints [items] in a single line with dividers.
# If [tprint] is true, prints using the tprint function.
func sprint(items: Array, tprint: bool = false, divider: String = " | "):
	var msg: String = ""
	
	for i in len(items):
		msg += str(items[i])
		if i + 1 != len(items):
			msg += divider
	
	if tprint:
		tprint(msg)
	else:
		print(msg)

# Prints [msg] prepended with the current engine time (OS.get_ticks_msec()). Useful for printing every frame.
func tprint(msg):
	print(OS.get_ticks_msec(), ": ", msg)

# Returns a random item from [array] using [rng]. If [weights] is passed, the item is selected according to those weights.
func random_array_item(array: Array, weights: PoolRealArray = null, rng: RandomNumberGenerator = get_RNG()):
	
	if weights != null and not weights.empty():
		
		var total: float = 0.0
		for i in array.size():
			if i < weights.size():
				assert(weights[i] >= 0.0)
				total += weights[i]
			else:
				total += 1
		
		var target: float = rng.randf_range(0.0, total)
		total = 0.0
		var i: int = 0
		for weight in weights:
			total += weight
			if total >= target:
				return array[i]
			i += 1
		
		assert(false)
	
	return array[rng.randi() % len(array)]

# Returns a random colour.
# Individual values can be overridden using [r], [g], [b], and [a].
func random_colour(r: float = NAN, g: float = NAN, b: float = NAN, a: float = NAN, rng: RandomNumberGenerator = get_RNG()) -> Color:
	var ret: Color = Color(rng.randf(), rng.randf(), rng.randf())
	for property in ["r", "g", "b", "a"]:
		if not is_nan(get(property)):
			ret[property] = get(property)
	return ret

# Removes [node] from its parent, then adds it to  [new_parent].
# If [retain_global_position] is true, the global_position of [node] will be maintained.
func reparent_node(node: Node, new_parent: Node, retain_global_position: bool = false):
	var original_global_position
	if retain_global_position:
		original_global_position = get_node_position(node, true)
	
	var old_parent: Node = node.get_parent()
	if is_instance_valid(old_parent):
		old_parent.remove_child(node)
	new_parent.add_child(node)
	
	if retain_global_position:
		set_node_position(node, original_global_position, true)

# Returns the position of [position_of] relative to [relative_to].
# Equivalent to Node2D.to_local(), but also works for Control and Spatial nodes.
func to_local(position_of: Node, relative_to: Node) -> Vector2:
	return get_node_position(position_of, true) - get_node_position(relative_to, true)

# Returns the local or [global] position of [node].
# [node] must be a Node2D, Control, or Spatial.
func get_node_position(node: Node, global: bool = false) -> Vector2:
	if node is Node2D:
		return node.global_position if global else node.position
	elif node is Control:
		return node.rect_global_position if global else node.rect_position
	elif node is Spatial:
		return node.global_transform if global else node.transform
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D or Control")
		return Vector2.ZERO

# Sets the local or [global] position of the [node].
# [node] must be a Node2D, Control, or Spatial.
func set_node_position(node: Node, position, global: bool = false):
	if node is Node2D:
		node.set("global_position" if global else "position", position)
	elif node is Control:
		node.set("rect_global_position" if global else "rect_position", position)
	elif node is Spatial:
		node.set("global_transform" if global else "transform", position)
	else:
		push_error("Node '" + str(node) + "' isn't a Node2D or Control")

# Returns the global modulation of [node] (the product of the modulations of the node and all its ancestors).
# In other words, returns the actual modulation applied to the node when rendered.
func get_global_modulate(node: CanvasItem) -> Color:
	var ret: Color = node.modulate
	var root: Viewport = get_tree().root
	
	var parent: Node = node.get_parent()
	while true:
		if parent is CanvasItem:
			ret *= parent.modulate
		parent = parent.get_parent()
		
		if not is_instance_valid(parent) or parent == root:
			break
	
	return ret

# Appends [append] onto [base] (values will be overwritten).
# If [duplicate_values] is true, values that are an array or dictionary will be duplicated.
func append_dictionary(base: Dictionary, append: Dictionary, duplicate_values: bool = false):
	for key in append:
		var value = append[key]
		if duplicate_values and (value is Array or value is Dictionary):
			value = value.duplicate()
		base[key] = value

# Returns [text] as a BBCode formatted string with the passed [colour].
func bbcode_colour_text(text: String, colour: Color) -> String:
	return "[color=#" + colour.to_html() + "]" + text + "[/color]"

# Returns the line number of [position] within [string].
func get_line_of_position(string: String, position: int) -> int:
	
	if position == 0:
		return 0
	elif position >= len(string) or position < 0:
		push_error("Position is outside of passed string bounds")
		return -1
	
	var line: int = 0
	for i in position:
		if string[i] == "\n":
			line += 1
	return line

# Returns the position of [line] within [string].
func get_position_of_line(string: String, line: int) -> int:
	if line == 0:
		return 0
	elif line > 0:
		var current_line: int = 0
		for i in len(string):
			if string[i] == "\n":
				current_line += 1
				if current_line == line:
					return i + 1
	
	push_error("Line is outside of passed string bounds")
	return -1

# Returns the items contained in [directory] as an array. May return an int error.
func get_dir_items(directory, skip_navigational: bool = true, skip_hidden: bool = true):
	assert(directory is String or directory is Directory, "[directory] must be a String or Directory")
	
	if directory is String:
		var path: String = directory
		directory = Directory.new()
		var error: int = directory.open(path)
		if error != OK:
			return error
	
	var ret: Array = []
	directory.list_dir_begin(skip_navigational, skip_hidden)
	var file_name = directory.get_next()
	while file_name != "":
		ret.append(file_name)
		file_name = directory.get_next()
	return ret

# Loads file at [path], parses its contents as JSON, and returns the result.
func load_json(path: String) -> JSONParseResult:
	var f = File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data)

# Writes a file at [path] with [data] in JSON format. If [pretty] is true, indentation is added to the file.
func save_json(path: String, data, pretty: bool = false):
	var f = File.new()
	var error: int = f.open(path, File.WRITE)
	if error != OK:
		push_error("Error saving json file '" + path + "': " + str(error))
		return
	f.store_string(JSON.print(data, "\t" if pretty else ""))
	f.close()

# Yields until [emitter] has stopped emitting, and has no remaining particles. [emitter] must be of type Particles, Particles2D, CPUParticles, or CPUParticles2D.
func yield_particle_completion(emitter: Node):
	assert(emitter is Particles or emitter is Particles2D or emitter is CPUParticles or emitter is CPUParticles2D)
	
	while emitter.emitting:
		while emitter.emitting:
			yield(get_tree(), "idle_frame")
		
		yield(get_tree().create_timer(emitter.lifetime / emitter.speed_scale), "timeout")

enum DIR2DICT_MODES {NESTED, SINGLE_LAYER_DIR, SINGLE_LAYER_FILE}
func dir2dict(path: String, mode: int = DIR2DICT_MODES.NESTED, allowed_files = null, allowed_extensions = null, top_path: String = ""):
	var ret: Dictionary = {}
	var data: Dictionary = ret
	if top_path == "":
		top_path = path
	
	var dir: Directory = Directory.new()
	
	var error: int = dir.open(path)
	if error != OK:
		return error
	
	for file in get_dir_items(dir):
		if dir.dir_exists(file):
			if mode == DIR2DICT_MODES.NESTED:
				data[file] = dir2dict(path + file + "/", mode, allowed_files, allowed_extensions, top_path)
			else:
				var layer_data: Dictionary = dir2dict(path + file + "/", mode, allowed_files, allowed_extensions, top_path)
				for key in layer_data:
					data[key] = layer_data[key]
		else:
			file = file.trim_suffix(".import")
			if (allowed_files == null or file in allowed_files) and (allowed_extensions == null or file.split(".")[1] in allowed_extensions):
				var key: String
				match mode:
					DIR2DICT_MODES.NESTED: key = file.split(".")[0]
					DIR2DICT_MODES.SINGLE_LAYER_DIR: key = path.trim_prefix(top_path)
					DIR2DICT_MODES.SINGLE_LAYER_FILE: key = path.trim_prefix(top_path) + file.split(".")[0]
				data[key.trim_suffix("/")] = path + file
	
	return ret

# Yields [signal_name] of [object] and returns the resulting value. If [return_value_container] is passed, the result value will be appended onto it. Useful for executing code while waiting for the signal.
func remote_yield(object: Object, signal_name: String, return_value_container: Array = null):
	var ret = yield(object, signal_name)
	if return_value_container:
		return_value_container.append(ret)
	return ret

func node_has_parent(node: Node) -> bool:
	return is_instance_valid(node.get_parent())

func get_tilemap_tile_sprite(tilemap: TileMap, tile_position: Vector2, use_world_position: bool = true, use_sprite: Sprite = null) -> Sprite:
	if use_world_position:
		tile_position = tilemap.world_to_map(tilemap.to_local(tile_position))
	
	assert(tilemap.get_cellv(tile_position) != TileMap.INVALID_CELL)
	
	var sprite: Sprite = Sprite.new() if use_sprite == null else use_sprite
	sprite.region_enabled = true
	
	var tile: int = tilemap.get_cellv(tile_position)
	var tileset: TileSet = tilemap.tile_set
	
	sprite.texture = tileset.tile_get_texture(tile)
	
	if tilemap.is_cellv_autotile(tile_position):
		sprite.region_rect = Rect2(tilemap.get_cellv_autotile_coord(tile_position) * (tileset.autotile_get_size(tile) + Vector2.ONE * tileset.autotile_get_spacing(tile)), tileset.autotile_get_size(tile))
	else:
		sprite.region_rect = tileset.tile_get_region(tile)
	
	return sprite

func array_append(array: Array, append_value):
	array.append(append_value)

func yield_funcitons(functions: Array):
	
	var running_functions: ExArray = ExArray.new()
	for function in functions:
		if function is GDScriptFunctionState and function.is_valid():
			running_functions.append(function)
			function.connect("completed", running_functions, "erase", [function])
	
	while not running_functions.empty():
		yield(running_functions, "items_removed")

class Callback extends Reference:
	var callback: FuncRef
	var binds: Array
	var standalone: bool
	
	var attached_node: Node = null setget attach_to_node
	const ATTACHED_NODE_META_NAME: String = "CONNECTED_CALLBACKS"
	
	func _init(callback: FuncRef, binds: Array = [], standalone: bool = false):
		self.callback = callback
		self.binds = binds
		self.standalone = standalone
	
	func attach_to_node(node: Node) -> Callback:
		if node == attached_node:
			return self
		
		# Detach from previous node
		if attached_node != null and is_instance_valid(attached_node) and attached_node.has_meta(ATTACHED_NODE_META_NAME):
			attached_node.get_meta(ATTACHED_NODE_META_NAME).erase(self)
		
		attached_node = node
		
		# Attach to new node
		if attached_node != null:
			assert(is_instance_valid(attached_node), "Node must be a valid instance")
			if attached_node.has_meta(ATTACHED_NODE_META_NAME):
				attached_node.get_meta(ATTACHED_NODE_META_NAME).append(self)
			else:
				attached_node.set_meta(ATTACHED_NODE_META_NAME, [self])
		
		return self
	
	func detach_from_node():
		attach_to_node(null)
	
	func connect_signal(signal_object: Object, signal_name: String, auto_attach: bool = false) -> Callback:
		if not is_signal_connected(signal_object, signal_name):
			signal_object.connect(signal_name, self, CALLBACK_METHOD)
		
		if auto_attach:
			assert(signal_object is Node, "Cannot attach to a non-node object")
			attach_to_node(signal_object)
		
		return self
	
	func disconnect_signal(signal_object: Object, signal_name: String) -> Callback:
		if is_signal_connected(signal_object, signal_name):
			signal_object.disconnect(signal_name, self, CALLBACK_METHOD)
		return self
	
	func is_signal_connected(signal_object: Object, signal_name: String) -> bool:
		return signal_object.is_connected(signal_name, self, CALLBACK_METHOD)
	
	func _notification(what: int):
		if what == NOTIFICATION_PREDELETE and attached_node == null and not standalone:
			push_error("Callback was freed prematurely")
	
	const CALLBACK_METHOD: String = "call_callback"
	func call_callback(_a=0, _b=0, _c=0, _d=0, _e=0, _f=0, _g=0, _h=0, _i=0, _j=0):
		callback.call_funcv(binds)

# ------------------------------

func _init():
	RNG.randomize()

# Deleted function
func set_RNG(_value: RandomNumberGenerator):
	return

# Deleted function
func set_anchor(_value: Node):
	return

# Deleted function
func set_canvaslayer(_value: CanvasLayer):
	return
