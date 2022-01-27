// ===========================================================================
//  Class Name  : KMCustomersOrdersClsTest
//  Company     : Keste @IDC
//  Author      : Jagadish Babu
//  Purpose     : test Class for KMCustomersOrdersCls
// ===========================================================================
@isTest
public class KMCustomersOrdersClsTest {
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
		//List Stores the Account records
		List<Account> accList = KMTestDataFactory.createAndInsertShipToAccounts(200);

		//Assert Statements
		System.assertEquals(acclist.size(), 200);
		System.assertEquals(
			acclist[0].recordtypeid,
			Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ACCOUNT_RECORD_SHIPTO).getRecordTypeId()
		);
		Test.startTest();
		KMCustomersOrdersCls.getShipToRecords('ShipTo', 10, 'young');
		KMCustomersOrdersCls.getAccountDetail(acclist[0].id, 'Name', true, 'Name', acclist[0].Name);
		KMCustomersOrdersCls.getAccountDetail(acclist[0].id, 'Name', false, 'Name', acclist[0].Name);
		KMCustomersOrdersCls.getContactRecords('ContactName', 10, 'ram');
		KMCustomersOrdersCls.getContactRecords('Email', 10, 'ram');
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMCustomersOrdersCls.getOrderHistoryList('70107510', '');
		KMCustomersOrdersCls.getOrderHistoryList('70107510', '3456');
		KMCustomersOrdersCls.getReorderList('70107510', '', '');
		KMCustomersOrdersCls.getOrderDetailList('697989', 'SO', '0725');
		KMCustomersOrdersCls.getCartShipToNumber();
		try {
			KMCustomersOrdersCls.getAvailabiltyInfo(new List<String>{ '458099', 'BA0380' }, '70107510');
		} catch (Exception e) {
		}
		KMCustomersOrdersCls.getCartData();
		string selOrders = '[{"OrderType":"TC","OrderDate":"2020/09/10","OrderNum":"31152209","OrderLineNum":"1","ShipToNum":"70421670","ProductNo":"375418PK","ProductName":"1.8ML CRYTBE RND EX TD STRFT","UnitSize":"Pack of 450","LotNo":"202006","NextStatus":"Shipped","HoldCode":null,"Quantity":1,"CancelledQuanity":0,"FutureQuanity":0,"ShippedQuantity":1,"BackorderQuantity":0,"CustomerPrice":183600,"CurrencyCode":"KRW","Amount":183600,"BalanceQtytobeinvoiced":null,"ContactLineId":"0","OrderMode":"KB","Quote":"P4107944","Filler_Field":null,"T9OrderCompany":"00725","T9OrderType":"T9","T9OrderNum":"31152691","T9OrderLineNum":"1000","OriginalOrderNum":null,"OriginalOrderType":null,"OriginalOrderLineNo":"0","OriginalOrderCompany":null,"OrderTable":"C"},{"OrderType":"T9","OrderDate":"2020/09/10","OrderNum":"31152274","OrderLineNum":"1","ShipToNum":"70421670","ProductNo":"21985023","ProductName":"2 MERCAPTOETHANOL 1000X","UnitSize":"50ML #21985","LotNo":"2188982","NextStatus":"Shipped","HoldCode":null,"Quantity":1,"CancelledQuanity":0,"FutureQuanity":0,"ShippedQuantity":1,"BackorderQuantity":0,"CustomerPrice":62000,"CurrencyCode":"KRW","Amount":62000,"BalanceQtytobeinvoiced":null,"ContactLineId":"0","OrderMode":"KB","Quote":"APIVGN","Filler_Field":null,"T9OrderCompany":null,"T9OrderType":null,"T9OrderNum":"0","T9OrderLineNum":"0","OriginalOrderNum":"31151684","OriginalOrderType":"TC","OriginalOrderLineNo":"1000","OriginalOrderCompany":"00725","OrderTable":"C"}]';
		List<Object> selOrderList = new List<Object>();
		selOrderList = (List<Object>) JSON.deserializeUntyped(selOrders);
		KMCustomersOrdersCls.sendEmailWithSelectedOrders('70107510', selOrderList);
		Test.stopTest();
	}

	@istest
	public static void unitMethod1() {
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		KMOrderHistoryHeaderService services = KMOrderHistoryHeaderService.getOFMResponse('70107510', '45468');
		KMOrderHistoryHeaderService.OrderHederDetails details = new KMOrderHistoryHeaderService.OrderHederDetails();
		details.TotalVal = services.responseDetail[0].TotalVal;
		test.stopTest();
	}

	@isTest
	public static void testGetOrderHistoryNegative() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		KMCustomersOrdersCls.getOrderHistoryList('70107510', '');
		Test.stopTest();
	}

	@isTest
	public static void testGetReorderListNegative() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		KMCustomersOrdersCls.getReorderList('70107510', '', '');
		Test.stopTest();
	}

	@isTest
	public static void testGetOrderDetailListNegative() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		KMCustomersOrdersCls.getOrderDetailList('697989', 'SO', '0725');
		Test.stopTest();
	}

	@isTest
	public static void testGetAvailabiltyInfoNegative() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		KMCustomersOrdersCls.getAvailabiltyInfo(new List<String>{ '458099', 'BA0380' }, '70107510');
		Test.stopTest();
	}
}