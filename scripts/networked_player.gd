class_name NetworkedPlayer extends CharacterBody2D

@export var bullet_scn: PackedScene = preload("res://scenes/bullet.tscn")

const speed = 800.0

func _enter_tree():
    # Local client is the "server" for InputSynchronizer
    %InputSynchronizer.set_multiplayer_authority(name.to_int())

func _ready():
    %Label.text = "ID: " + name

func _physics_process(delta):
    if multiplayer.is_server():
        _apply_movement_from_input(delta)

func _apply_movement_from_input(_delta):
    velocity = %InputSynchronizer.input_dir * speed
    move_and_slide()

# Server must call this from input_synchronizer
@rpc("call_local")
func shoot_bullet(mouse_position: Vector2):
    var bullet = bullet_scn.instantiate() as RigidBody2D
    # bullet.global_position = %BulletSpawnPos.global_position
    %BulletSpawnPos.add_child(bullet)

    # Calculate direction from character position to mouse position
    var direction = (mouse_position - global_position).normalized()
    bullet.shoot_bullet(direction)

# Server must call this from input_synchronizer
@rpc("call_local")
func play_rotate_anim():
    if !%AnimationPlayer.is_playing():
        %AnimationPlayer.play("rotate_360")
