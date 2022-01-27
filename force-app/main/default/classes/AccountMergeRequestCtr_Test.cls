// ===========================================================================
//  Object   : AccountMergeRequestCtr
//  Company  : Keste @ IDC
//  Author   : Adarsh Sharma
//  Purpose  : Unit Test Class for Lightning Component Controller to Account Merge Request.
// ===========================================================================
@isTest
public class AccountMergeRequestCtr_Test {
	@isTest
	public static void test_CheckForValidProfile() {
		//Check for System Admin User User
		AccountMergeRequestCtr.RequestResult oRequestResult = AccountMergeRequestCtr.checkForValidProfile();
		System.assertEquals(true, oRequestResult.isSuccess, 'Should be successful');
		System.assertEquals(null, oRequestResult.statusMessage, 'Should be successful');
		AccountMergeRequestCtr.accMergeErrorOverride.keySet();
	}

	@isTest
	public static void test_getAccountDetails() {
		List<Account> accountsToCreate = new List<Account>();
		Account survivoraccountObj = new Account();
		survivoraccountObj.Name = 'Site SGN';
		survivoraccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		survivoraccountObj.Unique_Id__c = '1004';
		survivoraccountObj.Parent_Unique_Id__c = '1003';
		survivoraccountObj.Primary_Bill_To_Unique_Id__c = '1005';
		survivoraccountObj.Child_Unique_Id__c = '1006';
		survivoraccountObj.BillingCountryCode = 'US';
		survivoraccountObj.Exclude_From_Hierarchy__c = true;
		accountsToCreate.add(survivoraccountObj);

		Account victimaccountObj = new Account();
		victimaccountObj.Name = 'Site SGN';
		victimaccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		victimaccountObj.Unique_Id__c = '1007';
		victimaccountObj.Parent_Unique_Id__c = '1008';
		victimaccountObj.Primary_Bill_To_Unique_Id__c = '1009';
		victimaccountObj.Child_Unique_Id__c = '1010';
		victimaccountObj.BillingCountryCode = 'US';
		victimaccountObj.Exclude_From_Hierarchy__c = true;
		accountsToCreate.add(victimaccountObj);

		Account victimaccountObj2 = new Account();
		victimaccountObj2.Name = 'Site SGN';
		victimaccountObj2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		victimaccountObj2.Unique_Id__c = '1011';
		victimaccountObj2.Parent_Unique_Id__c = '1012';
		victimaccountObj2.Primary_Bill_To_Unique_Id__c = '1013';
		victimaccountObj2.Child_Unique_Id__c = '1014';
		victimaccountObj2.BillingCountryCode = 'IN';
		victimaccountObj2.Exclude_From_Hierarchy__c = true;
		accountsToCreate.add(victimaccountObj2);

		Account victimnsgn = new Account();
		victimnsgn.Name = 'NSGNTest';
		victimnsgn.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_NATIONAL_SGN)
			.getRecordTypeId();
		victimnsgn.Unique_Id__c = '1002';
		victimnsgn.Parent_Unique_Id__c = '1001';
		victimnsgn.BillingCountryCode = 'US';
		victimnsgn.Exclude_From_Hierarchy__c = true;
		accountsToCreate.add(victimnsgn);
		insert accountsToCreate;

		AccountMergeRequestCtr.AccountMergeRequestWarpper res;

		//Scenraio - When both Survivor & Victim Ids are blank
		res = AccountMergeRequestCtr.getAccountDetails(null, null);
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, false);
		System.assertEquals(res.victim.accountFound, false);

		//Scenario when only Victim Id was povided
		res = AccountMergeRequestCtr.getAccountDetails(null, '1002');
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, false);
		System.assertEquals(res.victim.accountFound, true);

		//Scenario when only Victim Id was povided
		res = AccountMergeRequestCtr.getAccountDetails('1004', null);
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, true);
		System.assertEquals(res.victim.accountFound, false);

		//Scenario when both Ids were provided but record type are not same
		res = AccountMergeRequestCtr.getAccountDetails('1004', '1002');
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, true);
		System.assertEquals(res.victim.accountFound, true);

		//Scenario when both Ids were provided but Country are not same
		res = AccountMergeRequestCtr.getAccountDetails('1004', '1011');
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, true);
		System.assertEquals(res.victim.accountFound, true);

		//Scenario when both Ids were provided but both are same
		res = AccountMergeRequestCtr.getAccountDetails('1004', '1004');
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, true);
		System.assertEquals(res.victim.accountFound, true);

		//Scenario when both Ids were provided and all Good
		res = AccountMergeRequestCtr.getAccountDetails('1004', '1007');
		System.assertEquals(res.isAllValid, true);
		System.assertEquals(res.survivor.accountFound, true);
		System.assertEquals(res.victim.accountFound, true);

		//Scenario when both Ids were provided but Victim Id is invalid
		res = AccountMergeRequestCtr.getAccountDetails('1004', '9999');
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, true);
		System.assertEquals(res.victim.accountFound, false);

		//Scenario when both Ids were provided but Survivor Id is invalid
		res = AccountMergeRequestCtr.getAccountDetails('9999', '1004');
		System.assertEquals(res.isAllValid, false);
		System.assertEquals(res.survivor.accountFound, false);
		System.assertEquals(res.victim.accountFound, true);
	}

	@isTest
	public static void test_processAccountMerging() {
		List<Account> accountsToCreate = new List<Account>();
		Account survivoraccountObj = new Account();
		survivoraccountObj.Name = 'SiteSGN';
		survivoraccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		survivoraccountObj.Unique_Id__c = '1004';
		survivoraccountObj.Parent_Unique_Id__c = '1003';
		survivoraccountObj.Primary_Bill_To_Unique_Id__c = '1005';
		survivoraccountObj.Child_Unique_Id__c = '1006';
		accountsToCreate.add(survivoraccountObj);

		Account victimaccountObj = new Account();
		victimaccountObj.Name = 'SiteSGN';
		victimaccountObj.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		victimaccountObj.Unique_Id__c = '1007';
		victimaccountObj.Parent_Unique_Id__c = '1008';
		victimaccountObj.Primary_Bill_To_Unique_Id__c = '1009';
		victimaccountObj.Child_Unique_Id__c = '1010';
		accountsToCreate.add(victimaccountObj);

		Account victimaccountObj2 = new Account();
		victimaccountObj2.Name = 'SiteSGN2';
		victimaccountObj2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SITE_SGN)
			.getRecordTypeId();
		victimaccountObj2.Unique_Id__c = '1011';
		victimaccountObj2.Parent_Unique_Id__c = '1012';
		victimaccountObj2.Primary_Bill_To_Unique_Id__c = '1013';
		victimaccountObj2.Child_Unique_Id__c = '1014';
		accountsToCreate.add(victimaccountObj2);

		Account shipTo = new Account();
		shipTo.Name = 'shipTo';
		shipTo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SHIPTO)
			.getRecordTypeId();
		shipTo.Unique_Id__c = '1015';
		shipTo.Parent_Unique_Id__c = '1004';
		shipTo.Primary_Bill_To_Unique_Id__c = '1017';
		shipTo.Child_Unique_Id__c = '1017';
		accountsToCreate.add(shipTo);

		Account shipTo2 = new Account();
		shipTo2.Name = 'shipTo2';
		shipTo2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_SHIPTO)
			.getRecordTypeId();
		shipTo2.Unique_Id__c = '1016';
		shipTo2.Parent_Unique_Id__c = '1007';
		shipTo2.Primary_Bill_To_Unique_Id__c = '1018';
		shipTo2.Child_Unique_Id__c = '1018';
		accountsToCreate.add(shipTo2);

		Account billTo = new Account();
		billTo.Name = 'billTo';
		billTo.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_BILLTO)
			.getRecordTypeId();
		billTo.Unique_Id__c = '1017';
		accountsToCreate.add(billTo);

		Account billTo2 = new Account();
		billTo2.Name = 'billTo';
		billTo2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get(Label.ACCOUNT_RECORD_BILLTO)
			.getRecordTypeId();
		billTo2.Unique_Id__c = '1018';
		accountsToCreate.add(billTo2);

		insert accountsToCreate;

		List<Contact> contactsToCreate = new List<Contact>();
		Contact con1 = new Contact(
			FirstName = 'Con',
			LastName = 'One',
			Email = 'conone@test.com',
			AccountId = survivoraccountObj.Id
		);
		contactsToCreate.add(con1);
		Contact con2 = new Contact(
			FirstName = 'Con',
			LastName = 'Two',
			Email = 'contwo@test.com',
			AccountId = victimaccountObj.Id
		);
		contactsToCreate.add(con2);
		Contact con3 = new Contact(
			FirstName = 'Con',
			LastName = 'Three',
			Email = 'contwo@test.com',
			AccountId = victimaccountObj2.Id
		);
		contactsToCreate.add(con3);
		insert contactsToCreate;

		List<AccountContactRelation> acrList = new List<AccountContactRelation>();
		acrList.add(new AccountContactRelation(AccountId = victimaccountObj.Id, ContactId = con1.Id));
		acrList.add(new AccountContactRelation(AccountId = survivoraccountObj.Id, ContactId = con2.Id));
		acrList.add(new AccountContactRelation(AccountId = victimaccountObj.Id, ContactId = con3.Id));
		insert acrList;

		List<Account_Team__c> accTeamList = TestSetupDataUtil.insertAccountTeamRecords(
			new List<Account>{ victimaccountObj }
		);

		//Testing with one invalid id
		AccountMergeRequestCtr.RequestResult oRequestResult = AccountMergeRequestCtr.processAccountMerging(
			'999',
			'1007'
		);
		System.assertEquals(oRequestResult.isSuccess, false);
		System.assertEquals(oRequestResult.statusMessage, Label.ACCOUNT_MERGE_UNABLE_TO_FETCH_ACCOUNTS);

		//Testing with one invalid id
		oRequestResult = AccountMergeRequestCtr.processAccountMerging('1004', '1007');
		System.assertEquals(oRequestResult.isSuccess, true);

		oRequestResult = AccountMergeRequestCtr.processAccountMergingAsync('1004', '1011');
		System.assertEquals(oRequestResult.isSuccess, true);

		List<AccountContactRelation> survivorACR = new List<AccountContactRelation>(
			[SELECT Id FROM AccountContactRelation WHERE AccountId = :survivoraccountObj.Id]
		);
		System.assertEquals(survivorACR.size(), 3);
	}
}