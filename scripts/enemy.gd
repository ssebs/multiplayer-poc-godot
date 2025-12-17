class_name Enemy extends Area2D

# TODO: find closes player & move twd them
# on hit, do player dmg
@onready var nav_timer: Timer = %NavTimer

var move_target: Vector2 = Vector2.ZERO
var speed = 1

func _ready():
    nav_timer.timeout.connect(nav_to_nearest_player)
    nav_timer.start()

func nav_to_nearest_player():
    var closest_player = _get_closest_player_or_null()
    if closest_player == null:
        printerr("Can't nav to closest player since they're null")
        return
    move_target = closest_player.global_position

func die():
    print("owie")
    queue_free()

func _physics_process(delta):
    if move_target != Vector2.ZERO:
        print("move_target: %s" % move_target)
        global_position += move_target * speed * delta


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
