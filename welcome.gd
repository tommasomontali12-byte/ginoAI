extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.can_start_anmate:
		$"Welcome Animation".play("Welcome")
	else:
		get_tree().change_scene_to_file("res://ui.tscn")

func _on_continue_pressed() -> void:
	$Fader.modulate.a = 0.0
	$Fader.show()   #Ma non quello
	GlobalTweens.blink($BG/Logo)
	GlobalTweens.blink($Welcome, 3, 0.2)
	GlobalTweens.fade($Fader, 0, 1, 0.5)
	await get_tree().create_timer(2.0).timeout
	if Global.OOBE==true:
		get_tree().change_scene_to_file("res://oobe.tscn")
	else:
		get_tree().change_scene_to_file("res://ui.tscn")
		
