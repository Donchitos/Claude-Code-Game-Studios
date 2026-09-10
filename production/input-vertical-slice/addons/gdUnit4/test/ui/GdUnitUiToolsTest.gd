# GdUnit generated TestSuite
class_name GdUnitUiToolsTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/ui/GdUnitUiTools.gd'


func test__merge_images_same_size() -> void:
	var image_a := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var image_b := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var output := GdUnitUiTools._merge_images(image_a, Vector2.ZERO, image_b, Vector2.ZERO)

	assert_that(output.get_size()).is_equal(Vector2i(16, 16))


func test__merge_images_different_size() -> void:
	var image_a := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var image_b := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var output := GdUnitUiTools._merge_images(image_a, Vector2.ZERO, image_b, Vector2.ZERO)

	assert_that(output.get_size()).is_equal(Vector2i(16, 16))


func test__merge_images_scaled() -> void:
	var image_a := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var image_b := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var output := GdUnitUiTools._merge_images_scaled(image_a, Vector2.ZERO, image_b, Vector2.ZERO)

	assert_that(output.get_size()).is_equal(Vector2i(16, 16))


func test__merge_images_scaled_different_size() -> void:
	var image_a := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var image_b := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var output := GdUnitUiTools._merge_images_scaled(image_a, Vector2.ZERO, image_b, Vector2.ZERO)

	assert_that(output.get_size()).is_equal(Vector2i(16, 16))
