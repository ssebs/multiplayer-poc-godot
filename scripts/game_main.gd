class_name GameMain extends Node

@export var level_scene = preload("res://scenes/level.tscn")

@onready var multiplayer_manager: MultiplayerManager = %MultiplayerManager
@onready var lobby_ui: LobbyUI = %LobbyUI
@onready var text_chat_ui: TextChatUI = %TextChatUI

var level: Node2D

func _ready():
    # UI handlers
    lobby_ui.server_pressed.connect(func():
        multiplayer_manager.start_server()
        lobby_ui.start_btn.show()
    )
    lobby_ui.client_pressed.connect(func(ip_addr: String):
        multiplayer_manager.connect_client(ip_addr)
    )
    # Only host can start game
    lobby_ui.start_pressed.connect(func():
        start_game.rpc()
    )

    # When player connects to lobby, server sends msg for all to update their list
    multiplayer_manager.player_connected.connect(func(id: int, all_players: Array[int]):
        if multiplayer.is_server():
            lobby_ui.set_lobby_players.rpc(all_players)
            
        # Show connected msg
        text_chat_ui.show_player_connected.rpc(id)
    )
    # Show disconnected msg
    multiplayer_manager.player_disconnected.connect(func(id: int):
        text_chat_ui.show_player_disconnected.rpc(id)
    )

    # Reset stuff when the server disconnects you
    multiplayer_manager.server_disconnected.connect(func():
        if level != null:
            level.queue_free()
        lobby_ui.show()
        lobby_ui.clear_lobby_players()
        text_chat_ui.clear_chat()
    )


@rpc("call_local", "reliable")
func start_game():
    lobby_ui.hide()

    level = level_scene.instantiate()
    add_child(level)

    multiplayer_manager.players_spawn_node = level.get_node("Players")
    multiplayer_manager.enemies_spawn_node = level.get_node("Enemies")
    
    multiplayer_manager.spawn_players()

    multiplayer_manager.enemy_spawn_timer.start()
