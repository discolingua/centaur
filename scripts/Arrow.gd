class_name Arrow
extends Area2D


# direction is set by the player or weapon object
var direction = Vector2(-1, 0)
var speed : float= 100.0

# how many frames the arrow will live for
var lifetime : int = 150

func _ready():
	WorldAudio.play("sfx/woosh2.ogg")


func _physics_process(delta : float) -> void:
	look_at(self.position + direction)
	self.position += direction * speed * delta

	lifetime -= 1
	if lifetime <= 0:
		queue_free()
