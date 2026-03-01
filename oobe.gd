extends Control

var is_chatting_already_in_use = false
var is_study_already_in_use = false
var is_gaming_already_in_use = false
var is_work_already_in_use = false
var has_registered = false  # PREVENTS DUPLICATE REGISTRATIONS


func _ready() -> void:
	$OOBEscreen1/AnimationPlayer.play("Presentation")
	Global._build_personality()

func _on_line_edit_text_submitted(name: String) -> void:
	if has_registered:  # BLOCK IF ALREADY REGISTERED
		return
		
	var clean_name = name.strip_edges()
	if clean_name.length() < 3:
		$OOBEscreen1/Presentation2/Notification.text = "[color=red]Name must be at least 3 characters[/color]"
		$OOBEscreen1/Presentation2/Notification.show()
		return
		
	Global.user = clean_name
	Global._build_personality()
	
	# ✅ GENERATE DEVICE-BOUND IDKEY (ALWAYS THE SAME FOR THIS PC)
	var idkey = Global.get_or_create_idkey()
	
	# ✅ REGISTER USER ONCE ONLY
	if not has_registered:
		supabase_service.register_user(Global.user, idkey)
		has_registered = true
	
	# ✅ PROCEED IMMEDIATELY
	_proceed_to_next_screen()

func _proceed_to_next_screen():
	$OOBEscreen1/Presentation2.visible = false
	$OOBEscreen1/NameInput.visible = false
	$OOBEscreen1/Presentation3.visible = true
	$OOBEscreen1/AnimationPlayer.play("Presentation2")
	Global.save_data()

func _on_chatting_ck_pressed() -> void:
	if not is_chatting_already_in_use:
		Global.AI_USE += "For Chatting Use "
		is_chatting_already_in_use = true
	else:
		Global.AI_USE = Global.AI_USE.replace("For Chatting Use ", "")

func _on_study_ck_pressed() -> void:
	if not is_study_already_in_use:
		Global.AI_USE += "For Study Use "
		is_study_already_in_use = true
	else:
		Global.AI_USE = Global.AI_USE.replace("For Study Use ", "")

func _on_gaming_ck_pressed() -> void:
	if not is_gaming_already_in_use:
		Global.AI_USE += "For Gaming Use "
		is_gaming_already_in_use = true
	else:
		Global.AI_USE = Global.AI_USE.replace("For Gaming Use ", "")

func _on_work_pressed() -> void:
	if not is_work_already_in_use:
		Global.AI_USE += "For Work Use "
		is_work_already_in_use = true
	else:
		Global.AI_USE = Global.AI_USE.replace("For Work Use ", "")
	
	print("AI USE: ", Global.AI_USE)

func _on_save_button_pressed() -> void:
	var api_key: String = $OOBEscreen1/APIsetup/LineEdit.text.strip_edges()
	
	Global.isCustomApiSet = false
	
	if api_key == "":
		Global.API = Global.GROQ_API_KEY_LIMITED
		$OOBEscreen1/APIsetup/HelpLabel.text = "[center][color=orange]⚠️ Empty key. Using limited API.[/color][/center]"
		_show_final_screen()
		return
	
	var payload := {
		"model": "groq/compound-mini",
		"messages": [{"role": "user", "content": "ok"}],
		"max_tokens": 1
	}
	var json_body := JSON.stringify(payload)
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]
	
	var validator := HTTPRequest.new()
	validator.name = "TempAPIValidator"
	add_child(validator)
	
	validator.connect("request_completed", Callable(func(result, response_code, headers, body):
		validator.queue_free()
		
		if response_code == 200:
			Global.USER_API_KEY = api_key
			Global.isCustomApiSet = true
			$OOBEscreen1/APIsetup/HelpLabel.text = "[center][color=green]✅ API KEY VALID[/color][/center]"
			_show_final_screen()
		else:
			$OOBEscreen1/APIsetup/skip.show()
			$OOBEscreen1/APIsetup/HelpLabel.text = "[center][color=red]❌ INVALID API KEY (error: " + str(response_code) + ")[/color][/center]"
	).bind())
	
	# ✅ CORRECT URL (NO TRAILING SPACES)
	validator.request("https://api.groq.com/openai/v1/chat/completions", headers, HTTPClient.METHOD_POST, json_body)

func _show_final_screen():
	$OOBEscreen1/APIsetup.visible = false
	$OOBEscreen1/Final.show()
	Global.OOBE = false
	Global.save_data()

func _on_extreme_button_pressed() -> void:
	$OOBEscreen1/Presentation4Intro.visible = false
	$OOBEscreen1/APIsetup.visible = true

func _on_next_pressed() -> void:
	$OOBEscreen1/Presentation3.visible = false
	$OOBEscreen1/Presentation4Intro.show()

func _on_dev_skip_pressed() -> void:
	Global.OOBE = false
	Global.save_data()
	get_tree().change_scene_to_file("res://ui.tscn")

func _on_skip_pressed() -> void:
	_show_final_screen()

func _on_basic_button_pressed() -> void:
	_show_final_screen()

func _on_final_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://ui.tscn")
