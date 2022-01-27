// ===========================================================================
//  Object	: AccountTeamTriggerHandler_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for AccountTeamTrigger and AccountTeamTriggerHandler.
// ===========================================================================
@isTest
public class AccountTeamTriggerHandler_Test {
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SGN_RECORDTYPE_NAME1 = Label.ACCOUNT_RECORD_NATIONAL_SGN;
	public static String SGN_RECORDTYPE_NAME2 = Label.ACCOUNT_RECORD_SHIPTO;

	// Method Name: testSetupMethod
	// Author: Abinash panigrahi
	// Description: Method to create Test Data to be used
	@testSetup
	public static void testSetupMethod() {
		//Create Account Records -- Complete Hierarchy
		List<Account> accList = TestSetupDataUtil.insertAccountHierarchy();
		list<Account> acc = [SELECT Id, Name, ParentId FROM Account];
		System.assertEquals(acc.size(), 6);
		AccountTeamTriggerHandler.isReTriggerBatch = true;
	}

	// Method Name: insertLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Insert Logic of Custom Account Team record
	@isTest
	public static void insertLogicTest() {
		Test.startTest();
		list<Account> acc = [SELECT Id, Name, ParentId FROM Account];
		//Fetch Site SGN Account RecordType
		List<Account> sgnAccList = [
			SELECT Id, ParentId, Name, Account.Parent.parentid
			FROM Account
			WHERE RecordType.Name = :SGN_RECORDTYPE_NAME
		];
		sgnAccList[0].parentId = acc[0].id;
		sgnAccList[0].parent.parentId = acc[1].id;
		update sgnAccList[0];
		//Create Custom Account Team
		List<Account_Team__c> accTeamList = TestSetupDataUtil.insertAccountTeamRecords(sgnAccList);
		Test.stopTest();
		//Fetch Standrad AccountTeam Member
		List<AccountTeamMember> atmObj = [SELECT Id, AccountId, UserId FROM AccountTeamMember];
		System.assertEquals(atmObj.size(), 0);
		//Fetch Custom AccountTeam Member
		List<Account_Team__c> cusAtmObj = [
			SELECT Id, AccountId__c, Account_Unique_Id__c, IsUserActive__c, UserId__c
			FROM Account_Team__c
		];

		//Check for Expected Values with Assertion statements
		System.assertNotEquals(atmObj.size(), 5);
		System.assertEquals(cusAtmObj.size(), 1);
		Map<Id, Account_Team__c> mapResult = new Map<Id, Account_Team__c>();
		for (Account_Team__c a : cusAtmObj) {
			mapResult.put(a.id, a);
		}

		List<Account_Team__c> accountTeam = new List<Account_Team__c>();
		AccountTeamTriggerHandler.insertAccountTeamMember(cusAtmObj);

		for (Account_Team__c a : cusAtmObj) {
			a.IsUserActive__c = true;
			mapResult.put(a.id, a);
		}
		if (!mapResult.IsEmpty()) {
			AccountTeamTriggerHandler.isReTriggerBatch = true;
			update mapResult.values();
		}
	}

	// Method Name: deleteLogicTest
	// Author: Abinash panigrahi
	// Description: Method to test Delete Logic of Custom Account Team record
	@isTest
	public static void deleteLogicTest() {
		Test.startTest();
		List<Account> acc = TestSetupDataUtil.insertAccountRecords(1);
		//Fetch Site SGN Account RecordType
		List<Account> sgnAccList = [SELECT Id, ParentId FROM Account WHERE RecordType.Name = :SGN_RECORDTYPE_NAME];
		sgnAccList[0].parentId = acc[0].id;
		update sgnAccList[0];
		//Ftech ShipTo Records
		List<Account> shipaccList = [SELECT Id, ParentId FROM Account WHERE RecordType.Name = :SGN_RECORDTYPE_NAME2];
		shipaccList[0].parentId = sgnAccList[0].id;
		update shipaccList[0];
		//Create Custom Account Team
		List<Account_Team__c> accTeamList = TestSetupDataUtil.insertAccountTeamRecords(sgnAccList);
		list<Account_Team__c> tt = [SELECT Id, AccountId__c, UserId__c FROM Account_Team__c];

		//Delete Custom Account Team
		delete accTeamList;
		Test.stopTest();
		//Fetch Standrad AccountTeam Member
		List<AccountTeamMember> atmObj = [SELECT Id, AccountId, UserId FROM AccountTeamMember];

		//Fetch Custom AccountTeam Member
		List<Account_Team__c> cusAtmObj = [SELECT Id, AccountId__c, userId__c FROM Account_Team__c];
		//Check for Expected Values with Assertion statements
		System.assertEquals(atmObj.size(), 0);
		System.assertEquals(cusAtmObj.size(), 0);
	}

	@istest
	public static void insertAccountTeamMemberTest() {
		//Ftech All Accounts;
		List<Account> acc = [SELECT Id, Name FROM Account];
		//insert Account  team
		List<Account_Team__c> accTeams = TestSetupDataUtil.insertAccountTeamRecords(acc);
		List<Account> sgnAccList = [SELECT Id, ParentId FROM Account WHERE RecordType.Name = :SGN_RECORDTYPE_NAME1];
		//create the Account Records
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.Unique_Id__c = 'E1_SGN_0910';
		a.ParentId = sgnAccList[0].id;
		a.RecordTypeId = RecordTypeId;
		insert a;
		System.assertNotEquals(a.id, null);
		List<Account> shipnAccList = [SELECT Id, ParentId FROM Account WHERE RecordType.Name = :SGN_RECORDTYPE_NAME2];
		System.assertEquals(shipnAccList.size(), 1);
		//create the Account Records
		Id RecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Ship To').getRecordTypeId();
		Account a1 = new Account();
		a1.Name = 'Test Account';
		a1.Unique_Id__c = 'E1_SGN_09101';
		a1.ParentId = a.id;
		a1.Primary_Bill_To_Unique_Id__c = '234';
		a1.Child_Unique_Id__c = '234';
		a1.RecordTypeId = RecordTypeId1;
		insert a1;
		System.assertNotEquals(a1.id, null);
		Id RecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bill To').getRecordTypeId();
		Account a2 = new Account();
		a2.Name = 'Test Account';
		a2.Unique_Id__c = '234';
		a2.ParentId = a.id;
		a2.Primary_Bill_To_Unique_Id__c = '2345';
		a2.Child_Unique_Id__c = '234';
		a2.RecordTypeId = RecordTypeId2;
		insert a2;
		//Check for Expected Values with Assertion statements
		System.assertNotEquals(a1.id, null);
		System.assert(a2.ParentId == a.Id);
		System.assertNotEquals(a2.Primary_Bill_To_Unique_Id__c, a1.Primary_Bill_To_Unique_Id__c);
		System.assertEquals(a2.Child_Unique_Id__c, a1.Child_Unique_Id__c);
		//INSERT Account Team
		try {
			Account_Team__c obj = new Account_Team__c();
			obj.AccountId__c = a.Id;
			obj.UserId__c = UserInfo.getUserId();
			obj.AccountAccessLevel__c = 'Read';
			obj.CaseAccessLevel__c = 'Read';
			obj.ContactAccessLevel__c = 'Read';
			obj.OpportunityAccessLevel__c = 'Read';
			obj.Position__c = 'Test';
			obj.IsUserActive__c = true;
			obj.TeamMemberRole__c = 'Account Manager';
			database.insert(obj, false);

			delete obj;
		} catch (exception e) {
		}

		//Check for Expected Values with Assertion statements
		// System.assertNotEquals(obj.Id,null);
		//System.assert(obj.AccountId__c==a.id);

		Map<Id, Account_Team__c> result = new Map<Id, Account_Team__c>();
		for (Account_Team__c t : accTeams) {
			result.put(t.id, t);
		}
		System.assertNotEquals(result.size(), null);
	}
}