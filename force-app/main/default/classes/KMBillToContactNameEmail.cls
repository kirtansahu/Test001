// ===========================================================================
//  Class Name  : KMBillToContactNameEmail
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     : Korean Mobility Quick Order List service Functionality
//  Test Class  : KMBillToContactNameEmailTest
// ===========================================================================
public without sharing class KMBillToContactNameEmail {
	public class ResponseDetail {
		@AuraEnabled
		public String WWMLNM;
		@AuraEnabled
		public String EAEMAL;
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
	public static KMBillToContactNameEmail getOFMResponse(string billToNumber) {
		KMBillToContactNameEmail results = new KMBillToContactNameEmail();
		String reqBody;
		HttpResponse response;
		try {
			if (String.isNotBlank(billToNumber)) {
				Map<String, Object> billToNumMap = new Map<String, Object>();
				billToNumMap.put('Bill_TO_Number', billToNumber);
				reqBody = JSON.serialize(billToNumMap);
				String billToCTNameEmailEndpoint = KMOFMServicesHelper.getServiceEndpoint(
					'KM_OFM_GetBillToContactNameEmail'
				);
				response = getResponse(reqBody, billToCTNameEmailEndpoint);
				if (response.getStatusCode() == 200) {
					string resResult = response.getBody();
					results = parse(resResult);
					ExceptionHandlerController.createIntegrationException(
						'KMBillToContactNameEmail',
						'getOFMResponse',
						'Thermobile Order History Detail',
						'KM_OFM_GetBillToContactNameEmail',
						'',
						System.today(),
						reqBody,
						response.getBody(),
						response.getStatus()
					);
				} else {
					ExceptionHandlerController.createIntegrationException(
						'KMBillToContactNameEmail',
						'getOFMResponse',
						'Thermobile Order History Detail',
						'KM_OFM_GetBillToContactNameEmail',
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
					'KMBillToContactNameEmail',
					'getOFMResponse',
					'Thermobile Order History Detail',
					'KM_OFM_GetBillToContactNameEmail',
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
	// Author: Sreenivas
	// Description: Method to parse the Response body
	// Parameter 1: String json - Response body of OFM Service
	public static KMBillToContactNameEmail parse(String json) {
		return (KMBillToContactNameEmail) System.JSON.deserialize(json, KMBillToContactNameEmail.class);
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