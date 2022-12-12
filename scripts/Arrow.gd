class_name Arrow
extends Area2D


var speed = 600

func _physics_process(delta):
	position += transform.x * speed * delta
