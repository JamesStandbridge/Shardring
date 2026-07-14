class_name DebugLog
extends RefCounted


static func info(context: StringName, message: String) -> void:
	if not OS.is_debug_build():
		return

	print("[Shardring][%s] %s" % [context, message])


static func warn(context: StringName, message: String) -> void:
	if not OS.is_debug_build():
		return

	push_warning("[Shardring][%s] %s" % [context, message])
