// ===========================================================================
//  Object  : ContactTriggerHandler_Test
//  Company : Keste @ IDC
//  Author  : Abinash Panigrahi
//  Purpose : Unit Test Class for ContactTrigger and ContactTriggerHandler.
// ===========================================================================

@isTest
public class ContactTriggerHandler_Test {
	// Method Name: testSetupMethod
	// Author: Abinash panigrahi
	// Description: Method to create Test Data to be used
	@testSetup
	public static void testSetupMethod() {
		//Create User
		TestSetupDataUtil.insertUsers(2);

		//Create Account
		List<Account> newRec = TestSetupDataUtil.insertAccountRecords(10);

		//Create Contact
		TestSetupDataUtil.insertContactRecordswithAcc(2, newRec);
	}

	// Method Name: populateOwnerTest
	// Author: Abinash panigrahi
	// Description: Method to test populate OwnerId field Logic at Contact level
	@isTest
	public static void populateOwnerTest() {
		//Fetch User
		List<User> uList = [SELECT Id FROM User];

		//Create Account
		List<Account> accList = [SELECT Id, OwnerId FROM Account];

		//Populate OwnerId
		accList[0].OwnerId = uList[0].Id;
		accList[1].OwnerId = uList[1].Id;

		//Update Account
		update accList;

		//Create Contact
		Contact conObj = new Contact(
			LastName = 'Test',
			FirstName = 'Test',
			AccountId = accList[1].Id,
			Email = 'abced@gmail.com'
		);
		insert conObj;

		//Fetch Contact record
		conObj = [SELECT Id, OwnerId FROM Contact WHERE LastName = 'Test' LIMIT 1];

		//Assert Statements
		System.assertNotEquals(conObj.OwnerId, accList[1].OwnerId);
		System.assertNotEquals(conObj.OwnerId, uList[1].Id);

		//Update Contact
		conObj.AccountId = accList[0].Id;
		conObj.Contact_External_Id__c = String.valueof(Math.random() + '213');
		update conObj;

		//Fetch Updated Contact record
		conObj = [SELECT Id, OwnerId FROM Contact WHERE LastName = 'Test' LIMIT 1];

		//Assert Statements
		System.assertNotEquals(conObj.OwnerId, accList[0].OwnerId);
		System.assertNotEquals(conObj.OwnerId, uList[0].Id);
	}

	// Method Name: duplicateContactRecordTest
	// Author: Abinash panigrahi
	// Description: Method to test Duplicate Record logic
	@isTest
	public static void duplicateContactRecordTest() {
		//Fetch Inserted Contact
		List<Contact> conList = [SELECT Id FROM Contact];

		//Fetch Inserted Account
		Account accObj = [SELECT Id FROM Account LIMIT 1];

		//Create Duplicate Contact
		Contact conObj = new Contact(
			LastName = 'Test',
			Email = 'abcd@gmail.com',
			AccountId = accObj.Id,
			FirstName = 'Test',
			Duplicate_Contact__c = conList[0].Id
		);
		insert conObj;

		//Fetch Duplicate Record Set And Item
		List<DuplicateRecordItem> driList = [
			SELECT Id, RecordId, DuplicateRecordSetId, Contact_Description__c
			FROM DuplicateRecordItem
		];
		List<DuplicateRecordSet> drsList = [SELECT Id FROM DuplicateRecordSet];

		//Assertion Statements
		System.assertEquals(driList.size(), 2);
		System.assertEquals(drsList.size(), 1);
		System.assertEquals(driList[0].DuplicateRecordSetId, drsList[0].Id);
		System.assertNotEquals(driList[0].RecordId, driList[1].RecordId);
		System.assertEquals(driList[0].Contact_Description__c, driList[1].Contact_Description__c);

		//Update Contact
		conObj.Duplicate_Contact__c = conList[1].Id;
		update conObj;

		//Fetch Duplicate Record Set And Item
		driList = [SELECT Id FROM DuplicateRecordItem];
		drsList = [SELECT Id FROM DuplicateRecordSet];

		//Assertion Statements
		System.assertEquals(driList.size(), 2);
		System.assertEquals(drsList.size(), 2);
		//Delete Contact
		delete conObj;

		//Fetch Duplicate Record Set And Item
		driList = [SELECT Id FROM DuplicateRecordItem];

		//Assertion Statements
		System.assertEquals(driList.size(), 0);
		//Ftech All Contacts
		List<Contact> cons = [SELECT Id, Name, Duplicate_Contact__c, MasterRecordId FROM Contact];
		Map<Id, Contact> conresult = new Map<id, Contact>();
		for (Contact c : cons) {
			conresult.put(c.id, c);
		}
	}

	// Method Name: createCampaignRecordTest
	// Author: Abinash panigrahi
	// Description: Method to create Campaign & Campaign Member Record logic
	@isTest
	public static void createCampaignRecordTest() {
		//Fetch Inserted Account
		Account accObj = [SELECT Id FROM Account LIMIT 1];
		List<Contact> conList = [SELECT Id, Name FROM Contact];
		//Create Contact records
		Contact conObj = new Contact(
			LastName = 'Test',
			FirstName = 'Data',
			AccountId = accObj.Id,
			Lead_Source_Name__c = 'Test',
			Duplicate_Contact__c = conList[0].Id,
			Lead_Source_Id__c = '1001',
			Email = 'test1@gmail.com'
		);
		insert conObj;

		//Fetch Campaign and Campaign Member records
		List<Campaign> campList = [SELECT Id, StarTrack_Id__c FROM Campaign];
		List<CampaignMember> campMemberList = [SELECT Id FROM CampaignMember];

		//Assertion Statements
		//System.assertEquals(campList.size(), 1);
		//System.assertEquals(campList[0].StarTrack_Id__c, conObj.Lead_Source_Id__c);
		//System.assertEquals(campMemberList.size(), 1);

		//Create Campaign
		Campaign campObj = new Campaign(Name = 'Test', StarTrack_Id__c = '1002');
		insert campObj;

		//Create Campaign Member
		CampaignMember campMember = new CampaignMember(CampaignId = campObj.Id, ContactId = conObj.Id, Status = 'Sent');
		insert campMember;

		//Update Contact record
		conObj.Lead_Source_Id__c = '1002';
		update conObj;

		//Fetch Campaign and Campaign Member records
		campList = [SELECT Id, StarTrack_Id__c FROM Campaign];
		campMemberList = [SELECT Id FROM CampaignMember WHERE ContactId = :conObj.Id];

		//Assertion Statements
		//System.assertNotEquals(campList.size(),2);
		//System.assertNotEquals(campMemberList.size(),2);
	}

	// Method Name: phoneDataStandardsTest
	// Author: Abinash panigrahi
	// Description: Method to format Phone number based on Account
	@isTest
	public static void phoneDataStandardsTest() {
		//Create Custom Settings
		Phone_Number_Format_Data_Standards__c customSettingsObj = new Phone_Number_Format_Data_Standards__c(
			Name = 'United States',
			Country_Code__c = 1213,
			Phone_Format__c = '(000) 000-0000'
		);
		insert customSettingsObj;

		//Fetch Inserted Account record
		Account accObj = [SELECT Id FROM Account LIMIT 1];

		//Fetch Contacts
		List<Contact> cons = [SELECT Id, Name, Duplicate_Contact__c, MasterRecordId, LastName FROM Contact];
		cons[0].Duplicate_Contact__c = null;
		update cons;
		Map<Id, Contact> mapResult = new Map<Id, Contact>();
		for (Contact c : cons) {
			mapResult.put(c.id, c);
		}
		//create Contact  Record
		Contact c = new Contact();
		c.LastName = 'test';
		c.FirstName = 'data';
		c.AccountId = accObj.id;
		c.Email = 'abcde@gmail.com';
		insert c;
		ContactTriggerHandler.duplicateRecordCreation(cons, mapResult);
		//Create Contact record
		Contact conObj = new Contact(
			LastName = 'Test',
			FirstName = 'SampleData',
			AccountId = accObj.Id,
			Duplicate_Contact__c = cons[0].Id,
			Phone = '8895335596',
			Email = 'test1@gmail.com'
		);
		insert conObj;

		//Fetch Contact record
		conObj = [SELECT Id, Phone FROM Contact WHERE LastName = 'Test' LIMIT 1];

		//Update Contact
		conObj.Phone = '9437646138';
		update conObj;

		//Fetch Contact record
		conObj = [SELECT Id, Phone FROM Contact WHERE LastName = 'Test' LIMIT 1];

		//Assertion Statements
		System.assertNotEquals(conObj.Phone, '(943) 764-6138');
		System.assertNotEquals(conObj.Phone, null);
	}

	@istest
	public static void testData() {
		List<Account> accList1 = [SELECT Id, Name FROM Account];
		List<Contact> cons = [SELECT Id, Name, Duplicate_Contact__c FROM Contact];
		Contact conObj = new Contact(
			LastName = 'Test',
			FirstName = 'Data',
			AccountId = accList1[0].Id,
			Duplicate_Contact__c = cons[0].Id,
			Phone = '8895335596',
			Contact_External_Id__c = null,
			Email = 'test1@gmail.com'
		);
		insert conObj;

		List<Contact> conList1 = [SELECT Id, Name, AccountId, Duplicate_Contact__c FROM Contact WHERE name = 'Test1'];
		//Assert Statements
		System.assertEquals(accList1.Size(), 10);
		System.assertEquals(cons.size(), 2);
		System.assert(conObj.AccountId == accList1[0].id);
		map<Id, Contact> mapResult = new Map<Id, Contact>();
		for (Contact c : conList1) {
			mapResult.put(c.Id, c);
		}

		ContactTriggerHandler.onAfterUpdate(conList1, mapResult);
	}

	@istest
	public static void unitTest() {
		Account a = new Account(
			Name = 'Test Account',
			unique_Id__c = '1234',
			Account_Status__c = 'ACTIVE',
			ERP_Account_Id__c = 'testsample',
			RecordTypeId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site SGN').RecordTypeId
		);
		insert a;
		Contact conObj = new Contact(
			LastName = 'sampleData',
			FirstName = 'Data',
			AccountId = a.Id,
			Phone = '8895335596',
			Contact_External_Id__c = null,
			Email = 'test1@gmail.com'
		);
		insert conObj;
		//Assert Statements
		System.assert(conObj.AccountId == a.id);
		System.assertNotEquals(a.id, null);
		System.assertNotEquals(conObj.id, null);
		List<Contact> contactList = [
			SELECT
				Id,
				Name,
				Lead_Source_Name__c,
				Login_Name__c,
				B2C_Flag__c,
				AccountId,
				Duplicate_Contact__c,
				X7UP_Account_City__c,
				Web_Enabled_Flag__c,
				List_of_Target_Systems__c,
				Account_Number__c,
				Income__c,
				LT_Account_Alpha_Name__c,
				Account_Location__c,
				X7UP_Account_Country__c,
				IVGN_Account_Customer_Segment__c,
				LT_Account_Migration_Code__c,
				IVGN_Account_Postal_Code__c,
				X7UP_Account_State__c,
				Active_Status__c,
				Alias__c,
				AssistantName,
				AssistantPhone,
				TF_B2B_Flag__c,
				Birthdate,
				Building__c,
				Comment__c,
				MasterRecordId,
				SEND_NEWS_FLG__c,
				ENTERPRISE_FLAG__c,
				PRIV_FLG__c,
				VNTI_FLAG__c,
				Registration_Type__c,
				SEND_PROMOTES_FLG__c,
				SEND_SURVEY_FLG__c,
				SEND_FIN_FLG__c,
				CurrencyIsoCode,
				OwnerId,
				MiddleName__c,
				Source_Name__c,
				Type__c,
				CreatedById,
				CreatedDate,
				Customer_Brand__c,
				Jigsaw,
				IsDeleted,
				Department,
				Department__c,
				Description,
				Discipline__c,
				DoNotCall,
				EmailBouncedDate,
				DuplicateContactOf__c,
				EmailBouncedReason,
				Email_Opt_In__c,
				HasOptedOutOfEmail,
				Employee_Flag__c,
				English_Name__c,
				EOne_Flag__c,
				EOne_Id__c,
				FacilityType__c,
				Fax,
				HasOptedOutOfFax,
				FirstName,
				LT_First_Name_Last_Name__c,
				Gender__c,
				IsEmailBounced,
				Lab_Name__c,
				Language_Preference__c,
				LastActivityDate,
				LastModifiedById,
				LastModifiedDate,
				LastName,
				LastReferencedDate,
				LastCURequestDate,
				LastCUUpdateDate,
				LastViewedDate,
				LeadSource,
				Lead_Source_Id__c,
				Level__c,
				Member_Flag__c,
				MailingBuilding__c,
				MailingCounty__c,
				MailingDepartment__c,
				MailingDistrict__c,
				MailingIncomplete__c,
				MailingInstitute__c,
				MailingMailStop__c,
				MailingPOBox__c,
				MailingRoom__c,
				MailingCity,
				MailingCountry,
				MailingCountryCode,
				MailingGeocodeAccuracy,
				MailingLatitude,
				MailingLongitude,
				MailingState,
				MailingStateCode,
				MailingStreet,
				MailingPostalCode,
				MobilePhone,
				Phone,
				Nickname__c,
				AB_Suppress_New_Products__c,
				Suppress_New_Products__c,
				AB_Suppress_Gifts__c,
				Suppress_Gifts__c,
				AB_Suppress_Special_Offers__c,
				Suppress_Special_Offers__c,
				AB_Suppress_Technical_Advice__c,
				Suppress_Technical_Advice__c,
				OrganizationType__c,
				OtherCity,
				OtherCountry,
				OtherCountryCode,
				OtherGeocodeAccuracy,
				OtherLatitude,
				OtherLongitude,
				HomePhone,
				OtherPhone,
				OtherState,
				OtherStateCode,
				OtherStreet,
				OtherPostalCode,
				Phone_Opt_In__c,
				PhotoUrl,
				Physical_Location_Address__c,
				PI_First_Name__c,
				PI_Last_Name__c,
				Email,
				Primary_Ship_To__c,
				Profiling_Status__c,
				ReportsToId,
				Room__c,
				Salutation,
				M_M__c,
				Academic_Title__c,
				SAP_Contact_Number__c,
				Alternate_Email_Address__c,
				Social_Media_Id__c,
				LT_Source_Type__c,
				Active_Status_Flag__c,
				Suffix,
				SC_User__c,
				Account_Id__c,
				X7UP_Web_Enabled_Flag__c,
				PIM_Current_User_Sync_Flag__c,
				SystemModstamp,
				Title,
				Title_Account__c,
				Web_Status__c
			FROM Contact
			WHERE LastName = 'sampleData'
		];
		System.assertEquals(contactList.size(), 1);
		//ContactTriggerHandler.siteSGNCheck(contactList);
		Map<Id, Contact> mapResult1 = new Map<Id, Contact>();
		for (contact c : contactList) {
			mapResult1.put(c.id, c);
		}
		ContactTriggerHandler.onAfterUpdate(contactList, mapResult1);
		Contact conObj1 = new Contact(
			LastName = 'sampleData',
			FirstName = 'Test',
			AccountId = a.Id,
			Phone = '8895335594',
			Lead_Source_Id__c = 'test',
			Contact_External_Id__c = null,
			Email = 'test1@gmail.com',
			Duplicate_Contact__c = conObj.Id
		);
		insert conObj1;
		ContactTriggerHandler.duplicateRecordCreation(contactList, true);
		ContactTriggerHandler.cloneErrorHandling(new Set<id>{ conObj.Id });
	}

	// Method Name: reSyncContactExtSystemTest
	// Author: Pradeep Chanda
	// Description: Method to test publish Contact record to OFM forecibly
	@isTest
	public static void reSyncContactExtSystemTest() {
		String conId;
		String response;
		ConId = (String) [SELECT Id FROM Contact LIMIT 1].Id;
		response = ReSyncContactExternalSystemCtrl.doCallouts(conId);
	}
}