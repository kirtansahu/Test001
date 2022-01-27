// ===========================================================================
//  Object: SiebelSync_Test
//  Company: Keste @IDC
//  Author: Rambabu Gadde
//  Purpose: Unit Test Class for SiebelSync.
// ===========================================================================
@isTest
public class SiebelSync_Test {
	public static testMethod void SiebelSyncTestINSERT() {
		List<Account> lstAcc = new List<Account>();
		lstAcc = testSetupDataUtil.insertAccountRecords(1);
		Id SGNRTId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site SGN').RecordTypeId;
		lstAcc[0].ERP_Account_Id__c = Math.random() + '123';
		lstAcc[0].RecordTypeId = SGNRTId;
		update lstAcc;
		testSetupDataUtil.insertContactRecordswithAcc(1, lstAcc);
		Contact objCon = [SELECT Id, LastName, Email FROM Contact WHERE AccountId = :lstAcc[0].Id];
		objCon.Email = 'testcon' + Math.random() + '@mail.com';
		update objCon;
		Contact c = new Contact(
			LastName = 'TestContact',
			FirstName = 'TestContactName',
			AccountId = lstAcc[0].id,
			email = 'abcd@gamil.com'
		);
		insert C;
		Opportunity opList = new Opportunity(
			Name = 'Test Opportunity',
			CloseDate = System.today(),
			StageName = 'New',
			Confidence__c = '10%',
			AccountId = lstAcc[0].Id,
			Primary_Contact__c = c.id
		);
		insert opList;
		//Assert Statements
		System.assertEquals(lstAcc.size(), 1);
		System.assertNotEquals(opList.Id, null);
		SiebelSync testCSS = new SiebelSync();
		testCSS.parentObjectAPIName = 'Contact';
		testCSS.parentObjectAPIName = 'Opportunity';
		testCSS.objectName = 'Contact';
		testCSS.OperationType = 'INSERT';
		TestCSS.setRecordIds = new Set<id>();
		TestCSS.setRecordIds.add(c.id);
		testCSS.relatedOperationType = 'INsert';
		testCSS.strApplicationName = 'Contact';
		System.enqueueJob(testCSS);
		SiebelSync testCSS1 = new SiebelSync();
		testCSS1.parentObjectAPIName = 'Opportunity';
		testCSS1.objectName = 'Contact';
		testCSS1.OperationType = 'INSERT';
		testCSS1.setRecordIds = new Set<id>();
		testCSS1.setRecordIds.add(opList.Id);
		testCSS1.relatedOperationType = 'INsert';
		testCSS1.strApplicationName = 'Contact';
		System.enqueueJob(testCSS1);
		SiebelSync testCSS2 = new SiebelSync();
		testCSS2.parentObjectAPIName = 'Contact';
		testCSS2.objectName = 'Contact';
		testCSS2.OperationType = 'INSERT';
		testCSS2.setRecordIds = new Set<id>();
		testCSS2.setRecordIds.add(opList.Id);
		testCSS2.relatedOperationType = 'INsert';
		testCSS2.strApplicationName = 'Contact';
		System.enqueueJob(testCSS2);
	}
	@istest
	public static void unitTest() {
		test.startTest();
		IntegrationUtility.isMockResponseSetupped = true;
		//Assert Statement
		System.assertEquals(IntegrationUtility.isMockResponseSetupped, true);
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(200, ''));
		IntegrationResponse Instance = new IntegrationResponse();
		HttpResponse Hresponse = new HttpResponse();
		Hresponse.setBody('{"siebelId": ' + Math.random() + '}');
		Hresponse.setStatusCode(400);
		Instance.response = Hresponse;
		//Assert Statements
		System.assertEquals(400, Hresponse.getStatusCode());
		SiebelSync s = new SiebelSync();
		s.syncRecordWithSiebel('null', 'contact', 'null', 'Opportunity', true);
		SiebelSync.processIntegrationResponse('', '', Instance);
		Test.stopTest();
	}
}