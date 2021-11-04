extends Node2D

#0 is unpopulated 
#odd is white, 3 is king
#even is black, 4 is king
var current_board: Dictionary = {
	Vector2(0,0): 0
}

onready var w_peices_remaining: int = $W.get_child_count()
onready var b_peices_remaining: int = $B.get_child_count()

# Called when the node enters the scene tree for the first time.
func _ready():
	get_board()


func get_board():
	b_peices_remaining = $B.get_child_count()
	w_peices_remaining = $W.get_child_count()
	
	var b_children = $B.get_children()
	for b_child in b_children:
		var position = b_child.get_position()
		var coord: Vector2 = $Board.world_to_map(position)
#		print("black tile at: ", coord)
	
		if(b_child.is_in_group("Standard")):
			current_board[coord] = 2
		elif(b_child.is_in_group("King")):
			current_board[coord] = 4
		else:
			print("there is a weird checker at: ", coord)
	
#	print("")
	
	var w_children = $W.get_children()
	for w_child in w_children:
		var position = w_child.get_position()
		var coord: Vector2 = $Board.world_to_map(position)
#		print("white tile at: ", coord)
		
		if(w_child.is_in_group("Standard")):
			current_board[coord] = 1
		elif(w_child.is_in_group("King")):
			current_board[coord] = 3
		else:
			print("there is a weird checker at: ", coord)


