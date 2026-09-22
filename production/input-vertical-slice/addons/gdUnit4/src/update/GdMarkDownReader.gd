@tool
extends RefCounted

const GdUnitUpdateClient = preload("res://addons/gdUnit4/src/update/GdUnitUpdateClient.gd")

const FONT_H1 := 22
const FONT_H2 := 20
const FONT_H3 := 18
const FONT_H4 := 16
const FONT_H5 := 14
const FONT_H6 := 12

const HORIZONTAL_RULE := "[img=4000x2]res://addons/gdUnit4/src/update/assets/horizontal-line2.png[/img]"
const HEADER_RULE := "[font_size=%d]$1[/font_size]"
const HEADER_CENTERED_RULE := "[font_size=%d][center]$1[/center][/font_size]"

const image_download_folder := "res://addons/gdUnit4/tmp-update/"

const exclude_font_size := "\b(?!(?:(font_size))\b)"

var md_replace_patterns := [
	# comments
	[regex("(?m)^\\n?\\s*<!--[\\s\\S]*?-->\\s*\\n?"), ""],

	# horizontal rules
	[regex("(?m)^[ ]{0,3}---$"), HORIZONTAL_RULE],
	[regex("(?m)^[ ]{0,3}___$"), HORIZONTAL_RULE],
	[regex("(?m)^[ ]{0,3}\\*\\*\\*$"), HORIZONTAL_RULE],

	# headers
	[regex("(?m)^###### (.*)"), HEADER_RULE % FONT_H6],
	[regex("(?m)^##### (.*)"), HEADER_RULE % FONT_H5],
	[regex("(?m)^#### (.*)"), HEADER_RULE % FONT_H4],
	[regex("(?m)^### (.*)"), HEADER_RULE % FONT_H3],
	[regex("(?m)^## (.*)"), (HEADER_RULE + HORIZONTAL_RULE) % FONT_H2],
	[regex("(?m)^# (.*)"), (HEADER_RULE + HORIZONTAL_RULE) % FONT_H1],
	[regex("(?m)^(.+)=={2,}$"), HEADER_RULE % FONT_H1],
	[regex("(?m)^(.+)--{2,}$"), HEADER_RULE % FONT_H2],
	# html headers
	[regex("<h1>((.*?\\R?)+)<\\/h1>"), (HEADER_RULE + HORIZONTAL_RULE) % FONT_H1],
	[regex("<h1[ ]*align[ ]*=[ ]*\"center\">((.*?\\R?)+)<\\/h1>"), (HEADER_CENTERED_RULE + HORIZONTAL_RULE) % FONT_H1],
	[regex("<h2>((.*?\\R?)+)<\\/h2>"), (HEADER_RULE + HORIZONTAL_RULE) % FONT_H2],
	[regex("<h2[ ]*align[ ]*=[ ]*\"center\">((.*?\\R?)+)<\\/h2>"), (HEADER_CENTERED_RULE + HORIZONTAL_RULE) % FONT_H1],
	[regex("<h3>((.*?\\R?)+)<\\/h3>"), HEADER_RULE % FONT_H3],
	[regex("<h3[ ]*align[ ]*=[ ]*\"center\">((.*?\\R?)+)<\\/h3>"), HEADER_CENTERED_RULE % FONT_H3],
	[regex("<h4>((.*?\\R?)+)<\\/h4>"), HEADER_RULE % FONT_H4],
	[regex("<h4[ ]*align[ ]*=[ ]*\"center\">((.*?\\R?)+)<\\/h4>"), HEADER_CENTERED_RULE % FONT_H4],
	[regex("<h5>((.*?\\R?)+)<\\/h5>"), HEADER_RULE % FONT_H5],
	[regex("<h5[ ]*align[ ]*=[ ]*\"center\">((.*?\\R?)+)<\\/h5>"), HEADER_CENTERED_RULE % FONT_H5],
	[regex("<h6>((.*?\\R?)+)<\\/h6>"), HEADER_RULE % FONT_H6],
	[regex("<h6[ ]*align[ ]*=[ ]*\"center\">((.*?\\R?)+)<\\/h6>"), HEADER_CENTERED_RULE % FONT_H6],

	# asterics
	#[regex("(\\*)"), "xxx$1xxx"],

	# extract/compile image references
	[regex("!\\[(.*?)\\]\\[(.*?)\\]"), process_image_references],
	# extract images with path and optional tool tip
	[regex("!\\[(.*?)\\]\\((.*?)(( )+(.*?))?\\)"), process_image],

	# links
	[regex("([!]|)\\[(.+)\\]\\(([^ ]+?)\\)"),  "[url={\"url\":\"$3\"}]$2[/url]"],
	# links with tool tip
	[regex("([!]|)\\[(.+)\\]\\(([^ ]+?)( \"(.+)\")?\\)"),  "[url={\"url\":\"$3\", \"tool_tip\":\"$5\"}]$2[/url]"],
	# links to github, as shorted link
	[regex("(https://github.*/?/(\\S+))"), '[url={"url":"$1", "tool_tip":"$1"}]#$2[/url]'],

	# embeded text
	[regex("(?m)^[ ]{0,3}>(.*?)$"), "[img=50x14]res://addons/gdUnit4/src/update/assets/embedded.png[/img][i]$1[/i]"],

	# italic + bold font
	[regex("[_]{3}(.*?)[_]{3}"), "[i][b]$1[/b][/i]"],
	[regex("[\\*]{3}(.*?)[\\*]{3}"), "[i][b]$1[/b][/i]"],
	# bold font
	[regex("<b>(.*?)<\\/b>"), "[b]$1[/b]"],
	[regex("[_]{2}(.*?)[_]{2}"), "[b]$1[/b]"],
	[regex("[\\*]{2}(.*?)[\\*]{2}"), "[b]$1[/b]"],
	# italic font
	[regex("<i>(.*?)<\\/i>"), "[i]$1[/i]"],
	[regex(exclude_font_size+"_(.*?)_"), "[i]$1[/i]"],
	[regex("\\*(.*?)\\*"), "[i]$1[/i]"],

	# strikethrough font
	[regex("<s>(.*?)</s>"), "[s]$1[/s]"],
	[regex("~~(.*?)~~"), "[s]$1[/s]"],
	[regex("~(.*?)~"), "[s]$1[/s]"],

	# handling lists
	# using an image for dots
	[regex("(?m)^[ ]{0,1}[*\\-+] (.*)$"), list_replace(0)],
	[regex("(?m)^[ ]{2,3}[*\\-+] (.*)$"), list_replace(1)],
	[regex("(?m)^[ ]{4,5}[*\\-+] (.*)$"), list_replace(2)],
	[regex("(?m)^[ ]{6,7}[*\\-+] (.*)$"), list_replace(3)],
	[regex("(?m)^[ ]{8,9}[*\\-+] (.*)$"), list_replace(4)],

	# code
	[regex("``([\\s\\S]*?)``"), code_block("$1")],
	[regex("`([\\s\\S]*?)`{1,2}"), code_block("$1")],
]

var code_block_patterns := [
	# code blocks, code blocks looks not like code blocks in richtext
	[regex("```(javascript|python|shell|gdscript|gd)([\\s\\S]*?\n)```"), code_block("$2", true)],
]

var _img_replace_regex := RegEx.new()
var _image_urls := PackedStringArray()
var _on_table_tag := false
var _client: GdUnitUpdateClient


static func regex(pattern: String) -> RegEx:
	var regex_ := RegEx.new()
	var err := regex_.compile(pattern)
	if err != OK:
		push_error("error '%s' checked pattern '%s'" % [err, pattern])
		return null
	return regex_


func _init() -> void:
	@warning_ignore("return_value_discarded")
	_img_replace_regex.compile("\\[img\\]((.*?))\\[/img\\]")


func set_http_client(client: GdUnitUpdateClient) -> void:
	_client = client


@warning_ignore("return_value_discarded")
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# finally remove_at the downloaded images
		for image in _image_urls:
			DirAccess.remove_absolute(image)
			DirAccess.remove_absolute(image + ".import")


func list_replace(indent: int) -> String:
	var replace_pattern := "[img=12x12]res://addons/gdUnit4/src/update/assets/dot2.png[/img]" if indent %2 else "[img=12x12]res://addons/gdUnit4/src/update/assets/dot1.png[/img]"
	replace_pattern += " $1"

	for index in indent:
		replace_pattern = replace_pattern.insert(0, "   ")
	return replace_pattern


func code_block(replace: String, border: bool = false) -> String:
	if border:
		return """
			[img=1400x14]res://addons/gdUnit4/src/update/assets/border_top.png[/img]
			[indent][color=GRAY][font_size=16]%s[/font_size][/color][/indent]
			[img=1400x14]res://addons/gdUnit4/src/update/assets/border_bottom.png[/img]
			""".dedent() % replace
	return "[code][bgcolor=DARK_SLATE_GRAY][color=GRAY][font_size=16]%s[/font_size][/color][/bgcolor][/code]" % replace


func convert_text(input: String) -> String:
	input = process_tables(input)

	for pattern: Array in md_replace_patterns:
		var regex_: RegEx = pattern[0]
		var bb_replace: Variant = pattern[1]
		if bb_replace is Callable:
			@warning_ignore("unsafe_method_access")
			input = await bb_replace.call(regex_, input)
		else:
			@warning_ignore("unsafe_cast")
			input = regex_.sub(input, bb_replace as String, true)
	return input


func convert_code_block(input: String) -> String:
	for pattern: Array in code_block_patterns:
		var regex_: RegEx = pattern[0]
		var bb_replace: Variant = pattern[1]
		if bb_replace is Callable:
			@warning_ignore("unsafe_method_access")
			input = await bb_replace.call(regex_, input)
		else:
			@warning_ignore("unsafe_cast")
			input = regex_.sub(input, bb_replace as String, true)
	return input


func to_bbcode(input: String) -> String:
	var re := regex("(?m)```[\\s\\S]*?```")
	var current_pos := 0
	var as_bbcode := ""

	# we split by code blocks to handle this blocks customized
	for result in re.search_all(input):
		# Add text before code block
		if result.get_start() > current_pos:
			as_bbcode += await convert_text(input.substr(current_pos, result.get_start() - current_pos))
		# Add code block
		as_bbcode += await convert_code_block(result.get_string())
		current_pos = result.get_end()

	# Add remaining text after last code block
	if current_pos < input.length():
		as_bbcode += await convert_text(input.substr(current_pos))
	return as_bbcode


func process_tables(input: String) -> String:
	var bbcode := PackedStringArray()
	var lines: Array[String] = Array(input.split("\n") as Array, TYPE_STRING, "", null)
	while not lines.is_empty():
		if is_table(lines[0]):
			bbcode.append_array(parse_table(lines))
			continue
		@warning_ignore("return_value_discarded", "unsafe_cast")
		bbcode.append(lines.pop_front() as String)
	return "\n".join(bbcode)


class GdUnitMDReaderTable:
	var _columns: int
	var _rows: Array[Row] = []

	class Row:
		var _cells := PackedStringArray()


		func _init(cells: PackedStringArray, columns: int) -> void:
			_cells = cells
			for i in range(_cells.size(), columns):
				@warning_ignore("return_value_discarded")
				_cells.append("")


		func to_bbcode(cell_sizes: PackedInt32Array, bold: bool) -> String:
			var cells := PackedStringArray()
			for cell_index in _cells.size():
				var cell: String = _cells[cell_index]
				if cell.strip_edges() == "--":
					cell = create_line(cell_sizes[cell_index])
				if bold:
					cell = "[b]%s[/b]" % cell
				@warning_ignore("return_value_discarded")
				cells.append("[cell]%s[/cell]" % cell)
			return "|".join(cells)


		func create_line(length: int) -> String:
			var line := ""
			for i in length:
				line += "-"
			return line


	func _init(columns: int) -> void:
		_columns = columns


	func parse_row(line :String) -> bool:
		# is line containing cells?
		if line.find("|") == -1:
			return false
		_rows.append(Row.new(line.split("|"), _columns))
		return true


	func calculate_max_cell_sizes() -> PackedInt32Array:
		var cells_size := PackedInt32Array()
		for column in _columns:
			@warning_ignore("return_value_discarded")
			cells_size.append(0)

		for row_index in _rows.size():
			var row: Row = _rows[row_index]
			for cell_index in row._cells.size():
				var cell_size: int = cells_size[cell_index]
				var size := row._cells[cell_index].length()
				if size > cell_size:
					cells_size[cell_index] = size
		return cells_size


	@warning_ignore("return_value_discarded")
	func to_bbcode() -> PackedStringArray:
		var cell_sizes := calculate_max_cell_sizes()
		var bb_code := PackedStringArray()

		bb_code.append("[table=%d]" % _columns)
		for row_index in _rows.size():
			bb_code.append(_rows[row_index].to_bbcode(cell_sizes, row_index==0))
		bb_code.append("[/table]\n")
		return bb_code


func parse_table(lines: Array) -> PackedStringArray:
	var line: String = lines[0]
	var table := GdUnitMDReaderTable.new(line.count("|") + 1)
	while not lines.is_empty():
		line = lines.pop_front()
		if not table.parse_row(line):
			break
	return table.to_bbcode()


func is_table(line: String) -> bool:
	return line.find("|") != -1


func open_table(line: String) -> String:
	_on_table_tag = true
	return "[table=%d]" % (line.count("|") + 1)


func close_table() -> String:
	_on_table_tag = false
	return "[/table]"


func extract_cells(line: String, bold := false) -> String:
	var cells := ""
	for cell in line.split("|"):
		if bold:
			cell = "[b]%s[/b]" % cell
		cells += "[cell]%s[/cell]" % cell
	return cells


func process_image_references(p_regex: RegEx, p_input: String) -> String:
	#return p_input

	# exists references?
	var matches := p_regex.search_all(p_input)
	if matches.is_empty():
		return p_input
	# collect image references and remove_at it
	var references := Dictionary()
	var link_regex := regex("\\[(\\S+)\\]:(\\S+)([ ]\"(.*)\")?")
	# create copy of original source to replace checked it
	var input := p_input.replace("\r", "")
	var extracted_references :=  p_input.replace("\r", "")
	for reg_match in link_regex.search_all(input):
		var line := reg_match.get_string(0) + "\n"
		var ref := reg_match.get_string(1)
		#var topl_tip = reg_match.get_string(4)
		# collect reference and url
		references[ref] = reg_match.get_string(2)
		extracted_references = extracted_references.replace(line, "")

	# replace image references by collected url's
	for reference_key: String in references.keys():
		var regex_key := regex("\\](\\[%s\\])" % reference_key)
		for reg_match in regex_key.search_all(extracted_references):
			var ref: String = reg_match.get_string(0)
			var image_url: String = "](%s)" % references.get(reference_key)
			extracted_references = extracted_references.replace(ref, image_url)
	return extracted_references


@warning_ignore("return_value_discarded")
func process_image(p_regex: RegEx, p_input: String) -> String:
	#return p_input
	var to_replace := PackedStringArray()
	var tool_tips :=  PackedStringArray()
	# find all matches
	var matches := p_regex.search_all(p_input)
	if matches.is_empty():
		return p_input
	for reg_match in matches:
		# grap the parts to replace and store temporay because a direct replace will distort the offsets
		to_replace.append(p_input.substr(reg_match.get_start(0), reg_match.get_end(0)))
		# grap optional tool tips
		tool_tips.append(reg_match.get_string(5))
	# finally replace all findings
	for replace in to_replace:
		var re := p_regex.sub(replace, "[img]$2[/img]")
		p_input = p_input.replace(replace, re)
	return await _process_external_image_resources(p_input)


func _process_external_image_resources(input: String) -> String:
	@warning_ignore("return_value_discarded")
	DirAccess.make_dir_recursive_absolute(image_download_folder)
	# scan all img for external resources and download it
	for value in _img_replace_regex.search_all(input):
		if value.get_group_count() >= 1:
			var image_url: String = value.get_string(1)
			# if not a local resource we need to download it
			if image_url.begins_with("http"):
				if OS.is_stdout_verbose():
					prints("download image:", image_url)
				var response := await _client.request_image(image_url)
				if response.status() == 200:
					var image := Image.new()
					var error := image.load_png_from_buffer(response.get_body())
					if error != OK:
						prints("Error creating image from response", error)
					# replace characters where format characters
					var new_url := image_download_folder + image_url.get_file().replace("_", "-")
					if new_url.get_extension() != 'png':
						new_url = new_url + '.png'
					var err := image.save_png(new_url)
					if err:
						push_error("Can't save image to '%s'. Error: %s" % [new_url, error_string(err)])
					@warning_ignore("return_value_discarded")
					_image_urls.append(new_url)
					input = input.replace(image_url, new_url)
	return input
