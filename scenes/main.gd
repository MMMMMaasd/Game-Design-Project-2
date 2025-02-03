extends Node2D

@export var click_tolerance: int
@export var yellow_dot_scene: PackedScene
@export var white_highlight_dot_scene: PackedScene
@export var purple_dot_scene: PackedScene
@export var player_1_move_dot_scene: PackedScene
@export var player_2_move_dot_scene: PackedScene
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
var remaining_moves: int  # Tracks remaining moves for the current player
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if_init_dot_selected_1 = false
	if_init_dot_selected_2 = false
	player = 1
	remaining_moves = 0
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
								remaining_moves -= 1
								if player == 1:
									draw_connect_line(player, player_1_current_pos, cross_point)
									player_1_current_pos = cross_point
									player_1_move.position = player_1_current_pos
									print("Player 1 Moves - Moves remaining: " + str(remaining_moves))
									if board_status[target_pos.y][target_pos.x] == 2:
										board_status[target_pos.y][target_pos.x] = 4
									else:
										board_status[target_pos.y][target_pos.x] = player
								else:
									draw_connect_line(player, player_2_current_pos, cross_point)
									player_2_current_pos = cross_point
									player_2_move.position = player_2_current_pos
									print("Player 2 Moves - Moves remaining: " + str(remaining_moves))
									if board_status[target_pos.y][target_pos.x] == 3:
										board_status[target_pos.y][target_pos.x] = 5
									else:
										board_status[target_pos.y][target_pos.x] = player
								if remaining_moves == 0:
									switch_turn()
								for row in board_status:
									print(row)
							check_winner()
				else:
					if player == 1:
						for init_dot in init_dots_pos_1:
							var target_dot = (init_dot / cell_size)
							if event.position.distance_to(init_dot) <= click_tolerance:
								print("Player 1 Start")
								player_1_current_pos = init_dot
								player_1_move = player_1_move_dot_scene.instantiate()
								player_1_move.position = init_dot
								add_child(player_1_move)
								board_status[target_dot.y][target_dot.x] = 4
								switch_turn()
								if_init_dot_selected_1 = true
					else:
						for init_dot in init_dots_pos_2:
							var target_dot = (init_dot / cell_size)
							if event.position.distance_to(init_dot) <= click_tolerance:
								print("Player 2 Start")
								player_2_current_pos = init_dot
								player_2_move = player_2_move_dot_scene.instantiate()
								player_2_move.position = init_dot
								add_child(player_2_move)
								board_status[target_dot.y][target_dot.x] = 5
								switch_turn()
								if_init_dot_selected_2 = true

func is_valid_move(target_pos) -> bool:
	var current_pos = Vector2i(player_1_current_pos / cell_size) if player == 1 else Vector2i(player_2_current_pos / cell_size)
	var dx = abs(target_pos.x - current_pos.x)
	var dy = abs(target_pos.y - current_pos.y)
	
	# Check if the move is to an adjacent cell (up, down, left, or right)
	if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
		# Check if the target cell is empty or the player's dot
		if board_status[target_pos.y][target_pos.x] == 0 or board_status[target_pos.y][target_pos.x] == (2 if player == 1 else 3):
			print("VALID")
			return true
		else:
			print("PATH BLOCKED")
			return false
	print("TOO FAR")
	return false

func switch_turn():
	player = -player
	if is_player_blocked(player):
		print("Player " + str(player) + " is blocked and skips their turn.")
		player = -player
	if if_init_dot_selected_1 || if_init_dot_selected_2:
		remaining_moves = randi_range(1, 6)  # Random number of moves (1-6)
		print("Player " + str(player) + "'s turn. Moves this turn: " + str(remaining_moves))

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
			get_tree().quit()
		if p2_count == 3:
			print("Player 2 Wins!")
			get_tree().quit()

func create_dot(player, position):
	if player == 1:
		var new_dot = yellow_dot_scene.instantiate()
		new_dot.position = position
		add_child(new_dot)
	else:
		var new_dot = purple_dot_scene.instantiate()
		new_dot.position = position
		add_child(new_dot)

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
