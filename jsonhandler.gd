extends Node
#class handles json

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func get_invoice(json, id):
	#get a specific invoice as array
	var invoices = JSON.parse(json).result
	
	#print("parsed json: ")
	#print(invoices)
	
	if typeof(invoices) == TYPE_ARRAY:
		#loop through list of invoices and find the one requested
		for i in range(invoices.size()):
			if invoices[i]['id'] == id:
				return invoices[i] #return dictionary
	else:
	    print("unexpected result")

func new_invoice(json):
	#process json from new invoice
	var invoice = JSON.parse(json).result
	if typeof(invoice) == TYPE_DICTIONARY:
		return invoice #return dictonary
	else:
		print("not a dictionary")

func poll_invoice(json, id):
	var invoice = get_invoice(json, id)
	return invoice