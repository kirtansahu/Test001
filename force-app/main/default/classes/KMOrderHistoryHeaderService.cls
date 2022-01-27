// ===========================================================================
//  Class Name  : KMOrderHistoryHeaderService
//  Company     : Keste @IDC
//  Author      : Jagadish Babu
//  Purpose     : Korean Mobility Order History Header service Functionality
//  Test Class  : KMCustomersOrdersClsTest
// ===========================================================================
public without sharing class KMOrderHistoryHeaderService {
	public ServiceResult responseHeader;
	@auraEnabled
	public List<OrderHederDetails> responseDetail;

	// Method Name: parse
	// Author: Jagadish Babu
	// Description: Method to parse the response from the OFM
	// Parameter 1: String json - Response body of OFM Service
	public static KMOrderHistoryHeaderService parse(String json) {
		return (KMOrderHistoryHeaderService) System.JSON.deserialize(json, KMOrderHistoryHeaderService.class);
	}

	// Method Name: getOFMResponse
	// Author: Jagadish Babu
	// Description: Service Method to Process the Input request and return the service response
	// Parameter 1: String shipTo - Request Body of the Service
	// Parameter 2: String siebelRowId - Request Body of the Service
	// Old CMDTs modified with new CMDTs
	public static KMOrderHistoryHeaderService getOFMResponse(String shipTo, String siebelRowId) {
		KMOrderHistoryHeaderService results = new KMOrderHistoryHeaderService();
		String reqBody = '';
		HttpResponse response;
		try {
			reqBody = '{';
			if (shipTo != '') {
				reqBody += '"ShipToNumber" : "';
				reqBody += shipTo != '' ? (shipTo + '"') : null;
			}
			if (siebelRowId != '') {
				reqBody += ',"SiebelRowID" : "';
				reqBody += siebelRowId != '' ? (siebelRowId + '"') : null;
			}
			reqBody += '}';
			//added by Hardik Mehta to consume new secure API
			String orderHistoryEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_OrderHistoryHeader');
			response = getResponse(reqBody, orderHistoryEndpoint);

			if (response.getStatusCode() == 200) {
				results = parse(response.getBody());
				ExceptionHandlerController.createIntegrationException(
					'KMOrderHistoryHeaderService',
					'getOFMResponse',
					'KMCustomerOrderCls Order History',
					'KM_OFM_OrderHistoryHeader',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMOrderHistoryHeaderService',
					'getOFMResponse',
					'KMCustomerOrderCls Order History',
					'KM_OFM_OrderHistoryHeader',
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
					'KMOrderHistoryHeaderService',
					'getOFMResponse',
					'KMCustomerOrderCls Order History',
					'KM_OFM_OrderHistoryHeader',
					'Error Occured while queryng details. ' + ex.getMessage(),
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

	public class ServiceResult {
		public String responseStatusCode;
		public String responseStatus;
		public String responseStatusMsg;
	}
	public class OrderHederDetails {
		@auraEnabled
		public String ContactName;
		@auraEnabled
		public String OrderNumber;
		@auraEnabled
		public String PONumber;
		@auraEnabled
		public String OrderDate;
		@auraEnabled
		public String TotalVal {
			get {
				String value = '';
				if (this.Total != null && this.Total != '') {
					decimal outputvalues = decimal.valueOf(this.Total);
					Integer val = outputvalues.intValue();
					value = String.valueOf(this.CurrencyCode) + ' ' + String.valueOf(val.format());
					return value;
				}
				return value;
			}
			set;
		}
		@auraEnabled
		public String Total;
		@auraEnabled
		public String Status;
		@auraEnabled
		public String HoldCode;
		@auraEnabled
		public String OrderType;
		@auraEnabled
		public String OrderMode;
		@auraEnabled
		public String OrderCompany;
		@auraEnabled
		public String BillToNumber;
		@auraEnabled
		public String CurrencyCode;
		@auraEnabled
		public String PromoNum;
		@auraEnabled
		public String ContactLineId;
		@auraEnabled
		public String ContactFirstName;
		@auraEnabled
		public String ContactLastName;
	}

	/* * * * * * * * * * * * * *
	 * Method Name: getResponse
	 * Purpose: call new secure API URL for Order History
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