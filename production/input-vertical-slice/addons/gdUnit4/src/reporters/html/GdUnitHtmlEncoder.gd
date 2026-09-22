class_name GdUnitHtmlEncoder
extends RefCounted


static func encode(value: String) -> String:
	# & must be replaced first to avoid double-encoding the entities we insert
	return value\
		.replace("&", "&amp;")\
		.replace("<", "&lt;")\
		.replace(">", "&gt;")\
		.replace('"', "&quot;")\
		.replace("'", "&#39;")
