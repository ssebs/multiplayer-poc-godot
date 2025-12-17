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

    # Update line to mouse position (only for local player)
    if %InputSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
        _update_line_to_mouse()

func _apply_movement_from_input(_delta):
    velocity = %InputSynchronizer.input_dir * speed
    move_and_slide()

func _update_line_to_mouse():
    var mouse_position = get_viewport().get_mouse_position()
    var direction = (to_local(mouse_position)).angle()
    %Arrow.rotation = direction

@rpc("call_local")
func die():
    print("Die called")
    queue_free()

# Server must call this from input_synchronizer
@rpc("call_local")
func shoot_bullet(mouse_position: Vector2):
    var bullet = bullet_scn.instantiate() as Area2D

    bullet.global_position = self.global_position
    get_tree().current_scene.add_child(bullet)

    # Calculate direction from character position to mouse position
    var direction = (mouse_position - global_position).normalized()
    bullet.shoot_bullet(direction)

# Server must call this from input_synchronizer
@rpc("call_local")
func play_rotate_anim():
    if !%AnimationPlayer.is_playing():
        %AnimationPlayer.play("rotate_360")
