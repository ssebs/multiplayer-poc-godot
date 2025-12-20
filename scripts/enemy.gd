class_name Enemy extends Area2D

@onready var nav_timer: Timer = %NavTimer

var move_target: Vector2 = Vector2.ZERO
var speed = 100

func _ready():
    # Only run enemy logic on server
    if multiplayer.is_server():
        body_entered.connect(on_body_entered)
        nav_timer.timeout.connect(nav_to_nearest_player)
        nav_timer.start()

#region navigation
func _physics_process(delta):
    if !multiplayer.is_server():
        return

    if move_target != Vector2.ZERO:
        var direction = (move_target - global_position).normalized()
        global_position += direction * speed * delta

func nav_to_nearest_player():
    var closest_player = _get_closest_player_or_null()
    if closest_player == null:
        printerr("Can't nav to closest player since they're null")
        queue_free()
        return
    move_target = closest_player.global_position
#endregion

func die():
    print("Enemy owie")
    queue_free()

func on_body_entered(body: Node2D):
    if body.is_in_group("players"):
        body = body as NetworkedPlayer
        print("Hitting player %s" % body.name)
        if multiplayer.is_server():
            body.die.rpc()


func _get_closest_player_or_null() -> NetworkedPlayer:
    var all_players = get_tree().get_nodes_in_group("players")
    var closest_player = null
 
    if (all_players.size() > 0):
        closest_player = all_players[0]
        for player in all_players:
            var distance_to_this_player = global_position.distance_squared_to(player.global_position)
            var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
            if (distance_to_this_player < distance_to_closest_player):
                closest_player = player
 
    return closest_player
