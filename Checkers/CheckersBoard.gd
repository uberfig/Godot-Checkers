extends Node2D

#0 is unpopulated 
#odd is white, 3 is king
#even is black, 4 is king
var current_board: Dictionary = {}
#in format tile: [is occupied, refrence, color, is king]
onready var w_peices_remaining: int = $W.get_child_count()
onready var b_peices_remaining: int = $B.get_child_count()

var multijump_mode:= false
var multijump_cell: Vector2

var selecting_destination := false
var selected_tile: Vector2
var public_viable_locations:= {}
#contents will be formated {destination: [is_jumping, starting_point, jumped_tile(if applicable)]}

#we can use this as a state machine
var teams = ["black", "white"]
var turn_index: int = 0

onready var white_team = preload("res://Checkers/WhiteTeam.tscn")
onready var black_team = preload("res://Checkers/BlackTeam.tscn")
onready var move_marker = preload("res://Checkers/PossibleMoveMarker.tscn")
onready var white_team_ref =$W
onready var black_team_ref =$B
onready var black_king = preload("res://Checkers/BKing.tscn")
onready var white_king = preload("res://Checkers/WKing.tscn")



func _ready():
	empty_board()
	
	update_board()
	
#	print(current_board)
	
#	move_peice(Vector2(0,2), Vector2(2,4))


func empty_board():
	for y in 8:
		for x in 8:
			current_board[Vector2(x, y)] = [false, null, "", false]
#in format is occupied, refrence, color, is king


func update_board():
	b_peices_remaining = black_team_ref.get_child_count()
	w_peices_remaining = white_team_ref.get_child_count()
	
	var b_children = black_team_ref.get_children()
	for b_child in b_children:
		var position = b_child.get_position()
		var coord: Vector2 = $Board.world_to_map(position)
#		print("black tile at: ", coord)
	
		if(b_child.is_in_group("Standard")):
			current_board[coord] = [true, b_child, "black", false]#3 is for if it is a king
		elif(b_child.is_in_group("King")):
			current_board[coord] = [true, b_child, "black", true]
		else:
			print("there is a weird checker at: ", coord)
	
	var w_children = white_team_ref.get_children()
	for w_child in w_children:
		var position = w_child.get_position()
		var coord: Vector2 = $Board.world_to_map(position)
#		print("white tile at: ", coord)
		
		if(w_child.is_in_group("Standard")):
			current_board[coord] = [true, w_child, "white", false]
		elif(w_child.is_in_group("King")):
			current_board[coord] = [true, w_child, "white", true]
		else:
			print("there is a weird checker at: ", coord)


func move_peice(initial_coord: Vector2, destination: Vector2):
#	print(current_board)
	if(current_board[destination][0] == true):
		print("tile is filled")
		return
	else:
#		move the peice
		var current_pos = ($Board.map_to_world(initial_coord) + Vector2(32,32))
		var destination_global = ($Board.map_to_world(destination) + Vector2(32,32))
		$Tween.interpolate_property(current_board[initial_coord][1], "position",
		current_pos, destination_global, 1.2,
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		$Tween.start()
#		transfer the values
#		current_board in format tile: [is occupied, refrence, color, is king]
		current_board[destination] = current_board[initial_coord]
#		print("current_board[destination] = ", current_board[destination])
#		print("current_board[initial_coord] = ", current_board[initial_coord])
		var team = current_board[initial_coord][2]
		clear_tile_data(initial_coord)
		
		if((team == "white") && (destination.y == 7)):
			current_board[destination][3] = true
			yield($Tween, "tween_completed")
			king_me(destination)
		if((team == "black") && (destination.y == 0)):
			current_board[destination][3] = true
			yield($Tween, "tween_completed")
			king_me(destination)
		
		
#		print("current_board[initial_coord] = ", current_board[initial_coord])
		
		
		
	
	public_viable_locations = {}
#contents will be formated {destination: [is_jumping, starting_point, jumped_tile(if applicable)]}


func end_turn():
	turn_index += 1
	if(turn_index > (teams.size() - 1)):
		turn_index = 0


func clear_tile_data(tile):
	current_board[tile] = [false, null, "", false]


func _unhandled_input(event):
	if(event.is_action_pressed("click")):
		var world_click_pos = event.position
		var map_cell_pos = $Board.world_to_map(world_click_pos)
		
		print("unhandled event @", map_cell_pos)
		
		
		if((map_cell_pos.x >= 8) or (map_cell_pos.y >= 8) or (map_cell_pos.x < 0) or (map_cell_pos.y < 0)):
			if(selecting_destination == true):
				selecting_destination = false
			return
		
		print("location details: ", current_board[map_cell_pos])
		
		if((current_board[map_cell_pos][0] == false) && (selecting_destination == false)):
			return
		
		if selecting_destination == false:
			selecting_destination = true
#			print("selecting destination")
			position_move_data(map_cell_pos)
#			print("public_viable_locations: ", public_viable_locations)
			show_possible_moves()
		else:
			selecting_destination = false
			clear_move_markers()
#			if selected_tile == map_cell_pos:
#				selecting_destination = false
#			else:
#				move_peice(selected_tile, map_cell_pos)
#				selecting_destination = false


func new_game():
	empty_board()
	
	white_team_ref.queue_free()
	black_team_ref.queue_free()
	
	var w_instance = white_team.instance()
	white_team_ref = w_instance
	add_child(w_instance)
	
	var b_instance = black_team.instance()
	black_team_ref = b_instance
	add_child(b_instance)
	
	for child in $ViableLocations.get_children():
		child.queue_free()
	
	update_board()
	turn_index = 0


func _on_NewGame_pressed():
	new_game()


#true is black, false is white
func position_move_data(check_position: Vector2):
	
	var team = is_tile_filled(check_position)[1]
	var is_king = is_tile_filled(check_position)[2]
	
	#we will spawn a marker at each viable location which when cliked will
	#move the peice to that location and delete any jumped tile
	var viable_locations := {}
	#contents will be formated {destination: [is_jumping, starting_point, jumped_tile(if applicable)]}
	
	var directions_to_check:= []
	
	if(is_king == false):
		#black team
		if(team == "black"):
			directions_to_check = [Vector2(1,-1), Vector2(-1,-1)]
		#white
		if(team == "white"):
			directions_to_check = [Vector2(1,1), Vector2(-1,1)]
	
	if(is_king == true):
		directions_to_check = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]
	
	for direction in directions_to_check:
#		print("checking direction: ", direction)
		var adjacent_data = check_adjacent_for_move(check_position, direction)
		#in format [can_move, can_jump, [tile, adjacent_tile, jump_tile]]
		
		if((adjacent_data[0] == true) and (adjacent_data[1] == false)):
			viable_locations[adjacent_data[2][1]] = [false, check_position]
#			print("can move but not jump, adjacent data is: ", adjacent_data)
		
		if((adjacent_data[0] == true) and (adjacent_data[1] == true)):
			viable_locations[adjacent_data[2][2]] = [true, check_position, adjacent_data[2][1]]
#			print("can jump but not move, adjacent data is: ", adjacent_data)
	
#	print("viable_locations: ", viable_locations)
	public_viable_locations = viable_locations


func check_for_jump(tile):
	
	var team = is_tile_filled(tile)[1]
	var is_king = is_tile_filled(tile)[2]
	
	var directions_to_check:= []
	
	if(is_king == false):
		#black team
		if(team == "black"):
			directions_to_check = [Vector2(1,-1), Vector2(-1,-1)]
		#white
		if(team == "white"):
			directions_to_check = [Vector2(1,1), Vector2(-1,1)]
	
	if(is_king == true):
		directions_to_check = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]
	
	for direction in directions_to_check:
#		print("checking direction: ", direction)
		var adjacent_data = check_adjacent_for_move(tile, direction)
		#in format [can_move, can_jump, [tile, adjacent_tile, jump_tile]]
		if((adjacent_data[0] == true) and (adjacent_data[1] == true)):
			return(true)
	return(false)


func search_for_jumps_only(tile):
	
	var team = is_tile_filled(tile)[1]
	var is_king = is_tile_filled(tile)[2]
	
	var viable_locations := {}
	var directions_to_check:= []
	
	if(is_king == false):
		#black team
		if(team == "black"):
			directions_to_check = [Vector2(1,-1), Vector2(-1,-1)]
		#white
		if(team == "white"):
			directions_to_check = [Vector2(1,1), Vector2(-1,1)]
	
	if(is_king == true):
		directions_to_check = [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]
	
	for direction in directions_to_check:
#		print("checking direction: ", direction)
		var adjacent_data = check_adjacent_for_move(tile, direction)
		#in format [can_move, can_jump, [tile, adjacent_tile, jump_tile]]
		if((adjacent_data[0] == true) and (adjacent_data[1] == true)):
			viable_locations[adjacent_data[2][2]] = [true, tile, adjacent_data[2][1]]
	
	
	public_viable_locations = viable_locations


func spawn_move_marker(coord):
	var world_position: Vector2 = ($Board.map_to_world(coord) + Vector2(32, 32))
	var marker_instance = move_marker.instance()
	marker_instance.set_position(world_position)
	$ViableLocations.add_child(marker_instance)


func show_possible_moves():
	for coord in public_viable_locations:
		spawn_move_marker(coord)


func clear_move_markers():
	for child in $ViableLocations.get_children():
		child.queue_free()
#	print("cleared move markers")


func kill_checker(tile):
	current_board[tile][1].queue_free()
	current_board[tile] = [false, null, "", false]
	b_peices_remaining = black_team_ref.get_child_count()
	w_peices_remaining = white_team_ref.get_child_count()


#0 is if it is filled, 2 is by whom
func check_adjacent_for_move(tile: Vector2, vector_direction: Vector2):
	#returns in format [can_move, can_jump, [tile, adjacent_tile, jump_tile]]
	var adjacent_tile: Vector2 = (tile + vector_direction)
	var jump_tile: Vector2 = (tile + (vector_direction * 2))
	var my_color: String = current_board[tile][2]
	
	if(
		((adjacent_tile.x >= 8) or (adjacent_tile.y >= 8) or (adjacent_tile.x < 0) or (adjacent_tile.y < 0))
	):
		return([false, false]) #the tile is outside of the board; cannot move this way
	
	
	if(current_board[adjacent_tile][0] == false):
		return([true, false, [tile, adjacent_tile]])#the tile is within the board and empty
	
	
	if(current_board[adjacent_tile][2] == my_color):
		return([false, false])#the tile is filled with a friendly; cannot move this way
	
	
	if(current_board[adjacent_tile][2] != my_color):
		if(
			((jump_tile.x >= 8) or (jump_tile.y >= 8) or (jump_tile.x < 0) or (jump_tile.y < 0))
		):
			return([false, false]) 
			#the tile is on the edge of the board
		if(current_board[jump_tile][0] == false):
			return([true, true, [tile, adjacent_tile, jump_tile]])
			#the tile is filled with an enemy and there isn't a unit behind it; can jump
		else:
			return([false, false])#the tile is filled with a guarded enemy


func is_tile_filled(tile: Vector2):
	if(current_board[tile][0] == false):
		return([false, current_board[tile][2], current_board[tile][3]])
	else:
		return([true, current_board[tile][2], current_board[tile][3]])


func king_me(tile):
	var world_pos = ($Board.map_to_world(tile) + Vector2(32,32))
	
	current_board[tile][3] = true
	current_board[tile][1].queue_free()
	
	if(current_board[tile][2] == "black"):
		var king_instance = black_king.instance()
		king_instance.set_position(world_pos)
		black_team_ref.add_child(king_instance)
		current_board[tile][1] = king_instance
		
	if(current_board[tile][2] == "white"):
		var king_instance = white_king.instance()
		king_instance.set_position(world_pos)
		white_team_ref.add_child(king_instance)
		current_board[tile][1] = king_instance


func _on_Cursor_accept_pressed(cell):
	print("location details: ", current_board[cell])
	
	#check if empty
	if((current_board[cell][0] == false) && (selecting_destination == false)):
		return
	
	#check team
	if((selecting_destination == false) && (current_board[cell][2] != teams[turn_index])):
		print("not ", current_board[cell][2], "'s move! waiting for ", teams[turn_index], " to move")
		return
	
	#check if selecting is false
	if((selecting_destination == false) && (multijump_mode == false)):
		selecting_destination = true
		position_move_data(cell)
		show_possible_moves()
		return
	
	elif((selecting_destination == false) && (multijump_mode == true)):
		if (multijump_mode == true):
			search_for_jumps_only(cell)
		show_possible_moves()
		selecting_destination = true
		return
	
	elif(selecting_destination == true):
		if(public_viable_locations.has(cell)):
			var coord_data = public_viable_locations[cell]
#contents of public_viable_locations will be formated 
#{destination: [is_jumping, starting_point, jumped_tile(if applicable)]}
			
#contents of coord_data will be formated 
#[is_jumping, starting_point, jumped_tile(if applicable)]
			if(coord_data[0] == false):#not jumping
				move_peice(coord_data[1], cell)
				end_turn()
			
			if(coord_data[0] == true):#jumping
				move_peice(coord_data[1], cell)
				kill_checker(coord_data[2])
				
				var can_multijump = check_for_jump(cell)
				
				if(can_multijump == false):#can't jump again
					multijump_mode = false
					$EndTurn.disabled = true
					end_turn()
					public_viable_locations = {}
				
				if(can_multijump == true):#can multijump
					multijump_mode = true
					$EndTurn.disabled = false
					multijump_cell = cell
					search_for_jumps_only(cell)
					selecting_destination = false
			
			selecting_destination = false
			clear_move_markers()
			return
		
		selecting_destination = false
		clear_move_markers()
		return
	
	print("cursor unhandled")


func _on_EndTurn_pressed():
	end_turn()
	selecting_destination = false
	$EndTurn.disabled = true
	multijump_mode = false
	clear_move_markers()
