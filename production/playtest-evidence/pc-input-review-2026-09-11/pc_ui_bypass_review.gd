extends SceneTree
func _initialize():
    run.call_deferred()
func event_key(code):
    var e=InputEventKey.new()
    e.keycode=code
    e.physical_keycode=code
    e.pressed=true
    Input.parse_input_event(e)
    e=e.duplicate()
    e.pressed=false
    Input.parse_input_event(e)
func run():
    var game=load('res://src/core/GameRoot.tscn').instantiate()
    game.transient_profile=true
    root.add_child(game)
    await game.boot_completed
    game.set_physics_process(false)
    print('DEFAULT_ACCEPT ',InputMap.action_get_events('ui_accept'))
    var joy=InputEventJoypadButton.new()
    joy.device=919
    joy.button_index=JOY_BUTTON_A
    joy.pressed=true
    print('UNKNOWN_KNOWN ',Input.is_joy_known(919),' META ',PcMetaInput.action_for(joy))
    Input.parse_input_event(joy)
    joy=joy.duplicate()
    joy.pressed=false
    Input.parse_input_event(joy)
    await process_frame
    await process_frame
    print('UNKNOWN_AFTER_HOME ',game.state,' generation ',game.battle_generation)
    if game.current_battle == null:
        await game.request_start_battle(10,false)
    game.current_battle.pending_upgrade=true
    game.request_pause(true)
    print('MODAL_INITIAL ',root.gui_get_focus_owner().name)
    for i in 6:
        event_key(KEY_UP)
        print('UP_FOCUS ',root.gui_get_focus_owner().name)
    for i in 6:
        event_key(KEY_DOWN)
        print('DOWN_FOCUS ',root.gui_get_focus_owner().name)
    game.queue_free()
    await process_frame
    quit()
