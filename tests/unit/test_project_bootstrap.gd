extends GutTest


func test_rules_document_is_present() -> void:
	assert_true(
		FileAccess.file_exists("res://RULES.md"),
		"RULES.md must remain the gameplay source of truth."
	)


func test_game_events_autoload_exists() -> void:
	assert_not_null(GameEvents)
