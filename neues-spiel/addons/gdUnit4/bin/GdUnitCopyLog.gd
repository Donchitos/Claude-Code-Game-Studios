#!/usr/bin/env -S godot -s
extends MainLoop

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

# gdlint: disable=max-line-length
const LOG_FRAME_TEMPLATE = """
<!DOCTYPE html>
<html style="display: inline-grid;">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Godot Logging</title>
	<link rel="stylesheet" href="css/styles.css">
</head>

<body style="background-color: #eee;">
	<div class="godot-report-frame"">
${content}
	</div>
</body>
</html>
"""

const NO_LOG_MESSAGE = """
<h3>No logging available!</h3>
</br>
<p>In order for logging to take place, you must activate the Activate file logging option in the project settings.</p>
<p>You can enable the logging under:
<b>Project Settings</b> > <b>Debug</b> > <b>File Logging</b> > <b>Enable File Logging</b> in the project settings.</p>
"""

#warning-ignore-all:return_value_discarded
var _cmd_options := CmdOptions.new([
		CmdOption.new(
			"-rd, --report-directory",
			"-rd <directory>",
			"Specifies the output directory in which the reports are to be written. The default is res://reports/.",
			TYPE_STRING,
			true
		)
	])


var _report_root_path: String
var _current_report_path: String
var _debug_cmd_args := PackedStringArray()


func _init() -> void:
	set_report_directory(GdUnitFileAccess.current_dir() + "reports")
	set_current_report_path()


func _process(_delta: float) -> bool:
	# check if reports exists
	if not reports_available():
		prints("no reports found")
		return true

	# only process if godot logging is enabled
	if not GdUnitSettings.is_log_enabled():
		write_report(NO_LOG_MESSAGE, "")
		return true

	# parse possible custom report path,
	var cmd_parser := CmdArgumentParser.new(_cmd_options, "GdUnitCmdTool.gd")
	# ignore erros and exit quitly
	if cmd_parser.parse(get_cmdline_args(), true).is_error():
		return true
	CmdCommandHandler.new(_cmd_options).register_cb("-rd", set_report_directory)

	var godot_log_file := scan_latest_godot_log()
	var result := read_log_file_content(godot_log_file)
	if result.is_error():
		write_report(result.error_message(), godot_log_file)
		return true
	write_report(result.value_as_string(), godot_log_file)
	return true


func set_current_report_path() -> void:
	# scan for latest report directory
	var iteration := GdUnitFileAccess.find_last_path_index(
		_report_root_path, GdUnitConstants.REPORT_DIR_PREFIX
	)
	_current_report_path = "%s/%s%d" % [_report_root_path, GdUnitConstants.REPORT_DIR_PREFIX, iteration]


func set_report_directory(path: String) -> void:
	_report_root_path = path


func get_log_report_html() -> String:
	return _current_report_path + "/godot_report_log.html"


func reports_available() -> bool:
	return DirAccess.dir_exists_absolute(_report_root_path)


func scan_latest_godot_log() -> String:
	var path := GdUnitSettings.get_log_path().get_base_dir()
	var files_sorted := Array()
	for file in GdUnitFileAccess.scan_dir(path):
		var file_name := "%s/%s" % [path, file]
		files_sorted.append(file_name)
	# sort by name, the name contains the timestamp so we sort at the end by timestamp
	files_sorted.sort()
	return files_sorted.back()


func read_log_file_content(log_file: String) -> GdUnitResult:
	var file := FileAccess.open(log_file, FileAccess.READ)
	if file == null:
		return GdUnitResult.error(
			"Can't find log file '%s'. Error: %s"
			% [log_file, error_string(FileAccess.get_open_error())]
		)
	var content := "<pre>" + file.get_as_text()
	# patch out console format codes
	for color_index in range(0, 256):
		var to_replace := "[38;5;%dm" % color_index
		content = content.replace(to_replace, "")
	content += "</pre>"
	content = content\
		.replace("[0m", "")\
		.replace(GdUnitCSIMessageWriter.CSI_BOLD, "")\
		.replace(GdUnitCSIMessageWriter.CSI_ITALIC, "")\
		.replace(GdUnitCSIMessageWriter.CSI_UNDERLINE, "")
	return GdUnitResult.success(content)


func write_report(content: String, godot_log_file: String) -> GdUnitResult:
	var file := FileAccess.open(get_log_report_html(), FileAccess.WRITE)
	if file == null:
		return GdUnitResult.error(
			"Can't open to write '%s'. Error: %s"
			% [get_log_report_html(), error_string(FileAccess.get_open_error())]
		)
	var report_html := LOG_FRAME_TEMPLATE.replace("${content}", content)
	file.store_string(report_html)
	_update_index_html(godot_log_file)
	return GdUnitResult.success(file)


func _update_index_html(godot_log_file: String) -> void:
	var index_path := "%s/index.html" % _current_report_path
	var index_file := FileAccess.open(index_path, FileAccess.READ_WRITE)
	if index_file == null:
		push_error(
			"Can't add log path '%s' to `%s`. Error: %s"
			% [godot_log_file, index_path, error_string(FileAccess.get_open_error())]
		)
		return
	var content := index_file.get_as_text()\
		.replace("${log_report}", get_log_report_html())\
		.replace("${godot_log_file}", godot_log_file)
	# overide it
	index_file.seek(0)
	index_file.store_string(content)


func get_cmdline_args() -> PackedStringArray:
	if _debug_cmd_args.is_empty():
		return OS.get_cmdline_args()
	return _debug_cmd_args
