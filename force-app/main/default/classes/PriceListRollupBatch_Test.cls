// ===========================================================================
//  Object: PriceListRollupBatch_Test
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Unit Test Class for PriceListRollup_Batch And PriceListRollup_BatchSchedulable.
// ===========================================================================
@isTest
public class PriceListRollupBatch_Test {
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
	public static String SOLDTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SOLDTO;

	// Method Name: testSetupMethod
	// Author: Abinash Panigrahi
	// Description: Method to create Test Data to be used
	@testSetup
	public static void testSetupMethod() {
		// Insert Pricebook
		PriceBook2 customPriceBook1 = new PriceBook2();
		customPriceBook1.Name = 'AAA';
		customPriceBook1.Currency_Code__c = 'USD';
		customPriceBook1.IsActive = true;
		customPriceBook1.Country_Code__c = 'US';
		insert customPriceBook1;
		PriceBook2 customPriceBook2 = new PriceBook2();
		customPriceBook2.Name = 'ABA';
		customPriceBook2.IsActive = true;
		customPriceBook2.Currency_Code__c = 'USD';
		customPriceBook2.Country_Code__c = 'US';
		insert customPriceBook2;
		PriceBook2 customPriceBook3 = new PriceBook2();
		customPriceBook3.Name = 'BAB';
		customPriceBook3.IsActive = true;
		customPriceBook3.Currency_Code__c = 'USD';
		customPriceBook3.Country_Code__c = 'US';
		insert customPriceBook3;

		//Create SGN Account Hierarchy Records
		Account sgn = new Account(
			Name = 'Site SGN Test',
			Unique_Id__c = '1001',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SGN_RECORDTYPE_NAME)
				.getRecordTypeId()
		);
		insert sgn;
		Account shipto1 = new Account(
			Name = 'Ship To Test 1',
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1002',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook1.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'E1'
		);
		insert shipto1;
		Account shipto2 = new Account(
			Name = 'Ship To Test 2',
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1003',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook2.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'E1'
		);
		insert shipto2;
		Account shipto3 = new Account(
			Name = 'Ship To Test 3',
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1004',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook2.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'E1'
		);
		insert shipto3;
		Account shipto4 = new Account(
			Name = 'Ship To Test 4',
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1005',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook1.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'SAP'
		);
		insert shipto4;
		Account shipto5 = new Account(
			Name = 'Ship To Test 5',
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1006',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = null,
			Account_Status__c = 'Active',
			Source_System__c = 'E1'
		);
		insert shipto5;

		//Create SGN Account Hierarchy Records
		Account sgn2 = new Account(
			Name = 'Site SGN Test 2',
			Unique_Id__c = '3001',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SGN_RECORDTYPE_NAME)
				.getRecordTypeId()
		);
		insert sgn2;
		Account shipto6 = new Account(
			Name = 'Ship To Test 6',
			Parent_Unique_Id__c = '3001',
			Unique_Id__c = '3002',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = null,
			Account_Status__c = 'Inactive',
			Source_System__c = 'E1'
		);
		insert shipto6;
		shipto6.Exclude_From_Rollup__c = true;
		update shipto6;
		Account shipto7 = new Account(
			Name = 'Ship To Test 7',
			Parent_Unique_Id__c = '3001',
			Unique_Id__c = '3003',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = null,
			Account_Status__c = 'Active',
			Source_System__c = 'SAP'
		);
		insert shipto7;
		shipto7.Exclude_From_Rollup__c = true;
		update shipto7;

		//Create Sold To Account Hierarchy Records
		Account soldto = new Account(
			Name = 'Sold To Test',
			Unique_Id__c = '2001',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SOLDTO_RECORDTYPE_NAME)
				.getRecordTypeId()
		);
		insert soldto;
		Account shipto11 = new Account(
			Name = 'Ship To Test 11',
			Parent_Unique_Id__c = '2001',
			Unique_Id__c = '2002',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook1.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'SAP'
		);
		insert shipto11;
		Account shipto12 = new Account(
			Name = 'Ship To Test 12',
			Parent_Unique_Id__c = '2001',
			Unique_Id__c = '2003',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook2.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'SAP'
		);
		insert shipto12;
		Account shipto13 = new Account(
			Name = 'Ship To Test 13',
			Parent_Unique_Id__c = '2001',
			Unique_Id__c = '2004',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = customPriceBook3.Id,
			Account_Status__c = 'Active',
			Source_System__c = 'SAP'
		);
		insert shipto13;
		Account shipto14 = new Account(
			Name = 'Ship To Test 14',
			Parent_Unique_Id__c = '2001',
			Unique_Id__c = '2005',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Price_Book__c = null,
			Account_Status__c = 'Active',
			Source_System__c = 'SAP'
		);
		insert shipto14;
	}

	// Method Name: batchLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Batch Sync Logic for setting up Account Hierarchy
	@isTest
	public static void batchLogicTest() {
		Test.startTest();
		//Execute Batch
		PriceListRollup_Batch batchObj = new PriceListRollup_Batch();
		Id batchJobId = Database.executeBatch(batchObj);
		Test.stopTest();

		//Fetch Parent Account Records after Batch
		Account sgn1 = [SELECT Id, Price_Book__c FROM Account WHERE Name = 'Site SGN Test' LIMIT 1];
		Account sgn2 = [SELECT Id, Price_Book__c FROM Account WHERE Name = 'Site SGN Test 2' LIMIT 1];
		Account soldto = [SELECT Id, Price_Book__c FROM Account WHERE Name = 'Sold To Test' LIMIT 1];

		//Fetch Custom PriceBook
		PriceBook2 customPriceBook1 = [SELECT Id FROM PriceBook2 WHERE Name = 'AAA' LIMIT 1];
		PriceBook2 customPriceBook2 = [SELECT Id FROM PriceBook2 WHERE Name = 'ABA' LIMIT 1];
		PriceBook2 customPriceBook3 = [SELECT Id FROM PriceBook2 WHERE Name = 'BAB' LIMIT 1];

		//Fetch all Rollup True ACcount records
		List<Account> rollupList = [SELECT Id FROM Account WHERE Exclude_From_Rollup__c = TRUE];

		//Check for Expected Values with Assertion statements
		System.assertNotEquals(batchJobId, null);
		System.assertEquals(sgn1.Price_Book__c, customPriceBook2.Id);
		System.assertEquals(soldto.Price_Book__c, customPriceBook1.Id);
		System.assertEquals(sgn2.Price_Book__c, null);
		System.assertEquals(rollupList.size(), 0);
	}

	@isTest
	public static void testscheduleData() {
		Test.StartTest();
		PriceListRollup_BatchSchedulable sh1 = new PriceListRollup_BatchSchedulable();
		String sch = '0 0 23 * * ?';
		String jobId = system.schedule('Test check', sch, sh1);
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		//Assert Statements
		System.assertEquals(sch, ct.CronExpression);
		System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
}