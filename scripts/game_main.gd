class_name GameMain extends Node

@export var level_scene = preload("res://scenes/level.tscn")

@onready var multiplayer_manager: MultiplayerManager = %MultiplayerManager
@onready var lobby_ui: LobbyUI = %LobbyUI
@onready var text_chat_ui: TextChatUI = %TextChatUI

var level: Node2D

func _ready():
    lobby_ui.server_pressed.connect(multiplayer_manager.start_server)
    lobby_ui.client_pressed.connect(func(ip_addr: String):
        multiplayer_manager.connect_client(ip_addr)
    )
    lobby_ui.start_pressed.connect(start_game)

    multiplayer_manager.player_added_to_lobby.connect(func(id: int): 
        lobby_ui.add_to_lobby(str(id))
        lobby_ui.start_btn.show()
    )


func start_game():
    lobby_ui.hide()

    level = level_scene.instantiate()
    add_child(level)

    multiplayer_manager.players_spawn_node = level.get_node("Players")
    
    # Join server as a client
    multiplayer_manager.spawn_players()
