// ===========================================================================
//  Object	: AccountTeamCascadeBatch_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for AccountTeamCascadeBatch.
// ===========================================================================
@isTest
public class ParentalSetupAccountTeamCascade_Test {
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
	public static String BILLTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_BILLTO;
	public static String GSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_GLOBAL_SGN;
	public static String NSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_NATIONAL_SGN;

	// Method Name: batchLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Batch Sync Logic for setting up Account Hierarchy
	@isTest
	public static void batchLogicTest() {
		//Create ShipTo RecordType Account
		Account shipto = new Account(
			Name = 'ShipToTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1004',
			Parent_Unique_Id__c = '1003',
			Primary_Bill_To_Unique_Id__c = '1005',
			Child_Unique_Id__c = '1006',
			Exclude_From_Hierarchy__c = true
		);
		insert shipto;
		Account shipto2 = new Account(
			Name = 'ShipToTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1007',
			Parent_Unique_Id__c = '1003',
			Exclude_From_Hierarchy__c = true
		);
		insert shipto2;

		//Create NSGN RecordType Account
		Account nsgn = new Account(
			Name = 'NSGNTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(NSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1002',
			Parent_Unique_Id__c = '1001',
			Exclude_From_Hierarchy__c = true
		);
		insert nsgn;
		//Create SGN RecordType Account
		Account sgn = new Account(
			Name = 'SiteSGNTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1003',
			Parent_Unique_Id__c = '1001',
			Exclude_From_Hierarchy__c = true
		);
		insert sgn;

		List<Account> sgnAccList = new List<Account>();
		sgnAccList.add(sgn);
		//Create Custom Account Team
		List<Account_Team__c> accTeamList = TestSetupDataUtil.insertAccountTeamRecords(sgnAccList);

		//Create GSGN RecordType Account
		Account gsgn = new Account(
			Name = 'GSGNTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(GSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1001',
			Primary_Bill_To_Unique_Id__c = '001',
			Parent_Unique_Id__c = '1002'
		);
		insert gsgn;
		//Create BillTo RecordType Account
		Account billto = new Account(
			Name = 'BillToTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1005',
			Primary_Bill_To_Unique_Id__c = '002',
			Parent_Unique_Id__c = '1003'
		);
		insert billto;
		Account billto2 = new Account(
			Name = 'BillToTest2',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1006',
			Primary_Bill_To_Unique_Id__c = '003',
			Parent_Unique_Id__c = '1004'
		);
		insert billto2;
		Account billto3 = new Account(
			Name = 'BillToTest3',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1008',
			Primary_Bill_To_Unique_Id__c = '004',
			ParentId = null,
			Parent_Unique_Id__c = '1005'
		);
		insert billto3;
		Account billto4 = new Account(
			Name = 'BillToTest4',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1010',
			Primary_Bill_To_Unique_Id__c = '006',
			Primary_Bill_To__c = billTo3.Id,
			ParentId = null,
			Parent_Unique_Id__c = '1006'
		);
		insert billto4;
		//insert AccountTeamMember
		AccountTeamMember atm = new AccountTeamMember();
		atm.accountId = sgn.id;
		atm.userId = userinfo.getUserId();
		atm.TeamMemberRole = 'Account Manager';
		insert atm;
		//Assert Statements
		System.assert(atm.AccountId == sgn.Id);
		System.assertNotEquals(sgnAccList.size(), null);
		System.assertEquals(accTeamList.size(), 1);

		Test.startTest();
		//Execute Batch
		ParentalSetupAccountTeamCascade_Batch batchObj = new ParentalSetupAccountTeamCascade_Batch();
		List<Account> acc = [SELECT Id, Name, Parent_Unique_Id__c, ParentId FROM Account WHERE Name = 'SiteSGNTest'];
		acc[0].ParentId = null;
		update acc;

		acc = [SELECT Id, Name, Parent_Unique_Id__c, ParentId FROM Account WHERE Name = 'SiteSGNTest'];
		CommonUtilities.debug('==acc==75==' + acc);
		/*acc[0].Parent_Unique_Id__c='1001';
		 update acc;*/
		Id batchJobId = Database.executeBatch(batchObj);
		Test.stopTest();
		//Assertion Statements
		//accTeamlist = [SELECT Id,AccountId FROM AccountTeamMember];
		//System.assertEquals(accTeamlist.size(), 7);
		List<ShipTo_BillTo__c> shipToBillToList = [SELECT Id FROM ShipTo_BillTo__c];
		System.assertEquals(shipToBillToList.size(), 1);
		List<Account> accParentList = [SELECT Id FROM Account WHERE ParentId != NULL];
		System.assertNotEquals(accParentList.size(), null);

		Id batchJobId2 = Database.executeBatch(batchObj);
	}

	@isTest
	public static void testBatchSchedule() {
		//Create ShipTo RecordType Account
		Account shipto = new Account(
			Name = 'ShipToTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1004',
			Parent_Unique_Id__c = '1003',
			Primary_Bill_To_Unique_Id__c = '1005',
			Child_Unique_Id__c = '1006',
			Exclude_From_Hierarchy__c = true
		);
		insert shipto;
		Account shipto2 = new Account(
			Name = 'ShipToTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1007',
			Parent_Unique_Id__c = '1003',
			Exclude_From_Hierarchy__c = true
		);
		insert shipto2;

		//Create NSGN RecordType Account
		Account nsgn = new Account(
			Name = 'NSGNTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(NSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1002',
			Parent_Unique_Id__c = '1001',
			Exclude_From_Hierarchy__c = true
		);
		insert nsgn;
		//Create SGN RecordType Account
		Account sgn = new Account(
			Name = 'SiteSGNTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1003',
			Parent_Unique_Id__c = '1002',
			Exclude_From_Hierarchy__c = true
		);
		insert sgn;

		List<Account> sgnAccList = new List<Account>();
		sgnAccList.add(sgn);
		//Create Custom Account Team
		List<Account_Team__c> accTeamList = TestSetupDataUtil.insertAccountTeamRecords(sgnAccList);

		//Create GSGN RecordType Account
		Account gsgn = new Account(
			Name = 'GSGNTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(GSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1001',
			Primary_Bill_To_Unique_Id__c = '001',
			Parent_Unique_Id__c = '1002'
		);
		insert gsgn;
		//Create BillTo RecordType Account
		Account billto = new Account(
			Name = 'BillToTest',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1005',
			Primary_Bill_To_Unique_Id__c = '002',
			Parent_Unique_Id__c = '1003'
		);
		insert billto;
		Account billto2 = new Account(
			Name = 'BillToTest2',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1006',
			Primary_Bill_To_Unique_Id__c = '003',
			Parent_Unique_Id__c = '1004'
		);
		insert billto2;
		Account billto3 = new Account(
			Name = 'BillToTest3',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1008',
			Primary_Bill_To_Unique_Id__c = '004',
			ParentId = null,
			Parent_Unique_Id__c = '1005'
		);
		insert billto3;
		Account billto4 = new Account(
			Name = 'BillToTest4',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1010',
			Primary_Bill_To_Unique_Id__c = '006',
			Primary_Bill_To__c = billTo3.Id,
			ParentId = null,
			Parent_Unique_Id__c = '1006'
		);
		insert billto4;
		//insert AccountTeamMember
		AccountTeamMember atm = new AccountTeamMember();
		atm.accountId = sgn.id;
		atm.userId = userinfo.getUserId();
		atm.TeamMemberRole = 'Account Manager';
		insert atm;
		//Assert Statements
		System.assert(atm.AccountId == sgn.Id);
		System.assertNotEquals(sgnAccList.size(), null);
		System.assertEquals(accTeamList.size(), 1);

		Test.StartTest();
		String sch = '0 0 23 * * ?';
		ParentalSetupAccountTeamCascade_Sch ob = new ParentalSetupAccountTeamCascade_Sch();
		System.assert(ob != null);
		String jobId = system.schedule('Test status Check', sch, ob);
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		System.assertEquals(0, ct.TimesTriggered);

		Test.stopTest();
	}
}