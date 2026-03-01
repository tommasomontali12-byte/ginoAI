# global_services.gd - Singleton (Autoload)
# Lightweight service for tracking date/time, basic system info, and user position.
# Does NOT actively scan peripherals or drives to save resources.

extends Node

# Cached data
var _cached_date_time: Dictionary = {}
var _cached_os_details: Dictionary = {}
var _cached_machine_specs: Dictionary = {}
var _last_cache_update: int = 0
const CACHE_DURATION_MS: int = 30000 # 30 seconds between cache updates

# Performance tier settings
enum PerformanceTier { LOW, MEDIUM, HIGH }
var performance_tier: PerformanceTier = PerformanceTier.MEDIUM

# User position (obtained via IP)
var user_position: Vector2 = Vector2.ZERO
var is_position_activated: bool = false
var location_name: String = ""
var user_ip: String = ""

# Lazy-loaded peripheral list (empty by default to save resources)
var _peripherals: Array = []

# HTTP client for IP geolocation
var _http_request: HTTPRequest

# Called when node enters the tree
func _ready():
	# Initialize immediately upon loading
	_update_cached_data()
	
	# Create HTTP request node for IP geolocation
	_http_request = HTTPRequest.new()
	_http_request.timeout = 10
	_http_request.connect("request_completed", Callable(self, "_on_http_request_completed"))
	add_child(_http_request)

# Update all cached data if enough time has passed
func _update_cached_data():
	var current_time = Time.get_ticks_msec()
	if current_time - _last_cache_update < CACHE_DURATION_MS:
		return # Skip update if within cache duration

	_last_cache_update = current_time

	# Update date/time
	var now = Time.get_datetime_dict_from_system()
	_cached_date_time = {
		"year": now.year,
		"month": now.month,
		"day": now.day,
		"hour": now.hour,
		"minute": now.minute,
		"second": now.second,
		"formatted_string": "%04d-%02d-%02d %02d:%02d:%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]
	}

	# Update OS details
	_cached_os_details = {
		"name": OS.get_name(),
		"version": OS.get_version(),
		"is_debug_build": OS.is_debug_build(),
		"locale": OS.get_locale(),
		"renderer": RenderingServer.get_video_adapter_name() if RenderingServer else "Unknown"
	}

	# Update machine specs and determine performance tier
	var cpu_cores = OS.get_processor_count()
	var system_ram_mb = OS.get_static_memory_usage() / (1024 * 1024) # Approximation
	var cpu_model = "Unknown CPU"
	if OS.has_method("get_processor_name"):
		cpu_model = OS.get_processor_name()
	
	_cached_machine_specs = {
		"cpu_cores": cpu_cores,
		"locale": OS.get_locale(),
		"cpu_model": cpu_model,
		"system_ram_mb_approx": system_ram_mb,
	}
	
	# Determine performance tier based on CPU cores
	if cpu_cores <= 2:
		performance_tier = PerformanceTier.LOW
	elif cpu_cores <= 4:
		performance_tier = PerformanceTier.MEDIUM
	else:
		performance_tier = PerformanceTier.HIGH

# Fetch position via IP geolocation service
func _fetch_position_via_ip():
	if not is_position_activated:
		return
		
	var url = "http://ip-api.com/json/"
	print("Fetching position via IP...")
	_http_request.request(url)

# Callback when HTTP request completes
func _on_http_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("Failed to get geolocation data")
		return

	var json_result = JSON.parse_string(body.get_string_from_utf8())
	if json_result:
		print("Full API Response: ", json_result)  # Debug print of the full response
		
		# Extract IP address
		user_ip = json_result.get("query", "Unknown IP")
		
		# Extract position - try multiple possible field names
		var lat_val = json_result.get("lat", json_result.get("latitude", null))
		var lon_val = json_result.get("lon", json_result.get("lng", json_result.get("longitude", null)))
		
		if lat_val != null and lon_val != null:
			user_position = Vector2(lon_val, lat_val)
		else:
			print("Warning: Could not find latitude/longitude in response")
			user_position = Vector2.ZERO
		
		# Extract location name (try multiple possible field names)
		var city = json_result.get("city", "Unknown City")
		var region = json_result.get("regionName", json_result.get("region", "Unknown Region"))
		var country = json_result.get("country", "Unknown Country")
		var zip = json_result.get("zip", "")
		
		if zip and zip != "":
			location_name = city + ", " + region + ", " + country + " " + zip
		else:
			location_name = city + ", " + region + ", " + country
		
		print("Location: ", location_name)
		if user_position != Vector2.ZERO:
			print("Position: ", user_position)
			print("Latitude: ", user_position.y, ", Longitude: ", user_position.x)
		else:
			print("Position: Not available")
		print("IP Address: ", user_ip)
	else:
		print("Unexpected response format from geolocation service")

# Get current date/time string
func get_current_date_time() -> String:
	_update_cached_data() # Only updates if cache is stale
	return _cached_date_time.get("formatted_string", "N/A")

# Get OS details
func get_os_details() -> Dictionary:
	_update_cached_data()
	return _cached_os_details.duplicate() # Return a copy to prevent external modification

# Get machine specs
func get_machine_specs() -> Dictionary:
	_update_cached_data()
	return _cached_machine_specs.duplicate()

# Get performance tier based on system specs
func get_performance_tier() -> PerformanceTier:
	_update_cached_data() # Update tier if needed
	return performance_tier

# Get a minimal list of peripherals (currently only shows drives, but doesn't scan their content)
func get_connected_peripherals() -> Array:
	_update_cached_data()
	# Only compute this once per session to save resources
	if _peripherals.is_empty():
		_peripherals = _scan_basic_drives()
	return _peripherals.duplicate()

# Scan only drive letters/names, not contents (fast and light)
func _scan_basic_drives() -> Array:
	var drives = []
	var letters = []
	
	if OS.get_name() == "Windows":
		letters = ["C:"]
	else:
		letters = ["/", "/home"]
	
	for letter in letters:
		var dir_access = DirAccess.open(letter)
		if dir_access:
			drives.append({
				"name": letter,
				"type": "Storage Drive",
				"free_space_bytes": dir_access.get_space_left(),
			})
	return drives

# Enable or disable position tracking
func set_position_activation(active: bool):
	is_position_activated = active
	if is_position_activated:
		# Fetch position immediately when activation is turned on
		_fetch_position_via_ip()

# Check if position tracking is currently active
func is_position_active() -> bool:
	return is_position_activated

# Get current user position (only if activated, otherwise returns zero)
func get_user_position() -> Vector2:
	if is_position_activated:
		return user_position
	else:
		return Vector2.ZERO # Return zero if not activated

# Force immediate update of all cached data
func force_refresh():
	_last_cache_update = 0
	_update_cached_data()
	if is_position_activated:
		_fetch_position_via_ip()

# Get raw position data (for debugging)
func get_raw_position() -> Vector2:
	return user_position

# Print current position
func print_position():
	if is_position_activated:
		print("Location: ", location_name)
		if user_position != Vector2.ZERO:
			print("Position: ", user_position)
			print("Latitude: ", user_position.y, ", Longitude: ", user_position.x)
		else:
			print("Position: Not available")
		print("IP Address: ", user_ip)
	else:
		print("Position tracking is not activated")
		print("Location: ", location_name if location_name else "Not retrieved")
		print("IP Address: ", user_ip if user_ip else "Not retrieved")

# Get the location name
func get_location_name() -> String:
	return location_name

# Get the IP address
func get_user_ip() -> String:
	return user_ip

# Print system specs and performance tier
func print_system_specs():
	_update_cached_data()
	print("CPU Cores: ", _cached_machine_specs.get("cpu_cores", "Unknown"))
	print("CPU Model: ", _cached_machine_specs.get("cpu_model", "Unknown"))
	print("Approximate System RAM (MB): ", _cached_machine_specs.get("system_ram_mb_approx", "Unknown"))
	print("Performance Tier: ", performance_tier)
	
	match performance_tier:
		PerformanceTier.LOW:
			print("System detected as low-performance: Optimizing for efficiency")
		PerformanceTier.MEDIUM:
			print("System detected as medium-performance: Balanced optimization")
		PerformanceTier.HIGH:
			print("System detected as high-performance: Enhanced features enabled")

# Get recommended settings based on performance tier
func get_recommended_settings() -> Dictionary:
	var settings = {}
	
	match performance_tier:
		PerformanceTier.LOW:
			settings = {
				"max_particles": 100,
				"texture_quality": "low",
				"shadows_enabled": false,
				"anti_aliasing": "disabled",
				"physics_fps": 30,
				"cache_duration_ms": 60000,  # Longer cache for low perf
			}
		PerformanceTier.MEDIUM:
			settings = {
				"max_particles": 500,
				"texture_quality": "medium",
				"shadows_enabled": true,
				"anti_aliasing": "msaa_2x",
				"physics_fps": 60,
				"cache_duration_ms": 30000,  # Medium cache
			}
		PerformanceTier.HIGH:
			settings = {
				"max_particles": 2000,
				"texture_quality": "high",
				"shadows_enabled": true,
				"anti_aliasing": "msaa_4x",
				"physics_fps": 120,
				"cache_duration_ms": 15000,  # Shorter cache for high perf
			}
	
	return settings

# Print all information
func print_all_info():
	_update_cached_data()  # Ensure all cached data is fresh
	
	print("=== DATE & TIME ===")
	print("Formatted Date/Time: ", _cached_date_time.get("formatted_string", "N/A"))
	print("Year: ", _cached_date_time.get("year", "N/A"))
	print("Month: ", _cached_date_time.get("month", "N/A"))
	print("Day: ", _cached_date_time.get("day", "N/A"))
	print("Hour: ", _cached_date_time.get("hour", "N/A"))
	print("Minute: ", _cached_date_time.get("minute", "N/A"))
	print("Second: ", _cached_date_time.get("second", "N/A"))
	
	print("\n=== OS DETAILS ===")
	print("OS Name: ", _cached_os_details.get("name", "N/A"))
	print("OS Version: ", _cached_os_details.get("version", "N/A"))
	print("Is Debug Build: ", _cached_os_details.get("is_debug_build", "N/A"))
	print("Locale: ", _cached_os_details.get("locale", "N/A"))
	print("Renderer: ", _cached_os_details.get("renderer", "N/A"))
	
	print("\n=== MACHINE SPECS ===")
	print("CPU Cores: ", _cached_machine_specs.get("cpu_cores", "N/A"))
	print("CPU Model: ", _cached_machine_specs.get("cpu_model", "N/A"))
	print("Approximate System RAM (MB): ", _cached_machine_specs.get("system_ram_mb_approx", "N/A"))
	print("Performance Tier: ", performance_tier)
	
	print("\n=== POSITION INFO ===")
	print("Position Tracking Active: ", is_position_activated)
	if is_position_activated:
		print("Location: ", location_name)
		if user_position != Vector2.ZERO:
			print("Position: ", user_position)
			print("Latitude: ", user_position.y, ", Longitude: ", user_position.x)
		else:
			print("Position: Not available")
		print("IP Address: ", user_ip)
	else:
		print("Position: Not being tracked (deactivated)")
		print("Location: ", location_name if location_name else "Not retrieved")
		print("IP Address: ", user_ip if user_ip else "Not retrieved")
	
	print("\n=== PERIPHERALS ===")
	print("Number of connected peripherals: ", _peripherals.size())
	for i in range(_peripherals.size()):
		var drive = _peripherals[i]
		print("  Drive ", i+1, ": ", drive.get("name", "N/A"), " (", drive.get("type", "N/A"), ")")
		print("    Free Space: ", drive.get("free_space_bytes", "N/A"), " bytes")
	
	print("\n=== RECOMMENDED SETTINGS ===")
	var recommended_settings = get_recommended_settings()
	for key in recommended_settings:
		print(key, ": ", recommended_settings[key])
	
	print("\n=== TIMING ===")
	print("Last cache update (ms since startup): ", _last_cache_update)
	print("Cache duration (ms): ", CACHE_DURATION_MS)

# Initialize the service when the node is ready
func initialize_service():
	_ready()
