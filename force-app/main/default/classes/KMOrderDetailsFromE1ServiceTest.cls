// ===========================================================================
//  Class Name  : KMOrderDetailsFromE1ServiceTest
//  Company     : Keste @IDC
//  Author      : Rambabu
//  Purpose     : test Class for KMOrderDetailsFromE1Service
// ===========================================================================
@istest
public class KMOrderDetailsFromE1ServiceTest {
	// Method Name: setupTestData
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@testSetup
	static void setupTestData() {
		KMTestDataFactory.createOFMOAuthSettings();
		KMTestDataFactory.createOFMOAuthConfig('OAuth API');
	}

	@isTest
	public static void unitMethod() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMOrderDetailsFromE1Service details = KMOrderDetailsFromE1Service.getOFMResponse('70107510', 'SU', '0725');
		KMOrderDetailsFromE1Service.OrderDetails orders = new KMOrderDetailsFromE1Service.OrderDetails();
		orders.CustomerPrice = '48734687';
		orders.CustomerPrice = details.responseDetail.OrderDetails[0].CustomerPrice;
		Test.stopTest();
	}

	@istest
	public static void unitMethod1() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMOrderDetailsFromE1Service.getOFMResponse('70107510', 'SU', '0725');
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}
}