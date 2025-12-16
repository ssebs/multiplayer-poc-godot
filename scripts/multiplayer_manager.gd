class_name MultiplayerManager extends Node

signal player_added_to_lobby(id: int, all_players: Array[int])

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

func connect_client(ip_addr: String = "127.0.0.1"):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip_addr, PORT)
    multiplayer.multiplayer_peer = peer

func _on_peer_connected(id: int):
    lobby_players.append(id)
    player_added_to_lobby.emit(id, lobby_players)

func spawn_players():
    if players_spawn_node == null:
        printerr("players_spawn_node == null")
        return

    for p in lobby_players:
        _spawn_player(p)

func _spawn_player(id: int):
    const PLAYER_WIDTH := 66.0
    const SPACING := 10.0

    print("New Player: %s" % id)
    
    var player_to_add = player_scene.instantiate() as NetworkedPlayer
    player_to_add.name = str(id)

    players_spawn_node.add_child(player_to_add, true)
    # Add spawn offset
    var spawn_index := players_spawn_node.get_child_count() - 1
    player_to_add.position.x = spawn_index * (PLAYER_WIDTH + SPACING)
    

func _rm_player(id: int):
    print("Deleting %s" % id)
    if players_spawn_node == null:
        printerr("players_spawn_node == null")
        return
    if not players_spawn_node.has_node(str(id)):
        return
    players_spawn_node.get_node(str(id)).queue_free()
