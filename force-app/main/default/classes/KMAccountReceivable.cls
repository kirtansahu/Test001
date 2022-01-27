// ===========================================================================
//  Class Name  : KMAccountReceivable
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     : Korean Mobility Account Receivable Tab Functionality
//  Test Class  : KMAccountReceivable_Test
// ===========================================================================
public without sharing class KMAccountReceivable {
	// Method Name: getAccountReceivableDetails
	// Author: Rambabu gadde
	// Description: Method to Process the Account Records
	// Parameter 1: Integer accountOffset
	// Parameter 2: String Searchtext.
	@AuraEnabled
	public static List<Account> getAccountReceivableDetails(Integer accountOffset, String searchtext) {
		String accountSearchInput = '%' + searchtext + '%';
		List<Account> accList = [
			SELECT
				Id,
				Name,
				ERP_Account_Id__c,
				Account_Alpha_Name__c,
				Address_1__c,
				Address_2__c,
				Address_3__c,
				City_f__c,
				State_f__c,
				Zip_Postal_Code_f__c,
				Country__c,
				Price_Book__c,
				Primary_Bill_To__r.ERP_Account_Id__c,
				Primary_Bill_To__r.Name,
				Primary_Bill_To__r.Address_1__c,
				Primary_Bill_To__r.Address_2__c,
				Primary_Bill_To__r.Address_3__c,
				Primary_Bill_To__r.City_f__c,
				Primary_Bill_To__r.State_f__c,
				Primary_Bill_To__r.Zip_Postal_Code_f__c,
				Primary_Bill_To__r.Country__c
			FROM Account
			WHERE
				(ERP_Account_Id__c LIKE :accountSearchInput
				OR Account_Alpha_Name__c LIKE :accountSearchInput)
				AND RecordType.Name = :System.Label.KM_ShipToRecordType
				AND Price_Book__r.Name = :System.Label.KM_ShipTo_PriceList
			LIMIT :Integer.valueOf(System.Label.KM_Record_Limits)
			OFFSET :accountOffset
		];
		return accList;
	}

	// Method Name: getparticularAccount
	// Author: Rambabu Gadde
	// Description: Method to Process the Account Record
	// Parameter : String AccountId.
	@AuraEnabled
	public static Account getparticularAccount(String accountId) {
		Account acc = new Account();
		//Ftech Account record Based on parameter.
		acc = [
			SELECT
				Id,
				Name,
				ERP_Account_Id__c,
				State__c,
				Account_Alpha_Name__c,
				Address_1__c,
				Address_2__c,
				Address_3__c,
				City_f__c,
				State_f__c,
				Zip_Postal_Code_f__c,
				Country__c,
				Primary_Bill_To__r.ERP_Account_Id__c,
				Primary_Bill_To__r.Name,
				Primary_Bill_To__r.Address_1__c,
				Primary_Bill_To__r.Address_2__c,
				Primary_Bill_To__r.Address_3__c,
				Primary_Bill_To__r.City_f__c,
				Primary_Bill_To__r.State_f__c,
				Primary_Bill_To__r.Zip_Postal_Code_f__c,
				Primary_Bill_To__r.Country__c
			FROM Account
			WHERE
				ERP_Account_Id__c = :accountId
				AND RecordType.Name = :System.label.KM_ShipToRecordType
				AND Price_Book__r.Name = :System.label.KM_ShipTo_PriceList
			LIMIT 1
		];
		return acc;
	}

	// Method Name: getInvoicedetails
	// Author: Rambabu Gadde
	// Description: This Method is used to  get the OFM AccountReceivable Invoice details for Account.
	// Parameter1 : String OrderNumber.
	// Parameter2 : String OrderType.
	// Parameter3 : String OrderCompany.
	//Old CMDTs modified with new CMDTs

	@AuraEnabled
	public static KMOFMAuraResponse getInvoicedetails(String orderNumber, String orderType, String orderCompany) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				(List<Object>) getARInvoiceDetails(orderNumber, orderType, orderCompany)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getOFMResponse
	// Author: Rambabu Gadde
	// Description: This Method is used to  get the OFM AccountReceivable header  for Account.
	// Parameter1 : String shipTo.
	// @AuraEnabled
	// public static KMAccountReceivableService getOFMResponse(String shipTo) {
	//     return KMAccountReceivableService.getOFMResponse(shipTo);
	// }

	@AuraEnabled
	public static KMOFMAuraResponse getOFMResponse(String shipTo) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(true, KMAccountReceivableService.getOFMResponse(shipTo));
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getArExtention
	// Author: Rambabu Gadde
	// Description: This Method is used to  get the  AccountReceivable Extenstion  for Invoice.
	// Parameter1 : String InvoiceCompany.
	// Parameter2 : String InvoiceNumber.
	// Parameter3 : String invoicetype.
	@AuraEnabled
	public static KMOFMAuraResponse getArExtention(String invoiceCompany, String invoiceNumber, String invoicetype) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				(List<Object>) getARExtensions(invoiceCompany, invoiceNumber, invoicetype)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Old endpoints modified with New Urls
	// Modified By: Hardik Mehta
	// Date:30-06-2020
	public static HttpResponse getResponse(String reqBody, String endPointUrl) {
		HttpResponse objResponse = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		return objResponse;
	}

	private static List<ARInvoicedetails> getARInvoiceDetails(
		String orderNumber,
		String orderType,
		String orderCompany
	) {
		String Jsonrequest;
		String jsonresponse;
		String jsonstatus;
		HTTPResponse res;
		List<ARInvoicedetails> details = new List<ARInvoicedetails>();
		try {
			//Old Endpoint URL modified by secure new Urls
			String OrderDetailE1Endpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_OrderDetails');
			JsonRequest =
				'{"OrderNumber" : "' +
				orderNumber +
				'","OrderType" : "' +
				orderType +
				'","OrderCompany" : "' +
				orderCompany +
				'"}';
			res = getResponse(JsonRequest, OrderDetailE1Endpoint);
			Jsonresponse = res.getBody();
			JsonStatus = res.getStatus();
			ARInvoicedetails Arivoices = new ARInvoicedetails();
			//deserialize the Josn Response
			if (res.getStatusCode() == 200) {
				System.JSONParser parser = System.JSON.createParser(res.getBody());
				while (parser.nextToken() != null) {
					if (parser.getCurrentToken() == jsontoken.FIELD_NAME && parser.getText() == 'OrderDetails') {
						parser.nextToken();
						if (parser.getCurrentToken() == jsontoken.START_ARRAY) {
							parser.nextToken();
							while (parser.getCurrentToken() == jsontoken.START_OBJECT) {
								Arivoices = (ARInvoicedetails) parser.readValueAs(ARInvoicedetails.class);
								parser.nextToken();
								details.add(Arivoices);
							}
						}
					}
				}
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivable',
					'getInvoicedetails',
					'AccountReceivableComponent',
					'KM_OFM_OrderDetails',
					'',
					System.today(),
					jsonrequest,
					jsonResponse,
					jsonStatus
				);
			} else {
				//Create Apex Log to record JSON request & response
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivable',
					'getInvoicedetails',
					'AccountReceivableComponent',
					'KM_OFM_OrderDetails',
					'',
					System.today(),
					jsonrequest,
					jsonResponse,
					jsonStatus
				);
				throw new KMOFMCalloutException(res.getStatus());
			}
		} catch (exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				//Create Apex Log to record JSON request & response
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivable',
					'getInvoicedetails',
					'AccountReceivableComponent',
					'KM_OFM_OrderDetails',
					ex.getMessage(),
					System.today(),
					jsonrequest,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			throw new KMOFMCalloutException(errorMessage);
		}
		return details;
	}

	private static List<AccountReceivableExtention> getARExtensions(
		String invoiceCompany,
		String invoiceNumber,
		String invoicetype
	) {
		List<AccountReceivableExtention> extenstiondetails = new List<AccountReceivableExtention>();
		String setBodys;
		HTTPResponse res;
		try {
			String ARExtentionEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_ARDetails');
			setBodys =
				'{"invoiceCompany" : "' +
				invoiceCompany +
				'","invoiceNumber" : "' +
				invoiceNumber +
				'","invoiceType" : "' +
				invoicetype +
				'"}';
			res = getResponse(Setbodys, ARExtentionEndpoint);
			AccountReceivableExtention extenstion = new AccountReceivableExtention();
			if (res.getStatusCode() == 200) {
				//deserialize Json response.
				System.JSONParser parser = System.JSON.createParser(res.getBody());
				while (parser.nextToken() != null) {
					if (parser.getCurrentToken() == jsontoken.FIELD_NAME && parser.getText() == 'responseDetail') {
						parser.nextToken();
						if (parser.getCurrentToken() == jsontoken.START_ARRAY) {
							parser.nextToken();
							while (parser.getCurrentToken() == jsontoken.START_OBJECT) {
								extenstion = (AccountReceivableExtention) parser.readValueAs(
									AccountReceivableExtention.class
								);
								parser.nextToken();
								extenstiondetails.add(extenstion);
							}
						}
					}
				}
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivable',
					'getArExtention',
					'AccountReceivableComponent',
					'KM_OFM_ARDetails',
					'',
					System.today(),
					Setbodys,
					res.getBody(),
					res.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivable',
					'getArExtention',
					'AccountReceivableComponent',
					'KM_OFM_ARDetails',
					'',
					System.today(),
					Setbodys,
					res.getBody(),
					res.getStatus()
				);
				throw new KMOFMCalloutException(res.getStatus());
			}
		} catch (exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				//Create Apex Log to record JSON request & response
				ExceptionHandlerController.createIntegrationException(
					'KMAccountReceivable',
					'getArExtention',
					'AccountReceivableComponent',
					'KM_OFM_ARDetails',
					ex.getMessage(),
					System.today(),
					setBodys,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			throw new KMOFMCalloutException(errorMessage);
		}
		return extenstiondetails;
	}

	//  Wrapper class for ARInvoicedetails
	public class ARInvoicedetails {
		@AuraEnabled
		public String ProductNum { get; set; }
		@AuraEnabled
		public String ProductName { get; set; }
		@AuraEnabled
		public integer ShipToNum { get; set; }
		@AuraEnabled
		public String UnitSize { get; set; }
		@AuraEnabled
		public String Status { get; set; }
		@AuraEnabled
		public String Quantity { get; set; }
		@AuraEnabled
		public String CustomerPrice {
			get {
				if (this.CustomerPrice != '0') {
					decimal outputvalues = decimal.valueOf(this.CustomerPrice);
					Integer val = outputvalues.intValue();
					this.CustomerPrice = +'KRW ' + String.valueOf(val.format());
					return this.CustomerPrice;
				}
				return this.CustomerPrice;
			}
			set;
		}
		@AuraEnabled
		public String ShipmentDate { get; set; }
		@AuraEnabled
		public String UserRequestedDate { get; set; }
		@AuraEnabled
		public String AvailabilityDate { get; set; }
		@AuraEnabled
		public String Carrier { get; set; }
		@AuraEnabled
		public String OrderType { get; set; }
		@AuraEnabled
		public String OrderCompany { get; set; }
		@AuraEnabled
		public integer OrderNum { get; set; }
		@AuraEnabled
		public String TrackingNumber { get; set; }
		@AuraEnabled
		public String LineNumber { get; set; }
		@AuraEnabled
		public String CurrencyCode { get; set; }
		@AuraEnabled
		public String T9OrderCompany { get; set; }
		@AuraEnabled
		public String T9OrderType { get; set; }
		@AuraEnabled
		public String T9OrderNum { get; set; }
		@AuraEnabled
		public String T9OrderLineNum { get; set; }
		@AuraEnabled
		public String OriginalOrderNum { get; set; }
		@AuraEnabled
		public String OriginalOrderCompany { get; set; }
		@AuraEnabled
		public String OriginalOrderType { get; set; }
		@AuraEnabled
		public String OriginalOrderLineNo { get; set; }
	}

	//Wrapper class for ARExtentions
	public class AccountReceivableExtention {
		@AuraEnabled
		public String orderType { get; set; }
		@AuraEnabled
		public String orderNumber { get; set; }
		@AuraEnabled
		public String orderCompany { get; set; }
		@AuraEnabled
		public String shipToNum { get; set; }
	}
}