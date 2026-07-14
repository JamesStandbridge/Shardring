extends GutTest


func test_initial_state_is_ready() -> void:
	var run_controller := RunController.new()

	assert_eq(run_controller.get_state(), RunController.RunState.READY)
	assert_eq(run_controller.get_survival_time_seconds(), 0.0)
	assert_eq(run_controller.get_last_death_reason(), &"")

	run_controller.free()


func test_start_run_enters_playing_and_resets_runtime_state() -> void:
	var run_controller := RunController.new()

	run_controller.start_run()
	run_controller._physics_process(1.0)
	run_controller.register_death(&"test_death")
	run_controller.start_run()

	assert_eq(run_controller.get_state(), RunController.RunState.PLAYING)
	assert_eq(run_controller.get_survival_time_seconds(), 0.0)
	assert_eq(run_controller.get_last_death_reason(), &"")

	run_controller.free()


func test_survival_time_advances_only_while_playing() -> void:
	var run_controller := RunController.new()

	run_controller._physics_process(2.0)
	assert_eq(run_controller.get_survival_time_seconds(), 0.0)

	run_controller.start_run()
	run_controller._physics_process(1.25)
	assert_gt(run_controller.get_survival_time_seconds(), 1.24)
	assert_lt(run_controller.get_survival_time_seconds(), 1.26)

	run_controller.free()


func test_death_freezes_timer_and_keeps_reason() -> void:
	var run_controller := RunController.new()

	run_controller.start_run()
	run_controller._physics_process(2.0)
	run_controller.register_death(&"fell")
	var frozen_time := run_controller.get_survival_time_seconds()
	run_controller._physics_process(10.0)

	assert_eq(run_controller.get_state(), RunController.RunState.DEAD)
	assert_eq(run_controller.get_last_death_reason(), &"fell")
	assert_eq(run_controller.get_survival_time_seconds(), frozen_time)

	run_controller.free()


func test_restart_run_starts_a_clean_playing_run() -> void:
	var run_controller := RunController.new()

	run_controller.start_run()
	run_controller._physics_process(3.0)
	run_controller.register_death(&"projectile")
	run_controller.restart_run()

	assert_eq(run_controller.get_state(), RunController.RunState.PLAYING)
	assert_eq(run_controller.get_survival_time_seconds(), 0.0)
	assert_eq(run_controller.get_last_death_reason(), &"")

	run_controller.free()
