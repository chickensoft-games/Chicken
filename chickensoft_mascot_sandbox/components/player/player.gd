extends CharacterBody3D

@export var jump_height : float = 2.5
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.6

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@export var base_speed = 3.0
@export var run_speed = 7.0

@onready var visual_root = %VisualRoot
@onready var skin = %ChickensoftSkin
@onready var movement_dust = %MovementDust
@onready var foot_step_audio = %FootStepAudio
@onready var impact_audio = %ImpactAudio
@onready var center_root = %CenterRoot

const JUMP_PARTICLES_SCENE = preload("./vfx/jump_particles.tscn")
const LAND_PARTICLES_SCENE = preload("./vfx/land_particles.tscn")

var movement_input : Vector2 = Vector2.ZERO
var target_angle : float = 0.0
var last_movement_input : Vector2 = Vector2.ZERO
var last_movement_speed : float = base_speed

func _ready():
	move_and_slide()
	skin.footstep.connect(func(intensity : float = 1.0):
		foot_step_audio.volume_db = linear_to_db(intensity)
		foot_step_audio.play()
		)

func _physics_process(delta):
	var camera : Camera3D = get_viewport().get_camera_3d()
	if camera == null: return
	movement_input = Input.get_vector("left", "right", "up", "down").rotated(-camera.global_rotation.y).limit_length(1.0)
	var is_running : bool = Input.is_action_pressed("run")
	var vel_2d = Vector2(velocity.x, velocity.z)
	
	if movement_input != Vector2.ZERO:
		skin.set_state("run" if is_running else "walk")
		var speed = run_speed if is_running else base_speed
		last_movement_speed = speed
		vel_2d += movement_input * speed * 8.0 * delta
		vel_2d = vel_2d.limit_length(speed)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
		target_angle = atan2(movement_input.x, movement_input.y)
	else:
		skin.set_state("idle")
		vel_2d = vel_2d.move_toward(Vector2.ZERO, last_movement_speed * 4.0 * delta)
		velocity.x = vel_2d.x
		velocity.z = vel_2d.y
	

	visual_root.rotation.y = rotate_toward(visual_root.rotation.y, target_angle, 6.0 * delta)
	var angle_diff = angle_difference(visual_root.rotation.y, target_angle)
	skin.lean = move_toward(skin.lean, angle_diff if is_on_floor() else 0.0, 2.0 * delta)
	var forward_velocity = Vector2(velocity.x, velocity.z).normalized().dot(movement_input.normalized()) * 0.2
	visual_root.rotation.x = rotate_toward(visual_root.rotation.x, forward_velocity if !is_on_floor() else 0.0, 1.0 * delta)
	center_root.rotation.z = rotate_toward(center_root.rotation.z, -angle_diff * 0.2 if !is_on_floor() else 0.0, 2.0 * delta)
	
	movement_dust.emitting = is_running && is_on_floor() && movement_input != Vector2.ZERO
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			skin.set_state("jump")
			velocity.y = -jump_velocity
			
			var jump_particles = JUMP_PARTICLES_SCENE.instantiate()
			add_sibling(jump_particles)
			jump_particles.global_transform = global_transform
			
			do_squash_and_stretch(1.2, 0.1)
	else:
		skin.set_state("fall")
		
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta
	
	var in_the_air : bool = !is_on_floor()
	
	var previous_y_vel : float = velocity.y
	
	
	velocity = velocity.limit_length(fall_gravity)
	move_and_slide()
	
	if is_on_floor() && in_the_air:
		_on_hit_floor(previous_y_vel)

func _on_hit_floor(y_vel : float):
	y_vel = clamp(abs(y_vel), 0.0, fall_gravity)
	var floor_impact_percent : float = y_vel / fall_gravity
	impact_audio.volume_db = linear_to_db(remap(floor_impact_percent, 0.0, 1.0, 0.5, 2.0))
	impact_audio.play()
	var land_particles = LAND_PARTICLES_SCENE.instantiate()
	add_sibling(land_particles)
	land_particles.global_transform = global_transform
	do_squash_and_stretch(0.7, 0.08)

func do_squash_and_stretch(value : float, timing : float = 0.1):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(skin, "squash_and_stretch", value, timing)
	t.tween_property(skin, "squash_and_stretch", 1.0, timing * 1.8)
