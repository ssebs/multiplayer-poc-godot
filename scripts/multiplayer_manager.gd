class_name MultiplayerManager extends Node

signal player_added_to_lobby(id: int)

const PORT: int = 42069

@export var player_scene = preload("res://scenes/networked_player.tscn")
@export var game_main: GameMain

var players_spawn_node: Node2D
var lobby_players: Array[int] = []

func start_server():
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(PORT)
    multiplayer.multiplayer_peer = peer

    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_rm_player)

    _on_peer_connected(1)

func _on_peer_connected(id: int):
    lobby_players.append(id)
    player_added_to_lobby.emit(id)

func connect_client(ip_addr: String = "127.0.0.1"):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip_addr, PORT)
    multiplayer.multiplayer_peer = peer

func spawn_players():
    if players_spawn_node == null:
        printerr("players_spawn_node == null")
        return

    for p in lobby_players:
        _add_player_to_game(p)

func _add_player_to_game(id: int):
    print("New Player: %s" % id)
    var player_to_add = player_scene.instantiate()
    player_to_add.name = str(id)

    players_spawn_node.add_child(player_to_add, true)
    # TODO: add spawn offset

func _rm_player(id: int):
    print("Deleting %s" % id)

    if not players_spawn_node.has_node(str(id)):
        return
    players_spawn_node.get_node(str(id)).queue_free()
