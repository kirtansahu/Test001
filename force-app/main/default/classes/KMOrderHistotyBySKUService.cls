// ===========================================================================
//  Class Name  : KMOrderHistotyBySKUService
//  Company     : Keste @IDC
//  Author      : Jagadish Babu
//  Purpose     : Korean Mobility Order History by SKU OFM service Functionality
//  Test Class  : KMCustomersOrdersClsTest
// ===========================================================================

public without sharing class KMOrderHistotyBySKUService {
	public class ResponseDetail {
		@auraEnabled
		public String OrderType;
		@auraEnabled
		public String OrderDate;
		@auraEnabled
		public String OrderNum;
		@auraEnabled
		public String OrderLineNum;
		@auraEnabled
		public String ShipToNum;
		@auraEnabled
		public String ProductNo;
		@auraEnabled
		public String ProductName;
		@auraEnabled
		public String UnitSize;
		@auraEnabled
		public String LotNo;
		@auraEnabled
		public String NextStatus;
		@auraEnabled
		public String HoldCode;
		@auraEnabled
		public Integer Quantity;
		@auraEnabled
		public Integer CancelledQuanity;
		@auraEnabled
		public Integer FutureQuanity;
		@auraEnabled
		public Integer ShippedQuantity;
		@auraEnabled
		public Integer BackorderQuantity;
		@auraEnabled
		public String CustomerPrice {
			get {
				if (this.CustomerPrice != '0') {
					decimal outputvalues = decimal.valueOf(this.CustomerPrice);
					Integer val = outputvalues.intValue();
					this.CustomerPrice = String.valueOf(val.format());
					return this.CustomerPrice;
				}
				return this.CustomerPrice;
			}
			set;
		}

		@auraEnabled
		public String CurrencyCode;
		@auraEnabled
		public String Amount {
			get {
				if (this.Amount != '0') {
					decimal outputvalues = decimal.valueOf(this.Amount);
					Integer val = outputvalues.intValue();
					this.Amount = String.valueOf(val.format());
					return this.Amount;
				}
				return this.Amount;
			}
			set;
		}
		@auraEnabled
		public String BalanceQtytobeinvoiced;
		@auraEnabled
		public String ContactLineId;
		@auraEnabled
		public String OrderMode;
		@auraEnabled
		public String Quote;
		@auraEnabled
		public String Filler_Field;
		@auraEnabled
		public String T9OrderCompany;
		@auraEnabled
		public String T9OrderType;
		@auraEnabled
		public String T9OrderNum;
		@auraEnabled
		public String T9OrderLineNum;
		@auraEnabled
		public String OriginalOrderNum;
		@auraEnabled
		public String OriginalOrderType;
		@auraEnabled
		public String OriginalOrderLineNo;
		@auraEnabled
		public String OriginalOrderCompany;
		@auraEnabled
		public String OrderTable;
	}

	public class ResponseHeader {
		public String responseStatusCode;
		public String responseStatus;
	}
	@auraEnabled
	public ResponseHeader responseHeader;
	@auraEnabled
	public List<ResponseDetail> responseDetail;

	// Method Name: parse
	// Author: Jagadish Babu
	// Description: Method to parse the response body
	// Parameter 1: String json - Response body of OFM services
	public static KMOrderHistotyBySKUService parse(String json) {
		return (KMOrderHistotyBySKUService) System.JSON.deserialize(json, KMOrderHistotyBySKUService.class);
	}

	// Method Name: getOFMResponse
	// Author: Jagadish Babu
	// Description: Service Method to Process the Input request and return the service response
	// Parameter 1: String shipTo - ShipTo Number
	// Parameter 2: String fromDt - from Date for the Duration
	// Parameter 3: String toDt - To Date for the Duration
	public static KMOrderHistotyBySKUService getOFMResponse(String shipTo, String fromDt, String toDt) {
		KMOrderHistotyBySKUService results = new KMOrderHistotyBySKUService();
		String reqBody = '';
		HttpResponse response;
		try {
			reqBody = '{';
			if (shipTo != '') {
				reqBody += '"IN_SHIPTONUM" : "';
				reqBody += shipTo != '' ? (shipTo + '"') : null;
			}
			if (fromDt != '') {
				reqBody += ',"IN_FROMDATE" : "';
				reqBody += fromDt != '' ? (fromDt + '"') : null;
			}
			if (toDt != '') {
				reqBody += ',"IN_TODATE" : "';
				reqBody += toDt != '' ? (toDt + '"') : null;
			}
			reqBody += '}';
			//added by Hardik Mehta to consume new secure API
			String reOrderHistoryEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_GetReorder_History');
			response = getResponse(reqBody, reOrderHistoryEndpoint);
			if (response.getStatusCode() == 200) {
				results = parse(response.getBody());
				ExceptionHandlerController.createIntegrationException(
					'KMOrderHistotyBySKUService',
					'getOFMResponse',
					'KMCustomerOrderCls Order History By SKU',
					'KM_OFM_GetReorder_History',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMOrderHistotyBySKUService',
					'getOFMResponse',
					'KMCustomerOrderCls Order History By SKU',
					'KM_OFM_GetReorder_History',
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
					'KMOrderHistotyBySKUService',
					'getOFMResponse',
					'KMCustomerOrderCls Order History By SKU',
					'KM_OFM_GetReorder_History',
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