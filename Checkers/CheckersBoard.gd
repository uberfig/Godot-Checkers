extends Node2D

#0 is unpopulated 
#odd is white, 3 is king
#even is black, 4 is king
var current_board: Dictionary = {}

onready var w_peices_remaining: int = $W.get_child_count()
onready var b_peices_remaining: int = $B.get_child_count()

# Called when the node enters the scene tree for the first time.
func _ready():
	for y in 7:
		for x in 7:
			current_board[Vector2(x, y)] = [0, null]
	
	update_board()
	
	move_peice(Vector2(0,2), Vector2(2,4))



func update_board():
	b_peices_remaining = $B.get_child_count()
	w_peices_remaining = $W.get_child_count()
	
	var b_children = $B.get_children()
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
	
	var w_children = $W.get_children()
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
	if(current_board[initial_coord][0] == 0):
		return(0)
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

