# It connects to all signals of given emitter and collects received signals and arguments
# The collected signals are cleand finally when the emitter is freed.
class_name GdUnitSignalCollector
extends RefCounted

const NO_ARG :Variant = GdUnitConstants.NO_ARG
const SIGNAL_BLACK_LIST = []#["tree_exiting", "tree_exited", "child_exiting_tree"]

# {
#	emitter<Object> : {
#		signal_name<String> : [signal_args<Array>],
#		...
#	}
# }
var _collected_signals :Dictionary = {}


func clear() -> void:
	for emitter :Object in _collected_signals.keys():
		if is_instance_valid(emitter):
			unregister_emitter(emitter)


# connect to all possible signals defined by the emitter
# prepares the signal collection to store received signals and arguments
func register_emitter(emitter: Object, force_recreate := false) -> void:
	if is_instance_valid(emitter):
		# check emitter is already registerd
		if _collected_signals.has(emitter):
			if not force_recreate:
				return
			# If the flag recreate is set to true, emitters that are already registered must be deregistered before recreating,
			# otherwise signals that have already been collected will be evaluated.
			unregister_emitter(emitter)

		_collected_signals[emitter] = Dictionary()
		# connect to 'tree_exiting' of the emitter to finally release all acquired resources/connections.
		if emitter is Node and !(emitter as Node).tree_exiting.is_connected(unregister_emitter):
			(emitter as Node).tree_exiting.connect(unregister_emitter.bind(emitter))
		# connect to all signals of the emitter we want to collect
		for signal_def in emitter.get_signal_list():
			var signal_name :String = signal_def["name"]
			# set inital collected to empty
			if not is_signal_collecting(emitter, signal_name):
				_collected_signals[emitter][signal_name] = Array()
			if SIGNAL_BLACK_LIST.find(signal_name) != -1:
				continue
			if !emitter.is_connected(signal_name, _on_signal_emmited):
				var err := emitter.connect(signal_name, _on_signal_emmited.bind(emitter, signal_name))
				if err != OK:
					push_error("Can't connect to signal %s on %s. Error: %s" % [signal_name, emitter, error_string(err)])


# unregister all acquired resources/connections, otherwise it ends up in orphans
# is called when the emitter is removed from the parent
func unregister_emitter(emitter :Object) -> void:
	if is_instance_valid(emitter):
		for signal_def in emitter.get_signal_list():
			var signal_name :String = signal_def["name"]
			if emitter.is_connected(signal_name, _on_signal_emmited):
				emitter.disconnect(signal_name, _on_signal_emmited.bind(emitter, signal_name))
		@warning_ignore("return_value_discarded")
		_collected_signals.erase(emitter)


# receives the signal from the emitter with all emitted signal arguments and additional the emitter and signal_name as last two arguements
func _on_signal_emmited(
	arg0 :Variant= NO_ARG,
	arg1 :Variant= NO_ARG,
	arg2 :Variant= NO_ARG,
	arg3 :Variant= NO_ARG,
	arg4 :Variant= NO_ARG,
	arg5 :Variant= NO_ARG,
	arg6 :Variant= NO_ARG,
	arg7 :Variant= NO_ARG,
	arg8 :Variant= NO_ARG,
	arg9 :Variant= NO_ARG,
	arg10 :Variant= NO_ARG,
	arg11 :Variant= NO_ARG) -> void:
	var signal_args :Array = GdArrayTools.filter_value([arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11], NO_ARG)
	# extract the emitter and signal_name from the last two arguments (see line 61 where is added)
	var signal_name :String = signal_args.pop_back()
	var emitter :Object = signal_args.pop_back()
	#prints("_on_signal_emmited:", emitter, signal_name, signal_args)
	if is_signal_collecting(emitter, signal_name):
		@warning_ignore("unsafe_cast")
		(_collected_signals[emitter][signal_name] as Array).append(signal_args)


func reset_received_signals(emitter: Object, signal_name: String, signal_args: Array) -> void:
	#_debug_signal_list("before claer");
	if _collected_signals.has(emitter):
		var signals_by_emitter :Dictionary = _collected_signals[emitter]
		if signals_by_emitter.has(signal_name):
			var received_args: Array = _collected_signals[emitter][signal_name]
			# We iterate backwarts over to received_args to remove matching args.
			# This will avoid array corruption see comment on `erase` otherwise we need a timeconsuming duplicate before
			for arg_pos: int in range(received_args.size()-1, -1, -1):
				var arg: Variant = received_args[arg_pos]
				if GdObjects.equals(arg, signal_args):
					received_args.remove_at(arg_pos)
	#_debug_signal_list("after claer");


func is_signal_collecting(emitter: Object, signal_name: String) -> bool:
	@warning_ignore("unsafe_cast")
	return _collected_signals.has(emitter) and (_collected_signals[emitter] as Dictionary).has(signal_name)


func match(emitter: Object, signal_name: String, args: Array) -> bool:
	#prints("match", signal_name,  _collected_signals[emitter][signal_name]);
	if _collected_signals.is_empty() or not _collected_signals.has(emitter):
		return false
	for received_args :Variant in _collected_signals[emitter][signal_name]:
		#prints("testing", signal_name, received_args, "vs", args)
		if GdObjects.equals(received_args, args):
			return true
	return false


func _debug_signal_list(message :String) -> void:
	prints("-----", message, "-------")
	prints("senders {")
	for emitter :Object in _collected_signals:
		prints("\t", emitter)
		for signal_name :String in _collected_signals[emitter]:
			var args :Variant = _collected_signals[emitter][signal_name]
			prints("\t\t", signal_name, args)
	prints("}")
