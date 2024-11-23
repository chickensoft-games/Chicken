extends GPUParticles3D

func _ready():
	emitting = true
	one_shot = true
	finished.connect(queue_free)
