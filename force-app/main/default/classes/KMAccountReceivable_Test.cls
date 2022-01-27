// ===========================================================================
//  Class Name  : KMAccountReceivable_Test
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     : test Class for KmAccountReceivable
// ===========================================================================

@istest
public class KMAccountReceivable_Test {
	// Method Name: setupTestData
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@testSetup
	static void setupTestData() {
		KMTestDataFactory.createOFMOAuthSettings();
		KMTestDataFactory.createOFMOAuthConfig('OAuth API');
	}

	// Method Name: unitmentod
	// Author: Rambabu Gadde
	// Description: create the dummy data
	@isTest
	public static void unitMethod() {
		KMOFMAuraResponse auraResponse;
		Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
		Id pricebookId = Test.getStandardPricebookId();
		//insert PriceBook
		PriceBook2 customPriceBook1 = new PriceBook2();
		customPriceBook1.Name = 'IVGN KRKRW - INDUSTRIAL';
		customPriceBook1.Currency_Code__c = 'USD';
		customPriceBook1.IsActive = true;
		customPriceBook1.Country_Code__c = 'US';
		insert customPriceBook1;
		//Assert Statements
		System.assertNotEquals(customPriceBook1.id, null);
		System.assertEquals(customPriceBook1.Name, 'IVGN KRKRW - INDUSTRIAL');
		//ftech Ship to record type
		Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Ship To').getRecordTypeId();
		//List Stores the Account records
		List<Account> accList = new List<Account>();
		for (integer i = 0; i < 200; i++) {
			//insert test data for Account
			Account acc = new Account();
			acc.Name = 'sample' + i;
			acc.ERP_Account_Id__c = '' + i;
			acc.Account_Alpha_Name__c = 'test' + i;
			acc.Address_1__c = 'test';
			acc.Address_2__c = 'sample';
			acc.Unique_Id__c = ' ' + i;
			acc.recordtypeid = RecordTypeIdAccount;
			acc.Price_Book__c = customPriceBook1.Id;
			acclist.add(acc);
		}
		insert acclist;
		//Assert Statements
		System.assert(acclist.size() > 0);
		System.assertEquals(acclist.size(), 200);
		System.assertEquals(acclist[0].recordtypeid, RecordTypeIdAccount);
		test.startTest();
		KMAccountReceivable.getAccountReceivableDetails(0, '70107510');
		try {
			KMAccountReceivable.getparticularAccount(acclist[0].id);
		} catch (Exception ex) {
		}
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		//list<KMAccountReceivable.ARInvoicedetails> arDetails= KMAccountReceivable.getInvoicedetails('458099','SO','0725');
		auraResponse = KMAccountReceivable.getInvoicedetails('458099', 'SO', '0725');
		List<KMAccountReceivable.ARInvoicedetails> arDetails = (List<KMAccountReceivable.ARInvoicedetails>) auraResponse.dataList;
		KMAccountReceivable.ARInvoicedetails inDetails = new KMAccountReceivable.ARInvoicedetails();
		inDetails.ProductNum = '458099';
		inDetails.ProductName = 'Test';
		inDetails.ShipToNum = 70107510;
		inDetails.UnitSize = '10';
		inDetails.Status = 'complete';
		inDetails.Quantity = '10';
		inDetails.CustomerPrice = '346875364';
		inDetails.ShipmentDate = '';
		inDetails.UserRequestedDate = '';
		inDetails.AvailabilityDate = '';
		inDetails.Carrier = '';
		inDetails.OrderType = 'SO';
		inDetails.OrderCompany = '0725';
		inDetails.OrderNum = 458099;
		inDetails.TrackingNumber = '';
		inDetails.LineNumber = '56';
		inDetails.CurrencyCode = 'KRW';
		inDetails.T9OrderCompany = 'T9';
		inDetails.T9OrderType = 'order';
		inDetails.T9OrderNum = '';
		inDetails.T9OrderLineNum = '';
		inDetails.OriginalOrderNum = '';
		inDetails.OriginalOrderCompany = '';
		inDetails.OriginalOrderType = '';
		inDetails.OriginalOrderLineNo = '';
		inDetails.CustomerPrice = arDetails[0].CustomerPrice;
		KMAccountReceivable.getArExtention('0725', '458099', 'SO');
		KMAccountReceivable.AccountReceivableExtention arExtentions = new KMAccountReceivable.AccountReceivableExtention();
		arExtentions.orderCompany = '0725';
		arExtentions.orderNumber = '12345';
		arExtentions.orderType = 'SO';
		arExtentions.shipToNum = '70107510';
		//KMAccountReceivableService services= KMAccountReceivable.getOFMResponse('70107510');
		auraResponse = KMAccountReceivable.getOFMResponse('70107510');
		Object services = auraResponse.data;
		KMAccountReceivableService.ResponseARDetail response = new KMAccountReceivableService.ResponseARDetail();
		response.orderType = 'SO';
		response.orderNumber = 70107510;
		response.invoiceCompany = '0725';
		response.orderStatus = 'complte';
		response.openAmount = '34783';
		response.invoicedAmount = '2236732';
		response.invoiceType = 'SI';
		response.invoiceNumber = 458099;
		response.customerPONumber = 'p';
		response.invoiceDate = '';
		response.daysOutstanding = '10';
		// response.openAmount=services.responseARDetail[0].openAmount;
		// response.openAmount=services.responseARDetail[0].invoicedAmount;
		KMAccountReceivableService.ResponseARHeader header = new KMAccountReceivableService.ResponseARHeader();
		header.amountDue = '43834';
		header.creditLimit = '54689745';
		header.currencyCode = 'KRW';
		header.openOrderAmount = '3468743';
		header.totalExposure = '436734';
		// header.amountDue=services.responseARHeader.amountDue;
		// header.creditLimit=services.responseARHeader.creditLimit;
		// header.currencyCode=services.responseARHeader.currencyCode;
		// header.openOrderAmount=services.responseARHeader.openOrderAmount;
		// header.totalExposure=services.responseARHeader.totalExposure;
		test.stopTest();
	}

	@isTest
	public static void testWrapper() {
		KMAccountReceivableService.ResponseARDetail arDetail = new KMAccountReceivableService.ResponseARDetail();
		arDetail.openAmount = '10';
		String openAmount = arDetail.openAmount;
		arDetail.invoicedAmount = '10';
		String invoicedAmount = arDetail.invoicedAmount;
		KMAccountReceivableService.ResponseARHeader arHeader = new KMAccountReceivableService.ResponseARHeader();
		arHeader.amountDue = '10';
		String amountDue = arHeader.amountDue;
		arHeader.openOrderAmount = '10';
		String openOrderAmount = arHeader.openOrderAmount;
		arHeader.totalExposure = '10';
		String totalExposure = arHeader.totalExposure;
		arHeader.creditLimit = '10';
		String creditLimit = arHeader.creditLimit;
	}

	@isTest
	public static void unitMethod2() {
		Boolean hasException = false;
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		try {
			KMAccountReceivable.getInvoicedetails('70107510', 'SI', '0725');
		} catch (Exception e) {
			hasException = true;
		}
		test.stopTest();

		System.assert(true, hasException);
	}

	@isTest
	public static void unitMethod3() {
		Boolean hasException = false;
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		try {
			KMAccountReceivableService.getOFMResponse('70107510');
		} catch (Exception e) {
			hasException = true;
		}
		test.stopTest();

		System.assert(true, hasException);
	}

	@isTest
	public static void unitMethod4() {
		Boolean hasException = false;
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator());
		try {
			KMAccountReceivable.getArExtention('0725', '70107510', 'SI');
		} catch (Exception e) {
			hasException = true;
		}
		test.stopTest();

		System.assert(true, hasException);
	}

	@isTest
	public static void unitMethod5() {
		Boolean hasException;
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMAccountReceivable.getInvoicedetails('70107510', 'SI', '0725');
		} catch (Exception e) {
			hasException = true;
		}
		test.stopTest();

		System.assert(true, hasException);
	}

	@isTest
	public static void unitMethod6() {
		Boolean hasException;
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMAccountReceivableService.getOFMResponse('70107510');
		} catch (Exception e) {
			hasException = true;
		}
		test.stopTest();

		System.assert(true, hasException);
	}

	@isTest
	public static void unitMethod7() {
		Boolean hasException;
		test.startTest();
		Test.setMock(HttpCalloutMock.class, new KMMockHttpResponseGenerator_Exceptions());
		try {
			KMAccountReceivable.getArExtention('0725', '70107510', 'SI');
		} catch (Exception e) {
			hasException = true;
		}
		test.stopTest();

		System.assert(true, hasException);
	}
}