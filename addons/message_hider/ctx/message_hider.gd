@tool
extends Popup
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Message Hider
#
#	Message Hider addon.godot 4
#	author:	"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

var _type : int = 0

@export var file_dialog : FileDialog
@export var open_file : LineEdit
@export var out_file : LineEdit
@export var secret_file : LineEdit
@export var secret_area : TextEdit
@export var message : TextEdit
@export var addlabel : Label

@export var ok : Button
@export var cancel : Button

func _ready() -> void:
	_reset()
	visibility_changed.connect(_on_visible)
	#open_file.text = ""
	#out_file.text = ""
	#message.text = ""
	#secret_file = ""
	
func _on_visible() -> void:
	_reset()
	secret_area.text = ""
	_msg("Set paths and write a message!")

func _on_close_requested() -> void:
	hide()


func _on_go_back_requested() -> void:
	_on_close_requested()


func _error(color : Color = Color.RED) -> void:
	var root : Node = get_child(0)
	var tw : Tween = get_tree().create_tween()
	
	root.modulate = color
	tw.tween_property(root, "modulate", Color.WHITE, 0.24)

func _on_file_dialog_dir_selected(dir: String) -> void:
	_reset()
	if _type == 1:
		_error()
		open_file.text = ""
		open_file.placeholder_text = "Not valid File!"
	elif _type == 3:
		_error()
		secret_file.text = ""
		secret_file.placeholder_text = "Not valid File!"
	elif _type == 2:
		var filename : String = "output.png"
		if !open_file.text.is_empty():
			var nfilename : String = open_file.text.get_file()
			if nfilename.is_empty():
				filename = nfilename
				if !filename.ends_with("png"):
					if filename.get_extension().is_empty():
						filename += ".png"
					else:
						filename = filename.trim_suffix(filename.get_extension()) + "png"
		out_file.text = dir.path_join(filename)
		
func _reset() -> void:
	open_file.placeholder_text = "Input Image Path"
	out_file.placeholder_text = "Output Image File"
	message.placeholder_text = "Secret message here!"
	secret_file.placeholder_text = "Secret Message Image Path"
	secret_area.placeholder_text = "Search image with secret."
	ok.disabled = false
	cancel.disabled = false
	
		
func _on_file_dialog_file_selected(path: String) -> void:
	_reset()
	if _type == 1:
		if FileAccess.file_exists(path):
			open_file.text = path
			if out_file.text.is_empty():
				var ext : String = "." + path.get_extension()
				out_file.text = path.trim_suffix(ext) + "_out.png"
			return
		_error()
		open_file.text = ""
		open_file.placeholder_text = "Not valid File!"
	elif _type == 3:
		if FileAccess.file_exists(path):
			secret_file.text = path
			return
		_error()
		secret_file.text = ""
		secret_file.placeholder_text = "Not valid File!"
	elif _type == 2:
		if FileAccess.file_exists(path):
			out_file.text = path
			out_file.placeholder_text = "Out File Path"
			return
		_error()
		out_file.text = ""

func _on_cancel_button_pressed() -> void:
	_reset()
	_on_close_requested()


func _valid() -> bool:
	_reset()
	for x : Control in [open_file, out_file, message]:
		if x.text.is_empty():
			x.set(&"placeholder_text", "Can not be empty!")
			return false
	return true

func _on_ok_button_pressed() -> void:	
	_msg("Message: check the errors!")
	if _valid():
		if MessageHider.text_to_image(open_file.text, message.text, out_file.text):
			_error(Color.GREEN)
			ok.disabled = true
			cancel.disabled = true
			ok.set_deferred(&"disabled", false)
			cancel.set_deferred(&"disabled", false)
			secret_file.text = out_file.text
			_msg("Message saved!")
			#get_tree().create_timer(0.25).timeout.connect(_on_close_requested, CONNECT_ONE_SHOT)			
			return
	_error()
	

func _on_input_search_pressed() -> void:
	_type = 1
	file_dialog.popup_centered()

func _on_output_search_pressed() -> void:
	_type = 2
	file_dialog.popup_centered()


func _on_clear_msg_pressed() -> void:
	if !message.text.is_empty():
		message.text = ""
		_error(Color.SKY_BLUE)


func _on_secret_search_pressed() -> void:
	_type = 3
	file_dialog.popup_centered()


func _on_secret_ok_button_pressed() -> void:
	_reset()
	secret_area.text = ""
	_msg("Message: check the errors!")
	if secret_file.text.is_empty():
		secret_file.placeholder_text = "Can not be empty!"
		_error()
		return 
	var message : String = MessageHider.text_from_image(secret_file.text)	
	if !message.is_empty():
		secret_area.text = message
		_error(Color.GREEN)	
		_msg("Message Found!")
		return
	_error()
	secret_area.placeholder_text = "File Message have not a secret message or data is corrupt!"
	
func _msg(msg : String) -> void:
	addlabel.text = msg
