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
var if_init_dot_selected_1: bool;
var if_init_dot_selected_2: bool;
var player: int
var player_1_move: Node
var player_2_move: Node
var player_1_win: bool
var player_2_win: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if_init_dot_selected_1 = false
	if_init_dot_selected_2 = false
	player = 1
	board_size = $Board.texture.get_width()
	cell_size = board_size / 10
	for i in range(0, 11):
		var row_point = Array()
		for j in range(0, 11):
			cross_points.append(Vector2i((i*cell_size)+3, (j*cell_size)+4))
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
				var board_point_pos = Vector2i(event.position / cell_size)
				# Existing bug where clicking top left of cross point gave wrong coordinate
				print("event.position: " + str(event.position))
				print("board_point_pos: " + str(board_point_pos))
				if if_init_dot_selected_1 and if_init_dot_selected_2:
					for cross_point in cross_points:
						if event.position.distance_to(cross_point) <= click_tolerance:
							if is_valid_move(cross_point):
								if(player == 1):
									draw_connect_line(player, player_1_current_pos, cross_point)
									player_1_current_pos = cross_point
									player_1_move.position = player_1_current_pos
									print("Player 1 Moves")
									if(board_status[board_point_pos.y][board_point_pos.x] == 2):
										board_status[board_point_pos.y][board_point_pos.x] = 4
									else:
										board_status[board_point_pos.y][board_point_pos.x] = player
								else:
									draw_connect_line(player, player_2_current_pos, cross_point)
									player_2_current_pos = cross_point
									player_2_move.position = player_2_current_pos
									print("Player 2 Moves")
									if (board_status[board_point_pos.y][board_point_pos.x] == 3):
										board_status[board_point_pos.y][board_point_pos.x] = 5
									else:
										board_status[board_point_pos.y][board_point_pos.x] = player
								player = -player
								for row in board_status:
									print(row)
							check_winner()
				else:
					if player == 1:
						for init_dot in init_dots_pos_1:
							if event.position.distance_to(init_dot) <= click_tolerance:
								print("Player 1 Start")
								if_init_dot_selected_1 = true
								player_1_current_pos = init_dot
								player_1_move = player_1_move_dot_scene.instantiate()
								player_1_move.position = init_dot
								add_child(player_1_move)
								board_status[board_point_pos.y][board_point_pos.x] = 4
								player = -player
					else:
						for init_dot in init_dots_pos_2:
							if event.position.distance_to(init_dot) <= click_tolerance:
								print("Player 2 Start")
								if_init_dot_selected_2 = true
								player_2_current_pos = init_dot
								player_2_move = player_2_move_dot_scene.instantiate()
								player_2_move.position = init_dot
								add_child(player_2_move)
								board_status[board_point_pos.y][board_point_pos.x] = 5
								player = -player

func is_valid_move(cross_point) -> bool:
	var target_pos = Vector2i(cross_point / cell_size)
	var current_pos = Vector2i(player_1_current_pos / cell_size) if player == 1 else Vector2i(player_2_current_pos / cell_size)
	var dx = abs(target_pos.x - current_pos.x)
	var dy = abs(target_pos.y - current_pos.y)
	print("current_pos: "+str(current_pos))
	print("target_pos: "+str(target_pos))
	print("dx: "+str(dx))
	print("dy: "+str(dy))
	
	# Check if the move is horizontal or vertical and within 1-3 spaces
	if (dx == 0 and dy <= 3) or (dy == 0 and dx <= 3):
		# Check if the path is clear and doesn't cross itself or the opponent's path
		for i in range(1, max(dx, dy) + 1):
			var check_pos = Vector2i(
				current_pos.x + i * sign(target_pos.x - current_pos.x),
				current_pos.y + i * sign(target_pos.y - current_pos.y)
			)
			if board_status[check_pos.y][check_pos.x] > 3 and board_status[check_pos.y][check_pos.x] != player:
				print("SPOT OCCUPIED")
				return false
		print("VALID")
		return true
	print("TOO FAR")
	return false

func check_winner():
	#you win if there are 3 dots on the board with 4 (player 1) or 5 (player 2)
	var p1_count = 0
	var p2_count = 0
	for row in board_status:
		for cell in row:
			if cell == 4:
				p1_count += 1
			elif cell == 5:
				p2_count += 1
		if(p1_count == 3):
			print("Player 1 Wins!")
			get_tree().quit()
		if(p2_count == 3):
			print("Player 2 Wins!")
			get_tree().quit()
	
func create_dot(player, position):
	if(player == 1):
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
	if(player == 1):
		new_line.default_color = Color("Yellow") 
	else:
		new_line.default_color = Color("Purple")
	new_line.width = 3
	new_line.add_point(start_pos)
	new_line.add_point(end_pos)
	add_child(new_line)
