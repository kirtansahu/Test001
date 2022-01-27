// ===========================================================================
//  Class Name  : KMOrderDetailsFromE1Service
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     : Korean Mobility Quick Order List service Functionality
//  Test Class  :
// ===========================================================================
public without sharing class KMServiceStopCode {
	public class ResponseDetail {
		@AuraEnabled
		public String STOPCODE;
		@AuraEnabled
		public String SERVICECODE;
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
	public List<ResponseDetail> responseDetail;

	// Method Name: getOFMResponse
	// Author: Sreenivas
	// Description: Methdo to Process the products info for Quick Order as Integration response
	// Parameter 1: List<Object> quickOrderList - Request Body used in HTTP callouts
	// Old CMDTs modified with new CMDTs
	public static KMServiceStopCode getOFMResponse(string shipToNumber) {
		KMServiceStopCode results = new KMServiceStopCode();
		String reqBody;
		HttpResponse response;
		try {
			if (String.isNotBlank(shipToNumber)) {
				Map<String, Object> shipToNumMap = new Map<String, Object>();
				shipToNumMap.put('Ship_TO_Number', shipToNumber);
				reqBody = JSON.serialize(shipToNumMap);
				String serviceStopCodeEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_GetServiceStopCode');
				response = getResponse(reqBody, serviceStopCodeEndpoint);
				if (response.getStatusCode() == 200) {
					string resResult = response.getBody();
					results = parse(resResult);
				} else {
					ExceptionHandlerController.createIntegrationException(
						'KMServiceStopCode',
						'getOFMResponse',
						'Order Form',
						'KM_OFM_GetServiceStopCode',
						'',
						System.today(),
						reqBody,
						response.getBody(),
						response.getStatus()
					);
					throw new KMOFMCalloutException(response.getStatus());
				}
			}
		} catch (exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMServiceStopCode',
					'getOFMResponse',
					'Order Form',
					'KM_OFM_GetServiceStopCode',
					'Error Occured while quering details. ' + ex.getMessage(),
					System.today(),
					reqBody,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
		}
		return results;
	}

	// Method Name: parse
	// Author: Sreenivas
	// Description: Method to parse the Response body
	// Parameter 1: String json - Response body of OFM Service
	public static KMServiceStopCode parse(String json) {
		return (KMServiceStopCode) System.JSON.deserialize(json, KMServiceStopCode.class);
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