// ===========================================================================
//  Class Name  : KMOrderSummary_Test
//  Company     : Keste @IDC
//  Author      : Rambabu Gadde
//  Purpose     :Test class for KMOrderSummary class.
// ===========================================================================
@istest
public class KMOrderSummary_Test {
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
		//Insert Account  Records
		List<Account> accList = KMTestDataFactory.insertAccountHierarchy();
		BigMachines__Configuration_Record__c records = new BigMachines__Configuration_Record__c();
		records.BigMachines__API_Login__c = 'test';
		records.BigMachines__API_Password__c = '23fb4';
		records.BigMachines__Connected_App_Name__c = 'data';
		records.BigMachines__action_id_copy__c = 'A1';
		records.BigMachines__action_id_open__c = 'A2';
		records.BigMachines__bm_site__c = 'test';
		records.BigMachines__document_id__c = 'documents';
		records.BigMachines__process__c = 'process';
		records.BigMachines__process_id__c = 'Bigmachines';
		records.BigMachines__version_id__c = 'version';
		records.BigMachines__Is_Active__c = true;
		insert records;
		//Assert Systements
		System.assert(records.id != null);
		System.assertEquals(records.BigMachines__Is_Active__c, true);
		System.assertNotEquals(accList.size(), null);
		//insert Quote Records
		BigMachines__Quote__c quotes = new BigMachines__Quote__c();
		quotes.EC_Account_Alpha_Name__c = accList[0].Account_Alpha_Name__c;
		quotes.BigMachines__Account__c = accList[0].id;
		quotes.BigMachines__Status__c = 'active';
		quotes.BigMachines_Quote_Type__c = 'p';
		quotes.BigMachines__Site__c = records.Id;
		quotes.Name = '12345';
		insert quotes;
		//Assert Statements
		System.assert(quotes.id != null);
		System.assertEquals(quotes.BigMachines__Account__c, accList[0].id);
		System.assertEquals(quotes.BigMachines_Quote_Type__c, 'p');
		System.assertEquals(Quotes.BigMachines__Status__c, 'active');
		//insert Order records
		KMOrderDetails__c details = new KMOrderDetails__c();
		details.Name = 'CartStoredData_' + userinfo.getUserId();
		details.OrderDetail__c = 'details';
		details.Products__c = 'sample';
		details.UserId__c = userinfo.getUserId();
		insert details;
		//Assert Statements
		System.assertNotEquals(details.id, null);
		//Insert Attchment for orders
		Attachment attach = new Attachment();
		attach.Name = 'Unit Test Attachment';
		Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
		attach.body = bodyBlob;
		attach.ParentId = details.id;
		attach.ContentType = 'sample';
		insert attach;
		Test.startTest();
		KMOrderSummary.getQuoteRecords(accList[0].id);
		KMOrderSummary.saveAttachedFile(attach.name, 'test', attach.ContentType);
		KMOrderSummary.getUploadedAttachments();
		KMOrderSummary.saveCartData('test', 'sample');
		KMOrderSummary.removeAttachedFiles();
		try {
			Test.setMock(HttpCalloutMock.class, new YourHttpCalloutMockImpl());
			KMOrderSummary.getQuoteDiscountNetPrice('2564102', new Map<String, Object>(), new List<Object>{ details });
			KMOrderSummary.confirmOrder();
		} catch (exception e) {
		}
		KMOrderSummary.getBillToContactAndServiceStopCode('69480993', '69515049');
		Test.stopTest();
	}

	// Method Name: unitMethod1
	// Author: Rambabu Gadde
	// Description: create the dummy test data
	@isTest
	public static void unitMethod1() {
		insertOrderDetails();
		Test.startTest();
		KMOrderSummary.getUploadedAttachments();
		KMOrderSummary.removeAttachedFiles();
		KMOrderSummary.getCartData();
		try {
			KMOrderSummary.saveAttachedFile('testdata', 'sample', 'codes');
		} catch (exception e) {
		}
		Test.stopTest();
	}

	@isTest
	private static void testConfirmOrder() {
		// Test data setup
		insertOrderDetails();
		// Actual test
		Test.startTest();
		KMOrderSummary.confirmOrder();
		Test.stopTest();
	}

	@isTest
	private static void testGetUserDetails() {
		Test.startTest();
		User user = KMOrderSummary.getUserDetails();
		Test.stopTest();

		System.assertEquals(true, user != null, 'Null value returned for user record');
	}

	/**
	 * Order details data setup
	 */
	private static void insertOrderDetails() {
		KMOrderDetails__c detail = new KMOrderDetails__c();
		detail.Name = 'CartStoredData_' + UserInfo.getUserId();
		detail.UserId__c = UserInfo.getUserId();
		detail.OrderDetail__c = '{"orderFromState":"Complete","accountId":"0012900000YNDXtAAP","shipToNumber":"69482252","shipToAlphaName":"YOUNGINFRONTIER","shipToName":"YOUNGINFRONTIER","shipToAddressLine1":"A1","shipToAddressLine2":"A2","shipToAddressLine3":"A3","shipToCity":"A5","shipToPostalCode":"500025","shipToCountry":"Bahamas","billToNumber":"10066632","billToName":"Keste BillTo Account1","billToAddressLine1":"6100 W","billToAddressLine2":"Plano Parkway Suite","billToAddressLine3":"1800","billToCity":"Plano","billToState":"TX","billToPostalCode":"214.778.2100","billToCountry":"United States","orderType":"SO","defaultStopCode":"KSE","defaultServiceCode":"K03","defaultBillToContactName":"Invoices / Sales Forms Delivery Contact","defaultBillToContactEmail":"sainzrosa@uniovi.es","defaultServiceCodeLabel":"K03 - KR - Logistics Delivery","defaultStopCodeLabel":"KSE - Korea Seoul Customer","promotionType":"","quote":"","promotionCode":"","estimatedTotal":"1479000"}';
		detail.Products__c = '[{"productName":"OXPHOS RODENT WB ANTIBODY","productNumber":"458099","unitSize":"300 ug","currencyCode":"KRW","unitPrice":"739500","quantity":1,"selected":false},{"productName":"OXPHOS RODENT WB ANTIBODY","productNumber":"458099","unitSize":"300 ug","currencyCode":"KRW","unitPrice":"739500","quantity":1,"selected":false}]';
		insert detail;
	}
	public class YourHttpCalloutMockImpl implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			String Body = '{"MessageHeader":{"orderSource":"Dohmi-SFDC","APJ_Flag":"Y"},"Payload":{"OrderHeader":{"orderShipTo":"277488","orderType":"SO","orderMode":"IN","companyCode":"00100","promoCode1":"","promoCode2":"D1552446"},"OrderLineList":{"OrderLineDetails":[{"lineNumber":"1","SKU":"R302","desiredQty":"2"},{"lineNumber":"2","SKU":"NP0002","desiredQty":"6"}]}}}';
			res.setHeader('Content-Type', 'application/json');
			res.setBody(Body);
			res.setStatusCode(200);
			return res;
		}
	}
}