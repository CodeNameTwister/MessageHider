@tool
extends EditorPlugin
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Message Hider
#
#	Message Hider addon.godot 4
#	author:	"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const CONTEXT : PackedScene = preload("res://addons/message_hider/ctx/MessageHider.tscn")

var window : Window = null

func _enter_tree() -> void:
	add_tool_menu_item("Message Hider", _on_handler)
	
func _on_handler() -> void:
	if window == null:
		window = CONTEXT.instantiate()
		add_child(window)
	window.popup_centered()
	
func _exit_tree() -> void:
	remove_tool_menu_item("Message Hider")
