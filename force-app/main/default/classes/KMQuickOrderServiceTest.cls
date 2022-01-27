// ===========================================================================
//  Class Name  : KMQuickOrderServiceTest
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     :Test class for KMQuickOrderService class.
// ===========================================================================
@isTest(seeAllData=false)
public class KMQuickOrderServiceTest {
	// Method Name: setupTestData
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@testSetup
	static void setupTestData() {
		KMTestDataFactory.createOFMOAuthSettings();
		KMTestDataFactory.createOFMOAuthConfig('OAuth API');
	}

	// Method Name: unitMethod
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@istest
	public static void unitMethod_Excp() {
		List<Object> quickOrderList = new List<Object>();
		Map<string, Object> quickOrderMap = new Map<string, Object>();
		quickOrderMap.put('productNumber', 'P24742');
		quickOrderList.add(quickOrderMap);
		Map<string, Object> quickOrderMap1 = new Map<string, Object>();
		quickOrderMap1.put('productNumber', 'K240020');
		quickOrderList.add(quickOrderMap1);
		KMQuickOrderService results = new KMQuickOrderService();
		Boolean hasException;
		try {
			results = KMQuickOrderService.getOFMResponse(null, '69482521');
		} catch (Exception e) {
			hasException = true;
		}
		System.assertEquals(true, hasException);
	}

	@istest
	public static void unitMethod() {
		KM_OFM_OAuth_Config__c confi = new KM_OFM_OAuth_Config__c();
		confi.Access_Token__c = '';
		confi.Expiry_End_Datetime__c = System.today() + 20;
		confi.Expiry_Start_Datetime__c = System.today();
		confi.Name = 'test';
		confi.Token_Type__c = 'OAuth';
		insert confi;
		//Assert Statements
		System.assertNotEquals(confi.id, null);
		System.assertNotEquals(confi.Access_Token__c, null);
		string prodResJson = '{"responseDetail":[{"productNumber":"P24742","productDescription":"PRESS-TO-SEAL SILICON","searchtext":"PRESS-TO-SEAL SILICON","unitSize":"1 SET"},{"productNumber":"K240020","productDescription":"PENTR/D-TOPO CLONING KIT","searchtext":"PENTR/D-TOPO CLONING KIT","unitSize":"20 REACTIONS"}],"responseHeader":{"responseStatusCode":"200","responseStatus":"Success"}}';
		String Json = '[{"productName":"Plasmocin™ prophylactic","productNumber":"A25547","unitSize":"Invivogen/ant-mpp/ 25 mg (10 x","currencyCode":"KRW","unitPrice":"158000","quantity":1,"selected":false},{"productName":"LIPOFECTAMINE 2000 REAGENT","productNumber":"11668027","unitSize":"0.75 ML","currencyCode":"KRW","unitPrice":"459900","quantity":1,"selected":false},{"productName":"FG, TOTAL EXOSOME ISOL (CELLS)","productNumber":"4478359","unitSize":"EACH","currencyCode":"KRW","unitPrice":"487800","quantity":1,"selected":false},{"productName":"TRYPLE EXPRESS","productNumber":"12604013","unitSize":"100ML","currencyCode":"KRW","unitPrice":"28800","quantity":1,"selected":false},{"productName":"5-BROMO-4-CHLORO-3-INDOLY","productNumber":"B1690","unitSize":"1 G","currencyCode":"KRW","unitPrice":"274500","quantity":1,"selected":false}]';
		String orderDetails = '{"accountId":"0012900000Z4brNAAR","shipToNumber":"69482521","shipToAlphaName":"TC Account","shipToName":"TC Account","shipToAddressLine1":"Block A","shipToAddressLine2":"Cyber Pearl","shipToAddressLine3":"Madhapur","billToNumber":"000002","billToName":"Keste BillTo Account","billToAddressLine1":"6100 W","billToAddressLine2":"Plano Parkway Suite","billToAddressLine3":"1800","billToCity":"Plano","billToState":"TX","billToPostalCode":"214.778.2100","billToCountry":"United States","orderType":"SO","promotionType":"","quote":"","promotionCode":"","estimatedTotal":"1409000","orderFromState":"Pending","contactName":"test data141 Kestecontact","phoneNumber":"7567567577","emailAddress":"abcd@gmail.com","shipToAttention":"11111","billToAttention":"2222","shipComplete":true,"requestDeleveryDate":"2020-07-09","paymentMethod":"C-Purchase Order","poOrRefNumber":"dadad"}';
		string quickProd = '[{"lotNumber":"","quantity":"2","productNumber":"P24742","rowId":"1"},{"lotNumber":"","quantity":"3","productNumber":"K240020","rowId":"2"}]';
		List<Object> quickOrderList = new List<Object>();
		Map<string, Object> quickOrderMap = new Map<string, Object>();
		quickOrderMap.put('productNumber', 'P24742');
		quickOrderList.add(quickOrderMap);
		Map<string, Object> quickOrderMap1 = new Map<string, Object>();
		quickOrderMap1.put('productNumber', 'K240020');
		quickOrderList.add(quickOrderMap1);
		// KMQuickOrderService results = new KMQuickOrderService();
		// results = KMQuickOrderService.getOFMResponse(new List<Object>{quickProd},'69482521');
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		// KMQuickOrderService.getOFMResponse(new List<object>{},'69482521');
		KMQuickOrderService.getOFMResponse(quickOrderList, null);
		//KMQuickOrderService.parse(orderDetails);
		//KMQuickOrderService.getResponse(quickProd,'https://dev-siapi.thermofisher.com/dhm/getproductinfolist');
		//KMQuickOrderService.addPriceDetailsToProdList(prodResJson,'69482521');
		Test.stopTest();
	}

	@istest
	public static void unitMethod1() {
		string prodResJson = '{"responseDetail":[{"productNumber":"P24742","productDescription":"PRESS-TO-SEAL SILICON","searchtext":"PRESS-TO-SEAL SILICON","unitSize":"1 SET"},{"productNumber":"K240020","productDescription":"PENTR/D-TOPO CLONING KIT","searchtext":"PENTR/D-TOPO CLONING KIT","unitSize":"20 REACTIONS"}],"responseHeader":{"responseStatusCode":"200","responseStatus":"Success"}}';
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		Boolean hasException;
		try {
			KMQuickOrderService.getOFMResponse(null, null);
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();
		System.assertEquals(true, hasException);
	}
}