extends Area2D

@onready var timer: Timer = %Timer

var move_target: Vector2 = Vector2.ZERO
var speed = 1000

func _ready():
    timer.timeout.connect(on_timeout)

func _physics_process(delta):
    if move_target != Vector2.ZERO:
        position += move_target * speed * delta

func shoot_bullet(dir: Vector2):
    move_target = dir.normalized()
    timer.start()

func on_timeout():
    queue_free()

# TODO: Add hitcheck
