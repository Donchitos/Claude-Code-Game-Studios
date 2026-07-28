class_name XmlElement
extends RefCounted

var _name :String
# Dictionary[String, String]
var _attributes :Dictionary = {}
var _childs :Array[XmlElement] = []
var _parent :XmlElement = null
var _text :String = ""


func _init(name :String) -> void:
	_name = name


func dispose() -> void:
	for child in _childs:
		child.dispose()
	_childs.clear()
	_attributes.clear()
	_parent = null


func attribute(name :String, value :Variant) -> XmlElement:
	_attributes[name] = str(value)
	return self


func text(p_text :String) -> XmlElement:
	_text = p_text if p_text.ends_with("\n") else p_text + "\n"
	return self


func add_child(child :XmlElement) -> XmlElement:
	_childs.append(child)
	child._parent = self
	return self


func add_childs(childs :Array[XmlElement]) -> XmlElement:
	for child in childs:
		@warning_ignore("return_value_discarded")
		add_child(child)
	return self


func indentation() -> String:
	return "" if _parent == null else _parent.indentation() + "	"


func to_xml() -> String:
	var attributes := ""
	for key in _attributes.keys() as Array[String]:
		attributes += ' {attr}="{value}"'.format({"attr": key, "value": _attributes.get(key)})

	var childs := ""
	for child in _childs:
		childs += child.to_xml()

	return "{_indentation}<{name}{attributes}>\n{childs}{text}{_indentation}</{name}>\n"\
		.format({"name": _name,
			"attributes": attributes,
			"childs": childs,
			"_indentation": indentation(),
			"text": cdata(_text)})


func cdata(p_text :String) -> String:
	return "" if p_text.is_empty() else "<![CDATA[\n{text}]]>\n".format({"text" : p_text})
