extends HTTPRequest
# This simple class can do HTTP requests
const host = "10.0.0.1"
const port = 9112

func _ready():
	#output = get_invoices()
	pass

func get_info():
	return request_data("info")
	
func get_invoices():
	return request_data("invoices")

func new_invoice():
	#return json
	return request_data("invoice")

func request_data(type):
	var err = 0
	var http = HTTPClient.new() # Create the Client.

	err = http.connect_to_host(host, port) # Connect to host/port.
	assert(err == OK) # Make sure connection was OK.

	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		#print("Connecting...")
		OS.delay_msec(500)

	assert(http.get_status() == HTTPClient.STATUS_CONNECTED) # Could not connect

	# Some headers
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Content-Type: application/json",
		"Authorization: Basic xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", #base64 encoded string "Token:Secret" ! DO NOT USE in shared compiled program (add hashing)
		"Accept: */*"
	]
	var query = '{"msatoshi":10000,"metadata":{"customer_id":9999,"products":[1,1]},"description":"yourgame invoice"}'
	
	if type == "invoice":
		err = http.request(HTTPClient.METHOD_POST, "/" + type, headers, query) # Request a new invoice using POST
	else:
		err = http.request(HTTPClient.METHOD_GET, "/" + type, headers) # Request info or list of invoices using GET
	assert(err == OK) # Make sure all is OK.

	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		#print("Requesting...")
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")

	assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.

	#print("response? ", http.has_response()) # Site might not have a response.
	if http.has_response():
		# If there is a response...
		headers = http.get_response_headers_as_dictionary() # Get response headers.
		#print("code: ", http.get_response_code()) # Show response code.
		#print("**headers:\\n", headers) # Show headers.

		# Getting the HTTP Body

		if http.is_response_chunked():
			# Does it use chunks?
			print("Response is Chunked")
		#else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			print("Response Length: ",bl)
		# This method works for both anyway

		var rb = PoolByteArray() # Array that will hold the data.

		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a chunk.
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer.
				
		var text = rb.get_string_from_ascii()
		#print("bytes got: ", rb.size())
		return text
