extends Node2D

#0 is unpopulated 
#odd is white, 3 is king
#even is black, 4 is king
var current_board: Dictionary = {}

onready var w_peices_remaining: int = $W.get_child_count()
onready var b_peices_remaining: int = $B.get_child_count()

var selecting_destination := false
var selected_tile: Vector2

#if true it is black's turn if false it is white's turn
var current_turn:= true

onready var white_team = preload("res://Checkers/WhiteTeam.tscn")
onready var black_team = preload("res://Checkers/BlackTeam.tscn")
onready var white_team_ref =$W
onready var black_team_ref =$B


func _ready():
	empty_board()
	
	update_board()
	
#	print(current_board)
	
#	move_peice(Vector2(0,2), Vector2(2,4))


func empty_board():
	for y in 8:
		for x in 8:
			current_board[Vector2(x, y)] = [0, null]


func update_board():
	b_peices_remaining = black_team_ref.get_child_count()
	w_peices_remaining = white_team_ref.get_child_count()
	
	var b_children = black_team_ref.get_children()
	for b_child in b_children:
		var position = b_child.get_position()
		var coord: Vector2 = $Board.world_to_map(position)
#		print("black tile at: ", coord)
	
		if(b_child.is_in_group("Standard")):
			current_board[coord] = [2, b_child]
		elif(b_child.is_in_group("King")):
			current_board[coord] = [4, b_child]
		else:
			print("there is a weird checker at: ", coord)
	
	var w_children = white_team_ref.get_children()
	for w_child in w_children:
		var position = w_child.get_position()
		var coord: Vector2 = $Board.world_to_map(position)
#		print("white tile at: ", coord)
		
		if(w_child.is_in_group("Standard")):
			current_board[coord] = [1, w_child]
		elif(w_child.is_in_group("King")):
			current_board[coord] = [3, w_child]
		else:
			print("there is a weird checker at: ", coord)


func move_peice(initial_coord: Vector2, destination: Vector2):
#	if(current_turn == true):
#		if((current_board[initial_coord][0] != 2) or (current_board[initial_coord][0] != 4)):
#			return
#	else:
#		if((current_board[initial_coord][0] != 1) or (current_board[initial_coord][0] != 3)):
#			return
	
	if(current_board[destination][0] != 0):
		print("tile is filled")
		return
	else:
#		move the peice
		var current_pos = ($Board.map_to_world(initial_coord) + Vector2(32,32))
		var destination_global = ($Board.map_to_world(destination) + Vector2(32,32))
		$Tween.interpolate_property(current_board[initial_coord][1], "position",
		current_pos, destination_global, 1.5,
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		$Tween.start()
#		transfer the values
		current_board[destination][0] = current_board[initial_coord][0]
		current_board[destination][1] = current_board[initial_coord][1]
		current_board[initial_coord][0] = 0
		current_board[initial_coord][1] = null


func _unhandled_input(event):
	if event is InputEventMouseButton && event.is_pressed():
		var world_click_pos = event.position
		var map_cell_pos = $Board.world_to_map(world_click_pos)
		
		if((map_cell_pos.x >= 8) or (map_cell_pos.y >= 8) or (map_cell_pos.x < 0) or (map_cell_pos.y < 0)):
			if(selecting_destination == true):
				selecting_destination = false
			return
		
		if((current_board[map_cell_pos][0] == 0) && (selecting_destination == false)):
			return
		
		if selecting_destination == false:
			selecting_destination = true
			selected_tile = map_cell_pos
		else:
			if selected_tile == map_cell_pos:
				selecting_destination = false
			else:
				move_peice(selected_tile, map_cell_pos)
				selecting_destination = false


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
	
	update_board()
	current_turn = true


func _on_NewGame_pressed():
	new_game()

#true is black, false is white
func can_jump(check_position: Vector2, team:bool, is_king: bool):
	if(is_king == false):
		var jump_locations := []
		#black
		if(team == true):
			var tiles_to_check = [check_position + Vector2(1,1), check_position + Vector2(-1,1)]
			
			for possible_location in tiles_to_check:
				if(not((possible_location.x >= 8) or (possible_location.y >= 8) or (possible_location.x < 0) or (possible_location.y < 0))):
					pass
		
		#white
		if(team == false):
			pass


