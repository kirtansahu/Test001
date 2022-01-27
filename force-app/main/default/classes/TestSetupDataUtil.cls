// ===========================================================================
//  Object	: TestSetupDataUtil
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Utility Class to create Test Data, which is to be used in all Test classes.
// ===========================================================================
public class TestSetupDataUtil {
	//Class level variables for Account record type names
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
	public static String BILLTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_BILLTO;
	public static String GSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_GLOBAL_SGN;
	public static String NSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_NATIONAL_SGN;

	// Method Name: insertAccountHierarchy
	// Author: Abinash panigrahi
	// Description: Method to insert complete Account Hierarchy -- GSGN, NSGN, SGN, ShipTo
	// Parameter : Null
	// Return: accList - List of Account records for each hierarchy level
	public static List<Account> insertAccountHierarchy() {
		Account gsgn = new Account(
			Name = 'Global SGN Test Account',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(GSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1001'
		);
		insert gsgn;
		Account nsgn = new Account(
			Name = 'National SGN Test',
			ParentId = gsgn.Id,
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(NSGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1002'
		);
		insert nsgn;
		Account sgn = new Account(
			Name = 'Site SGN Test',
			ParentId = nsgn.Id,
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SGN_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Parent_Unique_Id__c = '1002',
			Unique_Id__c = '1003'
		);
		insert sgn;
		Account shipto = new Account(
			Name = 'Ship To Test',
			ParentId = sgn.Id,
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(SHIPTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Child_Unique_Id__c = '1005',
			Primary_Bill_To_Unique_Id__c = '1006',
			Parent_Unique_Id__c = '1003',
			Unique_Id__c = '1004'
		);
		insert shipto;

		//Add BillTo Account RecordType
		Account billto = new Account(
			Name = 'Bill To Test',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1005'
		);
		insert billto;
		Account billto1 = new Account(
			Name = 'Bill To Test',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(BILLTO_RECORDTYPE_NAME)
				.getRecordTypeId(),
			Unique_Id__c = '1006'
		);
		insert billto1;

		List<Account> accList = new List<Account>();
		accList.add(gsgn);
		accList.add(nsgn);
		accList.add(sgn);
		accList.add(shipto);
		accList.add(billto);
		return accList;
	}

	// Method Name: insertUsers
	// Author: Abinash panigrahi
	// Description: Method to insert Users
	// Parameter : num - No. of Users to be inserted
	// Return: userList - List of Users
	public static List<User> insertUsers(Integer num) {
		List<User> userList = new List<User>();
		DateTime dt = System.now();
		String dtStr =
			dt.year() +
			'' +
			dt.month() +
			'' +
			dt.day() +
			'' +
			dt.hour() +
			'' +
			dt.minute() +
			'' +
			dt.second() +
			'' +
			dt.millisecond();
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		for (Integer i = 1; i <= num; i++) {
			User u = new User(
				LastName = 'Test' + i,
				Email = 'test' + i + '@test.com',
				Username = 'Test_test' + i + dtStr + '@test.com',
				Alias = 'test' + i,
				ProfileId = profileId,
				TimeZoneSidKey = 'America/Los_Angeles',
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US'
			);
			userList.add(u);
		}
		insert userList;
		return userList;
	}

	// Method Name: insertUserWithProfileName
	// Author: Basant Kumar Verma
	// Description: Method to insert a single User with given profile
	// Parameter : profileName - Profile Name
	// Return: User - Created User Record
	public static User insertUserWithProfileName(String profileName) {
		Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
		//Insert the UserRole
		UserRole r = new UserRole(Name = 'My Role');
		insert r;
		User u = new User(
			LastName = 'Test_AM',
			Email = 'test_AM@test.com',
			Username = 'Test_test_AM@test.com',
			Alias = 'test_AM',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			userRoleId = r.Id
		);
		insert u;
		return u;
	}

	// Method Name: insertAccountRecords
	// Author: Abinash panigrahi
	// Description: Method to insert multiple Account records
	// Parameter : num - No. of Account to be inserted
	// Return: accList - List of Account
	public static List<Account> insertAccountRecords(Integer num) {
		List<Account> accList = new List<Account>();
		for (Integer i = 1; i <= num; i++) {
			Account a = new Account(
				Name = 'Test Account' + i,
				Unique_Id__c = '1234' + i,
				Account_Status__c = 'ACTIVE',
				RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
					.get(SGN_RECORDTYPE_NAME)
					.getRecordTypeId()
			);
			accList.add(a);
		}
		insert accList;
		return accList;
	}

	// Method Name: insertContactRecords
	// Author: Abinash panigrahi
	// Description: Method to insert multiple Contact records
	// Parameter : num - No. of Contact to be inserted
	// Return : conList - List of Contact
	public static List<Contact> insertContactRecords(Integer num) {
		List<Contact> conList = new List<Contact>();
		for (Integer i = 1; i <= num; i++) {
			Contact c = new Contact(
				LastName = 'TestContact' + i,
				FirstName = 'TestContactName' + i,
				Contact_External_Id__c = String.valueOf(i)
			);
			conList.add(c);
		}
		insert conList;
		return conList;
	}

	// Method Name: insertContactRecordswithAcc
	// Author: Keste @ IDC
	// Description: Method to insert Contact records for provided accounts
	// Parameter 1: Integer num - Number of records to be created
	// Parameter 2: List<Account> lstAcc - List of Accounts for which contacts need to be loaded
	// Return: List<Contact> - List of Contact records which was created
	public static List<Contact> insertContactRecordswithAcc(Integer num, List<Account> lstAcc) {
		List<Contact> conList = new List<Contact>();
		for (Integer i = 0; i < num; i++) {
			Contact c = new Contact(
				LastName = 'TestContact',
				FirstName = 'Test',
				AccountId = lstAcc[i].Id,
				Email = 'test' + i + '@gmail.com',
				Contact_External_Id__c = String.valueOf(i)
			);
			conList.add(c);
		}
		insert conList;
		return conList;
	}

	// Method Name: insertContactRecordswithAccount
	// Author: Keste @ IDC
	// Description: Method to insert Contact records for provided accounts
	// Parameter 1: Integer num - Number of records to be created
	// Parameter 2: List<Account> lstAcc - List of Accounts for which contacts need to be loaded
	// Return: List<Contact> - List of Contact records which was created
	public static List<Contact> insertContactRecordswithAccount(Integer num, List<Account> lstAcc) {
		List<Contact> conList = new List<Contact>();
		for (Integer i = 0; i < num; i++) {
			Contact c = new Contact(
				FirstName = 'TestContact',
				LastName = 'Data ',
				AccountId = lstAcc[i].Id,
				Email = 'test' + i + '@gmail.com',
				Contact_External_Id__c = String.valueOf(i)
			);
			conList.add(c);
		}
		insert conList;
		return conList;
	}

	// Method Name: insertAccountTeamRecords
	// Author: Abinash panigrahi
	// Description: Method to insert multiple custom Account Team records
	// Parameter : sgnAccList - List of SGN Account Records
	// Return : accTeamList - List of Account Team
	public static List<Account_Team__c> insertAccountTeamRecords(List<Account> sgnAccList) {
		List<Account_Team__c> accTeamList = new List<Account_Team__c>();
		for (Account a : sgnAccList) {
			Account_Team__c obj = new Account_Team__c();
			obj.AccountId__c = a.Id;
			obj.UserId__c = UserInfo.getUserId();
			obj.AccountAccessLevel__c = 'Read';
			obj.CaseAccessLevel__c = 'Read';
			obj.ContactAccessLevel__c = 'Read';
			obj.OpportunityAccessLevel__c = 'Read';
			obj.Position__c = 'Test';
			obj.TeamMemberRole__c = 'Account Manager';
			accTeamList.add(obj);
		}
		insert accTeamList;
		return accTeamList;
	}

	// Method Name: insertPriceBookRecords
	// Author: Abinash panigrahi
	// Description: Method to insert multiple Price Book records
	// Parameter : num - No. of Contact to be inserted
	// Return : pbList - List of Price Book
	public static List<PriceBook2> insertPriceBookRecords(Integer num) {
		List<PriceBook2> pbList = new List<PriceBook2>();
		for (Integer i = 0; i < num; i++) {
			PriceBook2 p = new PriceBook2(Name = 'Test PriceBook ' + i, isActive = true, Currency_Code__c = 'USD');
			pbList.add(p);
		}
		insert pbList;
		return pbList;
	}

	// Method Name: insertProfileRecords
	// Author: Keste @ IDC
	// Description: Method to insert multiple Profile records
	// Parameter : Integer num - No. of Profile to be inserted
	// Return : List<Profile__c> - List of Profiles
	public static List<Profile__c> insertProfileRecords(Integer num) {
		List<Profile__c> lstProfiles = new List<Profile__c>();
		for (Integer i = 1; i <= num; i++) {
			Profile__c objProfile = new Profile__c(
				Name = 'Test Profile' + i + Math.random(),
				Tier_Level__c = 'T1',
				Tier_Description__c = 'Test Profile' + i
			);
			lstProfiles.add(objProfile);
		}
		insert lstProfiles;
		return lstProfiles;
	}

	// Method Name: insertTerritoryRules
	// Author: Keste @ IDC
	// Description: Method to insert multiple Territory records
	// Parameter : Integer num - No. of Profile to be inserted
	// Return : List<Profile__c> - List of Profiles
	public static List<Territory_Rule__c> insertTerritoryRules() {
		List<Territory_Rule__c> lstRules = new List<Territory_Rule__c>();

		Territory_Rule__c territoryRule = new Territory_Rule__c();
		territoryRule.Rule_Name__c = 'Trade Channel Subtrade';
		territoryRule.IsActive__c = true;
		territoryRule.Filter_Criteria__c = '1 AND 2';
		territoryRule.Assigned_Territories__c = 'NA';
		territoryRule.Condition1_Field__c = 'Sub Trade Channel';
		territoryRule.Condition1_Operator__c = 'equals';
		territoryRule.Condition1_Value__c = 'ANF,ANG,ANI,DFA,DFI,DMA,DMI,DRA,DRG,DRI';
		territoryRule.Condition2_Field__c = 'Trade Channel';
		territoryRule.Condition2_Operator__c = 'equals';
		territoryRule.Condition2_Value__c = 'DIR';
		lstRules.add(territoryRule);

		Territory_Rule__c territoryRule1 = new Territory_Rule__c();
		territoryRule1.Rule_Name__c = '1.1SLN';
		territoryRule1.IsActive__c = true;
		territoryRule1.Filter_Criteria__c = '1 AND 2';
		territoryRule1.Assigned_Territories__c = 'NA';
		territoryRule1.Condition1_Field__c = 'Zip/Postal Code';
		territoryRule1.Condition1_Operator__c = 'equals';
		territoryRule1.Condition1_Value__c = '94080,94010,94014,94083,94030,94011,94066,94128,94044';
		territoryRule1.Condition2_Field__c = 'Account Record Type';
		territoryRule1.Condition2_Operator__c = 'equals';
		territoryRule1.Condition2_Value__c = 'Site SGN';
		lstRules.add(territoryRule1);

		Territory_Rule__c territoryRule2 = new Territory_Rule__c();
		territoryRule2.Rule_Name__c = 'Global Filter';
		territoryRule2.IsActive__c = true;
		territoryRule2.Filter_Criteria__c = '1 AND 2';
		territoryRule2.Assigned_Territories__c = 'NA';
		territoryRule2.Condition1_Field__c = 'Status';
		territoryRule2.Condition1_Operator__c = 'equals';
		territoryRule2.Condition1_Value__c = 'Active';
		territoryRule2.Condition2_Field__c = 'Account Record Type';
		territoryRule2.Condition2_Operator__c = 'equals';
		territoryRule2.Condition2_Value__c = 'Site SGN';
		lstRules.add(territoryRule2);

		insert lstRules;
		return lstRules;
	}

	// Method Name: insertTerritoryRules
	// Author: Keste @ IDC
	// Description: Method to insert multiple Territory records
	// Parameter : Integer num - No. of Profile to be inserted
	// Return : List<Profile__c> - List of Profiles
	public static List<Territory_Hierarchy__c> insertTerritoryHierarchy() {
		Integer count = 0;
		List<User> userRecords = TestSetupDataUtil.insertUsers(12);
		Parent_Territory_Node__mdt config = [
			SELECT Id, Territory_Model_Name__c, Type__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];
		String modelName = config.Territory_Model_Name__c;
		String type = config.Type__c;
		List<Territory_Hierarchy__c> terrRecords = new List<Territory_Hierarchy__c>();
		for (Integer i = 0; i < 2; i++) {
			Territory_Hierarchy__c terrRecord = new Territory_Hierarchy__c();
			terrRecord.Tier1_Label__c = 'GAWEST' + i;
			terrRecord.Tier2_Label__c = '1.0GA' + i;
			terrRecord.Tier3_Label__c = '1.1SLN' + i;
			terrRecord.Tier4_Label__c = '1.1.1SLN' + i;
			terrRecord.Tier5_Label__c = '1.1.1.1SLN' + i;
			terrRecord.Tier6_Label__c = '1.1.1.1.1SLN' + i;
			terrRecord.Tier1_User__c = userRecords[count + 0].id;
			terrRecord.Tier2_User__c = userRecords[count + 1].id;
			terrRecord.Tier3_User__c = userRecords[count + 2].id;
			terrRecord.Tier4_User__c = userRecords[count + 3].id;
			terrRecord.Tier5_User__c = userRecords[count + 4].id;
			terrRecord.Tier6_User__c = userRecords[count + 5].id;
			terrRecord.Is_Active__c = true;
			terrRecord.Tier1_Type__c = type;
			terrRecord.Tier2_Type__c = type;
			terrRecord.Tier3_Type__c = type;
			terrRecord.Tier4_Type__c = type;
			terrRecord.Tier5_Type__c = type;
			terrRecord.Tier6_Type__c = type;
			terrRecord.Territory_Model_Name__c = modelName;
			terrRecords.add(terrRecord);
			count = 6;
		}
		insert terrRecords;
		return terrRecords;
	}
}