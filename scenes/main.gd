extends Node2D

@export var click_tolerance: int
@export var yellow_dot_scene: PackedScene
@export var white_highlight_dot_scene: PackedScene
@export var purple_dot_scene: PackedScene
@export var player_1_move_dot_scene: PackedScene
@export var player_2_move_dot_scene: PackedScene
@onready var sfx_move: AudioStreamPlayer = $sfx_move
@onready var sfx_wrong: AudioStreamPlayer = $sfx_wrong
@onready var sfx_win: AudioStreamPlayer = $sfx_win

var grid_pos: Vector2i
var player_1_current_pos: Vector2i
var player_2_current_pos: Vector2i
var board_size: int
var cell_size: int
var cross_points: Array
var board_status: Array
var init_dots_pos_1: Array
var init_dots_pos_2: Array
var if_init_dot_selected_1: bool
var if_init_dot_selected_2: bool
var player: int
var player_1_move: Node
var player_2_move: Node
var player_1_win: bool
var player_2_win: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(get_tree())
	if_init_dot_selected_1 = false
	if_init_dot_selected_2 = false
	player = 1
	board_size = $Board.texture.get_width()
	cell_size = board_size / 10
	for i in range(0, 11):
		var row_point = Array()
		for j in range(0, 11):
			cross_points.append(Vector2i((i * cell_size) + 3, (j * cell_size) + 4))
			row_point.append(0)
		board_status.append(row_point)
	
	init_dots()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.position.x < board_size:
				if if_init_dot_selected_1 and if_init_dot_selected_2:
					for cross_point in cross_points:
						if event.position.distance_to(cross_point) <= click_tolerance:
							var target_pos = Vector2i(cross_point / cell_size)
							if is_valid_move(target_pos):
								sfx_move.play()
								if player == 1:
									update_path(player, player_1_current_pos, cross_point)
									player_1_current_pos = cross_point
									player_1_move.position = player_1_current_pos
									print("Player 1 Moves")
									if board_status[target_pos.y][target_pos.x] == 2:
										board_status[target_pos.y][target_pos.x] = 4
									else:
										board_status[target_pos.y][target_pos.x] = 1
								else:
									update_path(player, player_2_current_pos, cross_point)
									player_2_current_pos = cross_point
									player_2_move.position = player_2_current_pos
									print("Player 2 Moves")
									if board_status[target_pos.y][target_pos.x] == 3:
										board_status[target_pos.y][target_pos.x] = 5
									else:
										board_status[target_pos.y][target_pos.x] = -1
								player = -player
								for row in board_status:
									print(row)
								check_winner()
								if is_player_blocked(player):
									print("Player " + str(player) + " is blocked and skips their turn.")
									player = -player
							else:
								sfx_wrong.play()
				else:
					if player == 1:
						for init_dot in init_dots_pos_1:
							var target_dot = (init_dot / cell_size)
							if event.position.distance_to(init_dot) <= click_tolerance:
								print("Player 1 Start")
								if_init_dot_selected_1 = true
								player_1_current_pos = init_dot
								player_1_move = player_1_move_dot_scene.instantiate()
								player_1_move.position = init_dot
								add_child(player_1_move)
								board_status[target_dot.y][target_dot.x] = 4
								player = -player
					else:
						for init_dot in init_dots_pos_2:
							var target_dot = (init_dot / cell_size)
							if event.position.distance_to(init_dot) <= click_tolerance:
								print("Player 2 Start")
								if_init_dot_selected_2 = true
								player_2_current_pos = init_dot
								player_2_move = player_2_move_dot_scene.instantiate()
								player_2_move.position = init_dot
								add_child(player_2_move)
								board_status[target_dot.y][target_dot.x] = 5
								player = -player

func is_valid_move(target_pos) -> bool:
	var current_pos = Vector2i(player_1_current_pos / cell_size) if player == 1 else Vector2i(player_2_current_pos / cell_size)
	var dx = abs(target_pos.x - current_pos.x)
	var dy = abs(target_pos.y - current_pos.y)
	#print("current_pos: " + str(current_pos))
	#print("target_pos: " + str(target_pos))
	#print("dx: " + str(dx))
	#print("dy: " + str(dy))
	
	# Check if the move is horizontal or vertical and within 1-3 spaces
	if (dx == 0 and dy <= 3) or (dy == 0 and dx <= 3):
		# Check if the path is clear and doesn't cross itself or the opponent's path
		for i in range(1, max(dx, dy) + 1):
			var check_pos = Vector2i(
				current_pos.x + i * sign(target_pos.x - current_pos.x),
				current_pos.y + i * sign(target_pos.y - current_pos.y)
			)
			if board_status[check_pos.y][check_pos.x] != 0 and board_status[check_pos.y][check_pos.x] != (2 if player == 1 else 3):
				print("PATH BLOCKED")
				return false
		print("VALID")
		return true
	print("TOO FAR")
	return false

func update_path(player, start_pos, end_pos):
	var start_grid_pos = Vector2i(start_pos / cell_size)
	var end_grid_pos = Vector2i(end_pos / cell_size)
	var dx = end_grid_pos.x - start_grid_pos.x
	var dy = end_grid_pos.y - start_grid_pos.y
	var steps = max(abs(dx), abs(dy))
	# Update only the cells between the start and end positions
	for i in range(1, steps):  # Start from 1 to exclude the start cell
		var x = start_grid_pos.x + i * sign(dx)
		var y = start_grid_pos.y + i * sign(dy)
		board_status[y][x] = 1 if player == 1 else -1
	draw_connect_line(player, start_pos, end_pos)

func is_player_blocked(player) -> bool:
	var current_pos = Vector2i(player_1_current_pos / cell_size) if player == 1 else Vector2i(player_2_current_pos / cell_size)
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for dir in directions:
		var new_pos = current_pos + dir
		if new_pos.x >= 0 and new_pos.x < 11 and new_pos.y >= 0 and new_pos.y < 11:
			if board_status[new_pos.y][new_pos.x] == 0 or board_status[new_pos.y][new_pos.x] == (2 if player == 1 else 3):
				return false
	return true

func check_winner():
	var p1_count = 0
	var p2_count = 0
	for row in board_status:
		for cell in row:
			if cell == 4:
				p1_count += 1
			elif cell == 5:
				p2_count += 1
		if p1_count == 3:
			print("Player 1 Wins!")
			call_deferred("change_scene", "res://scenes/yellowWin.tscn") 
		if p2_count == 3:
			print("Player 2 Wins!")
			call_deferred("change_scene", "res://scenes/purpleWin.tscn") 

func create_dot(player, position):
	if player == 1:
		var new_dot = yellow_dot_scene.instantiate()
		new_dot.position = position
		add_child(new_dot)
	else:
		var new_dot = purple_dot_scene.instantiate()
		new_dot.position = position
		add_child(new_dot)

func change_scene(scene_path: String):
	if get_tree():
		get_tree().change_scene_to_file(scene_path)
		
func init_dots(): #make sure that points don't form on the border
	var player = 1
	for i in range(6):
		var valid_position_found = false
		while not valid_position_found:
			var random_x = randi_range(1, 9)
			var random_y = randi_range(1, 9)
			var board_point_pos = Vector2i(random_x, random_y)
			var world_pos = Vector2i((random_x * cell_size) + 3, (random_y * cell_size) + 4)
			if board_status[board_point_pos.y][board_point_pos.x] == 0:
				print(board_point_pos)
				create_dot(player, world_pos)
				if player == 1:
					board_status[board_point_pos.y][board_point_pos.x] = 2
					init_dots_pos_1.append(world_pos)
				else:
					board_status[board_point_pos.y][board_point_pos.x] = 3
					init_dots_pos_2.append(world_pos)
				player = -player
				valid_position_found = true

func draw_connect_line(player, start_pos, end_pos):
	var new_line = Line2D.new()
	if player == 1:
		new_line.default_color = Color("Yellow")
	else:
		new_line.default_color = Color("Purple")
	new_line.width = 3
	new_line.add_point(start_pos)
	new_line.add_point(end_pos)
	add_child(new_line)
