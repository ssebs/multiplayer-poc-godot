class_name NetworkedPlayer extends CharacterBody2D

@export var bullet_scn: PackedScene = preload("res://scenes/bullet.tscn")

const speed = 800.0

var arrow: Line2D

func _enter_tree():
    # Local client is the "server" for InputSynchronizer
    %InputSynchronizer.set_multiplayer_authority(name.to_int())

func _ready():
    %Label.text = "ID: " + name

    # Create arrow Line2D with fixed shape
    arrow = Line2D.new()
    arrow.width = 2.0
    arrow.default_color = Color.WHITE

    # Define arrow shape with fixed length
    var arrow_length = 50.0
    var arrow_head_length = 15.0
    var arrow_head_width = 10.0

    arrow.add_point(Vector2.ZERO)  # Start of arrow shaft
    arrow.add_point(Vector2(arrow_length, 0))  # End of shaft / tip
    arrow.add_point(Vector2(arrow_length - arrow_head_length, -arrow_head_width))  # Left wing
    arrow.add_point(Vector2(arrow_length, 0))  # Back to tip
    arrow.add_point(Vector2(arrow_length - arrow_head_length, arrow_head_width))  # Right wing

    add_child(arrow)

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
    arrow.rotation = direction

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
