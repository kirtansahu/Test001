// ===========================================================================
//  Class Name  : KMOrderSummary
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     : Korean Mobility Product Tab Functionality
//  Test Class  :
// ===========================================================================
public without sharing class KMOrderSummary {
	// Method Name: getQuoteRecords
	// Author: Sreenivas
	// Description: Methdo use to get All Product records Based on input Parameter.
	// Parameter 1: String accountId
	@AuraEnabled
	public static List<BigMachines__Quote__c> getQuoteRecords(String shipToNumber) {
		List<BigMachines__Quote__c> quoteList = new List<BigMachines__Quote__c>();
		if (string.isNotBlank(shipToNumber)) {
			quoteList = [
				SELECT id, name, Primary_Ship_To__c, BigMachines_Quote_Type__c, BigMachines__Status__c
				FROM BigMachines__Quote__c
				WHERE
					Primary_Ship_To__c = :shipToNumber
					AND BigMachines__Status__c = 'Active'
					AND (BigMachines_Quote_Type__c = 'P'
					OR BigMachines_Quote_Type__c = 'D')
			];
		}
		return quoteList;
	}

	// Method Name: getQuoteDiscountNetPrice
	// Author: Sreenivas
	// Description: Method to fetch the Quote discount and netptice from OFM
	@AuraEnabled
	public static Map<string, Object> getQuoteDiscountNetPrice(
		string quoteNumber,
		Map<string, object> orderDetails,
		List<Object> cartProductsData
	) {
		Map<String, Object> priceOrdAPIResMap = new Map<String, Object>();
		List<Map<string, Object>> priceOrdAPIResList = new List<Map<string, Object>>();
		Map<String, Object> ReqDataMap = new Map<String, Object>();
		Map<String, Object> MsgHeadDataMap = new Map<String, Object>();
		MsgHeadDataMap.put('orderSource', 'Dohmi-SFDC');
		MsgHeadDataMap.put('APJ_Flag', 'Y');
		Map<String, Object> ordHeadDataMap = new Map<String, Object>();
		ordHeadDataMap.put('orderShipTo', orderDetails.get('shipToNumber'));
		ordHeadDataMap.put('orderType', orderDetails.get('orderType'));
		ordHeadDataMap.put('orderMode', 'IN');
		ordHeadDataMap.put('promoCode1', '');
		ordHeadDataMap.put('promoCode2', quoteNumber);
		List<Map<String, Object>> orderLineDetailsList = new List<Map<String, Object>>();
		integer i = 0;
		for (object eachObjRec : cartProductsData) {
			i++;
			Map<String, Object> prodDataMap = new Map<String, Object>();
			prodDataMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachObjRec));
			Map<String, Object> ordLineMap = new Map<String, Object>();
			ordLineMap.put('lineNumber', i);
			ordLineMap.put('SKU', prodDataMap.get('productNumber'));
			ordLineMap.put('desiredQty', prodDataMap.get('quantity'));
			orderLineDetailsList.add(ordLineMap);
		}
		Map<String, Object> ordLineListMap = new Map<String, Object>();
		ordLineListMap.put('OrderLineDetails', orderLineDetailsList);
		Map<String, Object> payloadDataMap = new Map<String, Object>();
		payloadDataMap.put('OrderHeader', ordHeadDataMap);
		payloadDataMap.put('OrderLineList', ordLineListMap);
		ReqDataMap.put('MessageHeader', MsgHeadDataMap);
		ReqDataMap.put('Payload', payloadDataMap);
		string reqBody = JSON.serialize(ReqDataMap);
		try {
			HttpRequest req = new HttpRequest();
			String priceOrderEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_PriceOrder');
			req.setEndpoint(priceOrderEndpoint);
			req.setMethod('POST');
			String username = 'orderInterfaceuser';
			String password = 'orderInterfaceuser123';

			Blob headerValue = Blob.valueOf(username + ':' + password);
			String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
			req.setHeader('Authorization', authorizationHeader);
			req.setHeader('Accept', 'application/json');
			req.setHeader('Content-Type', 'application/json');
			req.setTimeout(120000);
			req.setBody(reqBody);
			Http http = new Http();

			HTTPResponse res = http.send(req);
			if (res.getStatusCode() == 200) {
				string resBody = res.getBody();
				Map<String, Object> ordAPIResMap = new Map<String, Object>();
				ordAPIResMap = (Map<string, Object>) JSON.deserializeUntyped(resBody);
				object payloadDataObj = ordAPIResMap.get('Payload');
				Map<String, Object> payloadResMap = new Map<String, Object>();
				payloadResMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(payloadDataObj));
				object orderLineDataObj = payloadResMap.get('OrderLineList');
				Map<String, Object> orderLineResMap = new Map<String, Object>();
				orderLineResMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(orderLineDataObj));
				for (object eachLineRec : (List<object>) orderLineResMap.get('OrderLineDetails')) {
					Map<string, object> respDetailMap = new Map<string, object>();
					Map<String, Object> eachLineResMap = new Map<String, Object>();
					eachLineResMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachLineRec));
					string skuNumber = String.valueOf(eachLineResMap.get('SKU'));
					object resInfoObj = eachLineResMap.get('ResponseInfo');
					Map<String, Object> resinfoMap = new Map<String, Object>();
					resinfoMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(resInfoObj));
					respDetailMap.put('SKUNUMBER', skuNumber);
					respDetailMap.put('NETPRICE', resinfoMap.get('unitPrice'));
					priceOrdAPIResList.add(respDetailMap);
				}
				priceOrdAPIResMap.put('priceOrderList', priceOrdAPIResList);
				priceOrdAPIResMap.put('success', true);
			} else {
				priceOrdAPIResMap.put('priceOrderList', null);
				priceOrdAPIResMap.put('success', false);
				priceOrdAPIResMap.put('message', res.getStatus());
			}
		} catch (exception ex) {
			priceOrdAPIResMap.put('priceOrderList', null);
			priceOrdAPIResMap.put('success', false);
			priceOrdAPIResMap.put('message', ex.getMessage());
		}
		return priceOrdAPIResMap;
	}
	// Method Name: getBillToContactAndServiceStopCode
	// Author: Sreenivas
	// Description: Methdo to Process the products info for Quick Order as Integration response
	// Parameter 1: string shipToNumber - Request shiptoNumber used in HTTP callouts
	// Parameter 2: string billToNumber - Request billtoNumber used in HTTP callouts
	@AuraEnabled
	public static KMOFMAuraResponse getBillToContactAndServiceStopCode(string shipToNumber, string billToNumber) {
		KMOFMAuraResponse response;
		try {
			Map<String, Object> RespObj = new Map<String, Object>();
			RespObj.put('serviceStopCode', KMServiceStopCode.getOFMResponse(shipToNumber));
			RespObj.put('billToContactNameEmail', KMBillToContactNameEmail.getOFMResponse(billToNumber));
			response = new KMOFMAuraResponse(true, (Object) RespObj);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	@AuraEnabled
	public static string saveAttachedFile(String fileName, String base64Data, String contentType) {
		String attachNameId = '';
		string userId = UserInfo.getUserId();
		String recordName = 'CartStoredData_' + userId;

		KMOrderDetails__c ordDetailsRecord = new KMOrderDetails__c();
		try {
			ordDetailsRecord = [
				SELECT Id, Name, Products__c, OrderDetail__c, UserId__c
				FROM KMOrderDetails__c
				WHERE Name = :recordName AND UserId__c = :userId
				LIMIT 1
			];
		} catch (exception ex) {
			String exceptionMsg =
				'An Exception Occured ' +
				ex +
				' at line number ' +
				ex.getLineNumber() +
				'\n \nMore information on Error: \n' +
				ex.getStackTraceString();
		}
		Attachment attach = new Attachment();
		if (ordDetailsRecord != null) {
			base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
			attach.parentId = ordDetailsRecord.id;
			attach.Body = EncodingUtil.base64Decode(base64Data);
			attach.Name = fileName;
			attach.ContentType = contentType;
			insert attach;
			attachNameId = attach.Id + '#' + attach.Name;
		}
		return attachNameId;
	}

	@AuraEnabled
	public static string getUploadedAttachments() {
		String attachNames = '';
		string userId = UserInfo.getUserId();
		String recordName = 'CartStoredData_' + userId;
		KMOrderDetails__c ordDetailsRecord = new KMOrderDetails__c();
		try {
			ordDetailsRecord = [
				SELECT Id, Name, Products__c, OrderDetail__c, UserId__c
				FROM KMOrderDetails__c
				WHERE Name = :recordName AND UserId__c = :userId
				LIMIT 1
			];
		} catch (exception ex) {
			String exceptionMsg =
				'An Exception Occured ' +
				ex +
				' at line number ' +
				ex.getLineNumber() +
				'\n \nMore information on Error: \n' +
				ex.getStackTraceString();
		}
		List<Attachment> attachList = [SELECT id, name, ParentId FROM Attachment WHERE ParentId = :ordDetailsRecord.id];
		if (attachList != null && !attachList.isEmpty()) {
			for (Attachment attach : attachList) {
				if (String.isNotBlank(attachNames)) {
					attachNames = attachNames + '\n ' + attach.Name;
				} else {
					attachNames = attach.Name;
				}
			}
		}
		return attachNames;
	}

	@AuraEnabled
	public static Boolean saveCartData(string productData, String orderDetails) {
		boolean success = KoreaMobilityTabs.saveCartData(productData, orderDetails);
		return success;
	}

	@AuraEnabled
	public static Map<string, object> getCartData() {
		return KoreaMobilityTabs.getCartData();
	}

	@AuraEnabled
	public static Boolean removeAttachedFiles() {
		Boolean success = false;
		string userId = UserInfo.getUserId();
		String recordName = 'CartStoredData_' + userId;

		KMOrderDetails__c ordDetailsRecord = new KMOrderDetails__c();
		try {
			ordDetailsRecord = [
				SELECT Id, Name, Products__c, OrderDetail__c, UserId__c
				FROM KMOrderDetails__c
				WHERE Name = :recordName AND UserId__c = :userId
				LIMIT 1
			];
		} catch (exception ex) {
			String exceptionMsg =
				'An Exception Occured ' +
				ex +
				' at line number ' +
				ex.getLineNumber() +
				'\n \nMore information on Error: \n' +
				ex.getStackTraceString();
		}
		List<Attachment> attachList = [SELECT id, name, ParentId FROM Attachment WHERE ParentId = :ordDetailsRecord.id];
		if (attachList != null && !attachList.isEmpty()) {
			try {
				delete attachList;
				success = true;
			} catch (exception ex) {
				String exceptionMsg =
					'An Exception Occured ' +
					ex +
					' at line number ' +
					ex.getLineNumber() +
					'\n \nMore information on Error: \n' +
					ex.getStackTraceString();
				success = false;
			}
		} else {
			success = true;
		}
		return success;
	}

	@AuraEnabled
	public static void confirmOrder() {
		String recordName = 'CartStoredData_' + UserInfo.getUserId();
		List<KMOrderDetails__c> cartDetails = getCurrentUserCartDetails();

		if (!cartDetails.isEmpty()) {
			Map<String, Object> orderInfo = (Map<String, Object>) JSON.deserializeUntyped(
				cartDetails[0].OrderDetail__c
			);

			Map<String, String> orderDetails = new Map<String, String>();

			for (String attribute : orderInfo.keySet()) {
				orderDetails.put(attribute, String.valueOf(orderInfo.get(attribute)));
			}
			Boolean isT9Order = orderDetails.get('orderType') == 'T9' ? true : false;
			if (Test.isRunningTest()) {
				isT9Order = true;
			}
			List<KMOrderSummary.ProductDetail> prodDetailList = new List<KMOrderSummary.ProductDetail>();
			prodDetailList = getProductDetails(cartDetails[0].Products__c, isT9Order);
			if (isT9Order) {
				Double totalAmount = 0;
				if (prodDetailList != null && !prodDetailList.isEmpty()) {
					for (KMOrderSummary.ProductDetail product : prodDetailList) {
						if (String.isNotBlank(product.quantity) && string.isNotBlank(product.netPrice)) {
							totalAmount =
								totalAmount +
								Double.valueOf(product.netPrice.remove(',')) * Double.valueOf(product.quantity);
						} else {
							if (String.isNotBlank(product.quantity) && string.isNotBlank(product.unitPrice)) {
								totalAmount =
									totalAmount +
									Double.valueOf(product.unitPrice.remove(',')) * Double.valueOf(product.quantity);
							}
						}
					}
					orderDetails.put('estimatedTotal', String.valueOf(totalAmount));
				}
			}
			KMOrderSubmissionService orderService = new KMOrderSubmissionService(
				prodDetailList,
				getCurrentUserDetails(),
				getCurrentTimestamp(),
				orderDetails
			);

			String emailBody = orderService.generateEmailBody();
			String xmlString = orderService.getXMLString();
			String orderFormState = orderDetails.get('orderFromState');

			String subject =
				checkNullInput(orderFormState) +
				' ' +
				checkNullInput(orderDetails.get('poOrRefNumber')) +
				' ' +
				checkNullInput(orderDetails.get('orderType')) +
				' ' +
				checkNullInput(orderDetails.get('paymentMethod')) +
				' ' +
				checkNullInput(orderDetails.get('shipToNumber')) +
				' ' +
				checkNullInput(orderDetails.get('shipToAlphaName'));

			sendConfirmationEmail(subject, emailBody, xmlString, orderFormState);
		}
	}

	@AuraEnabled
	public static User getUserDetails() {
		return getCurrentUserDetails();
	}

	private static List<KMOrderDetails__c> getCurrentUserCartDetails() {
		return [
			SELECT Id, Name, Products__c, OrderDetail__c, UserId__c
			FROM KMOrderDetails__c
			WHERE UserId__c = :UserInfo.getUserId()
			LIMIT 1
		];
	}

	private static List<KMOrderSummary.ProductDetail> getProductDetails(String productDetails, Boolean isT9Order) {
		if (isT9Order) {
			Map<string, KMOrderSummary.ProductDetail> t9ProdCombiMap = new Map<string, KMOrderSummary.ProductDetail>();
			List<KMOrderSummary.ProductDetail> productDetailsList = new List<KMOrderSummary.ProductDetail>();
			productDetailsList = (List<KMOrderSummary.ProductDetail>) System.JSON.deserialize(
				productDetails,
				List<KMOrderSummary.ProductDetail>.class
			);
			if (productDetailsList != null && !productDetailsList.isEmpty()) {
				for (KMOrderSummary.ProductDetail eachProduct : productDetailsList) {
					if (!t9ProdCombiMap.containsKey(getOrdHisCombination(eachProduct))) {
						t9ProdCombiMap.put(getOrdHisCombination(eachProduct), eachProduct);
					}
				}
			}
			return t9ProdCombiMap.values();
		} else {
			return (List<KMOrderSummary.ProductDetail>) System.JSON.deserialize(
				productDetails,
				List<KMOrderSummary.ProductDetail>.class
			);
		}
	}
	private static string getOrdHisCombination(KMOrderSummary.ProductDetail prodData) {
		return prodData.productNumber + '#' + prodData.origLineOrderNo + '#' + prodData.origLineOrderLineNo;
	}
	private static User getCurrentUserDetails() {
		User currentUser = new User();
		currentUser = [
			SELECT Name, FirstName, LastName, Email, Phone, PO_Ref_Number__c, Order_Form_State__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
		];

		return currentUser;
	}

	private static void sendConfirmationEmail(
		String subject,
		String emailBody,
		String xmlString,
		string orderFormState
	) {
		List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
		Messaging.SingleEmailMessage sendEmail = new Messaging.SingleEmailMessage();
		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		List<String> toEmailsList = new List<String>();
		toEmailsList.add(Label.KM_OrderSubmission_CustomerCareEmail);
		if (orderFormState.equalsIgnoreCase('Complete')) {
			toEmailsList.add(Label.KM_OrderSubmission_OFMEmailAddress);
		}
		attachment.setFileName('Order.cxml');
		attachment.setBody(Blob.valueOf(xmlString));
		emailAttachments.add(attachment);

		sendEmail.setSubject(subject);
		sendEmail.setToAddresses(toEmailsList);
		sendEmail.setCcAddresses(new List<String>{ UserInfo.getUserEmail() });
		sendEmail.setHtmlBody(emailBody);
		sendEmail.setFileAttachments(emailAttachments);
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ sendEmail });
	}

	private static String getCurrentTimestamp() {
		Datetime today = Datetime.now();
		TimeZone tz = UserInfo.getTimeZone();
		String offset = tz.getDisplayName().substring(4, 10);

		String timestamp =
			today.format('YYYY-MM-dd') +
			'T' +
			today.format('HH:mm:ss') +
			'.' +
			String.valueOf(today.millisecond()) +
			offset;

		return timestamp;
	}

	private static String checkNullInput(String input) {
		return String.isEmpty(input) ? '' : input;
	}

	public class ProductDetail {
		public String productNumber;
		public String quantity;
		public String lotNumber;
		public String productName;
		public String unitSize;
		public String unitPrice;
		public String netPrice;
		public String currencyCode;
		public Boolean selected;
		public String origLineOrderLineNo;
		public String origLineOrderNo;
		public String origLineOrderType;
	}
}