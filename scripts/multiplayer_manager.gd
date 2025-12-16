class_name MultiplayerManager extends Node

signal player_connected(id: int, all_players: Array[int])
signal player_disconnected(id: int)
signal server_disconnected()

const PORT: int = 42069

@export var player_scene = preload("res://scenes/networked_player.tscn")
@export var game_main: GameMain

var players_spawn_node: Node2D
var lobby_players: Array[int] = []

#region externally callable funcs
func start_server():
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(PORT)
    multiplayer.multiplayer_peer = peer

    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

    _on_peer_connected(1)

func connect_client(ip_addr: String = "127.0.0.1"):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip_addr, PORT)
    multiplayer.multiplayer_peer = peer
    multiplayer.server_disconnected.connect(_on_server_disconnected)

func spawn_players():
    if players_spawn_node == null:
        printerr("players_spawn_node == null")
        return

    for p in lobby_players:
        _spawn_player(p)
#endregion

func _spawn_player(id: int):
    print("Spawning Player: %s" % id)
    const PLAYER_WIDTH := 66.0
    const SPACING := 10.0

    var player_to_add = player_scene.instantiate() as NetworkedPlayer
    player_to_add.name = str(id)

    players_spawn_node.add_child(player_to_add, true)
    # Add spawn offset
    var spawn_index := players_spawn_node.get_child_count() - 1
    player_to_add.position.x = spawn_index * (PLAYER_WIDTH + SPACING)

func _on_peer_connected(id: int):
    print("Player %s connected" % id)
    lobby_players.append(id)
    player_connected.emit(id, lobby_players)

func _on_peer_disconnected(id: int):
    print("Player %s disconnected" % id)
    player_disconnected.emit(id)

    if players_spawn_node == null || !players_spawn_node.has_node(str(id)):
        return
    players_spawn_node.get_node(str(id)).queue_free()

func _on_server_disconnected():
    print("Disconnected from server")
    server_disconnected.emit()
    multiplayer.multiplayer_peer = null
