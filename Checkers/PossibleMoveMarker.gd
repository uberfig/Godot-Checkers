extends KinematicBody2D

signal clicked(refrence)
# Declare member variables here. Examples:
# var a = 2
# var b = "text"





# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_PossibleMoveMarker_input_event(viewport, event, shape_idx):
	if(event.is_action_pressed("click")):
		print("movemarker clicked")
		emit_signal("clicked", self)
