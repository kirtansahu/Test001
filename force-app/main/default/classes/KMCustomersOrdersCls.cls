// ===========================================================================
//  Class Name  : KMCustomersOrdersCls
//  Company     : Keste @IDC
//  Author      : Jagadish Babu
//  Purpose     : Korean Mobility Customer Order Tab Functionality
//  Test Class  :
// ===========================================================================
public without sharing class KMCustomersOrdersCls {
	// Method Name: getShipToRecords
	// Author: Rambabu Gadde
	// Description: Method to Process the  Account Records
	// Parameter 1: String selectOption
	// Parameter 2: String accountOffset.
	// Parameter 3: String searchInput
	@AuraEnabled
	public static List<Account> getShipToRecords(String selectOption, Integer accountOffset, String searchInput) {
		searchInput = '%' + searchInput + '%';
		String fieldName;
		if (selectOption == 'ShipToAlphaName') {
			fieldName = 'Account_Alpha_Name__c';
		} else if (selectOption == 'ShipTo') {
			fieldName = 'ERP_Account_Id__c';
		}
		String query = new KMQueryBuilder('Account')
			.selectFields(getAccountFields())
			.setCondition('RecordType.Name = \'' + Label.KM_ShipToRecordType + '\'')
			.setCondition('Price_Book__r.Name = \'' + Label.KM_ShipTo_PriceList + '\'')
			.setCondition(fieldName + ' LIKE ' + '\'' + searchInput + '\'')
			.setOffset(accountOffset)
			.setLimit(Integer.valueOf(System.Label.KM_Record_Limits))
			.toSOQL();
		return Database.query(query);
	}

	// Method Name: getAccountDetail
	// Author: Jagadish Babu
	// Description: Method to Process the Contact Records for contact detail Page
	// Parameter 1: String accountId - Account Id to search contacts
	@AuraEnabled
	public static Map<string, object> getAccountDetail(
		String accountId,
		String fieldName,
		Boolean isAsc,
		String filterField,
		string searchKey
	) {
		Map<string, object> AccConMap = new Map<string, object>();
		String soql = 'Select Id,Name,ERP_Account_Id__c, Account_Alpha_Name__c,Address_1__c,Address_2__c,Address_3__c,City_f__c,State_f__c,Zip_Postal_Code_f__c,Country__c,Primary_Bill_To__r.ERP_Account_Id__c,Primary_Bill_To__r.Name,Primary_Bill_To__r.Address_1__c,Primary_Bill_To__r.Address_2__c,Primary_Bill_To__r.Address_3__c,Primary_Bill_To__r.City_f__c,Primary_Bill_To__r.State_f__c,Primary_Bill_To__r.Zip_Postal_Code_f__c,Primary_Bill_To__r.Country__c,(Select Id,Contact_External_Id__c, Name, Email,Job_Title__c,Web_Enabled_Flag__c, Phone from Contacts where Web_Enabled_Flag__c= true ';

		if (String.isNotBlank(searchKey) && String.isNotBlank(filterField)) {
			String key = '%' + searchKey + '%';
			soql += ' AND ' + filterField + ' Like \'' + key + '\'';
		}
		soql += ' order by ' + fieldName;
		if (isAsc) {
			soql += ' ASC';
		} else {
			soql += ' DESC';
		}
		soql +=
			' ) from Account where RecordType.Name=\'' +
			Label.KM_ShipToRecordType +
			'\' and id=\'' +
			accountId +
			'\'';
		List<Account> acc = Database.query(soql);
		list<Object> AccRelData = new List<Object>();
		AccRelData = getShipToContacts(acc[0].ERP_Account_Id__c);
		AccConMap.put('accountData', acc[0]);
		AccConMap.put('contactData', AccRelData);
		return AccConMap;
	}

	@AuraEnabled
	public static List<Object> getShipToContacts(String shipToNumber) {
		List<accountcontactrelation> contactDetails = new List<accountcontactrelation>();
		if (shipToNumber != null) {
			contactDetails = [
				SELECT
					id,
					Account.Name,
					Account.id,
					contactId,
					contact.Name,
					contact.email,
					contact.phone,
					contact.Active_Status_Flag__c,
					contact.Active_Status__c,
					contact.title,
					contact.Contact_External_Id__c,
					contact.Web_Status__c,
					Siebel_Row_Id__c
				FROM accountcontactrelation
				WHERE Account.ERP_Account_Id__c = :shipToNumber AND contact.Active_Status__c = TRUE
			];
		}
		return contactDetails;
	}

	// Method Name: getContactRecords
	// Author: Rambabu Gadde
	// Description: Method to Process the Contact Records
	// Parameter 1: String selectOption
	// Parameter 2: String contactOffset.
	// Parameter 3: String searchInput
	@AuraEnabled
	public static list<Object> getContactRecords(String selectOption, Integer contactOffset, String searchInput) {
		searchInput = '%' + searchInput + '%';
		String fieldName;
		if (selectOption == 'ContactName') {
			fieldName = 'Contact.Name';
		} else if (selectOption == 'Email') {
			fieldName = 'Contact.Email';
		}
		String query = new KMQueryBuilder('AccountContactRelation')
			.selectFields(getAccountContactRelationshipFields())
			.setCondition('Account.RecordType.Name = \'' + Label.KM_ShipToRecordType + '\'')
			.setCondition('Account.Price_Book__r.Name = \'' + Label.KM_ShipTo_PriceList + '\'')
			.setCondition('Contact.Active_Status__c = true')
			.setCondition(fieldName + ' LIKE ' + '\'' + searchInput + '\'')
			.setOffset(contactOffset)
			.setLimit(Integer.valueOf(System.Label.KM_Record_Limits))
			.toSOQL();
		return Database.query(query);
	}

	// Method Name: getOrderHistoryList
	// Author: Jagadish Babu
	// Description: Method to Process the Order History Records from OFM
	// Parameter 1: String ShipToNumber - ShipTo number from Customer Orders Tab
	// Parameter 2: String SiebelRowID - Optional field Siebel contact Id
	@AuraEnabled
	public static KMOFMAuraResponse getOrderHistoryList(String shipToNumber, String siebelRowID) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				KMOrderHistoryHeaderService.getOFMResponse(shipToNumber, siebelRowID)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getReorderList
	// Author: Jagadish Babu
	// Description: Method to Process the Order History by SKU Records from OFM
	// Parameter 1: String SHIPTONUM - ShipTo number from Customer Orders Tab
	// Parameter 2: String FROMDATE - Duration  from
	// Parameter 3: String TODATE - Duration  To
	@AuraEnabled
	public static KMOFMAuraResponse getReorderList(String shipToNum, String fromDate, String toDate) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				KMOrderHistotyBySKUService.getOFMResponse(shipToNum, fromDate, toDate)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: sendEmailWithSelectedOrders
	// Author: Sreenivas
	// Description: Methdo to send email to current user with selected orders.
	// Parameter 1: String shipToNumber - requsting shipToNumber
	// Parameter 2: List<Object> selectedOrders - requsting selected orders list
	@AuraEnabled
	public static void sendEmailWithSelectedOrders(String shipToNumber, List<Object> selectedOrders) {
		string orderNumbers = '';
		String emailBody = '<html><head><style>table {border-left: 1px solid grey; border-right: 1px solid grey; border-collapse: collapse; }';
		emailBody += 'th {background-color: #ecebea; border-bottom: 1px solid grey; border-top: 1px solid grey; color: rgb(81, 79, 77);font-weight: 400;font-size: 12px;white-space: normal;}';
		emailBody += 'td {border-bottom: 1px solid grey;color: rgb(81, 79, 77);font-weight: 400;font-size: 12px; white-space: normal; overflow-wrap: break-word; }';
		emailBody += 'th, td {padding: 8px;text-align: left;}</style></head>';
		emailBody += '<body><table style="width:140%"><thead>';
		emailBody += '<tr><th><b>' + System.Label.KM_Order_Date;
		emailBody += '</b></th><th><b>' + System.Label.KM_Order;
		emailBody += '</b></th><th><b>' + System.Label.KM_Order_Type;
		emailBody += '</b></th><th><b>' + System.Label.KM_Line;
		emailBody += '</b></th><th><b>' + System.Label.KM_Product;
		emailBody += '</b></th><th><b>' + System.Label.KM_Quantity;
		emailBody += '</b></th><th><b>' + System.Label.KM_Customer_Price;
		emailBody += '</b></th><th><b>' + System.Label.KM_Amount;
		emailBody += '</b></th><th><b>' + System.Label.KM_Status;
		emailBody += '</b></th></tr></thead><tbody>';
		if (selectedOrders != null && !selectedOrders.isEmpty()) {
			for (Object eachOrderRec : (list<Object>) selectedOrders) {
				Map<string, Object> eachOrderRecMap = new Map<string, Object>();
				eachOrderRecMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachOrderRec));
				string orderDate = String.valueOf(eachOrderRecMap.get('OrderDate'));
				string orderNum = String.valueOf(eachOrderRecMap.get('OrderNum'));
				string originalOrderNum = String.valueOf(eachOrderRecMap.get('OriginalOrderNum'));
				string t9OrderNum = String.valueOf(eachOrderRecMap.get('T9OrderNum'));
				string orderType = String.valueOf(eachOrderRecMap.get('OrderType'));
				string originalOrderType = String.valueOf(eachOrderRecMap.get('OriginalOrderType'));
				string t9OrderType = String.valueOf(eachOrderRecMap.get('T9OrderType'));
				string orderLineNum = String.valueOf(eachOrderRecMap.get('OrderLineNum'));
				string originalOrderLineNo = String.valueOf(eachOrderRecMap.get('OriginalOrderLineNo'));
				string t9OrderLineNum = String.valueOf(eachOrderRecMap.get('T9OrderLineNum'));
				string productName = String.valueOf(eachOrderRecMap.get('ProductName'));
				string productNo = String.valueOf(eachOrderRecMap.get('ProductNo'));
				string unitSize = String.valueOf(eachOrderRecMap.get('UnitSize'));
				string quantity = String.valueOf(eachOrderRecMap.get('Quantity'));
				string currencyCode = String.valueOf(eachOrderRecMap.get('CurrencyCode'));
				string customerPrice = String.valueOf(eachOrderRecMap.get('CustomerPrice'));
				string amount = String.valueOf(eachOrderRecMap.get('Amount'));
				string nextStatus = String.valueOf(eachOrderRecMap.get('NextStatus'));
				if (string.isNotBlank(orderNumbers)) {
					orderNumbers = orderNumbers + ',' + orderNum;
				} else {
					orderNumbers = orderNum;
				}
				String linkedText = '';
				if (orderType == 'T9' && originalOrderLineNo != '0') {
					linkedText = '(OR LINKED)';
				} else if (orderType == 'TC' && t9OrderNum != '0') {
					linkedText = '(OR LINKED)';
				}
				emailBody += '<tr><td><div>' + orderDate + '<br/>' + linkedText + '</div></td>';
				String linkedOrderNum = '';
				if (orderType == 'T9') {
					linkedOrderNum = originalOrderNum;
				} else if (orderType == 'TC' && t9OrderNum != '0') {
					linkedOrderNum = t9OrderNum;
				}
				emailBody += '<td><div>' + orderNum + '<br/>' + linkedOrderNum + '</div></td>';
				String linkedOrderType = '';
				if (orderType == 'T9') {
					linkedOrderType = originalOrderType;
				} else if (orderType == 'TC' && t9OrderNum != '0') {
					linkedOrderType = t9OrderType;
				}
				emailBody += '<td><div>' + orderType + '<br/>' + linkedOrderType + '</div></td>';
				String linkedOrderLineNum = '';
				if (orderType == 'T9' && originalOrderLineNo != '0') {
					linkedOrderLineNum = originalOrderLineNo;
				} else if (orderType == 'TC' && t9OrderNum != '0') {
					linkedOrderLineNum = t9OrderLineNum;
				}
				emailBody += '<td><div>' + orderLineNum + '<br/>' + linkedOrderLineNum + '</div></td>';
				emailBody +=
					'<td><div>' +
					productName +
					'<br/><b>Product#:</b>' +
					productNo +
					'<br/><b>Unit Size:</b>' +
					unitSize +
					'</div></td>';
				emailBody += '<td><div>' + quantity + '</div></td>';
				emailBody += '<td><div>' + currencyCode + '&nbsp;' + customerPrice + '</div></td>';
				emailBody += '<td><div>' + currencyCode + '&nbsp;' + amount + '</div></td>';
				emailBody += '<td><div>' + nextStatus + '</div></td></tr>';
			}
		}
		emailBody += '</tbody></table></body></html>';
		String subject = '[ST#' + shipToNumber + '] Order#' + orderNumbers + ' 문의';
		Messaging.SingleEmailMessage sendEmail = new Messaging.SingleEmailMessage();
		sendEmail.setSubject(subject);
		sendEmail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
		sendEmail.setHtmlBody(emailBody);
		if (!Test.isRunningTest()) {
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ sendEmail });
		}
	}

	// Method Name: getOrderDetailList
	// Author: Jagadish Babu
	// Description: Methdo to Process Order detail list Integration response
	// Parameter 1: String OrderNumber - Request Body used in HTTP callouts
	// Parameter 2: String OrderType - Request Body used in HTTP callouts
	// Parameter 3: String OrderCompany - Request Body used in HTTP callouts
	@AuraEnabled
	public static KMOFMAuraResponse getOrderDetailList(String orderNumber, String orderType, String orderCompany) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				KMOrderDetailsFromE1Service.getOFMResponse(orderNumber, orderType, orderCompany)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getAvailabiltyInfo
	// Author: Ajinkya Hingne
	// Description: Methdo use to get OFM data.
	// Parameter 1: List-productNumber.
	// Parameter 2: String-shipNumber
	@AuraEnabled
	public static KMOFMAuraResponse getAvailabiltyInfo(List<String> productNos, String shipNumber) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				KMProudctAvailibilityService.getOFMResponseReorder(productNos, shipNumber)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	@AuraEnabled
	public static String getCartShipToNumber() {
		String shipToNumber = '';
		Map<String, Object> RespObj = new Map<String, Object>();
		RespObj = KoreaMobilityTabs.getCartData();
		Map<String, Object> orderDetailObj = (Map<String, Object>) RespObj.get('orderDetails');
		if (orderDetailObj != null) {
			shipToNumber = string.valueOf(orderDetailObj.get('shipToNumber'));
		}
		return shipToNumber;
	}

	// Method Name: getCartData
	// Author: Ajinkya Hingne
	// Description: Method use to get order details.
	@AuraEnabled
	public static Map<String, Object> getCartData() {
		return KoreaMobilityTabs.getCartData();
	}

	private static Set<String> getAccountFields() {
		return new Set<String>{
			'Id',
			'Name',
			'ERP_Account_Id__c',
			'Account_Alpha_Name__c',
			'Address_1__c',
			'Address_2__c',
			'Address_3__c',
			'City_f__c',
			'State_f__c',
			'Zip_Postal_Code_f__c',
			'Country__c',
			'Primary_Bill_To__r.ERP_Account_Id__c',
			'Primary_Bill_To__r.Name',
			'Primary_Bill_To__r.Address_1__c',
			'Primary_Bill_To__r.Address_2__c',
			'Primary_Bill_To__r.Address_3__c',
			'Primary_Bill_To__r.City_f__c',
			'Primary_Bill_To__r.State_f__c',
			'Primary_Bill_To__r.Zip_Postal_Code_f__c',
			'Primary_Bill_To__r.Country__c'
		};
	}

	private static Set<String> getAccountContactRelationshipFields() {
		return new Set<String>{
			'Id',
			'Contact.Id',
			'Contact.Name',
			'Contact.Email',
			'Contact.Phone',
			'Contact.Web_Status__c',
			'Contact.Contact_External_Id__c',
			'Account.Id',
			'Account.ERP_Account_Id__c',
			'Account.Account_Alpha_Name__c',
			'Account.Address_1__c',
			'Account.Address_2__c',
			'Account.Address_3__c',
			'Account.City_f__c',
			'Account.State_f__c',
			'Account.Zip_Postal_Code_f__c',
			'Account.Country__c',
			'Account.Primary_Bill_To__r.ERP_Account_Id__c',
			'Account.Primary_Bill_To__r.Name',
			'Account.Primary_Bill_To__r.Address_1__c',
			'Account.Primary_Bill_To__r.Address_2__c',
			'Account.Primary_Bill_To__r.Address_3__c',
			'Account.Primary_Bill_To__r.City_f__c',
			'Account.Primary_Bill_To__r.State_f__c',
			'Account.Primary_Bill_To__r.Zip_Postal_Code_f__c',
			'Account.Primary_Bill_To__r.Country__c'
		};
	}
}