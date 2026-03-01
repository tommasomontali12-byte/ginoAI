# res://ban_screen.gd
extends Control

@onready var rich_text_label = $RichTextLabel

func _ready():
	# Get ban reason from Global
	var reason = Global.ban_reason if Global.ban_reason != "" else "No reason specified"
	
	# Generate support ID using SupportService
	var support_id = SupportService.generate_support_id(Global.user)
	
	# Display in RichTextLabel
	rich_text_label.text = """	
[color=white]Ban reason:[/color] [color=yellow]""" + reason + """[/color]
[color=white]Support ID:[/color] [color=cyan][b]""" + support_id + """[/b][/color]
[color=gray]Contact tommaso.montali12@gmail.com with this ID for assistance[/color]
"""
	
	# Optional: Create support ticket in background
	SupportService.create_support_ticket(Global.idkey, Global.user, reason)

func _on_close_button_pressed():
	get_tree().quit()

func _on_appeal_button_pressed():
	# Open appeal form or email
	var email_body = "Support ID: " + SupportService.generate_support_id(Global.user) + "\nReason: " + Global.ban_reason
	OS.shell_open("mailto:support@laikagroup.com?subject=Appeal%20Request&body=" + email_body.uri_encode())
