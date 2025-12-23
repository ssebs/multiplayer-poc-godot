class_name MultiplayerManager extends Node

signal player_connected(id: int, all_players: Array[int])
signal player_disconnected(id: int)
signal server_disconnected()

const PORT: int = 42069

@export var player_scene = preload("res://scenes/networked_player.tscn")
@export var enemy_scene = preload("res://scenes/enemy.tscn")
@export var game_main: GameMain

@onready var enemy_spawn_timer: Timer = %EnemySpawnTimer

var players_spawn_node: Node2D
var enemies_spawn_node: Node2D
var lobby_players: Array[int] = []
var enemy_counter: int = 0

const SPAWN_SPACING := 10.0

func _ready():
    # Only server spawns enemies
    if multiplayer.is_server():
        enemy_spawn_timer.timeout.connect(spawn_enemies)

#region Public API
## Starts the ENet server and listens for connections.
func start_server():
    var peer = ENetMultiplayerPeer.new()
    peer.create_server(PORT)
    multiplayer.multiplayer_peer = peer

    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

    _on_peer_connected(1)

## Connects to a server at the given IP.
func connect_client(ip_addr: String = "127.0.0.1"):
    var peer = ENetMultiplayerPeer.new()
    peer.create_client(ip_addr, PORT)
    multiplayer.multiplayer_peer = peer
    multiplayer.server_disconnected.connect(_on_server_disconnected)

## Spawns all lobby players. Called when game starts.
func spawn_players():
    if players_spawn_node == null:
        printerr("players_spawn_node == null")
        return

    for p in lobby_players:
        _spawn_player(p)

## Spawns an enemy if below max count (3). Server-only.
func spawn_enemies():
    if enemies_spawn_node == null:
        printerr("enemies_spawn_node == null")
        return
    if enemies_spawn_node.get_child_count() < 3:
        _spawn_enemy()
#endregion

#region Spawning (local)
func _spawn_player(id: int):
    print("Spawning Player: %s" % id)
    const PLAYER_WIDTH := 66.0

    var player_to_add = player_scene.instantiate() as NetworkedPlayer
    player_to_add.name = str(id)
    player_to_add.tree_exiting.connect(_on_player_died.bind(id))

    players_spawn_node.add_child(player_to_add, true)
    # Add spawn offset
    var spawn_index := players_spawn_node.get_child_count() - 1
    player_to_add.position.x = spawn_index * (PLAYER_WIDTH + SPAWN_SPACING)

func _spawn_enemy():
    print("Spawning enemy")
    const ENEMY_WIDTH = 68.0
    var enemy_to_add = enemy_scene.instantiate() as Enemy
    enemy_to_add.name = "Enemy_%s" % enemy_counter
    enemy_counter += 1
    enemies_spawn_node.add_child(enemy_to_add, true)
    enemy_to_add.position.x -= enemies_spawn_node.get_child_count() * (ENEMY_WIDTH + SPAWN_SPACING)
#endregion

#region Event Handlers
func _on_player_died(id: int):
    if multiplayer.is_server():
        print("Player %s died, respawning in 2 seconds" % id)
        await get_tree().create_timer(2.0).timeout
        _spawn_player(id)

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
#endregion
