// ===========================================================================
//  Object	: CaseTriggerHandler_Test
// 	Company	: Keste @IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Unit Test Class for CaseTriggerHandler And CaseTrigger.
// ===========================================================================
@isTest
public class CaseTriggerHandler_Test {
	@testSetup
	public static void createTestData() {
		Account oAccount;
		List<Account> lstAccount = new List<Account>();
		oAccount = new Account();
		oAccount.Name = 'Site SGN';
		oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		oAccount.Unique_Id__c = '1004';
		oAccount.Parent_Unique_Id__c = '1003';
		oAccount.Primary_Bill_To_Unique_Id__c = '1005';
		oAccount.Child_Unique_Id__c = '1006';
		oAccount.BillingCountryCode = 'US';
		oAccount.Exclude_From_Hierarchy__c = true;
		lstAccount.add(oAccount);
		oAccount = new Account();
		oAccount.Name = 'Site NEW SGN';
		oAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		oAccount.Unique_Id__c = '1007';
		oAccount.Parent_Unique_Id__c = '1008';
		oAccount.Primary_Bill_To_Unique_Id__c = '1009';
		oAccount.Child_Unique_Id__c = '10010';
		oAccount.BillingCountryCode = 'US';
		oAccount.Exclude_From_Hierarchy__c = true;
		lstAccount.add(oAccount);
		insert lstAccount;

		List<Contact> lstContact = new List<Contact>();
		Contact oContact;
		oContact = new Contact();
		oContact.AccountId = lstAccount[0].Id;
		oContact.FirstName = 'Test ';
		oContact.LastName = 'Service';
		oContact.Email = 'servicecontact@thermofisher.com';
		lstContact.add(oContact);
		oContact = new Contact();
		oContact.AccountId = lstAccount[1].Id;
		oContact.FirstName = 'Test';
		oContact.LastName = 'New Account';
		oContact.Email = 'testcontact@thermofisher.com';
		lstContact.add(oContact);
		insert lstContact;
	}

	@isTest
	public static void testSetupContactAccountValue() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();
		List<Case_Assignment_Helper__c> lstCaseAssignmentHelper = new List<Case_Assignment_Helper__c>();
		Case_Assignment_Helper__c oCaseAssignmentHelper;
		oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Email';
		ocaseAssignmentHelper.Keywords__c = 'Test';
		ocaseAssignmentHelper.Email_Queue__c = 'Test';
		ocaseAssignmentHelper.Application_Area__c = 'Animal Health';
		ocaseAssignmentHelper.Country_Region__c = 'Argentina';
		lstCaseAssignmentHelper.add(ocaseAssignmentHelper);
		oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Email';
		ocaseAssignmentHelper.Keywords__c = 'Test1';
		ocaseAssignmentHelper.Email_Queue__c = 'Test1';
		ocaseAssignmentHelper.Application_Area__c = 'Animal Health';
		ocaseAssignmentHelper.Country_Region__c = 'Argentina';
		lstCaseAssignmentHelper.add(ocaseAssignmentHelper);
		insert lstCaseAssignmentHelper;

		Product2 p = new Product2();
		p.Name = 'testproduct';
		insert p;

		Product2 p1 = new Product2();
		p1.Name = 'testproduct';
		insert p1;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Email';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'New';
		oCase.Sub_Status__c = 'Unassigned';
		oCase.SuppliedEmail = 'mastercontact@thermofisher.com';
		oCase.Description = 'test';
		oCase.Primary_Product__c = p.Id;
		oCase.Subject = 'Test1 Case';
		oCase.ContactId = lstContact[0].Id;
		oCase.AccountId = lstAccount[0].Id;
		insert oCase;
		System.assertEquals(lstContact[0].Id, oCase.ContactId);
		System.assertEquals(lstAccount[0].Id, oCase.AccountId);

		CaseHistory oCaseHistory;
		oCaseHistory = new CaseHistory();
		oCaseHistory.CaseId = oCase.Id;
		oCaseHistory.Field = 'CaseMerged';
		insert oCaseHistory;

		Case_Related_Products__c oCaseRelatedProducts = new Case_Related_Products__c();
		oCaseRelatedProducts.Case__c = oCase.Id;
		oCaseRelatedProducts.Product__c = p.Id;
		oCaseRelatedProducts.Primary__c = true;
		insert oCaseRelatedProducts;

		oCase.ContactId = lstContact[1].Id;
		oCase.Primary_Product__c = p1.Id;
		update oCase;

		oCase = [SELECT Id, ContactId, AccountId FROM Case];
		System.assertEquals(lstAccount[0].Id, oCase.AccountId);
		Test.stopTest();
	}

	@isTest
	public static void testWebEmailOriginCaseEmailQueue() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();
		Case_Assignment_Helper__c oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Email';
		ocaseAssignmentHelper.Keywords__c = 'Test';
		ocaseAssignmentHelper.Email_Queue__c = 'Test';
		insert ocaseAssignmentHelper;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Email';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'Closed';
		oCase.Subject = 'Test';
		oCase.SuppliedEmail = 'Test@gmail.com';
		oCase.Description = 'test';
		oCase.Sub_Status__c = 'Resolved';
		insert oCase;

		/* oCase = [SELECT Id, Email_Queue__c FROM Case];
		 System.assertEquals(Label.CASE_ASSIGNMENT_RULE_NO_MATCH_CONDITION, oCase.Email_Queue__c);*/
		Test.stopTest();
	}

	@isTest
	public static void testWebEmailOriginCase() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();
		Case_Assignment_Helper__c oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Instrument';
		ocaseAssignmentHelper.Keywords__c = 'Test';
		ocaseAssignmentHelper.Email_Queue__c = 'Test';
		insert ocaseAssignmentHelper;
		String queueId = [SELECT Id, Name FROM Group WHERE Name = 'Agent Unassigned' AND Type = 'Queue' LIMIT 1].Id;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Instrument';
		oCase.Status = 'New';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'Closed';
		oCase.Subject = 'Test';
		oCase.Description = 'test';
		oCase.SuppliedEmail = 'Test@gmail.com';
		oCase.OwnerId = queueId;
		oCase.Sub_Status__c = 'Resolved';
		insert oCase;
		Test.stopTest();
	}

	@isTest
	public static void testTechSupportAutomateCaseStatusSubstatusChange() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();
		String queueId = [SELECT Id, Name FROM Group WHERE Name = 'Agent Unassigned' AND Type = 'Queue' LIMIT 1].Id;

		//Insert Asset Record
		//Asset assetRec = new Asset(AccountId = lstAccount[0].Id,ContactId = lstContact[0].Id,Name = 'Test123456');
		// insert assetRec;

		Product2 p = new Product2();
		p.Name = 'testproduct';
		insert p;

		Product2 p1 = new Product2();
		p1.Name = 'testproduct';
		insert p1;
		Case_Assignment_Helper__c oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Queue';
		oCaseAssignmentHelper.Keywords__c = 'Test';
		oCaseAssignmentHelper.Email_Queue__c = 'Test';
		oCaseAssignmentHelper.TimeZone__c = 'GMT';
		insert ocaseAssignmentHelper;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Instrument';
		oCase.Status = 'New';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Subject = 'Test';
		oCase.Description = 'test';
		oCase.SuppliedEmail = 'Test@gmail.com';
		oCase.OwnerId = queueId;
		oCase.Primary_Product__c = p.Id;
		oCase.Sub_Status__c = 'Unassigned';
		//  oCase.AssetId = assetRec.Id;
		//oCase.Email_Queue__c = ocaseAssignmentHelper.Email_Queue__c;
		insert oCase;

		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals('Unassigned', oCase.Sub_Status__c);
		System.assertEquals(queueId, oCase.OwnerId);

		oCase.OwnerId = UserInfo.getUserId();
		update oCase;

		oCase = [SELECT Id, Sub_Status__c, OwnerId, Email_Queue__c FROM Case];
		System.assertEquals('Assigned', oCase.Sub_Status__c);

		oCaseAssignmentHelper = [
			SELECT Id, Case_Origin__c, Keywords__c, Email_Queue__c, TimeZone__c
			FROM Case_Assignment_Helper__c
		];
		oCaseAssignmentHelper.Case_Origin__c = 'Queue';
		oCaseAssignmentHelper.Keywords__c = 'Test';
		oCaseAssignmentHelper.Email_Queue__c = oCase.Email_Queue__c;
		oCaseAssignmentHelper.TimeZone__c = 'GMT';
		update oCaseAssignmentHelper;

		oCase.Status = 'Closed';
		update oCase;
		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals('Resolved', oCase.Sub_Status__c);

		oCase.Status = 'Open';
		update oCase;
		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals('Re-Opened', oCase.Sub_Status__c);

		/* oCase.Status = 'Pending Internal';
        update oCase;
         oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
        System.assertEquals('Follow-Up', oCase.Sub_Status__c);*/

		/* oCase.Status = 'Cancelled';
        oCase.Sub_Status__c = 'Spam';
        update oCase;
        
        oCase = [SELECT Id, Sub_Status__c, OwnerId, Status, Retrigger_Case_KPI__c FROM Case];
        System.assertEquals('Spam', oCase.Sub_Status__c);*/

		oCase.Retrigger_Case_KPI__c = true;
		oCase.Email_Queue__c = 'Test';
		oCase.Web_File_Name__c = 'Test_File_Name';
		oCase.Web_File_Type__c = 'txt';
		oCase.Web_File_URL__c = '/testURL/Test_File_Name.txt';
		oCase.Web_File_AWS_Integration_Status__c = 'New';
		update oCase;

		oCase = [SELECT Id, Sub_Status__c, OwnerId, Status, Retrigger_Case_KPI__c, Email_Queue__c FROM Case];

		oCaseAssignmentHelper = [
			SELECT Id, Case_Origin__c, Keywords__c, Email_Queue__c, TimeZone__c
			FROM Case_Assignment_Helper__c
		];
		oCaseAssignmentHelper.Case_Origin__c = 'Queue';
		oCaseAssignmentHelper.Keywords__c = 'Test';
		oCaseAssignmentHelper.Email_Queue__c = oCase.Email_Queue__c;
		oCaseAssignmentHelper.TimeZone__c = 'GMT';
		update oCaseAssignmentHelper;

		oCase.Status = 'Closed';
		update oCase;

		delete oCase;
		Test.stopTest();
	}

	@isTest
	public static void testFASAutomateCaseStatusSubstatusChange() {
		Test.startTest();
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		String queueId = [SELECT Id, Name FROM Group WHERE Name = 'Agent Unassigned' AND Type = 'Queue' LIMIT 1].Id;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('FAS').getRecordTypeId();
		oCase.Origin = 'Instrument';
		oCase.Status = 'New';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Subject = 'Test';
		oCase.Description = 'test';
		oCase.SuppliedEmail = 'Test@gmail.com';
		oCase.OwnerId = queueId;
		insert oCase;

		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals('Assigned', oCase.Sub_Status__c);
		System.assertEquals(queueId, oCase.OwnerId);

		oCase.OwnerId = UserInfo.getUserId();
		update oCase;

		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals('Assigned', oCase.Sub_Status__c);

		oCase.Status = 'Pending Internal';
		update oCase;
		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals(null, oCase.Sub_Status__c);

		oCase.Status = 'Closed';
		update oCase;
		oCase = [SELECT Id, Sub_Status__c, OwnerId FROM Case];
		System.assertEquals('Resolved', oCase.Sub_Status__c);

		Test.stopTest();
	}

	@isTest
	public static void testWebEmailOriginCaseEmailQueueForWeb() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();
		String queueId = [SELECT Id, Name FROM Group WHERE Name = 'Agent Unassigned' AND Type = 'Queue' LIMIT 1].Id;

		Case_Assignment_Helper__c oCaseAssignmentHelper = new Case_Assignment_Helper__c();
		oCaseAssignmentHelper.Case_Origin__c = 'Web';
		ocaseAssignmentHelper.Keywords__c = 'Test';
		ocaseAssignmentHelper.Email_Queue__c = 'Test';
		ocaseAssignmentHelper.TimeZone__c = 'GMT';
		insert ocaseAssignmentHelper;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'Web';
		oCase.Status = 'New';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Subject = 'Test';
		oCase.Description = 'test';
		oCase.SuppliedEmail = 'Test@gmail.com';
		oCase.OwnerId = queueId;
		insert oCase;

		Test.stopTest();
	}

	@isTest
	public static void testCaseCloseValidation() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();
		String queueId = [SELECT Id, Name FROM Group WHERE Name = 'Agent Unassigned' AND Type = 'Queue' LIMIT 1].Id;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('FAS').getRecordTypeId();
		oCase.Origin = 'Instrument';
		oCase.Status = 'New';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Subject = 'Test';
		oCase.Description = 'test';
		oCase.SuppliedEmail = 'Test@gmail.com';
		oCase.OwnerId = queueId;
		insert oCase;

		Task task = new Task();
		task.WhatId = oCase.Id;
		task.Subject = 'Test Close Validation';
		insert task;
		oCase.Status = 'Closed';
		update oCase;
		Test.stopTest();
	}
	@isTest
	public static void testemailMessageForWebAndInstrumentOrigin() {
		List<Account> lstAccount = [SELECT Id FROM Account];
		List<Contact> lstContact = [SELECT Id, Email FROM Contact];

		Test.startTest();

		Product2 p = new Product2();
		p.Name = 'testproduct';
		insert p;

		Product2 p1 = new Product2();
		p1.Name = 'testproduct';
		insert p1;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.Origin = 'web';
		oCase.Web_Application_Area__c = 'Animal Health';
		oCase.Web_Country_Region__c = 'Argentina';
		oCase.Status = 'New';
		oCase.Sub_Status__c = 'Unassigned';
		oCase.SuppliedEmail = 'mastercontact@thermofisher.com';
		oCase.Description = 'test';
		oCase.Primary_Product__c = p.Id;
		oCase.Subject = 'Test1 Case';
		oCase.ContactId = lstContact[0].Id;
		oCase.AccountId = lstAccount[0].Id;
		insert oCase;
		System.assertEquals(lstContact[0].Id, oCase.ContactId);
		System.assertEquals(lstAccount[0].Id, oCase.AccountId);

		CaseHistory oCaseHistory;
		oCaseHistory = new CaseHistory();
		oCaseHistory.CaseId = oCase.Id;
		oCaseHistory.Field = 'CaseMerged';
		insert oCaseHistory;

		Case_Related_Products__c oCaseRelatedProducts = new Case_Related_Products__c();
		oCaseRelatedProducts.Case__c = oCase.Id;
		oCaseRelatedProducts.Product__c = p.Id;
		oCaseRelatedProducts.Primary__c = true;
		insert oCaseRelatedProducts;
		oCase.ContactId = lstContact[1].Id;
		oCase.Primary_Product__c = p1.Id;
		update oCase;

		EmailMessage eMessage = new EmailMessage();
		eMessage.ParentId = oCase.Id;
		eMessage.ToAddress = oCase.SuppliedEmail;
		eMessage.HtmlBody = oCase.Description;
		eMessage.MessageDate = oCase.CreatedDate;
		eMessage.TextBody = oCase.Description;
		eMessage.Subject = 'Case ID' + oCase.CaseNumber;
		eMessage.Status = '1';
		insert eMessage;

		oCase = [SELECT Id, ContactId, AccountId FROM Case];
		System.assertEquals(lstAccount[0].Id, oCase.AccountId);
		Test.stopTest();
	}
}