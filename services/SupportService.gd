# services/SupportService.gd
extends Node

const SUPABASE_URL = "https://snfluljzlqlnsvffraun.supabase.co"
const SUPABASE_KEY = "sb_publishable_pyD1zz1Dkz3Y_-IhoNueww_L7CzSCCR"

signal support_ticket_created(support_id)

func generate_support_id(username: String) -> String:
	# Get first 2 letters of username (uppercase)
	var initials = ""
	if username.length() >= 2:
		initials = username.substr(0, 2).to_upper()
	else:
		initials = username.to_upper().pad_zeros(2)  # Ensure 2 characters
	
	# Generate 13 random numbers
	var random_numbers = ""
	for i in range(13):
		random_numbers += str(randi() % 10)
	
	return initials + random_numbers

func create_support_ticket(idkey: String, username: String, reason: String) -> void:
	var support_id = generate_support_id(username)
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var url = SUPABASE_URL + "/rest/v1/support_tickets"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
        "Content-Type: application/json"
	]
	var body = JSON.stringify({
		"idkey": idkey,
		"support_id": support_id,
		"reason": reason,
		"status": "open"
	})
	
	http.request(url, headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_ticket_created.bind(http, support_id))

func _on_ticket_created(result, response_code, headers, body, http, support_id):
	http.queue_free()
	
	if response_code == 201:
		emit_signal("support_ticket_created", support_id)
