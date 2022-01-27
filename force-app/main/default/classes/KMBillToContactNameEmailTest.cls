// ===========================================================================
//  Class Name  : KMBillToContactNameEmailTest
//  Company     : Keste @IDC
//  Author      : Sreenivas
//  Purpose     :Test class for KMBillToContactNameEmail class.
// ===========================================================================

@isTest(seeAllData=false)
public class KMBillToContactNameEmailTest {
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
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMBillToContactNameEmail.getOFMResponse('70107510');
		KMBillToContactNameEmail.getOFMResponse(null);
		KMBillToContactNameEmail.parse('{}');
		Test.stopTest();
	}

	// Method Name: unitMethod1
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@istest
	public static void unitMethod1() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMBillToContactNameEmail.getOFMResponse('70107510');
		} catch (Exception ex) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}
}