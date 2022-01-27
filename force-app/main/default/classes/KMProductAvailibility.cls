// ===========================================================================
//  Class Name  : KMProductAvailibility
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     : Korean Mobility Product Tab Functionality
//  Test Class  :KMProductAvailibility_Test
// ===========================================================================
public without sharing class KMProductAvailibility {
	// Method Name: getOFMProducts
	// Author: Rambabu Gadde
	// Description: Methdo use to get ListOfProducts.
	// Parameter 1: String-inputSearchValue.
	@AuraEnabled
	public static KMOFMAuraResponse getOFMProducts(String inputSearchValue) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				(List<Object>) KMProudctAvailibilityService.getOFMProductResponse(inputSearchValue)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getAvailabiltyInfo
	// Author: Rambabu Gadde
	// Description: Methdo use to get OFM data.
	// Parameter 1: String-productNumber.
	// Parameter 2: String-shipNumber
	@AuraEnabled
	public static KMOFMAuraResponse getAvailabiltyInfo(String productNumber, String shipNumber) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(
				true,
				KMProudctAvailibilityService.getOFMResponse(productNumber, shipNumber)
			);
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getOrderDetailObject
	// Author: Rambabu Gadde
	// Description: Methdo use to get cart item ShiptToNumbers.
	@AuraEnabled
	public static Map<String, Object> getOrderDetailObject() {
		Map<String, Object> RespObj = new Map<String, Object>();
		RespObj = KoreaMobilityTabs.getCartData();
		Map<String, Object> orderDetailObj = (Map<String, Object>) RespObj.get('orderDetails');
		return orderDetailObj;
	}
}