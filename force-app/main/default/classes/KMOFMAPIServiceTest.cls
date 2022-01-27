/* * * * * * * * * * * * * *
 * Class Name:   KMOFMAPIServiceTest
 * Purpose:      Class to test the consumed OFM web service to get the access token which can then be used in subsequent callouts to get the data.
 * Author:       Hardik Mehta
 * Company:      Keste @ IDC
 * Created Date: 06-July-2020
 * Type:         Test Class
 * * * * * * * * * * * * * */
@isTest
private class KMOFMAPIServiceTest {
	/* * * * * * * * * * * * * *
	 * Method Name:  setupTestData
	 * Purpose:      Test method to create setup test data
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@testSetup
	static void setupTestData() {
		KMTestDataFactory.createOFMOAuthSettings();
		KMTestDataFactory.createOFMOAuthConfig('Bearer');
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testOrderDetailsResponse
	 * Purpose:      Test method to check for Order Details API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testOrderDetailsResponse() {
		KM_OFM_Services__mdt orderDetailsUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_OrderDetails'
		];
		String methodType = 'POST';
		String endPointURL = orderDetailsUrl.Endpoint__c;
		String reqBody = '{"OrderNumber" : "72123179", "OrderType" : "S2", "OrderCompany" : "00702", "ShipToNum" : "", "BillToNum" : "", "OrderStatus" : "", "InvoiceNumber" : "", "InvoiceType" : "", "InvoiceCompany" : "" }';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name: testProductInfoResponse
	 * Purpose:      Test method to check for Product Info API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testProductInfoResponse() {
		KM_OFM_Services__mdt productInfoUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_ProductInfo'
		];
		String methodType = 'POST';
		String endPointURL = productInfoUrl.Endpoint__c;
		String reqBody = '{"searchCriteria" : "P24742"}';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testProductListResponse
	 * Purpose:      Test method to check for Product List API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testProductListResponse() {
		KM_OFM_Services__mdt productListUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_ProductInfoList'
		];
		String methodType = 'POST';
		String endPointURL = productListUrl.Endpoint__c;
		String reqBody = '{ "requestList": [ { "productNumber": "P24742" }, { "productNumber": "K240020" } ] }';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name: testOrderHistoryResponse
	 * Purpose:      Test method to check for Order History Details API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testOrderHistoryResponse() {
		KM_OFM_Services__mdt orderHistoryHeaderUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_OrderHistoryHeader'
		];
		String methodType = 'POST';
		String endPointURL = orderHistoryHeaderUrl.Endpoint__c;
		String reqBody = '{"ShipToNumber" : "68556568","SiebelRowID" : ""}';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testARDetailsResponse
	 * Purpose:      Test method to check for AR Details API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testARDetailsResponse() {
		KM_OFM_Services__mdt arDetailsUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_ARHeader'
		];
		String methodType = 'POST';
		String endPointURL = arDetailsUrl.Endpoint__c;
		String reqBody = '{"invoiceCompany" : "00712","invoiceNumber" : 281210,"invoiceType" : "RT"}';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMOFMAPIService.callToOFMToRefreshToken();
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testARHeaderResponse
	 * Purpose:      Test method to check for AR Header API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testARHeaderResponse() {
		KM_OFM_Services__mdt arHeaderUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_ARDetails'
		];
		String methodType = 'POST';
		String endPointURL = arHeaderUrl.Endpoint__c;
		String reqBody = '{"shipToNum" : 68431225}';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testPandaResponse
	 * Purpose:      Test method to check for PandA API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 06-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testPandaResponse() {
		KM_OFM_Services__mdt pandaUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_Panda'
		];
		String methodType = 'POST';
		String endPointURL = pandaUrl.Endpoint__c;
		String reqBody = '{ "PriceAndAvailabilityInfo": [ { "target": "E1", "USER": "PANDA:USER_KEY:785189_CART_KEY:NOCARTKEY_TIME_STAMP:1509096173583", "PWD": "@GES12", "ROLE": "*ALL", "ENV": "JPY900", "SHIPTO": "223347", "COMPANYCODE1": "00100", "pandaItemDetails": [ { "ITEMLINENUMBER": "4", "REQUESTTYPE": "A1", "SKUNUMBER": "PV4794", "DESIREDQUANTITY": "1", "ITEMTYPE": "catalog", "UOM": "EA", "MPN": "PV4794" }, { "ITEMLINENUMBER": "5", "REQUESTTYPE": "A1", "SKUNUMBER": "4432470", "DESIREDQUANTITY": "1", "ITEMTYPE": "catalog", "UOM": "EA", "MPN": "4432470" }, { "ITEMLINENUMBER": "6", "REQUESTTYPE": "A1", "SKUNUMBER": "PHC4064", "DESIREDQUANTITY": "1", "ITEMTYPE": "catalog", "UOM": "EA", "MPN": "PHC4064" } ] } ] }';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testBillToNameContactResponse
	 * Purpose:      Test method to check for response from GetBillToContactNameEmail API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 07-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testBillToNameContactResponse() {
		KM_OFM_Services__mdt billTONameUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_GetBillToContactNameEmail'
		];
		String methodType = 'POST';
		String endPointURL = billTONameUrl.Endpoint__c;
		String reqBody = '{ "Bill_TO_Number" : "10066632" }';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();
		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testStartStopCodeResponse
	 * Purpose:      Test method to check for response from GetServiceStopCode API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 07-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testStartStopCodeResponse() {
		KM_OFM_Services__mdt startStopUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_GetServiceStopCode'
		];
		String methodType = 'POST';
		String endPointURL = startStopUrl.Endpoint__c;
		String reqBody = '{ "Ship_TO_Number" : "99999586" } ';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testNegativeResponse
	 * Purpose:      Test method to check for negative response from PandA API
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 07-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testNegativeResponse() {
		String methodType = 'POST';
		String endPointURL = 'dhm/negative';
		String reqBody = '{abcdefghi}';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(500, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testIfAccessTokenIsExpired
	 * Purpose:      Test method to validate scenario if token is expired
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 08-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testIfAccessTokenIsExpired() {
		KM_OFM_OAuth_Config__c objConfig = [
			SELECT Id, Expiry_Start_Datetime__c, Expiry_End_Datetime__c
			FROM KM_OFM_OAuth_Config__c
			LIMIT 1
		];
		objConfig.Expiry_End_Datetime__c = System.now().addHours(-3); // changing the datetime explicitly so that token is expired
		objConfig.Expiry_End_Datetime__c = System.now().addHours(-3); // changing the datetime explicitly so that token is expired
		update objConfig;

		// calling the API
		KM_OFM_Services__mdt orderDetailsUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_OrderDetails'
		];
		String methodType = 'POST';
		String endPointURL = orderDetailsUrl.Endpoint__c;
		String reqBody = '{"OrderNumber" : "72123179", "OrderType" : "S2", "OrderCompany" : "00702", "ShipToNum" : "", "BillToNum" : "", "OrderStatus" : "", "InvoiceNumber" : "", "InvoiceType" : "", "InvoiceCompany" : "" }';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}

	/* * * * * * * * * * * * * *
	 * Method Name:  testIfConfigRecordIsNotCreated
	 * Purpose:      Test method to validate scenario when API will be called for first time.
	 * Author:       Hardik Mehta
	 * Company:      Keste @ IDC
	 * Created Date: 08-July-2020
	 * Type:         Method
	 * * * * * * * * * * * * * */
	@isTest
	static void testIfConfigRecordIsNotCreated() {
		KM_OFM_OAuth_Config__c objConfig = [SELECT Id FROM KM_OFM_OAuth_Config__c LIMIT 1];
		delete objConfig;

		// calling the API
		KM_OFM_Services__mdt orderDetailsUrl = [
			SELECT Endpoint__c
			FROM KM_OFM_Services__mdt
			WHERE DeveloperName = 'KM_OFM_OrderDetails'
		];
		String methodType = 'POST';
		String endPointURL = orderDetailsUrl.Endpoint__c;
		String reqBody = '{"OrderNumber" : "72123179", "OrderType" : "S2", "OrderCompany" : "00702", "ShipToNum" : "", "BillToNum" : "", "OrderStatus" : "", "InvoiceNumber" : "", "InvoiceType" : "", "InvoiceCompany" : "" }';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		HTTPResponse response = KMOFMAPIService.callToOFMAPI(reqBody, 'POST', endPointURL);
		Test.stopTest();

		System.assert(response != null);
		System.assertEquals(200, response.getStatusCode());
	}
}