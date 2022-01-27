public without sharing class KMQuickOrderFormService {
	// Method Name: GetProductInfoForQuickOrder
	// Author: Sreenivas
	// Description: Methdo to Process the products info for Quick Order as Integration response
	// Parameter 1: List<Object> quickOrderList - Request Body used in HTTP callouts
	@AuraEnabled
	public static KMOFMAuraResponse getProductInfoForQuickOrder(List<Object> quickOrderList, string shipToNumber) {
		KMOFMAuraResponse response;
		try {
			response = new KMOFMAuraResponse(true, KMQuickOrderService.getOFMResponse(quickOrderList, shipToNumber));
		} catch (Exception ex) {
			response = new KMOFMAuraResponse(false, ex.getMessage());
		}
		return response;
	}

	// Method Name: getOrderDetailObject
	// Author: Sreenivas
	// Description: Methdo to get orderdetailObject
	@AuraEnabled
	public static Map<String, Object> getOrderDetailObject() {
		Map<String, Object> RespObj = new Map<String, Object>();
		RespObj = KoreaMobilityTabs.getCartData();
		Map<String, Object> orderDetailObj = (Map<String, Object>) RespObj.get('orderDetails');
		try {
			KMOFMAPIService.callToOFMToRefreshToken();
		} catch (Exception ex) {
			system.debug('exception Message' + ex.getMessage());
		}
		return orderDetailObj;
	}
}