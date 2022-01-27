// ===========================================================================
//  Class Name  : KMProudctAvailibilityService
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     : Korean Mobility Product Tab Functionality
//  Test Class  : KMProductAvailibility_Test
// ===========================================================================
public without sharing class KMProudctAvailibilityService {
	public static list<OFMProductLists> oFMProductResult;

	// Method Name: getOFMResponse
	// Author: Rambabu Gadde
	// Description: Methdo use to get the OFM Data.
	// Parameter 1: String-productNumber.
	// Parameter 2: String-shipNumber.
	//Old CMDTs modified with new CMDTs
	@AuraEnabled
	public static PriceAvailabilityInfo getOFMResponse(String productNumber, String shipNumber) {
		PriceAvailabilityInfo priceInfo = new PriceAvailabilityInfo();
		String reqBody;
		HttpResponse response;
		try {
			reqBody = '';
			reqBody = '{' + '"PriceAndAvailabilityInfo":[';
			reqBody +=
				'{' +
				'"target":"E1",' +
				'"USER":"PANDA:USER_KEY:785189_CART_KEY:NOCARTKEY_TIME_STAMP:1509096173583",';
			reqBody += '"PWD":"@GES12",' + '"ROLE":"*ALL",' + '"ENV":"' + System.Label.KM_PandaAPI_ENV + '",';
			if (shipNumber != null) {
				reqBody += '"SHIPTO":"' + shipNumber + '",';
			} else {
				reqBody += '"SHIPTO":"' + System.Label.KM_PA_Default_ShipTo + '",';
			}
			reqBody += '"COMPANYCODE1":"00100",';
			reqBody += '"pandaItemDetails":[{';
			reqBody +=
				'"ITEMLINENUMBER":"4",' +
				'"REQUESTTYPE":"PA",' +
				'"SKUNUMBER":"' +
				productNumber +
				'"' +
				',"DESIREDQUANTITY":"1",';
			reqBody +=
				'"ITEMTYPE":"catalog",' +
				'"UOM":"EA",' +
				'"MPN":"' +
				productNumber +
				'"' +
				'}' +
				']' +
				'}' +
				']' +
				'}';
			String productInfoEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_Panda');
			response = getResponse(reqBody, productInfoEndpoint);
			if (response.getStatusCode() == 200) {
				//Deseralize the httpresponse
				System.JSONParser parser = System.json.createParser(response.getBody());
				while (parser.nextToken() != null) {
					if (parser.getCurrentToken() == jsontoken.FIELD_NAME && parser.getText() == 'reponseInfo') {
						parser.nextToken();
						if (parser.getCurrentToken() == jsontoken.START_ARRAY) {
							parser.nextToken();
							while (parser.getCurrentToken() == jsontoken.START_OBJECT) {
								priceInfo = (PriceAvailabilityInfo) parser.readValueAs(PriceAvailabilityInfo.class);
								parser.nextToken();
							}
						}
					}
				}
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability',
					'KM_OFM_Panda',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
			} else {
				//Create Apex Log to record JSON request & response
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability',
					'KM_OFM_Panda',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
				throw new KMOFMCalloutException(response.getStatus());
			}
		} catch (exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				//Create Apex Log to record JSON request & response
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability',
					'KM_OFM_Panda',
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
		return priceInfo;
	}

	// Method Name: getOFMResponse
	// Author: Rambabu Gadde
	// Description: Methdo use to get the OFM Data.
	// Parameter 1: String-productNumber.
	// Parameter 2: String-shipNumber.
	//Modified old CMDTs with the new CMDTs
	@AuraEnabled
	public static list<OFMProductLists> getOFMProductResponse(String searchText) {
		httpResponse response;
		list<OFMProductLists> productLists = new List<OFMProductLists>();
		String body;
		try {
			body = '';
			if (searchText != null) {
				body = '{"searchCriteria": "';
				body += searchText + '"}';
			}
			String reqEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_ProductInfo');
			OFMProductLists productResult = new OFMProductLists();
			response = getResponse(body, reqEndpoint);
			if (response.getStatusCode() == 200) {
				System.JSONParser parser = System.json.createParser(response.getBody());
				while (parser.nextToken() != null) {
					if (parser.getCurrentToken() == jsontoken.FIELD_NAME && parser.getText() == 'responseDetail') {
						parser.nextToken();
						if (parser.getCurrentToken() == jsontoken.START_ARRAY) {
							parser.nextToken();
							while (parser.getCurrentToken() == jsontoken.START_OBJECT) {
								productResult = (OFMProductLists) parser.readValueAs(OFMProductLists.class);
								productLists.add(productResult);
								parser.nextToken();
							}
						}
					}
				}
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMProductResponse',
					'Product Search',
					'KM_OFM_ProductInfo',
					'',
					System.today(),
					body,
					response.getBody(),
					response.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMProductResponse',
					'Product Search',
					'KM_OFM_ProductInfo',
					'',
					System.today(),
					body,
					response.getBody(),
					response.getStatus()
				);
				throw new KMOFMCalloutException(response.getStatus());
			}
		} catch (CalloutException calloutEx) {
			String exceptionMsg = calloutEx.getMessage();
			ExceptionHandlerController.createIntegrationException(
				'KMProudctAvailibilityService',
				'getOFMResponse',
				'Product availability',
				'KM_OFM_Panda',
				'Error Occured while quering details. ' + exceptionMsg,
				System.today(),
				Body,
				'',
				''
			);
			if (exceptionMsg.containsIgnoreCase('Exceeded max size limit')) {
				exceptionMsg = System.Label.KM_Size_Limit_Exceed_Message;
			}
			throw new KMOFMCalloutException(exceptionMsg);
		} catch (exception ex) {
			String errorMessage;
			if (ex.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = ex.getMessage();
			} else {
				//Create Apex Log to record JSON request & response
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability',
					'KM_OFM_Panda',
					'Error Occured while quering details. ' + ex.getMessage(),
					System.today(),
					Body,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			throw new KMOFMCalloutException(errorMessage);
		}
		return productLists;
	}

	@AuraEnabled
	public static Map<String, List<KMProudctAvailibilityService.ReponseInfo>> getOFMResponseReorder(
		List<String> productNos,
		String shipNumber
	) {
		String itemDetail;
		String reqBody = '';
		HttpResponse response;
		List<String> itemDetails = new List<String>();
		PriceAvailabilityInfo priceInfo;
		List<KMProudctAvailibilityService.PandaItemDetails> productDetails = new List<KMProudctAvailibilityService.PandaItemDetails>();
		Map<String, List<KMProudctAvailibilityService.ReponseInfo>> responseInfo;
		try {
			reqBody = '{' + '"PriceAndAvailabilityInfo":[';
			reqBody +=
				'{' +
				'"target":"E1",' +
				'"USER":"PANDA:USER_KEY:785189_CART_KEY:NOCARTKEY_TIME_STAMP:1509096173583",';
			reqBody += '"PWD":"@GES12",' + '"ROLE":"*ALL",' + '"ENV":"' + System.Label.KM_PandaAPI_ENV + '",';

			if (shipNumber != null) {
				reqBody += '"SHIPTO":"' + shipNumber + '",';
			} else {
				reqBody += '"SHIPTO":"' + System.Label.KM_PA_Default_ShipTo + '",';
			}

			reqBody += '"COMPANYCODE1":"00100",';
			reqBody += '"pandaItemDetails":[';

			for (String productNumber : productNos) {
				itemDetail =
					'{"ITEMLINENUMBER" : "4", "REQUESTTYPE" : "PA", "SKUNUMBER" : "' +
					productNumber +
					'", "DESIREDQUANTITY" : "1",' +
					'"ITEMTYPE" : "catalog", "UOM" : "EA", "MPN" : "' +
					productNumber +
					'"}';
				itemDetails.add(itemDetail);
			}
			reqBody += String.join(itemDetails, ',') + '] } ] }';

			String productInfoEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_Panda');

			response = getResponse(reqBody, productInfoEndpoint);
			if (response.getStatusCode() == 200) {
				Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
				List<Map<String, Object>> test = new List<Map<String, Object>>();
				List<Object> paInfo = (List<Object>) responseMap.get('PriceAndAvailabilityInfo');
				String productDetailsString = JSON.serialize(paInfo[0]);
				KMProudctAvailibilityService.PAInfo pa = (KMProudctAvailibilityService.PAInfo) System.JSON.deserialize(
					productDetailsString,
					KMProudctAvailibilityService.PAInfo.class
				);
				productDetails.addAll(pa.pandaItemDetails);
				responseInfo = getProductResponse(productDetails);
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability reorder',
					'KM_OFM_Panda',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability reorder',
					'KM_OFM_Panda',
					'',
					System.today(),
					reqBody,
					response.getBody(),
					response.getStatus()
				);
				throw new KMOFMCalloutException(response.getStatus());
			}
		} catch (Exception e) {
			String errorMessage;
			if (e.getTypeName() == 'KMOFMCalloutException') {
				errorMessage = e.getMessage();
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMProudctAvailibilityService',
					'getOFMResponse',
					'Product availability reorder',
					'KM_OFM_Panda',
					'Error Occured while quering details. ' + e.getMessage(),
					System.today(),
					reqBody,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			throw new KMOFMCalloutException(errorMessage);
		}
		return responseInfo;
	}

	private static Map<String, List<KMProudctAvailibilityService.ReponseInfo>> getProductResponse(
		List<KMProudctAvailibilityService.PandaItemDetails> productDetails
	) {
		Map<String, List<KMProudctAvailibilityService.ReponseInfo>> productResponseInfo = new Map<String, List<KMProudctAvailibilityService.ReponseInfo>>();
		for (KMProudctAvailibilityService.PandaItemDetails product : productDetails) {
			productResponseInfo.put(product.SKUNUMBER, product.reponseInfo);
		}
		return productResponseInfo;
	}

	// Method Name: getResponse
	// Author: Rambabu Gadde
	// Description: Method to Process the HTTP Request
	// Parameter 1: String reqBody - Request Body of the Service
	// Parameter 2: String endPointUrl - End Point URL for the OrderHistory Header Service
	// Old endpoints modified with New Urls
	// Modified By: Hardik Mehta
	// Date:30-06-2020
	public static HttpResponse getResponse(String reqBody, String endPointUrl) {
		HttpResponse objResponse = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		return objResponse;
	}

	public class PriceAvailabilityInfo {
		@AuraEnabled
		public String CURRENCYCODE { get; set; }
		@AuraEnabled
		public String BRANCHPLANT { get; set; }
		@AuraEnabled
		public String AVAILABLEQUANTITY { get; set; }
		@AuraEnabled
		public String AVAILABILITYDATE { get; set; }
		@AuraEnabled
		public String ERPIDENTIFIER { get; set; }
		@AuraEnabled
		public String EXTENDEDPRICE { get; set; }
		@AuraEnabled
		public String UNITPRICE { get; set; }
		@AuraEnabled
		public String LISTPRICE { get; set; }
	}

	public class ReponseInfo {
		@AuraEnabled
		public String CURRENCYCODE;
		@AuraEnabled
		public String BRANCHPLANT;
		@AuraEnabled
		public Integer AVAILABLEQUANTITY;
		@AuraEnabled
		public String AVAILABILITYDATE;
		@AuraEnabled
		public String ERPIDENTIFIER;
		@AuraEnabled
		public String EXTENDEDPRICE;
		@AuraEnabled
		public String UNITPRICE;
		@AuraEnabled
		public String LISTPRICE;
		@AuraEnabled
		public String ERRORMESSAGE;
		@AuraEnabled
		public String WARNINGMESSAGE;
	}

	public class PandaItemDetails {
		public String ITEMLINENUMBER;
		public String REQUESTTYPE;
		@AuraEnabled
		public String SKUNUMBER;
		@AuraEnabled
		public String DESIREDQUANTITY;
		@AuraEnabled
		public String ITEMTYPE;
		public String UOM;
		public String MPN;
		public String SEGMENTID;
		public String SEGMENTVALUE;
		@AuraEnabled
		public List<ReponseInfo> reponseInfo;
	}

	public class PAInfo {
		@AuraEnabled
		public List<PandaItemDetails> pandaItemDetails;
	}

	public class OFMProductLists {
		@AuraEnabled
		public String ShortItemnumber;
		@AuraEnabled
		public String SKU;
		@AuraEnabled
		public String Baseunitprice;
		@AuraEnabled
		public String currencycode;
		@AuraEnabled
		public String SKUdesc1;
		@AuraEnabled
		public String SKUdesc2;
		@AuraEnabled
		public String searchtext;
		@AuraEnabled
		public String SKUstockingtype;
		@AuraEnabled
		public String SKUlinetype;
		@AuraEnabled
		public String SKUGlcatcode;
		@AuraEnabled
		public String BranchPlant;
		@AuraEnabled
		public String Filler_Field;
	}
}