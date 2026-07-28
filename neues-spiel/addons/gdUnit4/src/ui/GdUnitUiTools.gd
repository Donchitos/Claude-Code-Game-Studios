class_name GdUnitUiTools
extends RefCounted


static var _spinner: AnimatedTexture


enum ImageFlipMode {
	HORIZONTAl,
	VERITCAL
}


## Returns the icon by name, if it exists.
static func get_icon(icon_name: String, color: = Color.BLACK) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var icon := EditorInterface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
	if icon == null:
		return null
	if color != Color.BLACK:
		icon = _modulate_texture(icon, color)
	return icon


## Returns the icon flipped
static func get_flipped_icon(icon_name: String, mode: = ImageFlipMode.HORIZONTAl) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var icon := EditorInterface.get_base_control().get_theme_icon(icon_name, "EditorIcons")
	if icon == null:
		return null
	return ImageTexture.create_from_image(_flip_image(icon, mode))


static func get_spinner() -> AnimatedTexture:
	if _spinner != null:
		return _spinner
	_spinner = AnimatedTexture.new()
	_spinner.frames = 8
	_spinner.speed_scale = 2.5
	for frame in _spinner.frames:
		_spinner.set_frame_texture(frame, get_icon("Progress%d" % (frame+1)))
		_spinner.set_frame_duration(frame, 0.2)
	return _spinner


static func get_color_animated_icon(icon_name :String, from :Color, to :Color) -> AnimatedTexture:
	if not Engine.is_editor_hint():
		return null
	var texture := AnimatedTexture.new()
	texture.frames = 8
	texture.speed_scale = 2.5
	var color := from
	for frame in texture.frames:
		color = lerp(color, to, .2)
		texture.set_frame_texture(frame, get_icon(icon_name, color))
		texture.set_frame_duration(frame, 0.2)
	return texture


static func get_run_overall_icon() -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var icon := EditorInterface.get_base_control().get_theme_icon("Play", "EditorIcons")
	var image := _merge_images(icon.get_image(), Vector2i(-2, 0), icon.get_image(), Vector2i(3, 0))
	return ImageTexture.create_from_image(image)


static func get_GDScript_icon(status: String, color: Color) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var icon_a := EditorInterface.get_base_control().get_theme_icon("GDScript", "EditorIcons")
	var icon_b := EditorInterface.get_base_control().get_theme_icon(status, "EditorIcons")
	var overlay_image := _modulate_image(icon_b.get_image(), color)
	var image := _merge_images_scaled(icon_a.get_image(), Vector2i(0, 0), overlay_image, Vector2i(5, 5))
	return ImageTexture.create_from_image(image)


static func get_CSharpScript_icon(status: String, color: Color) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var icon_a := EditorInterface.get_base_control().get_theme_icon("CSharpScript", "EditorIcons")
	var icon_b := EditorInterface.get_base_control().get_theme_icon(status, "EditorIcons")
	var overlay_image := _modulate_image(icon_b.get_image(), color)
	var image := _merge_images_scaled(icon_a.get_image(), Vector2i(0, 0), overlay_image, Vector2i(5, 5))
	return ImageTexture.create_from_image(image)


static func _modulate_texture(texture: Texture2D, color: Color) -> Texture2D:
	var image := _modulate_image(texture.get_image(), color)
	return ImageTexture.create_from_image(image)


static func _modulate_image(image: Image, color: Color) -> Image:
	var data: PackedByteArray = image.data["data"]
	for pixel in range(0, data.size(), 4):
		var pixel_a := _to_color(data, pixel)
		if pixel_a.a8 != 0:
			pixel_a = pixel_a.lerp(color, .9)
		data[pixel + 0] = pixel_a.r8
		data[pixel + 1] = pixel_a.g8
		data[pixel + 2] = pixel_a.b8
		data[pixel + 3] = pixel_a.a8
	var output_image := Image.new()
	output_image.set_data(image.get_width(), image.get_height(), image.has_mipmaps(), image.get_format(), data)
	return output_image


static func _merge_images(image1: Image, offset1: Vector2i, image2: Image, offset2: Vector2i) -> Image:
	## we need to fix the image to have the same size to avoid merge conflicts
	if image1.get_height() < image2.get_height():
		image1.resize(image2.get_width(), image2.get_height())
	# Create a new Image for the merged result
	var merged_image := Image.create(image1.get_width(), image1.get_height(), false, Image.FORMAT_RGBA8)
	merged_image.blit_rect_mask(image1, image2, Rect2(Vector2.ZERO, image1.get_size()), offset1)
	merged_image.blit_rect_mask(image1, image2, Rect2(Vector2.ZERO, image2.get_size()), offset2)
	return merged_image


@warning_ignore("narrowing_conversion")
static func _merge_images_scaled(image1: Image, offset1: Vector2i, image2: Image, offset2: Vector2i) -> Image:
	## we need to fix the image to have the same size to avoid merge conflicts
	if image1.get_height() < image2.get_height():
		image1.resize(image2.get_width(), image2.get_height())
	# Create a new Image for the merged result
	var merged_image := Image.create(image1.get_width(), image1.get_height(), false, image1.get_format())
	merged_image.blend_rect(image1, Rect2(Vector2.ZERO, image1.get_size()), offset1)
	@warning_ignore("narrowing_conversion")
	image2.resize(image2.get_width()/1.3, image2.get_height()/1.3)
	merged_image.blend_rect(image2, Rect2(Vector2.ZERO, image2.get_size()), offset2)
	return merged_image


static func _flip_image(texture: Texture2D, mode: ImageFlipMode) -> Image:
	var flipped_image := Image.new()
	flipped_image.copy_from(texture.get_image())
	if mode == ImageFlipMode.VERITCAL:
		flipped_image.flip_x()
	else:
		flipped_image.flip_y()
	return flipped_image


static func _to_color(data: PackedByteArray, position: int) -> Color:
	var pixel_a := Color()
	pixel_a.r8 = data[position + 0]
	pixel_a.g8 = data[position + 1]
	pixel_a.b8 = data[position + 2]
	pixel_a.a8 = data[position + 3]
	return pixel_a
