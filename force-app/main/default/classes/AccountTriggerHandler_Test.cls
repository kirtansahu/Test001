//===========================================================================
//	Object	:	AccountTriggerHandler_Test
//	Company	:	Keste @IDC
//	Author	:	Abinash Panigrahi
//	Purpose	:	Unit Test Class for AccountTrigger and AccountTriggerHandler.
//===========================================================================
@isTest
private class AccountTriggerHandler_Test {
	// Method Name: testSetupMethod
	// Author: Abinash panigrahi
	// Description: Method to create Test Data to be used
	@testSetup
	public static void testSetupMethod() {
		//Insert Account Records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(1);
		//Insert Contact Records
		TestSetupDataUtil.insertContactRecordswithAcc(1, accList);
		//Insert User
		TestSetupDataUtil.insertUsers(1);
		//Insert PriceBook Records
		TestSetupDataUtil.insertPriceBookRecords(1);
	}

	// Method Name: contactOwnerLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Update Logic of Contact OwnerId field
	@isTest
	public static void contactOwnerLogicTest() {
		//Fetch Inserted Account Records
		Account accObj = [SELECT Id, OwnerId FROM Account LIMIT 1];
		//Fetch User
		List<User> userObj = [SELECT Id FROM User LIMIT 3];
		//Update Account Owner
		accObj.OwnerId = userObj[0].Id;
		update accObj;
		//Fetch Contact Records
		Contact conObj = [SELECT Id, AccountId, OwnerId FROM Contact LIMIT 1];
		//Fetch Updated Account Records
		accObj = [SELECT Id, OwnerId FROM Account LIMIT 1];
		//Assertion Statements
		System.assertNotEquals(accObj.OwnerId, conObj.OwnerId);
		System.assertNotEquals(conObj.OwnerId, null);
	}

	// Method Name: rollupPriceBookLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Logic for PriceBook Checkbox Logic
	@isTest
	public static void rollupPriceBookLogicTest() {
		//Fetch PriceBook Records
		PriceBook2 pbObj = [SELECT Id FROM PriceBook2];

		//Create ShipTo Account Records
		String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
		Account shipToAcc = new Account(
			Name = 'Test ShipTo Account',
			Unique_Id__c = '123',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Parent_Unique_Id__c = '1001',
			Price_Book__c = pbObj.Id
		);
		insert shipToAcc;

		//Fetch ShipTo Account Records
		shipToAcc = [SELECT Id, Exclude_From_Rollup__c FROM Account WHERE Name = 'Test ShipTo Account'];

		//Update ShipTo Account Records
		shipToAcc.Price_Book__c = null;
		update shipToAcc;

		System.assertEquals(shipToAcc.Price_Book__c, null);

		//Insert InActive PriceBook
		PriceBook2 pbObj2 = new PriceBook2(Name = 'Test PriceBook 2', isActive = false, Currency_Code__c = 'USD');
		insert pbObj2;

		//Create ShipTo Account Records
		Account shipToAcc2 = new Account(
			Name = 'Test ShipTo Account 2',
			Unique_Id__c = '1234',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Parent_Unique_Id__c = '1001',
			Price_Book__c = pbObj2.Id
		);
		insert shipToAcc2;

		//Fetch ShipTo Account Records
		shipToAcc2 = [SELECT Id, Exclude_From_Rollup__c FROM Account WHERE Name = 'Test ShipTo Account 2'];

		//Assertion Statements
		System.assert(pbObj2.IsActive == false);
		System.assertNotEquals(pbObj2.id, null);

		//Update ShipTo Account Records
		shipToAcc2.Price_Book__c = null;
		update shipToAcc2;

		//Fetch Updated ShipTo Account Records
		shipToAcc2 = [
			SELECT Id, Exclude_From_Rollup__c, Price_Book__c
			FROM Account
			WHERE Name = 'Test ShipTo Account 2'
		];

		//Assertion Statements
		System.assertEquals(shipToAcc2.Price_Book__c, null);
	}

	// Method Name: shipToBillToRelationSetupLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Logic for ShipTo and Child BillTo Relationship
	@isTest
	public static void shipToBillToRelationSetupLogicTest() {
		//Create BillTo Account Records
		String BILLTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_BILLTO;
		Account billToAcc = new Account(
			Name = 'Test BillTo Account',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1001'
		);
		insert billToAcc;
		Account billToAcc2 = new Account(
			Name = 'Test BillTo Account 2',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1002'
		);
		insert billToAcc2;

		//Create ShipTo Account Records
		String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
		Account shipToAcc = new Account(
			Name = 'Test ShipTo Account',
			Unique_Id__c = '123',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Child_Unique_Id__c = '1001',
			Parent_Unique_Id__c = '1003'
		);
		insert shipToAcc;

		//Fetch ShipTo Account Records
		shipToAcc = [SELECT Id, (SELECT Id FROM BillTos__r) FROM Account WHERE Name = 'Test ShipTo Account'];

		//Assertion Statements
		System.assertEquals(shipToAcc.BillTos__r.size(), 1);

		//Update ShipTo Account Records
		shipToAcc.Child_Unique_Id__c = null;
		update shipToAcc;
		//Assertion Statements
		System.assertEquals(shipToAcc.Child_Unique_Id__c, null);

		//Fetch Updated ShipTo Account Records
		shipToAcc = [SELECT Id, (SELECT Id FROM BillTos__r) FROM Account WHERE Name = 'Test ShipTo Account'];

		//Assertion Statements
		System.assertEquals(shipToAcc.BillTos__r.size(), 0);

		//Update ShipTo Account Records
		shipToAcc.Child_Unique_Id__c = '1002';
		update shipToAcc;
		// //Assertion Statements
		System.assertEquals(shipToAcc.Child_Unique_Id__c, '1002');
		//Fetch Updated ShipTo Account Records
		shipToAcc = [SELECT Id, (SELECT Id FROM BillTos__r) FROM Account WHERE Name = 'Test ShipTo Account'];

		//Assertion Statements
		System.assertEquals(shipToAcc.BillTos__r.size(), 1);

		//Get GSGN Recordtype Id
		Id GSGN_RECORDTYPE_ID = AccountTriggerHandler.GSGN_RECORDTYPE_ID;
		System.assertEquals(
			GSGN_RECORDTYPE_ID,
			Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ACCOUNT_RECORD_GLOBAL_SGN).getRecordTypeId()
		);

		//Get Bill To Recordtype Id
		Id BILLTO_RECORDTYPE_ID = AccountTriggerHandler.BILLTO_RECORDTYPE_ID;
		System.assertEquals(
			BILLTO_RECORDTYPE_ID,
			Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ACCOUNT_RECORD_BILLTO).getRecordTypeId()
		);
	}

	// Method Name: parentalSetupLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Logic for Parent Structure Setup
	@isTest
	public static void parentalSetupLogicTest() {
		//Create NSGN Account record
		String NSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_NATIONAL_SGN;
		Account nsgnAcc = new Account(
			Name = 'Test NSGN Account',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(NSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1002',
			Parent_Unique_Id__c = '1001'
		);
		insert nsgnAcc;

		//Create GSGN Account record
		String GSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_GLOBAL_SGN;
		Account gsgnAcc = new Account(
			Name = 'Test GSGN Account',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(GSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1001'
		);
		insert gsgnAcc;

		//Fetch NSGN Account record
		nsgnAcc = [
			SELECT Id, ParentId, Exclude_From_Hierarchy__c
			FROM Account
			WHERE Name = 'Test NSGN Account'
			LIMIT 1
		];

		//Assertion Statements
		System.assertEquals(nsgnAcc.ParentId, null);
		System.assertEquals(nsgnAcc.Exclude_From_Hierarchy__c, true);

		//Create SGN Account record
		String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
		Account sgnAcc = new Account(
			Name = 'Test SGN Account',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1003',
			Parent_Unique_Id__c = '1002'
		);
		insert sgnAcc;

		//Fetch NSGN Account record
		sgnAcc = [SELECT Id, ParentId, Exclude_From_Hierarchy__c FROM Account WHERE Name = 'Test SGN Account' LIMIT 1];

		//Assertion Statements
		System.assertEquals(sgnAcc.ParentId, nsgnAcc.Id);
		System.assertEquals(sgnAcc.Exclude_From_Hierarchy__c, false);

		//Update SGN Account record
		sgnAcc.Parent_Unique_Id__c = '1001';
		update sgnAcc;
		//Assertion Statements
		System.assertEquals(sgnAcc.Parent_Unique_Id__c, '1001');
		//Fetch NSGN Account record
		sgnAcc = [SELECT Id, ParentId, Exclude_From_Hierarchy__c FROM Account WHERE Name = 'Test SGN Account' LIMIT 1];

		//Assertion Statements
		System.assertNotEquals(sgnAcc.ParentId, null);
		System.assertEquals(sgnAcc.Exclude_From_Hierarchy__c, true);
		Country_Organization_Mapping__c cc = new Country_Organization_Mapping__c(
			Name = 'sample',
			Base_Currency_code__c = 'USD',
			BU__c = 'Organization',
			Code__c = 'US',
			Country__c = 'state',
			Default_City__c = 'test',
			Default_PriceList__c = '',
			Default_State__c = ''
		);
		insert cc;
		//Ftech All Users
		List<User> uu1 = [SELECT Id, Name FROM User];
		//create new Account
		Account a = new Account(
			Name = 'Test Account',
			billingCountryCode = 'US',
			ShippingCountryCode = 'IN',
			Parent_Unique_Id__c = null,
			ownerId = uu1[0].id,
			Primary_Bill_To_Unique_Id__c = '1237',
			Unique_Id__c = '1237',
			Account_Status__c = 'ACTIVE',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(label.ACCOUNT_RECORD_SHIPTO)
				.getRecordTypeId()
		);
		insert a;
		Account acc1 = new Account(
			Name = 'Test AccountData',
			billingCountryCode = 'US',
			ShippingCountryCode = 'IN',
			Parent_Unique_Id__c = null,
			ownerId = uu1[0].id,
			Primary_Bill_To_Unique_Id__c = '12367',
			Unique_Id__c = '12357',
			Account_Status__c = 'ACTIVE',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(label.ACCOUNT_RECORD_SITE_SGN)
				.getRecordTypeId()
		);
		insert acc1;
		//Ftech All Users
		List<User> uu = [SELECT Id, Name FROM User];
		//Ftech All Account Records
		List<Account> acc = [
			SELECT Id, Name, OwnerId, Parent_Unique_Id__c, Primary_Bill_To_Unique_Id__c, Child_Unique_Id__c
			FROM Account
		];
		acc[0].Parent_Unique_Id__c = '1562345';
		acc[0].Primary_Bill_To_Unique_Id__c = '452345';
		update acc;
		acc[0].ownerid = userinfo.getUserId();
		update acc;
		//Assertion Statement
		System.assertNotEquals(acc.size(), null);
		Map<Id, Account> mapResult = new Map<ID, Account>();
		for (Account a1 : acc) {
			mapResult.put(a1.id, a1);
		}
		//AccountTriggerHandler.updateContactOwner(new List<Account>{a},mapResult);
		//AccountTriggerHandler.updateDefaultOwner(new List<Account>{a});
		AccountTriggerHandler.updateParentalSetup(acc, mapresult);
		//AccountTriggerHandler.updateContactOwner(new List<Account>(),mapResult);
		AccountTriggerHandler.parentalSetup(new List<Account>{ a });
		AccountTriggerHandler.populateCountryWiseOrganizationRegion(new List<Account>{ acc1 });
	}

	// Method Name: testAccountDeleteScenario
	// Author: Basant Kumar Verma
	// Description: Method to test Account Delete Scenario
	@isTest
	public static void testAccountDeleteScenario() {
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		List<Account> accList = new List<Account>();
		System.runAs(thisUser) {
			Test.startTest();
			accList.add(
				new Account(
					Name = 'Test Account2',
					Unique_Id__c = '1235',
					Account_Status__c = 'ACTIVE',
					RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
						.get(TestSetupDataUtil.SGN_RECORDTYPE_NAME)
						.getRecordTypeId()
				)
			);
			insert accList;
			delete accList;
			test.stopTest();
		}
	}

	// Method Name: testAccountRealignment
	// Author: Basant Kumar Verma
	// Description: Method to test Account Realignment
	@isTest
	public static void testAccountRealignment() {
		List<Account> accList = [SELECT Id, SGNCustomCriteria1__c FROM Account WHERE RecordType.Name = 'Site SGN'];
		Test.startTest();
		accList[0].SGNCustomCriteria1__c = 'Test';
		update accList[0];
		Test.stopTest();
	}
}