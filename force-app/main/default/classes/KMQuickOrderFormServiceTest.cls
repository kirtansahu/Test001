// ===========================================================================
//  Class Name  : KMQuickOrderFormServiceTest
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     :Test class for KMQuickOrderFormService class.
// ===========================================================================
@isTest(seeAllData=false)
public class KMQuickOrderFormServiceTest {
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
	@isTest
	public static void unitMethod() {
		String json = '[{"productNumber": "P24742"},{"productNumber": "K240020"}]';
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMQuickOrderFormService.getProductInfoForQuickOrder(new List<Object>{ json }, '70107510');
		KMQuickOrderFormService.getOrderDetailObject();
		Test.stopTest();
	}

	@isTest
	public static void unitMethod1() {
		String json = '[{"productNumber": "P24742"},{"productNumber": "K240020"}]';
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		KMQuickOrderFormService.getProductInfoForQuickOrder(new List<Object>{ json }, '70107510');
		Test.stopTest();
	}
}