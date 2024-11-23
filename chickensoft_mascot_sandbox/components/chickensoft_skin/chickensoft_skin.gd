extends Node3D

@onready var animation_tree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")
@onready var blink_timer = %BlinkTimer

var lean : float = 0.0 : set = _set_lean
var squash_and_stretch = 1.0 : set = _set_squash_and_stretch

signal footstep(intensity : float)

func _ready():
	blink_timer.timeout.connect(_on_blink)

func _on_blink():
	blink_timer.start(randf_range(4.0, 12.0))
	animation_tree.set("parameters/BlinkShot/request", true)

func _set_lean(value : float) -> void:
	lean = clamp(value, -1.0, 1.0)
	animation_tree.set("parameters/LeanAdd/add_amount", abs(lean))
	animation_tree.set("parameters/LeanDirectionBlend/blend_position", lean)

func set_state(state_name : String) -> void:
	state_machine.travel(state_name)

func _set_squash_and_stretch(value : float) -> void:
	squash_and_stretch = value
	var negative = 1.0 + (1.0 - squash_and_stretch)
	scale = Vector3(negative, squash_and_stretch, negative)

func emit_footstep(intensity : float = 1.0) -> void:
	footstep.emit(intensity)
