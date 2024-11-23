extends SpringArm3D

var active : bool = true : set = set_active

@export_range(-90.0, 90.0, 0.1, "radians") var min_limit_x : float
@export_range(-90.0, 90.0, 0.1, "radians") var max_limit_x : float

func _ready():
	set_active(active)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton && event.is_pressed():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_active(state : bool):
	active = state
	set_process_input(active)
	set_process(active)

func _input(event):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	if event is InputEventMouseMotion: 
		rotate_from_vector(event.relative * 0.005)

func _process(delta):
	var joy_dir = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	rotate_from_vector(joy_dir * Vector2(1.0, 0.5) * 2.0 * delta)

func rotate_from_vector(v : Vector2):
	if v.length() == 0: return
	rotation.y -= v.x
	rotation.x -= v.y
	rotation.x = clamp(rotation.x, min_limit_x, max_limit_x)
