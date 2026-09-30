extends Node
## All sound is made in code when the game starts: short marimba-like tones and
## two looping tunes. There are no audio files to license or download.
## Loss and error sounds are soft on purpose, never buzzers.

const RATE := 22050
const A4 := 440.0

var sfx_on: bool = true
var music_on: bool = true

var _players: Array = []
var _music_player: AudioStreamPlayer
var _sounds: Dictionary = {}
var _tracks: Dictionary = {}
var _current_track: String = ""


func _ready() -> void:
	_sounds = {
		"click": _seq([[0.0, 880.0, 0.08, 0.5]]),
		"snap": _seq([[0.0, 300.0, 0.09, 0.6], [0.02, 600.0, 0.07, 0.3]]),
		"collect": _seq([[0.0, 784.0, 0.15, 0.5], [0.09, 1047.0, 0.3, 0.5]]),
		"success": _seq([[0.0, 523.0, 0.2, 0.5], [0.09, 659.0, 0.2, 0.5], [0.18, 784.0, 0.2, 0.5], [0.27, 1047.0, 0.45, 0.55]]),
		"miss": _seq([[0.0, 392.0, 0.25, 0.35, "soft"], [0.16, 330.0, 0.35, 0.35, "soft"]]),
		"win": _seq([[0.0, 523.0, 0.18, 0.5], [0.12, 659.0, 0.18, 0.5], [0.24, 784.0, 0.18, 0.5], [0.4, 659.0, 0.12, 0.5], [0.5, 784.0, 0.12, 0.5], [0.62, 1047.0, 0.6, 0.6]]),
		"lose": _seq([[0.0, 330.0, 0.3, 0.3, "soft"], [0.28, 294.0, 0.45, 0.3, "soft"]]),
		"pest": _seq([[0.0, 220.0, 0.12, 0.4], [0.1, 180.0, 0.18, 0.4]]),
		"whistle": _seq([[0.0, 1320.0, 0.25, 0.35, "soft"], [0.2, 1760.0, 0.3, 0.35, "soft"]]),
	}
	_tracks = {
		"calm": _tune(96.0, [0, 2, 4, 2, 5, 4, 2, 0, 3, 2, 0, 2, 4, 5, 4, 2], [0, 0, 3, 3], 0.22),
		"race": _tune(132.0, [4, 5, 7, 5, 4, 2, 4, 5, 7, 9, 7, 5, 4, 2, 0, 2], [0, 3, 4, 3], 0.22),
	}
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -14.0
	add_child(_music_player)


func sfx(name: String) -> void:
	if not sfx_on or not _sounds.has(name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sounds[name]
			p.play()
			return


## "calm", "race" or "" to stop.
func music(name: String) -> void:
	_current_track = name
	_apply_music()


func set_flags(sfx_enabled: bool, music_enabled: bool) -> void:
	sfx_on = sfx_enabled
	music_on = music_enabled
	_apply_music()


func _apply_music() -> void:
	if _music_player == null:
		return
	if music_on and _tracks.has(_current_track):
		if _music_player.stream != _tracks[_current_track] or not _music_player.playing:
			_music_player.stream = _tracks[_current_track]
			_music_player.play()
	else:
		_music_player.stop()


## Read text aloud with the device's voice, when it has one.
func speak(text: String) -> bool:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return false
	var voices := DisplayServer.tts_get_voices_for_language("en")
	if voices.is_empty():
		return false
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voices[0])
	return true


## --- synthesis -----------------------------------------------------------

## Mix notes into one clip. A note is [start_s, freq_hz, length_s, volume, kind].
func _seq(notes: Array) -> AudioStreamWAV:
	var total := 0.0
	for n in notes:
		total = maxf(total, float(n[0]) + float(n[2]))
	var buf := PackedFloat32Array()
	buf.resize(int(total * RATE) + 1)
	for n in notes:
		_add_note(buf, float(n[0]), float(n[1]), float(n[2]), float(n[3]), n[4] if n.size() > 4 else "pluck")
	return _to_stream(buf, false)


func _add_note(buf: PackedFloat32Array, start: float, freq: float, length: float, vol: float, kind: String) -> void:
	var first := int(start * RATE)
	var count := int(length * RATE)
	for i in count:
		var idx := first + i
		if idx >= buf.size():
			break
		var t := float(i) / RATE
		var env: float
		var wave: float
		if kind == "soft":
			env = minf(1.0, t / 0.04) * exp(-3.0 * t / length)
			wave = sin(TAU * freq * t)
		else:
			env = exp(-7.0 * t / length) * minf(1.0, t / 0.004)
			wave = sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 4.0 * t) * exp(-20.0 * t)
		buf[idx] += wave * env * vol * 0.5


## A looping tune from scale degrees of a major pentatonic scale.
func _tune(bpm: float, melody: Array, bass: Array, vol: float) -> AudioStreamWAV:
	var scale := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]  # semitones above C4
	var beat := 60.0 / bpm
	var notes: Array = []
	for i in melody.size():
		var semis: int = scale[int(melody[i]) % scale.size()]
		notes.append([i * beat * 0.5, 261.63 * pow(2.0, semis / 12.0), beat * 0.6, vol])
	for i in bass.size():
		var semis: int = scale[int(bass[i]) % scale.size()] - 12
		notes.append([i * beat * 2.0, 261.63 * pow(2.0, semis / 12.0), beat * 1.6, vol * 1.2, "soft"])
	var stream := _seq(notes)
	var length := float(melody.size()) * beat * 0.5
	# pad or trim to exactly the loop length so it repeats cleanly
	var samples := int(length * RATE)
	var data := stream.data
	data.resize(samples * 2)
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


func _to_stream(buf: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := clampi(int(buf[i] * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return s


## For tests: the loudest sample in a stream, 0 to 1.
static func peak_of(stream: AudioStreamWAV) -> float:
	var peak := 0
	var data := stream.data
	for i in range(0, data.size() - 1, 2):
		peak = maxi(peak, absi(data.decode_s16(i)))
	return float(peak) / 32767.0
