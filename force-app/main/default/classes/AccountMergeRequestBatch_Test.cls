@isTest
public class AccountMergeRequestBatch_Test {
	@isTest
	static void unitTestWithAccountMerge_1() {
		List<Account> accountsToCreate = new List<Account>();
		Account siteSGN = new Account();
		siteSGN.Name = 'Ship To';
		siteSGN.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		siteSGN.Unique_Id__c = '1000';
		accountsToCreate.add(siteSGN);

		Account survivoraccountObj = new Account();
		survivoraccountObj.Name = 'Ship To';
		survivoraccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SHIPTO)
			.getRecordTypeId();
		survivoraccountObj.Unique_Id__c = '1004';
		survivoraccountObj.Parent_Unique_Id__c = '1003';
		accountsToCreate.add(survivoraccountObj);

		Account victimaccountObj = new Account();
		victimaccountObj.Name = 'Ship To';
		victimaccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SHIPTO)
			.getRecordTypeId();
		victimaccountObj.Unique_Id__c = '1007';
		victimaccountObj.Parent_Unique_Id__c = '1003';
		accountsToCreate.add(victimaccountObj);

		Account billTo = new Account();
		billTo.Name = 'Bill To';
		billTo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_BILLTO)
			.getRecordTypeId();
		billTo.Unique_Id__c = '1011';
		accountsToCreate.add(billTo);

		Account billTo2 = new Account();
		billTo2.Name = 'Bill To';
		billTo2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_BILLTO)
			.getRecordTypeId();
		billTo2.Unique_Id__c = '1012';
		accountsToCreate.add(billTo2);

		Account billTo3 = new Account();
		billTo3.Name = 'Bill To';
		billTo3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_BILLTO)
			.getRecordTypeId();
		billTo3.Unique_Id__c = '1013';
		accountsToCreate.add(billTo3);

		Account childAcc = new Account();
		childAcc.Name = 'child';
		childAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SHIPTO)
			.getRecordTypeId();
		childAcc.Unique_Id__c = '1066';
		childAcc.Parent_Unique_Id__c = '1007';
		childAcc.Primary_Bill_To_Unique_Id__c = '1007';
		childAcc.Child_Unique_Id__c = '1007';
		accountsToCreate.add(childAcc);
		insert accountsToCreate;

		List<ShipTo_BillTo__c> sbToInserts = new List<ShipTo_BillTo__c>();
		sbToInserts.add(
			new ShipTo_BillTo__c(
				Ship_To__c = survivoraccountObj.Id,
				Bill_To__c = billTo.Id,
				ShipTo_BillTo_External_Id__c = survivoraccountObj.Id + '_' + billTo.Id
			)
		);
		sbToInserts.add(
			new ShipTo_BillTo__c(
				Ship_To__c = survivoraccountObj.Id,
				Bill_To__c = billTo2.Id,
				ShipTo_BillTo_External_Id__c = survivoraccountObj.Id + '_' + billTo2.Id
			)
		);
		sbToInserts.add(
			new ShipTo_BillTo__c(
				Ship_To__c = victimaccountObj.Id,
				Bill_To__c = billTo.Id,
				ShipTo_BillTo_External_Id__c = victimaccountObj.Id + '_' + billTo.Id
			)
		);
		sbToInserts.add(
			new ShipTo_BillTo__c(
				Ship_To__c = victimaccountObj.Id,
				Bill_To__c = billTo2.Id,
				ShipTo_BillTo_External_Id__c = victimaccountObj.Id + '_' + billTo2.Id
			)
		);
		sbToInserts.add(
			new ShipTo_BillTo__c(
				Ship_To__c = victimaccountObj.Id,
				Bill_To__c = billTo3.Id,
				ShipTo_BillTo_External_Id__c = victimaccountObj.Id + '_' + billTo3.Id
			)
		);
		insert sbToInserts;

		List<Contact> contactsToCreate = new List<Contact>();
		Contact oContact = new Contact();
		oContact.FirstName = 'TestContact';
		oContact.LastName = 'Contact';
		oContact.Email = 'Test@test.com';
		oContact.AccountId = siteSGN.Id;
		contactsToCreate.add(oContact);

		Contact oContact2 = new Contact();
		oContact2.FirstName = 'TestContactOne';
		oContact2.LastName = 'ContactOne';
		oContact2.Email = 'Test2@test.com';
		oContact2.AccountId = siteSGN.Id;
		contactsToCreate.add(oContact2);

		Contact oContact3 = new Contact();
		oContact3.FirstName = 'TestContactThree';
		oContact3.LastName = 'ContactThree';
		oContact3.Email = 'Test3@test.com';
		oContact3.AccountId = siteSGN.Id;
		contactsToCreate.add(oContact3);
		insert contactsToCreate;

		List<AccountContactRelation> acrToInsert = new List<AccountContactRelation>();
		acrToInsert.add(new AccountContactRelation(AccountId = survivoraccountObj.Id, ContactId = oContact.Id));
		acrToInsert.add(new AccountContactRelation(AccountId = survivoraccountObj.Id, ContactId = oContact2.Id));
		acrToInsert.add(new AccountContactRelation(AccountId = victimaccountObj.Id, ContactId = oContact.Id));
		acrToInsert.add(new AccountContactRelation(AccountId = victimaccountObj.Id, ContactId = oContact2.Id));
		acrToInsert.add(new AccountContactRelation(AccountId = victimaccountObj.Id, ContactId = oContact3.Id));
		insert acrToInsert;

		List<Account_Team__c> accountTeamsToCreate = new List<Account_Team__c>();
		Account_Team__c at = new Account_Team__c();
		at.AccountId__c = victimaccountObj.Id;
		at.UserId__c = UserInfo.getUserId();
		at.Position__c = 'Test 1';
		accountTeamsToCreate.add(at);

		Account_Team__c at2 = new Account_Team__c();
		at2.AccountId__c = victimaccountObj.Id;
		at2.UserId__c = UserInfo.getUserId();
		at2.Position__c = 'Test 2';
		accountTeamsToCreate.add(at2);
		insert accountTeamsToCreate;

		Account_Merge_Request__c amrRequested = new Account_Merge_Request__c();
		amrRequested.Survivor_Unique_Id__c = survivoraccountObj.Unique_Id__c;
		amrRequested.Survivor_Id__c = survivoraccountObj.Id;
		amrRequested.Victim_Unique_Id__c = victimaccountObj.Unique_Id__c;
		amrRequested.Victim_Id__c = victimaccountObj.Id;
		amrRequested.Status__c = 'Requested';
		insert amrRequested;

		Test.startTest();
		AccountMergeRequestBatch.accMergeErrorOverride.keySet();
		Database.executeBatch(new AccountMergeRequestBatch(amrRequested));
		Test.stopTest();
	}

	@isTest
	static void unitTestWithAccountMerge_2() {
		List<Account> accountsToCreate = new List<Account>();
		Account survivoraccountObj = new Account();
		survivoraccountObj.Name = 'Ship To';
		survivoraccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		survivoraccountObj.Unique_Id__c = '1004';
		survivoraccountObj.Parent_Unique_Id__c = '1003';
		accountsToCreate.add(survivoraccountObj);

		Account victimaccountObj = new Account();
		victimaccountObj.Name = 'Ship To';
		victimaccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		victimaccountObj.Unique_Id__c = '1007';
		victimaccountObj.Parent_Unique_Id__c = '1003';
		accountsToCreate.add(victimaccountObj);
		insert accountsToCreate;

		List<Contact> contactsToCreate = new List<Contact>();
		Contact oContact = new Contact();
		oContact.FirstName = 'TestContact';
		oContact.LastName = 'Contact';
		oContact.Email = 'Test@test.com';
		oContact.AccountId = survivoraccountObj.Id;
		contactsToCreate.add(oContact);

		Contact oContact2 = new Contact();
		oContact2.FirstName = 'TestContactOne';
		oContact2.LastName = 'ContactOne';
		oContact2.Email = 'Test2@test.com';
		oContact2.AccountId = victimaccountObj.Id;
		contactsToCreate.add(oContact2);

		Contact oContact3 = new Contact();
		oContact3.FirstName = 'TestContactThree';
		oContact3.LastName = 'ContactThree';
		oContact3.Email = 'Test3@test.com';
		oContact3.AccountId = victimaccountObj.Id;
		contactsToCreate.add(oContact3);
		insert contactsToCreate;

		List<AccountContactRelation> acrToInsert = new List<AccountContactRelation>();
		acrToInsert.add(new AccountContactRelation(AccountId = survivoraccountObj.Id, ContactId = oContact2.Id));
		acrToInsert.add(new AccountContactRelation(AccountId = victimaccountObj.Id, ContactId = oContact.Id));
		insert acrToInsert;

		Account_Merge_Request__c amrRequested = new Account_Merge_Request__c();
		amrRequested.Survivor_Unique_Id__c = survivoraccountObj.Unique_Id__c;
		amrRequested.Survivor_Id__c = survivoraccountObj.Id;
		amrRequested.Victim_Unique_Id__c = victimaccountObj.Unique_Id__c;
		amrRequested.Victim_Id__c = victimaccountObj.Id;
		amrRequested.Status__c = 'Requested';
		insert amrRequested;

		Test.startTest();
		Database.executeBatch(new AccountMergeRequestBatch(amrRequested));
		Test.stopTest();
	}
}