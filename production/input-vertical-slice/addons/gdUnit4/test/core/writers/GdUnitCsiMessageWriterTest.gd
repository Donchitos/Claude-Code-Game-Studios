# GdUnit generated TestSuite
extends GdUnitTestSuite


func test_bbcode_tags_to_csi_codes_empty() -> void:
	var csi_formatted := GdUnitCSIMessageWriter.new()._bbcode_tags_to_csi_codes("")
	assert_str(csi_formatted).is_empty()


func test_bbcode_tags_to_csi_codes_color() -> void:
	var bbcode:= "[color=green]line [/color][color=aqua]9:[/color] [color=#CD5C5C]Expecting:[/color]\n"
	var csi_formatted := GdUnitCSIMessageWriter.new()._bbcode_tags_to_csi_codes(bbcode)
	assert_str(csi_formatted)\
		.is_equal("[38;2;0;255;0mline [0m[38;2;0;255;255m9:[0m [38;2;205;92;92mExpecting:[0m\n")


func test_bbcode_tags_to_csi_codes_color_and_bgcolor() -> void:
	var bbcode:= "[color=#1E90FF]This is a[bgcolor=#00ff004d][color=white]n[/color][/bgcolor] test"\
		+ " [bgcolor=#ff00004d][color=white]m[/color][/bgcolor][bgcolor=#00ff004d][color=white]M[/color][/bgcolor]essage[/color]"
	var csi_formatted := GdUnitCSIMessageWriter.new()._bbcode_tags_to_csi_codes(bbcode)
	assert_str(csi_formatted)\
		.is_equal("[38;2;30;144;255mThis is a[48;2;0;77;0m[38;2;255;255;255mn[0m[38;2;30;144;255m[48;2;0;77;0m[0m[38;2;30;144;255m test"\
		 + " [48;2;77;0;0m[38;2;255;255;255mm[0m[38;2;30;144;255m[48;2;77;0;0m[0m[38;2;30;144;255m[48;2;0;77;0m[38;2;255;255;255mM"\
		 + "[0m[38;2;30;144;255m[48;2;0;77;0m[0m[38;2;30;144;255message[0m")


func test_bbcode_tags_to_csi_codes_text_styles() -> void:
	var csi_formatted := GdUnitCSIMessageWriter.new()._bbcode_tags_to_csi_codes("This [b]is[/b] a [i]message[/i]")
	assert_str(csi_formatted)\
		.is_equal("This [1mis[0m a [3mmessage[0m")
