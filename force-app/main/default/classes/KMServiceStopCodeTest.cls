// ===========================================================================
//  Class Name  : KMServiceStopCodeTest
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     :Test class for KMServiceStopCode class.
// ===========================================================================
@isTest(seeAllData=false)
public class KMServiceStopCodeTest {
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
	public static void unitMethod() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMServiceStopCode.getOFMResponse('70107510');
		KMServiceStopCode.parse('{}');
		Test.stopTest();
	}

	// Method Name: unitMethod1
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@istest
	public static void unitMethod1() {
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		KMServiceStopCode.getOFMResponse('70107510');
		test.stopTest();
	}
}