// ===========================================================================
//  Class Name  : KMOrderDetailsFromE1Service
//  Company     : Keste @IDC
//  Author      : Jagadish Babu
//  Purpose     : Korean Mobility Order History List service Functionality
//  Test Class  : KMCustomersOrdersClsTest
// ===========================================================================

public without sharing class KMOrderDetailsFromE1Service {
	public class ResponseDetail {
		@AuraEnabled
		public OrderDetailHeader OrderDetailHeader;
		@AuraEnabled
		public List<OrderDetails> OrderDetails;
	}

	public class ResponseHeader {
		@AuraEnabled
		public String responseStatusCode;
		@AuraEnabled
		public String responseStatus;
		@AuraEnabled
		public Object responseStatusMsg;
	}
	@AuraEnabled
	public ResponseHeader responseHeader;
	@AuraEnabled
	public ResponseDetail responseDetail;

	public class OrderDetails {
		@AuraEnabled
		public String ProductNum;

		@AuraEnabled
		public String ProductName;
		@AuraEnabled
		public Integer ShipToNum;
		@AuraEnabled
		public String UnitSize;
		@AuraEnabled
		public String Status;
		@AuraEnabled
		public Integer Quantity;
		@AuraEnabled
		public String CustomerPrice {
			get {
				String value = '';
				if (this.CustomerPrice != '') {
					decimal outputvalues = decimal.valueOf(this.CustomerPrice);
					Integer val = outputvalues.intValue();
					value = String.valueOf(this.CurrencyCode) + ' ' + String.valueOf(val.format());
					return value;
				}
				return value;
			}
			set;
		}
		@AuraEnabled
		public String ShipmentDate;
		@AuraEnabled
		public String UserRequestedDate;
		@AuraEnabled
		public String AvailabilityDate;
		@AuraEnabled
		public String Carrier;
		@AuraEnabled
		public String OrderType;
		@AuraEnabled
		public String OrderCompany;
		@AuraEnabled
		public Integer OrderNum;
		@AuraEnabled
		public String TrackingNumber;
		@AuraEnabled
		public String LineNumber;
		@AuraEnabled
		public String CurrencyCode;
		@AuraEnabled
		public String T9OrderCompany;
		@AuraEnabled
		public String T9OrderType;
		@AuraEnabled
		public String T9OrderNum;
		@AuraEnabled
		public String T9OrderLineNum;
		@AuraEnabled
		public String OriginalOrderNum;
		@AuraEnabled
		public String OriginalOrderCompany;
		@AuraEnabled
		public String OriginalOrderType;
		@AuraEnabled
		public Integer OriginalOrderLineNo;
	}

	public class OrderDetailHeader {
		public String ShipToName;
		public String ShipToAddress;
		public String BillToName;
		public String BillToAddress;
	}

	// Method Name: getOFMResponse
	// Author: Jagadish Babu
	// Description: Service Method to Process the Input request and return the service response
	// Parameter 1: String OrderNumber - OrderNumber for Request body of OFM services
	// Parameter 2: String OrderType - OrderType for Request body of OFM services
	// Parameter 3: String OrderType -  OrderCompany for Request body of OFM services
	//Old CMDTs are modified with the new CMDTs
	public static KMOrderDetailsFromE1Service getOFMResponse(
		String OrderNumber,
		String OrderType,
		String OrderCompany
	) {
		KMOrderDetailsFromE1Service results = new KMOrderDetailsFromE1Service();
		String reqBody;
		HttpResponse response;
		try {
			reqBody = '{';
			if (OrderNumber != '') {
				reqBody += '"OrderNumber" : "';
				reqBody += OrderNumber != '' ? (OrderNumber + '"') : null;
			}
			if (OrderType != '') {
				reqBody += ',"OrderType" : "';
				reqBody += OrderType != '' ? (OrderType + '"') : null;
			}
			if (OrderCompany != '') {
				reqBody += ',"OrderCompany" : "';
				reqBody += OrderCompany != '' ? (OrderCompany + '"') : null;
			}
			reqBody += '}';
			String OrderDetailsEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_OrderDetails');
			response = getResponse(reqBody, OrderDetailsEndpoint);
			if (response.getStatusCode() == 200) {
				results = parse(response.getBody());
				ExceptionHandlerController.createIntegrationException(
					'KMOrderDetailsFromE1Service',
					'getOFMResponse',
					'KMCustomerOrderCls Order Details',
					'KM_OFM_OrderDetails',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMOrderDetailsFromE1Service',
					'getOFMResponse',
					'KMCustomerOrderCls Order Details',
					'KM_OFM_OrderDetails',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
				throw new KMOFMCalloutException(response.getStatus());
			}
		} catch (Exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMOrderDetailsFromE1Service',
					'getOFMResponse',
					'KMCustomerOrderCls Order Details',
					'KM_OFM_OrderDetails',
					'Error Occured while quering details. ' + ex.getMessage(),
					System.today(),
					reqBody,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			throw new KMOFMCalloutException(errorMessage);
		}
		return results;
	}

	// Method Name: parse
	// Author: Jagadish Babu
	// Description: Method to parse the Response body
	// Parameter 1: String json - Response body of OFM Service
	public static KMOrderDetailsFromE1Service parse(String json) {
		return (KMOrderDetailsFromE1Service) System.JSON.deserialize(json, KMOrderDetailsFromE1Service.class);
	}

	/* * * * * * * * * * * * * *
	 * Method Name: getResponse
	 * Purpose: Old endpoints modified with New Urls
	 * Author: Hardik Mehta
	 * Company: Keste
	 * Created Date: 30-June-2020
	 * Type: Method
	 * * * * * * * * * * * * * */
	public static HttpResponse getResponse(String reqBody, String endPointUrl) {
		HttpResponse objResponse = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		return objResponse;
	}
}