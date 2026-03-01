# services/SupabaseService.gd
extends Node

const SUPABASE_URL = "https://snfluljzlqlnsvffraun.supabase.co"
const SUPABASE_KEY = "sb_publishable_pyD1zz1Dkz3Y_-IhoNueww_L7CzSCCR"

signal response_received(result, response_code, headers, body_text)

func register_user(username: String, idkey: String):
	var http = HTTPRequest.new()
	add_child(http)
	var url = SUPABASE_URL + "/rest/v1/users"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
        "Content-Type: application/json"
	]
	var body = JSON.stringify({"username": username, "idkey": idkey})
	http.request(url, headers, HTTPClient.METHOD_POST, body)
	http.request_completed.connect(_on_request_completed.bind(http))

func validate_idkey(idkey: String):
	var http = HTTPRequest.new()
	add_child(http)
	var url = SUPABASE_URL + "/rest/v1/users?idkey=eq." + idkey.uri_encode() + "&select=idkey,username,banned,ban_reason"
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY
	]
	http.request(url, headers, HTTPClient.METHOD_GET)
	http.request_completed.connect(_on_request_completed.bind(http))

func update_user(username: String, idkey: String):
	var http = HTTPRequest.new()
	add_child(http)
	var url = SUPABASE_URL + "/rest/v1/users?idkey=eq." + idkey.uri_encode()
	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json",
        "Prefer: return=representation"
	]
	var body = JSON.stringify({"username": username})
	http.request(url, headers, HTTPClient.METHOD_PATCH, body)
	http.request_completed.connect(_on_request_completed.bind(http))

func _on_request_completed(result, response_code, headers, body, http):
	http.queue_free()
	emit_signal("response_received", result, response_code, headers, body.get_string_from_utf8())
