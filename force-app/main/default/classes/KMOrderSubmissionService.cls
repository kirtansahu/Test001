// ===========================================================================
//  Class Name  : KMOrderSubmissionService
//  Company     : Keste @IDC
//  Author      : Ajinkya Hingne
//  Purpose     : Korean Mobility OrderSubmission functionality
//  Test Class  :
// ===========================================================================

public without sharing class KMOrderSubmissionService {
	public List<KMOrderSummary.ProductDetail> productDetails;
	public User currentUserDetails;
	public Map<String, String> orderDetails;
	public String currentTimestamp;

	public KMOrderSubmissionService(
		List<KMOrderSummary.ProductDetail> productDetails,
		User currentUserDetails,
		String currentTimestamp,
		Map<String, String> orderDetails
	) {
		this.productDetails = productDetails;
		this.currentUserDetails = currentUserDetails;
		this.orderDetails = orderDetails;
		this.currentTimestamp = currentTimestamp;
	}

	public String generateEmailBody() {
		Map<String, String> orderTypes = new Map<String, String>{
			'SO' => 'SO - Standard Order',
			'SU' => 'SU - Prepaid Order for Deposit',
			'SE' => 'SE - Prepaid Order for SU',
			'TC' => 'TC - Deferred Payment',
			'T9' => 'T9 - Deferred Payment Billing Order'
		};

		Map<String, String> paymentTypes = new Map<String, String>{
			'C' => 'C - Purchase Order',
			'S' => 'S - Credit Card with Tax Invoice',
			'3' => '3 - Credit Card without Tax Invoice'
		};

		Boolean isT9Order = orderDetails.get('orderType') == 'T9' ? true : false;

		String emailBody = '<html><head><style> table {border-collapse: collapse;} td {padding:2px 4px 2px 4px;}</style></head>';
		emailBody += '<body><table border="1"><tbody><tr><td>CRM Row ID</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('crmRowId'));
		emailBody += '</td><td>Thermo Emp Name</td><td>';
		emailBody += this.checkNullInput(currentUserDetails.Name);
		emailBody += '</td></tr><tr><td>Contact Name</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('contactName')) + '</td>';
		emailBody += '<td>Thermo Emp Phone#</td><td>';
		emailBody += this.checkNullInput(currentUserDetails.Phone);
		emailBody += '</td></tr><tr><td>Email</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('emailAddress'));
		emailBody += '</td><td>Thermo Emp Email</td><td>';
		emailBody += this.checkNullInput(currentUserDetails.Email);
		emailBody += '</td></tr><tr><td>Phone</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('phoneNumber'));
		emailBody += '</td></tr><tr style="height:20px;"><td colspan="4"></td></tr>';
		emailBody += '<tr><td>ShipTo#</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToNumber'));
		emailBody += '</td><td>BillTo#</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToNumber'));
		emailBody += '</td></tr><tr><td>ShipTo Alpha Name</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('shipToAlphaName'));
		emailBody += '</td></tr><tr><td>ShipTo Name</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToName'));
		emailBody += '</td><td>BillTo Name</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToName'));
		emailBody += '</td></tr><tr><td>Attention:</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToAttention'));
		emailBody += '</td><td>Attention:</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToAttention'));
		emailBody += '</td></tr><tr><td>Address Line 1</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToAddressLine1'));
		emailBody += '</td><td>Address Line 1</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToAddressLine1'));
		emailBody += '</td></tr><tr><td>Address Line 2</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToAddressLine2'));
		emailBody += '</td><td>Address Line 2</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToAddressLine2'));
		emailBody += '</td></tr><tr><td>Address Line 3</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToAddressLine3'));
		emailBody += '</td><td>Address Line 3</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToAddressLine3'));
		emailBody += '</td></tr><tr><td>City</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToCity'));
		emailBody += '</td><td>City</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToCity'));
		emailBody += '</td></tr><tr><td>State</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToState'));
		emailBody += '</td><td>State</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToState'));
		emailBody += '</td></tr><tr><td>Postcode</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToPostalCode'));
		emailBody += '</td><td>Postcode</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToPostalCode'));
		emailBody += '</td></tr><tr><td>Country</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('shipToCountry'));
		emailBody += '</td><td>Country</td><td>';
		emailBody += this.checkNullInput(orderDetails.get('billToCountry'));
		emailBody += '</td></tr><tr style="height:20px;"><td colspan="4"></td></tr>';
		emailBody += '<tr><td>Ship Complete?</td><td colspan="3">';
		emailBody += this.getBooleanInput(this.checkNullInput(orderDetails.get('shipComplete')));
		emailBody += '</td></tr><tr><td>Requested Delivery Date</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('requestDeleveryDate'));
		emailBody += '</td></tr><tr><td>New Stop Code</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('newStopCode'));
		emailBody += '</td></tr><tr><td>New Service Code</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('newServiceCode'));
		emailBody += '</td></tr><tr><td>Special Instructions</td><td colspan="3">';
		emailBody += this.getSpecialInstructions(false);
		emailBody += '</td></tr><tr style="height:20px;"><td colspan="4"></td></tr>';
		emailBody += '<tr><td>Order Type</td><td colspan="3">';
		emailBody += this.checkNullInput(orderTypes.get(orderDetails.get('orderType')));
		emailBody += '</td></tr><tr><td>Payment Type</td><td colspan="3">';
		emailBody += this.checkNullInput((orderDetails.get('paymentMethod')));
		emailBody += '</td></tr><tr><td>PO/Ref. Number</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('poOrRefNumber'));
		emailBody += '</td></tr><tr style="height:20px;"><td colspan="4"></td></tr>';
		emailBody += '<tr><td>Quote</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('quote'));
		emailBody += '</td></tr><tr><td>Promo Code</td><td colspan="3">';
		emailBody += this.checkNullInput(orderDetails.get('promotionCode'));
		emailBody += '</td></tr></tbody></table><br/><p>Order Line Items</p><table border="1"><thead>';
		emailBody += '<tr><td>Catalog#</td><td>Catalog Name</td><td>Unit Size</td><td>Quantity</td><td>Lot#</td>';
		if (isT9Order) {
			emailBody += '<td>OriginalOrderNum</td><td>OriginalOrderLineNo</td>';
		}
		emailBody += '<td>Customer Price</td><td>Sub Total</td></tr></thead>';
		emailBody += '<tbody>';

		Double subtotal;

		for (KMOrderSummary.ProductDetail product : productDetails) {
			subtotal = 0;
			if (String.isNotBlank(product.quantity) && string.isNotBlank(product.netPrice)) {
				subtotal = Double.valueOf(product.netPrice.remove(',')) * Double.valueOf(product.quantity);
			} else {
				if (String.isNotBlank(product.quantity) && string.isNotBlank(product.unitPrice)) {
					subtotal = Double.valueOf(product.unitPrice.remove(',')) * Double.valueOf(product.quantity);
				}
			}
			// if(!(String.isEmpty(product.quantity) && String.isEmpty(product.unitPrice))) {
			//     subtotal = Double.valueOf(product.quantity) * (Double.valueOf(product.unitPrice.remove(',')));
			// }
			emailBody += '<tr>';
			emailBody += '<td>' + this.checkNullInput(product.productNumber) + '</td>';
			emailBody += '<td>' + this.checkNullInput(product.productName) + '</td>';
			emailBody += '<td>' + this.checkNullInput(product.unitSize) + '</td>';
			emailBody += '<td>' + this.checkNullInput(product.quantity) + '</td>';
			emailBody += '<td>' + this.checkNullInput(product.lotNumber) + '</td>';
			if (isT9Order) {
				emailBody += '<td>' + this.checkNullInput(product.origLineOrderNo) + '</td>';
				emailBody += '<td>' + this.checkNullInput(product.origLineOrderLineNo) + '</td>';
			}
			string discPrice;
			if (string.isNotBlank(product.netPrice)) {
				discPrice = product.netPrice;
			} else {
				if (string.isNotBlank(product.unitPrice)) {
					discPrice = product.unitPrice;
				}
			}
			emailBody += '<td>' + 'KRW ' + this.getFormattedPrice(this.checkNullInput(discPrice)) + '</td>';
			emailBody += '<td>' + 'KRW ' + this.checkNullInput(subtotal.format()) + '</td>';
			emailBody += '</tr>';
		}
		String colspan1 = isT9Order ? '9' : '7';
		String colspan2 = isT9Order ? '5' : '3';
		emailBody +=
			'<tr style="height:20px;"><td colspan="' +
			colspan1 +
			'"></td></tr><tr><td colspan="' +
			colspan2 +
			'"></td>';
		emailBody += '<td colspan="3">Estimated total excluding VAT and freight</td>';
		emailBody +=
			'<td>' +
			'KRW ' +
			this.getFormattedPrice(this.checkNullInput(orderDetails.get('estimatedTotal'))) +
			'</td></tr></tbody></table></body></html>';
		return emailBody;
	}

	public String getXMLString() {
		Dom.Document doc = new Dom.Document();
		Dom.Xmlnode rootNode = doc.createRootElement('cXML', null, null);
		rootNode.setAttribute('timestamp', currentTimestamp);
		rootNode.setAttribute('xml:lang', 'en-US');
		rootNode.setAttribute('payloadID', '');

		this.createHeaderNode(rootNode);
		this.createRequestNode(rootNode);

		return doc.toXmlString();
	}

	private void createHeaderNode(Dom.Xmlnode rootNode) {
		Dom.Xmlnode header = rootNode.addChildElement('Header', null, null);

		Dom.Xmlnode fromNode = header.addChildElement('From', null, null);
		Dom.Xmlnode credential = fromNode.addChildElement('Credential', null, null);
		credential.setAttribute('domain', 'NetworkID');
		Dom.Xmlnode identity = credential.addChildElement('Identity', null, null);
		identity.addTextNode('KOREASALESAPP');

		Dom.Xmlnode toNode = header.addChildElement('To', null, null);
		Dom.Xmlnode toNodeCredential = toNode.addChildElement('Credential', null, null);
		toNodeCredential.setAttribute('domain', 'DUNS');
		Dom.Xmlnode toNodeIdentity = toNodeCredential.addChildElement('Identity', null, null);
		toNodeIdentity.addTextNode('182158873');

		Dom.Xmlnode sender = header.addChildElement('Sender', null, null);
		Dom.Xmlnode senderCredential = sender.addChildElement('Credential', null, null);
		senderCredential.setAttribute('domain', 'NetworkID');
		Dom.Xmlnode senderId = senderCredential.addChildElement('Identity', null, null);
		senderId.addTextNode('KOREASALESAPP');
		Dom.Xmlnode sharedSecret = senderCredential.addChildElement('SharedSecret', null, null);
		sharedSecret.addTextNode(Label.KM_XMLFile_SharedSecret);
		Dom.Xmlnode userAgent = sender.addChildElement('UserAgent', null, null);
		userAgent.addTextNode('Korea Sales App Automation');
	}

	private void createRequestNode(Dom.Xmlnode rootNode) {
		Dom.Xmlnode request = rootNode.addChildElement('Request', null, null);
		Dom.Xmlnode orderRequest = request.addChildElement('OrderRequest', null, null);
		this.createOrderRequestHeader(orderRequest);

		Integer lineNumber = 1;

		Boolean isT9Order = orderDetails.get('orderType') == 'T9' ? true : false;

		for (KMOrderSummary.ProductDetail product : productDetails) {
			this.createItemOutNode(orderRequest, lineNumber, product, isT9Order);
			lineNumber++;
		}
	}

	private void createOrderRequestHeader(Dom.Xmlnode orderRequest) {
		Dom.Xmlnode orderRequestHeader = orderRequest.addChildElement('OrderRequestHeader', null, null);
		orderRequestHeader.setAttribute('type', 'new');
		orderRequestHeader.setAttribute('orderType', 'regular');
		orderRequestHeader.setAttribute('orderDate', currentTimestamp);
		orderRequestHeader.setAttribute('orderID', this.checkNullInput(orderDetails.get('poOrRefNumber')));

		if (orderDetails.get('shipComplete') == 'true') {
			orderRequestHeader.setAttribute('shipComplete', 'yes');
		}

		this.createTotalNode(orderRequestHeader);
		this.createShipToNode(orderRequestHeader);
		this.createBillToNode(orderRequestHeader);
		this.createCommentsNode(orderRequestHeader);
		this.createExtrinsicNodes(orderRequestHeader);
	}

	private void createTotalNode(Dom.Xmlnode orderRequestHeader) {
		Dom.Xmlnode total = orderRequestHeader.addChildElement('Total', null, null);
		Dom.Xmlnode money = total.addChildElement('Money', null, null);
		money.setAttribute('currency', 'KRW');
		money.addTextNode(this.getFormattedPrice(this.checkNullInput(orderDetails.get('estimatedTotal'))));
	}

	private void createShipToNode(Dom.Xmlnode orderRequestHeader) {
		Dom.Xmlnode shipTo = orderRequestHeader.addChildElement('ShipTo', null, null);

		Dom.Xmlnode address = shipTo.addChildElement('Address', null, null);
		address.setAttribute('isoCountryCode', 'kr');
		address.setAttribute('addressID', this.checkNullInput(orderDetails.get('shipToNumber')));

		Dom.Xmlnode name = address.addChildElement('Name', null, null);
		name.setAttribute('xml:lang', 'en-US');
		name.addTextNode(this.checkNullInput(orderDetails.get('shipToAlphaName')));

		Dom.Xmlnode postalAddress = address.addChildElement('PostalAddress', null, null);
		postalAddress.setAttribute('name', '');

		Dom.Xmlnode deliverTo = postalAddress.addChildElement('DeliverTo', null, null);
		deliverTo.addTextNode(this.checkNullInput(orderDetails.get('contactName')));

		Dom.Xmlnode addressLine_1 = postalAddress.addChildElement('Street', null, null);
		Dom.Xmlnode addressLine_2 = postalAddress.addChildElement('Street', null, null);
		Dom.Xmlnode addressLine_3 = postalAddress.addChildElement('Street', null, null);
		addressLine_1.addTextNode(this.checkNullInput(orderDetails.get('shipToAddressLine1')));
		addressLine_2.addTextNode(this.checkNullInput(orderDetails.get('shipToAddressLine1')));
		addressLine_3.addTextNode(this.checkNullInput(orderDetails.get('shipToAddressLine1')));

		Dom.Xmlnode city = postalAddress.addChildElement('City', null, null);
		city.addTextNode(this.checkNullInput(orderDetails.get('shipToCity')));

		Dom.Xmlnode postalCode = postalAddress.addChildElement('PostalCode', null, null);
		postalCode.addTextNode(this.checkNullInput(orderDetails.get('shipToPostalCode')));

		Dom.Xmlnode country = postalAddress.addChildElement('Country', null, null);
		country.setAttribute('isoCountryCode', 'kr');
		country.addTextNode(this.checkNullInput(orderDetails.get('shipToCountry')));

		if (orderDetails.get('emailAddress') != null && orderDetails.get('emailAddress') != '') {
			Dom.Xmlnode email = address.addChildElement('Email', null, null);
			email.addTextNode(orderDetails.get('emailAddress'));
		}

		Dom.Xmlnode phone = address.addChildElement('Phone', null, null);
		phone.setAttribute('name', 'work');

		Dom.Xmlnode telephoneNumber = phone.addChildElement('TelephoneNumber', null, null);

		Dom.Xmlnode countryCode = telephoneNumber.addChildElement('CountryCode', null, null);
		countryCode.setAttribute('isoCountryCode', 'kr');
		countryCode.addTextNode('82');

		telephoneNumber.addChildElement('AreaOrCityCode', null, null);

		Dom.Xmlnode numberNode = telephoneNumber.addChildElement('Number', null, null);
		numberNode.addTextNode(this.checkNullInput(orderDetails.get('phoneNumber')));
	}

	private void createBillToNode(Dom.Xmlnode orderRequestHeader) {
		Dom.Xmlnode billTo = orderRequestHeader.addChildElement('BillTo', null, null);

		Dom.Xmlnode billToAddress = billTo.addChildElement('Address', null, null);
		billToAddress.setAttribute('isoCountryCode', 'kr');
		billToAddress.setAttribute('addressID', this.checkNullInput(orderDetails.get('billToNumber')));

		Dom.Xmlnode billToName = billToAddress.addChildElement('Name', null, null);
		billToName.setAttribute('xml:lang', 'en-US');
		billToName.addTextNode(this.checkNullInput(orderDetails.get('billToName')));

		Dom.Xmlnode billToPostalAddress = billToAddress.addChildElement('PostalAddress', null, null);

		Dom.Xmlnode billToDeliver = billToPostalAddress.addChildElement('DeliverTo', null, null);
		billToDeliver.addTextNode(this.checkNullInput(orderDetails.get('billToAttention')));

		Dom.Xmlnode billToAddressLine_1 = billToPostalAddress.addChildElement('Street', null, null);
		Dom.Xmlnode billToAddressLine_2 = billToPostalAddress.addChildElement('Street', null, null);
		Dom.Xmlnode billToAddressLine_3 = billToPostalAddress.addChildElement('Street', null, null);

		billToAddressLine_1.addTextNode(this.checkNullInput(orderDetails.get('billToAddressLine1')));
		billToAddressLine_2.addTextNode(this.checkNullInput(orderDetails.get('billToAddressLine2')));
		billToAddressLine_3.addTextNode(this.checkNullInput(orderDetails.get('billToAddressLine3')));

		Dom.Xmlnode billToCity = billToPostalAddress.addChildElement('City', null, null);
		billToCity.addTextNode(this.checkNullInput(orderDetails.get('billToCity')));

		Dom.Xmlnode billToPostalCode = billToPostalAddress.addChildElement('PostalCode', null, null);
		billToPostalCode.addTextNode(this.checkNullInput(orderDetails.get('billToPostalCode')));

		Dom.Xmlnode billToCountry = billToPostalAddress.addChildElement('Country', null, null);
		billToCountry.setAttribute('isoCountryCode', 'kr');
		billToCountry.addTextNode(this.checkNullInput(orderDetails.get('billToCountry')));

		Dom.Xmlnode billToPhone = billToAddress.addChildElement('Phone', null, null);
		billToPhone.setAttribute('name', 'work');

		Dom.Xmlnode billToTelephoneNumber = billToPhone.addChildElement('TelephoneNumber', null, null);
		Dom.Xmlnode billToCountryCode = billToTelephoneNumber.addChildElement('CountryCode', null, null);

		billToCountryCode.setAttribute('isoCountryCode', 'kr');
		billToCountryCode.addTextNode('82');
		billToTelephoneNumber.addChildElement('AreaOrCityCode', null, null);

		Dom.Xmlnode billToNumber = billToTelephoneNumber.addChildElement('Number', null, null);
		billToNumber.addTextNode(this.checkNullInput(orderDetails.get('phoneNumber')));
	}

	private void createCommentsNode(Dom.Xmlnode orderRequestHeader) {
		Dom.Xmlnode commentsNode = orderRequestHeader.addChildElement('Comments', null, null);
		commentsNode.setAttribute('xml:lang', 'en-US');
		String comments = '';
		List<String> itemsInfo = new List<String>();

		itemsInfo.add(this.getSpecialInstructions(true));

		String comment;
		for (KMOrderSummary.ProductDetail product : productDetails) {
			comment = '';
			if (!String.isEmpty(product.lotNumber)) {
				comment += 'Item ' + product.productNumber + ' Lot#' + product.lotNumber;
				itemsInfo.add(comment);
			}
		}
		comments += String.join(itemsInfo, ',');
		commentsNode.addTextNode(comments);
	}

	private void createExtrinsicNodes(Dom.Xmlnode orderRequestHeader) {
		String orderQuoteNumber = '';
		if (!String.isEmpty(orderDetails.get('quote'))) {
			orderQuoteNumber = orderDetails.get('quote');
		} else if (!String.isEmpty(orderDetails.get('promotionCode'))) {
			orderQuoteNumber = orderDetails.get('promotionCode');
		}

		Map<String, String> attributeText = new Map<String, String>{
			'orderRequesterName' => this.checkNullInput(orderDetails.get('contactName')),
			'orderMode' => 'KB',
			'paymentType' => this.checkNullInput(orderDetails.get('paymentMethod')),
			'orderType' => this.checkNullInput(orderDetails.get('orderType')),
			'orderStatus' => this.checkNullInput(orderDetails.get('orderFromState')),
			'quoteRequest' => 'No',
			'orderShipToAttention' => this.checkNullInput(orderDetails.get('shipToAttention')),
			'additionalOrderConf' => this.checkNullInput(currentUserDetails.Email),
			'orderQuoteNumber' => this.checkNullInput(orderQuoteNumber),
			'orderIsSplitAccount' => '0',
			'orderIsAttachment' => '0'
		};

		for (String attribute : attributeText.keySet()) {
			Dom.Xmlnode extrinsic = orderRequestHeader.addChildElement('Extrinsic', null, null);
			extrinsic.setAttribute('name', attribute);
			extrinsic.addTextNode(attributeText.get(attribute));
		}
	}

	private void createItemOutNode(
		Dom.Xmlnode orderRequest,
		Integer lineNumber,
		KMOrderSummary.ProductDetail product,
		Boolean isT9Order
	) {
		Map<String, String> attributeText = new Map<String, String>{
			'origLineOrderCompany' => '00725',
			'origLineOrderLineNo' => this.checkNullInput(product.origLineOrderLineNo),
			'origLineOrderNo' => this.checkNullInput(product.origLineOrderNo),
			'origLineOrderType' => this.checkNullInput(product.origLineOrderType)
		};

		Dom.Xmlnode itemOut = orderRequest.addChildElement('ItemOut', null, null);
		itemOut.setAttribute('quantity', this.checkNullInput(product.quantity));
		itemOut.setAttribute('lineNumber', this.checkNullInput(String.valueOf(lineNumber)));

		Dom.Xmlnode itemId = itemOut.addChildElement('ItemID', null, null);
		Dom.Xmlnode supplierPartId = itemId.addChildElement('SupplierPartID', null, null);
		supplierPartId.addTextNode(this.checkNullInput(product.productNumber));

		if (isT9Order) {
			Dom.Xmlnode itemDetail = itemOut.addChildElement('ItemDetail', null, null);
			Dom.Xmlnode unitPrice = itemDetail.addChildElement('UnitPrice', null, null);
			Dom.Xmlnode money = unitPrice.addChildElement('Money', null, null);
			money.setAttribute('currency', 'KRW');
			string discPrice;
			if (string.isNotBlank(product.netPrice)) {
				discPrice = product.netPrice;
			} else {
				if (string.isNotBlank(product.unitPrice)) {
					discPrice = product.unitPrice;
				}
			}
			money.addTextNode(this.getFormattedPrice(this.checkNullInput(discPrice)));

			Dom.Xmlnode description = itemDetail.addChildElement('Description', null, null);
			description.setAttribute('xml:lang', 'en-US');
			description.addTextNode(this.checkNullInput(product.productName));

			Dom.Xmlnode unitOfMeasure = itemDetail.addChildElement('UnitOfMeasure', null, null);
			unitOfMeasure.addTextNode(this.checkNullInput(product.unitSize));

			Dom.Xmlnode classification = itemDetail.addChildElement('Classification', null, null);
			classification.setAttribute('domain', 'UNSPSC');

			for (String attribute : attributeText.keySet()) {
				Dom.Xmlnode extrinsic = itemDetail.addChildElement('Extrinsic', null, null);
				extrinsic.setAttribute('name', attribute);
				extrinsic.addTextNode(attributeText.get(attribute));
			}
		}
	}

	private String checkNullInput(String input) {
		return String.isEmpty(input) ? '' : input;
	}

	private String getFormattedPrice(String price) {
		String priceValue = String.isEmpty(price) ? '0' : price;
		return Double.valueOf(priceValue).format();
	}

	private String getBooleanInput(String input) {
		if (input == 'true') {
			return 'Yes';
		} else {
			return 'No';
		}
	}

	private String getSpecialInstructions(Boolean isXMLFile) {
		String estimatedTotal = checkNullInput(orderDetails.get('estimatedTotal'));
		String orderType = checkNullInput(orderDetails.get('orderType'));
		String eTotal = estimatedTotal == '' ? '0' : estimatedTotal;
		Double total = Double.valueOf(eTotal.remove(','));
		List<String> instructions = new List<String>();

		if (!String.isEmpty(orderDetails.get('specialInstructions'))) {
			instructions.add(orderDetails.get('specialInstructions'));
		}

		if (isXMLFile) {
			if (total > 10500000) {
				instructions.add(Label.KM_OrderAmountExceeds_SpecialInstruction);
			}
			if (!String.isEmpty(orderDetails.get('newStopCode'))) {
				instructions.add(Label.KM_NewStopCode_SpecialInstruction);
			}
			if (!String.isEmpty(orderDetails.get('newServiceCode'))) {
				instructions.add(Label.KM_NewServiceCode_SpecialInstruction);
			}
		}

		return String.join(instructions, ',');
	}
}