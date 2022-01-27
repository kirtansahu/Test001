@isTest(seeAllData=false)
private class KoreaMobilityTabsTest {
	static string userId = UserInfo.getUserId();
	static string productData = '[{"productName":"test","productNumber":"324234","unitSize":"1 set","currencyCode":"KRW","unitPrice":"34200","quantity":"2","lotNumber":"","selected":false}]';
	static string ordDetil = '{}';

	static void setupData() {
		String recordName = 'CartStoredData_' + userId;
		KMOrderDetails__c ordDetail = new KMOrderDetails__c();
		ordDetail.Name = recordName;
		ordDetail.Products__c = productData;
		ordDetail.OrderDetail__c = ordDetil;
		ordDetail.UserId__c = userId;
		insert ordDetail;
	}

	static testMethod void testKMTabs() {
		setupData();
		Boolean success = KoreaMobilityTabs.saveCartData(productData, ordDetil);
		Map<string, object> cartDataMap = KoreaMobilityTabs.getCartData();
		System.assert(cartDataMap != null);
		System.assertEquals(true, success);
	}

	static testMethod void testKMTabs_Null() {
		Boolean success = KoreaMobilityTabs.saveCartData(productData, ordDetil);
		System.assertEquals(true, success);
	}

	static testMethod void testKMTabs_Exp() {
		Map<string, object> cartDataMap = KoreaMobilityTabs.getCartData();
		System.assert(cartDataMap != null);
	}
}