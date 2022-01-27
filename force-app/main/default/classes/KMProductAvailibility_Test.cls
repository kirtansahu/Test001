// ===========================================================================
//  Class Name  : KMProductAvailibility_Test
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     :Test class for KMProductAvailibility class.
// ===========================================================================
@istest
public class KMProductAvailibility_Test {
	// Method Name: setupTestData
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@testSetup
	static void setupTestData() {
		KMTestDataFactory.createOFMOAuthSettings();
		KMTestDataFactory.createOFMOAuthConfig('OAuth API');
	}

	// Method Name: unitmethods
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@istest
	public static void unitMethod() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMProductAvailibility.getOFMProducts('70107510');
		KMProductAvailibility.getAvailabiltyInfo('458099', '70107510');
		KMProductAvailibility.getOrderDetailObject();
		Test.stopTest();
	}

	@istest
	public static void unitMethod1() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		try {
			KMProudctAvailibilityService.getOFMResponse('458099', '70107510');
			KMProudctAvailibilityService.getOFMResponse('458099', null);
			KMProudctAvailibilityService.getOFMProductResponse('458');
			KMProudctAvailibilityService.PriceAvailabilityInfo info = new KMProudctAvailibilityService.PriceAvailabilityInfo();
			info.AVAILABILITYDATE = '';
			info.AVAILABLEQUANTITY = '10';
			info.BRANCHPLANT = 'KR01';
			info.CURRENCYCODE = 'KRW';
			info.ERPIDENTIFIER = '';
			info.EXTENDEDPRICE = '';
			info.LISTPRICE = '34';
			info.UNITPRICE = '456';
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}

	@isTest
	public static void unitMethod2() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMProudctAvailibilityService.getOFMResponse('458099', '70107510');
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}

	@isTest
	public static void unitMethod3() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMProudctAvailibilityService.getOFMProductResponse('458099');
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}

	@istest
	public static void unitMethod4() {
		Boolean hasException = false;
		List<String> productNumber = new List<String>{ '458099' };
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		try {
			KMProudctAvailibilityService.getOFMResponseReorder(productNumber, '70107510');
			KMProudctAvailibilityService.getOFMResponseReorder(productNumber, null);
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}

	@istest
	public static void unitMethod5() {
		Boolean hasException = false;
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMProudctAvailibilityService.getOFMResponseReorder(new List<String>{ '458099' }, '70107510');
		} catch (Exception e) {
			hasException = true;
		}
		Test.stopTest();

		System.assertEquals(true, hasException);
	}
}