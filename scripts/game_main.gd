class_name GameMain extends Node

@export var level_scene = preload("res://scenes/level.tscn")

@onready var multiplayer_manager: MultiplayerManager = %MultiplayerManager
@onready var lobby_ui: LobbyUI = %LobbyUI
@onready var text_chat_ui: TextChatUI = %TextChatUI

var level: Node2D

func _ready():
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
    multiplayer_manager.player_added_to_lobby.connect(func(_id: int, all_players: Array[int]):
        if multiplayer.is_server():
            lobby_ui.set_lobby_players.rpc(all_players)
    )

@rpc("call_local", "reliable")
func start_game():
    lobby_ui.hide()

    level = level_scene.instantiate()
    add_child(level)

    multiplayer_manager.players_spawn_node = level.get_node("Players")
    multiplayer_manager.spawn_players()
