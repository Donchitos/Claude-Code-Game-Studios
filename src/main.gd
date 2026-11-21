## Binds the economy config and ClubState signals to the vertical-slice control panel.
extends Control

const CONFIG_PATH: String = "res://data/economy.json"

var _config: Dictionary = {}
var _state: ClubState = null
var _decision_buttons: Array[Button] = []

@onready var week_label: Label = $WeekLabel
@onready var cash_label: Label = $CashLabel
@onready var points_label: Label = $PointsLabel
@onready var facility_label: Label = $FacilityLabel
@onready var escalar_button: Button = $EscalarButton
@onready var contratar_button: Button = $ContratarButton
@onready var melhorar_button: Button = $MelhorarButton
@onready var cortar_button: Button = $CortarButton
@onready var end_panel: Panel = $EndPanel
@onready var result_label: Label = $EndPanel/ResultLabel
@onready var restart_button: Button = $EndPanel/RestartButton

func _ready() -> void:
	_decision_buttons = [escalar_button, contratar_button, melhorar_button, cortar_button]
	_load_config()

	escalar_button.pressed.connect(_on_decision.bind("escalar_titulares"))
	contratar_button.pressed.connect(_on_decision.bind("contratar_reforco"))
	melhorar_button.pressed.connect(_on_decision.bind("melhorar_instalacao"))
	cortar_button.pressed.connect(_on_decision.bind("cortar_gastos"))
	restart_button.pressed.connect(_on_restart_pressed)

	_start_run()

func _load_config() -> void:
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir " + CONFIG_PATH)
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("Configuração de economia inválida: " + CONFIG_PATH)
		return
	_config = parsed as Dictionary

func _start_run() -> void:
	_state = ClubState.new(_config)
	_state.turn_resolved.connect(_on_turn_resolved)
	_state.run_ended.connect(_on_run_ended)
	for button: Button in _decision_buttons:
		button.disabled = false
	end_panel.visible = false
	result_label.text = ""
	_update_labels(_state)

func _update_labels(state: ClubState) -> void:
	week_label.text = "Semana %d" % state.week
	cash_label.text = "Caixa: R$ %d" % state.cash
	points_label.text = "Pontos: %d / %d" % [state.points, int(_config["target_points"])]
	facility_label.text = "Nível: %d | Reforços: %d" % [state.facility_level, state.reinforcements]

func _on_decision(decision: String) -> void:
	_state.apply_decision(decision)

func _on_turn_resolved(state: ClubState, _summary: Dictionary) -> void:
	_update_labels(state)

func _on_run_ended(_state: ClubState, outcome: String) -> void:
	for button: Button in _decision_buttons:
		button.disabled = true
	match outcome:
		"victory":
			result_label.text = "Vitória! Meta cumprida."
		"bankruptcy":
			result_label.text = "Falência! O clube fechou as portas."
		"defeat":
			result_label.text = "Derrota. A meta não foi atingida."
	end_panel.visible = true

func _on_restart_pressed() -> void:
	_start_run()
