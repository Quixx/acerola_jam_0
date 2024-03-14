extends Node3D

@onready var room_definitions = $RoomDefinitions
@onready var rooms_parent = $NavigationRegion/Rooms
@onready var navmesh = $NavigationRegion

@export var tile_size = 12
@export var map_size = Vector2i(6, 6)
@export var goal_teleporter: PackedScene
var start_tile = 0
var end_tile = 0
var player_spawn_position = Vector3(0, 0, 0)

enum DOOR_POSITIONS {
	TOP = 1,
	BOTTOM = 2,
	LEFT = 4,
	RIGHT = 8
};

class RoomResult:
	var generated = false
	var dirty = true
	var room_index = null
	var rotation = 0
	var door_flags = 0
	var room_candidates: Array[int]

var generated_rooms: Array[RoomResult]

func generate_map():
	generated_rooms.resize(map_size.x * map_size.y)
	for i in generated_rooms.size():
		generated_rooms[i] = RoomResult.new()
	
	start_tile = get_room_index( Global.rng.randi() % map_size.x, 0 ) 
	end_tile = get_room_index(Global.rng.randi() % map_size.x, map_size.y - 1)
	
	# select starting and end room
	apply_room_generation(generated_rooms[start_tile], 0)
	apply_room_generation(generated_rooms[end_tile], 2)
	
	while true:
		for y in map_size.y:
			for x in map_size.x:
				evaluate_room_candidates(x, y)
	
		var next_randomize_rooms = []
		var possible_rooms_count = INF
		for room_index in generated_rooms.size():
			var room = generated_rooms[room_index]
			if room.generated:
				continue
			if room.room_candidates.size() > possible_rooms_count:
				continue
			if room.room_candidates.size() < possible_rooms_count:
				possible_rooms_count = room.room_candidates.size()
				next_randomize_rooms.clear()
			next_randomize_rooms.push_back(room_index)
		
		if next_randomize_rooms.is_empty():
			break
		
		var pick_tile_index = Global.rng.randi() % next_randomize_rooms.size()
		var random_tile_index = next_randomize_rooms[pick_tile_index]
		
		var room_candidates = generated_rooms[random_tile_index].room_candidates
		if room_candidates.is_empty():
			apply_room_generation(generated_rooms[random_tile_index], null)
		else:
			var pick_room_index =  Global.rng.randi() % room_candidates.size()
			var selected_room_index = room_candidates[pick_room_index]
			apply_room_generation(generated_rooms[random_tile_index], selected_room_index)
		
		
	for y in map_size.y:
		for x in map_size.x:
			var selected_room_index = get_room_result(x, y).room_index
			if selected_room_index == null:
				continue
			
			var room = room_definitions.get_child(selected_room_index).duplicate()
			
			room.position.z = -y * tile_size
			room.position.x = x * tile_size
			room.visible = true
			rooms_parent.add_child(room)
			
			var tile_index = get_room_index(x, y)
			if tile_index == end_tile:
				var goal = goal_teleporter.instantiate()
				room.add_child(goal)
			elif  tile_index == start_tile:
				player_spawn_position.x = room.position.x
				player_spawn_position.z = room.position.z
				
			
	room_definitions.queue_free()
	navmesh.bake_navigation_mesh()

func apply_room_generation(room: RoomResult, selected_index):
	room.generated = true
	room.dirty = false
	room.room_index = selected_index
	if selected_index != null:
		room.door_flags = room_definitions.get_child(selected_index).doors

func evaluate_room_candidates(x, y):
	var room_result = get_room_result(x, y)
	if room_result.generated:
		return
	# if not room_result.dirty:
		# return
	
	room_result.room_candidates.clear()
	
	for room_definition_index in room_definitions.get_children().size():
		var room_defintion = room_definitions.get_child(room_definition_index)
		if not room_defintion.isRoom:
			continue
		
		if is_room_valid(x, y, room_defintion.doors):
			room_result.room_candidates.push_back(room_definition_index)
	
	room_result.dirty = false

func is_room_valid(x, y, door_flags):
	var door_top = bool(door_flags & DOOR_POSITIONS.TOP)
	var door_right = bool(door_flags & DOOR_POSITIONS.RIGHT)
	var door_bottom = bool(door_flags & DOOR_POSITIONS.BOTTOM)
	var door_left = bool(door_flags & DOOR_POSITIONS.LEFT)
	
	if not has_room_connection(x, y + 1, door_top, DOOR_POSITIONS.BOTTOM):
		return false
	if not has_room_connection(x + 1, y, door_right, DOOR_POSITIONS.LEFT):
		return false
	if not has_room_connection(x, y - 1, door_bottom, DOOR_POSITIONS.TOP):
		return false
	if not has_room_connection(x - 1, y, door_left, DOOR_POSITIONS.RIGHT):
		return false

	if door_flags == 0:
		return true

	var searched_rooms = {}
	searched_rooms[get_room_index(x, y)] = true
	if not has_neighbour_valid_path_to(x, y, door_flags, start_tile, searched_rooms):
		return false

	searched_rooms = {}
	searched_rooms[get_room_index(x, y)] = true
	if not has_neighbour_valid_path_to(x, y, door_flags, end_tile, searched_rooms):
		return false

	return true

func has_room_connection(x, y, connection_door, required_door):
	var target_room = get_room_result(x, y)
	if not target_room:
		return !connection_door
	
	if not target_room.generated:
		return true
	
	var has_required_door = false
	
	# is empty cell
	if target_room.room_index == null:
		has_required_door = false
	else:
		has_required_door = bool(target_room.door_flags & required_door)

	return connection_door == has_required_door

func has_neighbour_valid_path_to(x, y, door_mask, target_room, searched_rooms):
	# Quick and dirty floodfill search to find a certain room
	# this can be optimized a lot for bigger level generation
	
	var door_top = bool(door_mask & DOOR_POSITIONS.TOP)
	var door_right = bool(door_mask & DOOR_POSITIONS.RIGHT)
	var door_bottom = bool(door_mask & DOOR_POSITIONS.BOTTOM)
	var door_left = bool(door_mask & DOOR_POSITIONS.LEFT)
	
	if door_right and valid_path_to(
		Vector2(x + 1, y),
		target_room,
		searched_rooms ):
		return true
	if door_bottom and valid_path_to(
		Vector2(x, y - 1),
		target_room,
		searched_rooms ):
		return true
	if door_left and valid_path_to(
		Vector2(x - 1, y),
		target_room,
		searched_rooms ):
		return true
	if door_top and valid_path_to(
		Vector2(x, y + 1),
		target_room,
		searched_rooms ):
		return true
	return false


func valid_path_to(source_position, target_room, searched_rooms):
	var room = get_room_result(source_position.x, source_position.y)
	if room == null:
		return false

	var room_index = get_room_index(source_position.x, source_position.y)
	if searched_rooms.has(room_index):
		return false

	if room_index == target_room:
		return true

	searched_rooms[room_index] = true

	var door_mask = DOOR_POSITIONS.TOP | DOOR_POSITIONS.RIGHT | DOOR_POSITIONS.BOTTOM | DOOR_POSITIONS.LEFT

	if room.generated:
		door_mask = room.door_flags
	
	return has_neighbour_valid_path_to(source_position.x, source_position.y, door_mask, target_room, searched_rooms)

func get_room_index(x, y) -> int:
	if x < 0 or y < 0:
		return -1
	if x >= map_size.x or y >= map_size.y:
		return -1
	
	return y * map_size.x + x

func get_room_result(x, y) -> RoomResult:
	var room_index = get_room_index(x, y)
	if room_index == -1:
		return null

	return generated_rooms[room_index]

