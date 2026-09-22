extends Node
## Original offline-generated score, with bounded polyphony and per-cue throttles.
var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var settings: Dictionary = {"master": 0.8, "music": 0.65, "sfx": 0.7}
var last: Dictionary = {}
var current := ""
var streams: Dictionary = {}

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	for cue in ["menu", "battle", "boss", "boss_cue", "shot", "hit", "kill", "level", "win", "lose", "ui"]:
		streams[cue] = load("res://assets/audio/campaign/" + cue + ".wav")
	for i in 6:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

## Applies all three independent mix controls, including exact silence.
func apply_settings(value: Dictionary) -> void:
	settings = value.duplicate()
	if music_player != null:
		music_player.volume_db = linear_to_db(maxf(0.00001, float(settings.master) * float(settings.music)))
		music_player.stream_paused = float(settings.master) * float(settings.music) == 0
	for voice in voices:
		voice.volume_db = linear_to_db(maxf(0.00001, float(settings.master) * float(settings.sfx)))

## Switches seamless loops only when the requested musical scene changes.
func music(cue: String) -> void:
	if cue == current or music_player == null:
		return
	var stream: AudioStreamWAV = streams.get(cue)
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	music_player.stream = stream
	current = cue
	if DisplayServer.get_name() != "headless":
		music_player.play()
	apply_settings(settings)

## Plays at most six simultaneous effects and rate-limits repeated combat cues.
func effect(cue: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if float(settings.master) * float(settings.sfx) <= 0:
		return
	if cue not in ["shot", "hit", "kill", "level", "boss", "win", "lose", "ui"]:
		return
	var now := Time.get_ticks_msec()
	if now - int(last.get(cue, -1000)) < (180 if cue in ["shot", "hit", "kill"] else 90):
		return
	last[cue] = now
	for voice in voices:
		if not voice.playing:
			voice.stream = streams.get("boss_cue" if cue == "boss" else cue)
			voice.play()
			return

## Retires native playback before the owning scene or test tree is released.
func shutdown() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()

func _exit_tree() -> void:
	shutdown()
