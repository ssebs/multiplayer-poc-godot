extends Control

@onready var server_btn: Button = %Server
@onready var client_btn: Button = %Client
@onready var ip_entry: LineEdit = %IPEntry

func _ready():
    server_btn.pressed.connect(_on_server_pressed)
    client_btn.pressed.connect(_on_client_pressed)

    if OS.is_debug_build():
        _adjust_both_windows()

func _on_server_pressed():
    self.hide()
    MultiplayerManager.start_server()

func _on_client_pressed():
    self.hide()
    MultiplayerManager.start_client(ip_entry.text)


# Hack
func _adjust_both_windows():
    var offset = 100
    randomize()
    await get_tree().create_timer(randf_range(0,1)).timeout
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
