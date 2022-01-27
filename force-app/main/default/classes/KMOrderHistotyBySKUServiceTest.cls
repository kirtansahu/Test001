// ===========================================================================
//  Class Name  : KMOrderHistotyBySKUServiceTest
//  Company     : Keste @IDC
//  Author      : Rambabu
//  Purpose     : test Class for KMOrderHistotyBySKUService
// ===========================================================================
@istest
public class KMOrderHistotyBySKUServiceTest {
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
		KMOrderHistotyBySKUService skuServices = KMOrderHistotyBySKUService.getOFMResponse(
			'70107510',
			'01072020',
			'30072020'
		);
		KMOrderHistotyBySKUService.ResponseDetail details = new KMOrderHistotyBySKUService.ResponseDetail();
		details.CustomerPrice = '436743';
		details.Amount = '23542';
		details.Amount = skuServices.responseDetail[0].Amount;
		details.CustomerPrice = skuServices.responseDetail[0].CustomerPrice;
		Test.stopTest();
	}

	@istest
	public static void unitMethod2() {
		Boolean hasException = false;
		Test.startTest();
		try {
			Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
			KMOrderHistotyBySKUService.getOFMResponse('70107510', '01072020', '30072020');
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}
}