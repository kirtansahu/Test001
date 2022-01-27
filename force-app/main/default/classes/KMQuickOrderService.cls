// ===========================================================================
//  Class Name  : KMOrderDetailsFromE1Service
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     : Korean Mobility Quick Order List service Functionality
//  Test Class  : KMQuickOrderServiceTest
// ===========================================================================
public without sharing class KMQuickOrderService {
	public class ResponseDetail {
		@AuraEnabled
		public String productNumber;
		@AuraEnabled
		public String productDescription;
		@AuraEnabled
		public string searchtext;
		@AuraEnabled
		public String unitSize;
		@AuraEnabled
		public string unitPrice;
		@AuraEnabled
		public String currencyCode;
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
	public static KMQuickOrderService getOFMResponse(list<Object> quickOrderList, string shipToNumber) {
		KMQuickOrderService results = new KMQuickOrderService();
		String reqBody;
		HttpResponse response;
		try {
			Map<String, Object> ReqDataMap = new Map<String, Object>();
			List<Object> requestList = new List<Object>();
			if (quickOrderList != null && !quickOrderList.isEmpty()) {
				for (Object eachProdObj : (list<Object>) quickOrderList) {
					Map<string, Object> ProductMap = new Map<string, Object>();
					ProductMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachProdObj));
					string prodNum = String.valueOf(ProductMap.get('productNumber'));
					if (String.isNotBlank(prodNum)) {
						Map<String, Object> productNumMap = new Map<String, Object>();
						productNumMap.put('productNumber', prodNum);
						requestList.add(productNumMap);
					}
				}
			}
			ReqDataMap.put('requestList', requestList);
			reqBody = JSON.serialize(ReqDataMap);
			String QuickOrderEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_ProductInfoList');
			response = getResponse(reqBody, QuickOrderEndpoint);
			if (response.getStatusCode() == 200) {
				string resResult = response.getBody();
				string updatedRes = addPriceDetailsToProdList(resResult, shipToNumber);
				results = parse(updatedRes);
			} else {
				ExceptionHandlerController.createIntegrationException(
					'KMQuickOrderService',
					'getOFMResponse',
					'Quick Order Capture',
					'KM_OFM_ProductInfoList',
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
				ExceptionHandlerController.createIntegrationException(
					'KMQuickOrderService',
					'getOFMResponse',
					'Quick Order Capture',
					'KM_OFM_ProductInfoList',
					'Error Occured while quering details. ' + ex.getMessage(),
					System.today(),
					reqBody,
					'',
					''
				);
				errorMessage = System.Label.KM_General_Error_Message;
			}
			if (response != null && response.getStatusCode() != 200) {
				throw new KMOFMCalloutException(response.getStatus());
			} else {
				throw new KMOFMCalloutException(errorMessage);
			}
		}
		return results;
	}

	// Method Name: parse
	// Author: Sreenivas
	// Description: Method to parse the Response body
	// Parameter 1: String json - Response body of OFM Service
	public static KMQuickOrderService parse(String json) {
		return (KMQuickOrderService) System.JSON.deserialize(json, KMQuickOrderService.class);
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

	// Method Name: getProductRecords
	// Author: Sreenivas
	// Description: Methdo to add the price and currecy code into response object
	// Parameter 1: String resResult - passing response string parameter
	// Parameter 2: String shipToNumber - passing shipToNumber string parameter
	public static string addPriceDetailsToProdList(String resResult, string shipToNumber) {
		Map<string, Object> PAndAReqMap = new Map<string, Object>();
		List<Object> pandaItemDetailsList = new List<Object>();

		Map<string, Object> OFMProdResMap = new Map<string, Object>();
		OFMProdResMap = (Map<string, Object>) JSON.deserializeUntyped(resResult);
		List<Object> resDetailList = new List<Object>();
		resDetailList = (List<Object>) OFMProdResMap.get('responseDetail');
		if (resDetailList != null && !resDetailList.isEmpty()) {
			for (object eachRec : resDetailList) {
				Map<String, Object> eachProdRecMap = new Map<String, Object>();
				eachProdRecMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachRec));
				string prodNum = String.valueOf(eachProdRecMap.get('productNumber'));
				Map<String, Object> pandaItemDetailsMap = new Map<String, Object>();
				pandaItemDetailsMap.put('ITEMLINENUMBER', String.valueOf(pandaItemDetailsList.size() + 1));
				pandaItemDetailsMap.put('REQUESTTYPE', 'PA');
				pandaItemDetailsMap.put('SKUNUMBER', prodNum);
				pandaItemDetailsMap.put('DESIREDQUANTITY', '1');
				pandaItemDetailsMap.put('ITEMTYPE', 'catalog');
				pandaItemDetailsMap.put('UOM', 'EA');
				pandaItemDetailsMap.put('MPN', prodNum);
				pandaItemDetailsList.add(pandaItemDetailsMap);
			}
		}
		Map<string, Object> productPriceMap = new Map<string, Object>();
		List<Object> PAndAReqList = new List<Object>();
		Map<string, Object> PAndAinfoMap = new Map<string, Object>();
		PAndAinfoMap.put('target', 'E1');
		PAndAinfoMap.put('USER', 'PANDA:USER_KEY:785189_CART_KEY:NOCARTKEY_TIME_STAMP:1509096173583');
		PAndAinfoMap.put('PWD', '@GES12');
		PAndAinfoMap.put('ROLE', '*ALL');
		PAndAinfoMap.put('ENV', System.Label.KM_PandaAPI_ENV);
		PAndAinfoMap.put('SHIPTO', shipToNumber);
		PAndAinfoMap.put('COMPANYCODE1', '00100');
		PAndAinfoMap.put('pandaItemDetails', pandaItemDetailsList);
		PAndAReqList.add(PAndAinfoMap);
		PAndAReqMap.put('PriceAndAvailabilityInfo', PAndAReqList);
		String PAndAApiEndpoint = KMOFMServicesHelper.getServiceEndpoint('KM_OFM_Panda');
		HttpResponse response = getResponse(JSON.serialize(PAndAReqMap), PAndAApiEndpoint);
		if (response.getStatusCode() == 200) {
			string PAresResult = response.getBody();
			Map<String, Object> PAResMap = new Map<String, Object>();
			PAResMap = (Map<string, Object>) JSON.deserializeUntyped(PAresResult);
			List<Object> PAndAResList = new List<Object>();
			PAndAResList = (List<Object>) PAResMap.get('PriceAndAvailabilityInfo');
			if (PAndAResList != null && !PAndAResList.isEmpty()) {
				for (object eachPARec : PAndAResList) {
					Map<String, Object> PAndAInfoResMap = new Map<String, Object>();
					PAndAInfoResMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachPARec));
					List<Object> pandaItemDetailsResList = new List<Object>();
					pandaItemDetailsResList = (List<Object>) PAndAInfoResMap.get('pandaItemDetails');
					if (pandaItemDetailsResList != null && !pandaItemDetailsResList.isEmpty()) {
						for (object eachPAItemRec : pandaItemDetailsResList) {
							Map<String, Object> PAndAItemMap = new Map<String, Object>();
							PAndAItemMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachPAItemRec));
							string skuNumber = String.valueOf(PAndAItemMap.get('SKUNUMBER'));
							List<Object> reponseInfoList = new List<Object>();
							reponseInfoList = (List<Object>) PAndAItemMap.get('reponseInfo');
							productPriceMap.put(skuNumber, reponseInfoList[0]);
						}
					}
				}
			}
		} else {
			ExceptionHandlerController.createIntegrationException(
				'KMQuickOrderService',
				'addPriceDetailsToProdList',
				'Quick Order Capture',
				'KM_OFM_Panda',
				'',
				System.today(),
				JSON.serialize(PAndAReqMap),
				response.getBody(),
				response.getStatus()
			);
			throw new KMOFMCalloutException(response.getStatus());
		}
		List<Object> resDetailListNew = new List<Object>();
		if (productPriceMap != null && !productPriceMap.isEmpty()) {
			if (resDetailList != null && !resDetailList.isEmpty()) {
				for (object eachRec : resDetailList) {
					Map<String, Object> eachProdRecMap = new Map<String, Object>();
					eachProdRecMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(eachRec));
					string prodNum = String.valueOf(eachProdRecMap.get('productNumber'));
					Object PADataObj = productPriceMap.get(prodNum);
					if (PADataObj != null) {
						Map<String, Object> PADataObjMap = new Map<String, Object>();
						PADataObjMap = (Map<string, Object>) JSON.deserializeUntyped(JSON.serialize(PADataObj));
						eachProdRecMap.put('unitPrice', String.valueOf(PADataObjMap.get('UNITPRICE')));
						eachProdRecMap.put('currencyCode', String.valueOf(PADataObjMap.get('CURRENCYCODE')));
						resDetailListNew.add(eachProdRecMap);
					}
				}
			}
			OFMProdResMap.put('responseDetail', resDetailListNew);
		}
		return JSON.serialize(OFMProdResMap);
	}
}