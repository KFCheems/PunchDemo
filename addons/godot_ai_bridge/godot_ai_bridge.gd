@tool
extends EditorPlugin
## Main plugin for Godot AI Bridge

const WSServer = preload("res://addons/godot_ai_bridge/ws_server.gd")
const MessageHandler = preload("res://addons/godot_ai_bridge/message_handler.gd")

var _ws_server: Node
var _message_handler: RefCounted
var _debugger_plugin: AIBridgeDebuggerPlugin
var _port: int = 6550


func _enter_tree() -> void:
	# Initialize message handler
	_message_handler = MessageHandler.new()
	_message_handler.editor_interface = get_editor_interface()
	_message_handler.undo_redo = get_undo_redo()

	# Initialize debugger plugin to capture output
	_debugger_plugin = AIBridgeDebuggerPlugin.new()
	_debugger_plugin.message_handler = _message_handler
	add_debugger_plugin(_debugger_plugin)

	# Initialize WebSocket server
	_ws_server = WSServer.new()
	_ws_server.port = _port
	_ws_server.message_received.connect(_on_message_received)
	_ws_server.client_connected.connect(_on_client_connected)
	_ws_server.client_disconnected.connect(_on_client_disconnected)

	add_child(_ws_server)

	# Start server
	var err = _ws_server.start()
	if err == OK:
		print("[AI Bridge] Server started on port ", _port)
	elif err == ERR_ALREADY_IN_USE:
		push_warning("[AI Bridge] Port %d is already in use, bridge server was not started." % _port)
	else:
		push_error("[AI Bridge] Failed to start server: " + str(err))


func _exit_tree() -> void:
	if _debugger_plugin:
		remove_debugger_plugin(_debugger_plugin)
	if _ws_server:
		_ws_server.stop()
		_ws_server.queue_free()
	if _message_handler:
		_message_handler.free()


func _on_message_received(peer_id: int, message: String) -> void:
	var response: String = _message_handler.handle_message(message)
	_ws_server.send_message(peer_id, response)


func _on_client_connected(peer_id: int) -> void:
	print("[AI Bridge] Client connected: ", peer_id)


func _on_client_disconnected(peer_id: int) -> void:
	print("[AI Bridge] Client disconnected: ", peer_id)


## Debugger plugin to capture output and errors from running game
class AIBridgeDebuggerPlugin extends EditorDebuggerPlugin:
	var message_handler: RefCounted

	# Known debugger message prefixes
	const CAPTURED_PREFIXES := [
		"debug",      # debug_enter, debug_exit, etc.
		"error",      # script errors
		"output",     # print output
		"stack",      # stack_dump, stack_frame_vars
		"memory",     # memory info
		"performance",# performance stats
		"scene",      # scene tree
		"servers",    # server profiler
	]

	func _has_capture(prefix: String) -> bool:
		# Capture all known prefixes
		for p in CAPTURED_PREFIXES:
			if prefix.begins_with(p):
				return true
		return true  # Actually capture everything to see what comes through

	# Messages to filter out (too noisy)
	const FILTERED_MESSAGES := [
		"game_view:cursor_set_shape",
		"game_view:mouse_over",
	]

	func _capture(message: String, data: Array, _session_id: int) -> bool:
		if not message_handler:
			return false

		# Skip filtered messages
		for filtered in FILTERED_MESSAGES:
			if message == filtered:
				return false

		# Parse based on message type
		match message:
			"output":
				_handle_output(data)
			"error":
				_handle_error(data)
			"debug_enter":
				_handle_debug_enter(data)
			"stack_dump":
				_handle_stack_dump(data)
			"stack_frame_vars":
				pass  # Variable inspection, skip
			"debug_exit":
				message_handler.log_output("[DEBUG] Resumed execution", "debug", "debugger")
			_:
				# Keep unknown debugger packets as debug-level breadcrumbs.
				if data.size() > 0 and not message.begins_with("performance") and not message.begins_with("servers"):
					message_handler.log_output(
						"[MSG:%s] %s" % [message, _format_data(data)],
						"debug",
						"debugger"
					)

		return false  # Let other handlers also process

	func _handle_output(data: Array) -> void:
		for item in data:
			if item is String:
				var clean: String = (item as String).strip_edges()
				if not clean.is_empty():
					message_handler.log_output(clean, "info", "runtime")

	func _handle_error(data: Array) -> void:
		# Error format: [is_warning, function, file, line, error_msg, stack_info...]
		if data.size() >= 5:
			var is_warning: bool = data[0] if data[0] is bool else false
			var func_name: String = str(data[1]) if data.size() > 1 else ""
			var file_path: String = str(data[2]) if data.size() > 2 else ""
			var line_num: int = data[3] if data.size() > 3 and data[3] is int else 0
			var error_msg: String = str(data[4]) if data.size() > 4 else ""

			var prefix := "[WARN]" if is_warning else "[ERROR]"
			var location := ""
			if not file_path.is_empty():
				location = " @ %s:%d" % [file_path.get_file(), line_num]
				if not func_name.is_empty():
					location += " in %s()" % func_name

			message_handler.log_output(
				"%s%s: %s" % [prefix, location, error_msg],
				"warning" if is_warning else "error",
				"runtime"
			)

			message_handler.log_error({
				"type": "warning" if is_warning else "error",
				"file": file_path,
				"line": line_num,
				"function": func_name,
				"message": error_msg
			})
		else:
			message_handler.log_output("[ERROR] %s" % _format_data(data), "error", "runtime")

	func _handle_debug_enter(data: Array) -> void:
		# Debug break: [can_continue, reason, has_stackdump]
		if data.size() >= 2:
			var reason: String = str(data[1]) if data.size() > 1 else "unknown"
			message_handler.log_output("[BREAK] Debugger paused: %s" % reason, "warning", "debugger")

	func _handle_stack_dump(data: Array) -> void:
		message_handler.log_output("[STACK] Call stack:", "debug", "debugger")
		for i in range(0, data.size(), 3):
			if i + 2 < data.size():
				var file: String = str(data[i])
				var line: int = data[i + 1] if data[i + 1] is int else 0
				var func_name: String = str(data[i + 2])
				message_handler.log_output(
					"  → %s:%d in %s()" % [file.get_file(), line, func_name],
					"debug",
					"debugger"
				)

	func _format_data(data: Array) -> String:
		if data.size() == 0:
			return "(empty)"
		if data.size() == 1:
			return str(data[0])
		var parts: PackedStringArray = []
		for item in data:
			parts.append(str(item).left(100))  # Truncate long items
		return ", ".join(parts)

	func _setup_session(session_id: int) -> void:
		var session = get_session(session_id)
		if session:
			session.started.connect(_on_session_started.bind(session_id))
			session.stopped.connect(_on_session_stopped.bind(session_id))

	func _on_session_started(session_id: int) -> void:
		if message_handler:
			message_handler.log_output(
				"[DEBUG] Game started (session %d)" % session_id,
				"info",
				"debugger"
			)

	func _on_session_stopped(session_id: int) -> void:
		if message_handler:
			message_handler.log_output(
				"[DEBUG] Game stopped (session %d)" % session_id,
				"info",
				"debugger"
			)
