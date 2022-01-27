// ===========================================================================
//  Object	: TaskTriggerHandler_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for TaskTriggerHandler and TaskTrigger.
// ===========================================================================
@istest
public class TaskTriggerHandler_Test {
	@TestSetup
	public static void makeData() {
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.CurrencyIsoCode = 'USD';
		a.Unique_Id__c = 'test';
		insert a;
		Id pricebookId = Test.getStandardPricebookId();

		Product2 prod = new Product2(
			Name = 'Product X',
			ProductCode = 'Pro-X',
			//Group_Division__c='LSG',
			isActive = true
		);
		insert prod;

		//Create your pricebook entry
		PricebookEntry pbEntry = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = prod.Id,
			UnitPrice = 100.00,
			IsActive = true
		);
		insert pbEntry;
		//Insert Account Records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(2);
		//Insert contact record
		Contact cons = new Contact(
			LastName = 'TestContact',
			FirstName = 'Test',
			AccountId = accList[0].Id,
			Email = 'test@gmail.com'
		);
		insert cons;
		//Assert Statements
		System.assertEquals(accList.Size(), 2);
		//  System.assertEquals(conList.Size(), 1);
		System.assertNotEquals(pbEntry.Id, null);
		System.assert(pbEntry.Product2Id == prod.id);

		Account oAccount = new Account();
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
		insert oAccount;

		Contact oContact = new Contact();
		oContact.AccountId = oAccount.Id;
		oContact.FirstName = 'Test';
		oContact.LastName = 'Test';
		oContact.Email = 'test@test.com';
		insert oContact;
	}

	@IsTest
	static void caseTasks() {
		Test.startTest();

		List<Account> accList = [SELECT Id FROM Account];
		List<Contact> conList = [SELECT Id FROM Contact];

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.ContactId = conList[0].Id;
		oCase.AccountId = accList[0].Id;
		oCase.Origin = 'Email';
		oCase.Status = 'Closed';
		oCase.Sub_Status__c = 'Resolved';
		insert oCase;

		List<Task> lstTask = new List<Task>();
		Task oTask = new Task();
		oTask.WhatId = oCase.Id;
		oTask.Type = 'Call';
		oTask.Subject = 'Test Subject';
		oTask.Travel_Hours__c = 10;
		lstTask.add(oTask);
		insert lstTask;

		try {
			oCase = [SELECT Id, Status FROM Case];
			oCase.Status = 'Closed';
			update oCase;

			delete lstTask;
		} catch (Exception ex) {
		}

		Case oCase2 = new Case();
		oCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('FAS').getRecordTypeId();
		oCase2.ContactId = conList[0].Id;
		oCase2.AccountId = accList[0].Id;
		oCase2.Origin = 'Email';
		oCase2.Status = 'New';
		oCase2.Sub_Status__c = 'Assigned';
		insert oCase2;

		Task oTask2 = new Task();
		oTask2.WhatId = oCase2.Id;
		oTask2.Type = 'FAS';
		oTask2.Subject = 'Test Subject';
		oTask2.Travel_Hours__c = 10;

		try {
			insert oTask2;
		} catch (Exception ex) {
		}

		Test.stopTest();
	}

	@istest
	public static void UpdateOpportunityTest() {
		Test.startTest();

		List<Account> accList = [SELECT Id FROM Account];
		List<Contact> conList = [SELECT Id FROM Contact];

		Opportunity opp = new Opportunity(
			Name = 'Test Opp',
			CloseDate = System.today(),
			currencyisocode = 'USD',
			StageName = 'New',
			Confidence__c = '100%',
			Reason_Won_Lost__c = 'Won/Lost - Price',
			Request_Demo__c = true,
			Primary_Contact__c = conList[0].Id,
			AccountId = accList[0].id
		);

		insert opp;
		List<Task> Tasks = new List<Task>();
		Task e = new Task();
		e.WhatId = opp.Id;
		e.Type = 'Demo Request';
		e.Subject = 'Test Subject';
		Tasks.add(e);
		//Assert Statement
		System.assertNotEquals(opp.Id, null);
		List<Task> Tasks1 = new List<Task>();
		Task e1 = new Task();
		e1.WhatId = opp.Id;
		e1.Type = 'Call';
		e1.Subject = 'Test Subject';
		Tasks1.add(e1);
		insert Tasks1;

		try {
			Task tempTask = new Task();
			tempTask.WhatId = opp.Id;
			tempTask.Type = 'Call';
			tempTask.Subject = 'Test Subject';
			tempTask.Travel_Hours__c = 10;
			insert tempTask;
		} catch (Exception ex) {
		}

		Test.stopTest();
	}
}