// ===========================================================================
//  Object	: ChildDeleteSync_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for ChildDeleteSync.
// ===========================================================================
@istest
public class ChildDeleteSync_Test {
	@istest
	public static void unitTest() {
		//Insert Account Records
		List<Account> lstAcc = TestSetupDataUtil.insertAccountRecords(2);
		//Insert AccountAssociated with Contact Records
		List<Contact> lstCons = TestSetupDataUtil.insertContactRecordswithAcc(lstAcc.size(), lstAcc);
		//Insert Profile Records
		List<Profile__c> lstProfiles = TestSetupDataUtil.insertProfileRecords(2);
		//create the contact Profile Record
		Contact_Profile__c objCP = new Contact_Profile__c(
			Contact__c = lstCons[0].Id,
			Profile__c = lstProfiles[0].Id,
			Contact_Profile_External_Id__c = String.valueof(Math.random())
		);
		insert objCP;
		//Assert Statements
		System.assertEquals(lstAcc.size(), 2);
		System.assertEquals(lstProfiles.size(), 2);
		System.assertNotEquals(objCP.id, null);

		IntegrationUtility.isMockResponseSetupped = true;
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(200, '{"siebelId": ' + Math.random() + '}'));
		test.startTest();
		ChildDeleteSync cc = new ChildDeleteSync();
		cc.strObjectName = 'CONTACT_PROFILE__C';
		sObjectRecordWrapper ss = new sObjectRecordWrapper(
			'sample',
			'',
			'ACCOUNTCONTACTRELATION',
			'CONTACT_PROFILE__C',
			''
		);
		cc.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>{ ss };
		System.enqueueJob(cc);
		ChildDeleteSync cc1 = new ChildDeleteSync();
		cc1.strObjectName = 'CONTACT_PROFILE__C';
		sObjectRecordWrapper ss1 = new sObjectRecordWrapper(
			'sample',
			'',
			'CONTACT_PROFILE__C',
			'CONTACT_PROFILE__C',
			''
		);
		cc1.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>{ ss1 };
		System.enqueueJob(cc1);
		ChildDeleteSync cc2 = new ChildDeleteSync();
		cc2.strObjectName = 'CONTACT_PROFILE__C';
		sObjectRecordWrapper ss2 = new sObjectRecordWrapper(
			'sample',
			'',
			'OPPORTUNITYTEAMMEMBER',
			'CONTACT_PROFILE__C',
			''
		);
		cc2.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>{ ss2 };
		System.enqueueJob(cc2);
		ChildDeleteSync cc3 = new ChildDeleteSync();
		cc3.strObjectName = 'CONTACT_PROFILE__C';
		sObjectRecordWrapper ss3 = new sObjectRecordWrapper(
			'sample',
			'',
			'OPPORTUNITY_PRODUCT_LINE__C',
			'CONTACT_PROFILE__C',
			''
		);
		cc3.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>{ ss3 };
		System.enqueueJob(cc3);
		ChildDeleteSync cc4 = new ChildDeleteSync();
		cc4.strObjectName = 'CONTACT_PROFILE__C';
		sObjectRecordWrapper ss4 = new sObjectRecordWrapper(
			'sample',
			'',
			'OPPORTUNITYLINEITEM',
			'CONTACT_PROFILE__C',
			''
		);
		cc4.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>{ ss4 };
		System.enqueueJob(cc4);
		test.stopTest();
	}

	@istest
	public static void unitTest_1() {
		IntegrationUtility.isMockResponseSetupped = true;
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(400, '{"siebelId": ' + Math.random() + '}'));
		test.startTest();
		ChildDeleteSync cc = new ChildDeleteSync();
		cc.strObjectName = 'CONTACT_PROFILE__C';
		//Assert Statement
		System.assertEquals('CONTACT_PROFILE__C', cc.strObjectName);
		System.assertEquals(IntegrationUtility.isMockResponseSetupped, true);
		sObjectRecordWrapper ss = new sObjectRecordWrapper(
			'sample',
			'',
			'ACCOUNTCONTACTRELATION',
			'CONTACT_PROFILE__C',
			''
		);
		//Assert statement
		System.assertNotEquals(ss, null);
		cc.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>{ ss };
		ID jobId = System.enqueueJob(cc);
		System.assertNotEquals(null, jobId);
		AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId];
		System.assertEquals(0, job.NumberOfErrors);
		ChildDeleteSync cc1 = new ChildDeleteSync();
		cc1.strObjectName = null;
		System.assertEquals(cc1.strObjectName, null);
		cc1.lstsObjectRecordWrapper = new List<sObjectRecordWrapper>();
		System.enqueueJob(cc1);
		test.stopTest();
	}
}