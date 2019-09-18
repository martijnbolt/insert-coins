extends Node

func _ready():
	pass # Replace with function body.

func _on_insertcoin_pressed():
	get_node("invoice").show()