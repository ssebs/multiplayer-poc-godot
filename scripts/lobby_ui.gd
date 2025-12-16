class_name LobbyUI extends Control

signal server_pressed()
signal client_pressed(ip_addr: String)
signal start_pressed()

@onready var server_btn: Button = %Server
@onready var client_btn: Button = %Client
@onready var start_btn: Button = %Start

@onready var ip_entry: LineEdit = %IPEntry
@onready var lobby_list: VBoxContainer = %LobbyList

func _ready():
    server_btn.pressed.connect(_on_server_pressed)
    client_btn.pressed.connect(_on_client_pressed)
    start_btn.pressed.connect(_on_start_pressed)

    start_btn.hide() # only host should see it

    if OS.is_debug_build():
        _adjust_both_windows()

func _on_server_pressed():
    server_pressed.emit()

func _on_client_pressed():
    client_pressed.emit(ip_entry.text)

func _on_start_pressed():
    start_pressed.emit()


@rpc("call_local", "reliable")
func set_lobby_players(player_names: Array[int]):
    for player_id in player_names:
        var player_name = str(player_id)
        if lobby_list.has_node(player_name):
            continue

        var label = Label.new()
        label.name = player_name
        label.text = player_name
        lobby_list.add_child(label, true)

func clear_lobby_players():
    for child in lobby_list.get_children():
        child.queue_free()

# Hack for debugging
func _adjust_both_windows():
    var offset = 100
    randomize()
    await get_tree().create_timer(randf_range(0, 1)).timeout
    var the_path = 'user://lil_number.tres'
    var save_the_value = func(val):
        var the_file = FileAccess.open(the_path, FileAccess.WRITE)
        the_file.store_64(val)
        the_file.flush()
        the_file.close()
    var read_value = func():
        if FileAccess.file_exists(the_path):
            await get_tree().create_timer(.5).timeout
            var the_file = FileAccess.open(the_path, FileAccess.READ)
            var val = the_file.get_64()
            the_file.close()
            return val
        return 0
    var the_value = await read_value.call()
    save_the_value.call(the_value + 1)
    # get_window().size = get_window().size*0.75
    if (the_value % 2 == 0):
        get_window().position.x = offset
    else:
        get_window().position.x = get_window().size.x + offset
