extends Sprite
const qrpng = "payreq_qrcode.png"
const path = "C:/Users/your/location/of/godot/insertcoins/"

func _ready():
	#unused
	pass

func generate_qrcode(payreq):
	var output = []
	#generate rcode
	OS.execute(path + 'zint.exe', ['-b', '58', '-o', path + qrpng, '--vers=15', '--scale', '2', '-d', payreq] ,true ,output)
	#to test the generation of the qrcode, uncomment the next line and check if zint is in this path
	#print(path)

func _on_Button_pressed():
	var httpr = load("res://HTTPRequest.gd").new()
	var jsonh = load("res://jsonhandler.gd").new()
	
	#generate new invoice
	var ni = httpr.new_invoice() 
	#test what happens by uncommenting the next line:
	#print(ni)

	#construct the new invoice data dictionary
	var invoice = jsonh.new_invoice(ni)
	
	#generate QR COde
	generate_qrcode(invoice['payreq'])
	#show qrcode
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
	dynImage.load(path + qrpng)
	imageTexture.create_from_image(dynImage)
	self.texture = imageTexture

	#print(invoice['id'])
	#show invoice status
	get_node("../Button").disabled = true
	get_node("../Button").text = "Connecting..."
	get_node("../Label").text = "scan QR code with your LN wallet."
	
	#pause
	yield(get_tree().create_timer(1.1),"timeout")
	#var invoices = httpr.get_invoices()

	#start polling this invoice's status
	var invid = invoice['id']
	invoice_poller(httpr, jsonh, invid)

func invoice_poller(httpr, jsonh, id, count = 1023):
	#get status for this invoice (try 1023 times (max))
	count -= 1
	#request data and process json
	var invoices = httpr.get_invoices()
	var invoice = jsonh.poll_invoice(invoices, id)
	#print("status:" + invoice['status'] + " Expires: " + str(invoice['expires_at']) + " Conn timeout: " + str(count))
	if count == 0 or invoice['status'] == 'paid':
		#print(invoice)
		#print("status:" + invoice['status'] + " Expires: " + str(invoice['expires_at']) + " Conn timeout: " + str(count))
		if count == 0:
			print("LN server timeout")
		if invoice['status'] == 'paid':
			if int(invoice['msatoshi_received']) >= 10000:
				get_node("../Label").text = invoice['msatoshi_received'] + " sats received. Have fun!"
				get_tree().change_scene("res://game.tscn")
			else:
				get_node("../Label").text = "PAyment received. Insufficient funds :-("
		#print("invoice expiry date: " + str(invoice['expires_at']))
		return
	else:
		yield(get_tree().create_timer(2.5),"timeout")
	get_node("../Label").text = "Scan QR code with your LN wallet. Conn timeout: " + str(count) + " (" + str(invoice['status']) + ")"
	#recurse: see if invoice is paid yet
	invoice_poller(httpr, jsonh, id, count)