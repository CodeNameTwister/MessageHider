class_name MessageHider extends Object
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	Message Hider
#
#	Message Hider addon.godot 4
#	author:	"Twister"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

const BITS : int = 8
const EOM: String = "00000000"

static var can_use_padding : bool = true

static func _binary_string_to_string(binary_data: String) -> String:
	if binary_data.length() % BITS != 0:
		if !can_use_padding:
			return ""
			
		if OS.is_debug_build():
			push_warning("[WARN] Using padding for fill binary data.")
		while binary_data.length() % BITS != 0:
			binary_data += " "
	
	var result : PackedByteArray = PackedByteArray()
	var bits : int = BITS - 1
	for x : int in range(0, binary_data.length(), BITS):
		var byte_str : String = binary_data.substr(x, BITS)
		var byte_val : int = 0
		for bit_idx : int in range(BITS):
			if byte_str[bit_idx] == '1':
				byte_val |= (1 << (bits - bit_idx))
		result.append(byte_val)
	
	return result.get_string_from_utf8()

static func _string_to_binary_string(text: String) -> String:
	var binary_string : String = ""
	var bytes: PackedByteArray = text.to_utf8_buffer()
	for byte_val : int in bytes:
		var current_byte_bits : String = ""
		for x : int in range(BITS):
			current_byte_bits = str(byte_val & 1) + current_byte_bits
			byte_val >>= 1
		binary_string += current_byte_bits
	return binary_string

static func text_to_image(input_image_path : String, input_message : String, output_image_png_path : String) -> bool:
	if !FileAccess.file_exists(input_image_path):
		printerr("File not exist! ", input_image_path)
		return false
		
	var image : Image = null
	var dir : String = output_image_png_path.get_base_dir()	
	var extension : String = input_image_path.get_extension()	
	var refresh : bool = false
	
	input_image_path = ProjectSettings.globalize_path(input_image_path)
	if Engine.is_editor_hint():
		output_image_png_path = ProjectSettings.localize_path(output_image_png_path)
		refresh = output_image_png_path.begins_with("res://")
	
	if ResourceLoader.exists(input_image_path):
		var variant : Variant = ResourceLoader.load(input_image_path)
		if !(variant is Image):
			if variant is Texture2D:
				variant = variant.get_image()
			else:
				printerr("Resource file is not a image! ,", input_image_path)
				return false
		image = variant
	else:
		image = Image.load_from_file(input_image_path)
	
	if image == null or image.get_size() == Vector2i.ZERO:
		printerr("Error!, can not load image: {0}".format([input_image_path]))
		return false
		
	if extension != "png":
		push_warning("[WARN] expected PNG format, using another format compressed may corrupt the hided message.")
		
	if image.is_compressed():
		image.decompress()

	var binary_data_to_hide : String= _string_to_binary_string(input_message) + EOM
	var data_length_bits : int = binary_data_to_hide.length()

	var max_capacity_bits : int = image.get_width() * image.get_height() * 3
	if data_length_bits > max_capacity_bits:
		printerr("Error: too much data for hide in this message!.")
		return false

	var bit_index : int = 0
	for y : int in range(image.get_height()):
		for x : int in range(image.get_width()):
			if bit_index >= data_length_bits:
				break

			var current_color: Color = image.get_pixel(x, y)
			var r8 : int = current_color.r8
			var g8 : int = current_color.g8
			var b8 : int = current_color.b8
			var a8 : int = current_color.a8

			if bit_index < data_length_bits:
				var bit_to_hide : int = int(binary_data_to_hide[bit_index])
				r8 = (r8 & ~1) | bit_to_hide
				bit_index += 1
			
			if bit_index < data_length_bits:
				var bit_to_hide : int = int(binary_data_to_hide[bit_index])
				g8 = (g8 & ~1) | bit_to_hide
				bit_index += 1

			if bit_index < data_length_bits:
				var bit_to_hide : int = int(binary_data_to_hide[bit_index])
				b8 = (b8 & ~1) | bit_to_hide
				bit_index += 1
			
			image.set_pixel(x, y, Color8(r8, g8, b8, a8))
		
		if bit_index >= data_length_bits:
			break

	if bit_index < data_length_bits:
		printerr("Error: Can not hide all data, bad imagen format.")
		return false

	
	if output_image_png_path.get_extension().is_empty():
		dir = output_image_png_path
		output_image_png_path = output_image_png_path.path_join("outout.png")
		
	if !DirAccess.dir_exists_absolute(dir):
		if OS.is_debug_build():
			print("Created new folder ", dir)
		DirAccess.make_dir_recursive_absolute(dir)
		
	var save_error : int = -1
	
	save_error = image.save_png(output_image_png_path)
	if save_error != OK:
		printerr("Error {0} on save image!: {1}".format([save_error, output_image_png_path]))
		return false
	
	print("Data has been hided in: ", output_image_png_path)
	
	if refresh:
		var fs : EditorFileSystem = EditorInterface.get_resource_filesystem()
		if fs:
			fs.scan_sources()
	return true


static func text_from_image(image_path: String) -> String:
	var image : Image = null
	
	image_path = ProjectSettings.globalize_path(image_path)
	
	if !FileAccess.file_exists(image_path):
		printerr("File not exist! ", image_path)
		return ""
	
	image = Image.load_from_file(image_path)
		
	if image == null or image.get_size() == Vector2i.ZERO:
		printerr("Error!, can not load image: {0}".format([image_path]))
		return ""

	if image.is_compressed():
		image.decompress()
		
	var binary_string : String = ""
	var found_eom : bool = false

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var current_color: Color = image.get_pixel(x, y)
			
			binary_string += str(current_color.r8 & 1)
			if binary_string.ends_with(EOM) and binary_string.length() % BITS == 0:
				found_eom = true
				break
			
			binary_string += str(current_color.g8 & 1)
			if binary_string.ends_with(EOM) and binary_string.length() % BITS == 0:
				found_eom = true
				break

			binary_string += str(current_color.b8 & 1)
			if binary_string.ends_with(EOM) and binary_string.length() % BITS == 0:
				found_eom = true
				break
		
		if found_eom:
			break

	if found_eom:
		var data_part : String = binary_string.substr(0, binary_string.length() - EOM.length())
		return _binary_string_to_string(data_part)
	else:
		push_warning("[WARN]: end of message not found or data is corrupt.")
		return _binary_string_to_string(binary_string)
