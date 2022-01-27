// ===========================================================================
//  Object	: OpportunityTriggerHandler_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for OpportunityTrigger and OpportunityTriggerHandler.
// ===========================================================================
@isTest
public class OpportunityTriggerHandler_Test {
	// Method Name: testSetupMethod
	// Author: Abinash panigrahi
	// Description: Method to create Test Data to be used
	@testSetup
	public static void testSetupMethod() {
		//Insert Account
		List<Account> accNews = TestSetupDataUtil.insertAccountRecords(10);
		//Insert PriceBook
		TestSetupDataUtil.insertPriceBookRecords(1);
		//Insert Contact
		TestSetupDataUtil.insertContactRecordswithAcc(3, accNews);
	}

	// Method Name: testSetupMethod
	// Author: Abinash panigrahi
	// Description: Method to populate currency and pricebook at Opportunity record
	@isTest
	public static void populateCurrencyPricebookTest() {
		//Fetch Account
		Account accObj = [SELECT Id, CurrencyIsoCode FROM Account LIMIT 1];
		List<Contact> cons1 = [SELECT Id, Name FROM Contact];
		//Fetch PriceBook
		PriceBook2 pbObj = [SELECT Id FROM PriceBook2];
		//Update Account
		accObj.CurrencyIsoCode = 'INR';
		accObj.Price_Book__c = pbObj.Id;
		update accObj;
		//Create Opportunity
		Opportunity oppObj = new Opportunity(
			Name = 'Test Opportunity',
			CloseDate = System.today(),
			StageName = 'New',
			Confidence__c = '10%',
			AccountId = accObj.Id,
			Primary_Contact__c = cons1[0].id
		);
		insert oppObj;

		Opportunity oppObj1 = new Opportunity(
			Name = 'Test Opportunity',
			PriceBook2Id = pbObj.Id,
			CloseDate = System.today(),
			StageName = 'New',
			Confidence__c = '10%',
			AccountId = accObj.Id,
			Primary_Contact__c = cons1[0].id
		);
		insert oppObj1;
		//Fetch Opportunity
		oppObj = [SELECT Id, PriceBook2Id, CurrencyIsoCode FROM Opportunity LIMIT 1];

		//Assertion Statements
		System.assertEquals(oppObj.PriceBook2Id, pbObj.Id);
		System.assertEquals(oppObj.CurrencyIsoCode, 'USD');
	}

	// Method Name: populateCampaignTest
	// Author: Abinash panigrahi
	// Description: Method to populate Lead Source for Campaign records
	@isTest
	public static void populateCampaignTest() {
		//Fetch Profile Id
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		//Insert User
		User userRec = new User(
			LastName = 'Test User',
			Email = 'testUser@test.com',
			Username = 'sysint@test.com',
			Alias = 'test123',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert userRec;
		//Fetch Contact
		List<Contact> cons = [SELECT Id, Name FROM Contact];

		//Fetch Account
		Account accObj = [SELECT Id, CurrencyIsoCode FROM Account LIMIT 1];

		//Create Opportunity
		Opportunity oppObj = new Opportunity(
			Name = 'Test Opportunity',
			CloseDate = System.today(),
			StageName = 'New',
			Confidence__c = '10%',
			AccountId = accObj.Id,
			Lead_Source_Id__c = '1002',
			Primary_Contact__c = cons[0].id
		);
		insert oppObj;

		//Fetch campaign
		// Campaign cmpObj = [SELECT Id, StarTrack_Id__c, Name FROM Campaign LIMIT 1];

		//Assertion Statements
		//System.assertNotEquals(oppObj.CampaignId, cmpObj.Id);
		//System.assertNotEquals(oppObj.Lead_Source_Id__c, cmpObj.StarTrack_Id__c);
		//System.assertEquals(oppObj.Lead_Source_Id__c, cmpObj.Name);

		//Create Campaign
		Campaign campObj = new Campaign(Name = 'Test Campaign', StarTrack_Id__c = '1002');
		insert campObj;

		//Fetch campaign
		campObj = [SELECT Id, StarTrack_Id__c, Name FROM Campaign WHERE Name = 'Test Campaign'];
		//Fetch All Opportunity Records
		List<Opportunity> op1 = [SELECT Id, Name, OwnerId FROM Opportunity];
		Map<Id, Opportunity> oplistResult = new Map<id, Opportunity>();
		for (Opportunity o : op1) {
			oplistResult.put(o.id, o);
		}

		//create OpportunityteamMember
		OpportunityTeamMember otm = new OpportunityTeamMember(
			OpportunityId = op1[0].id,
			OpportunityAccessLevel = 'read',
			userId = userinfo.getUserId()
		);
		insert otm;
		//List<Opportunity>oplist3 =new List<Opportunity>();
		System.runAs(userRec) {
			Opportunity oppObj1 = new Opportunity(
				Name = 'Test Opportunity1',
				CloseDate = System.today() + 7,
				StageName = 'New',
				Confidence__c = '10%',
				AccountId = accObj.Id,
				Lead_Source_Id__c = '1002',
				Primary_Contact__c = cons[0].id,
				Status__c = 'Pending',
				Opportunity_Source__c = 'Marketing'
			);
			insert oppObj1;
			oppObj1.Lead_Source_Id__c = '1002';
			update oppObj1;
		}
		// oplist3.add(oppObj1);

		OpportunityTriggerHandler.createUpdateOpportunityTeamMember(op1, oplistResult);

		//Assertion Statements
		System.assertNotEquals(oppObj.CampaignId, campObj.Id);
		System.assertEquals(oppObj.Lead_Source_Id__c, campObj.StarTrack_Id__c);
	}

	@isTest
	public static void testData() {
		BigMachines__Configuration_Record__c site = new BigMachines__Configuration_Record__c();
		site.BigMachines__bm_site__c = 'TEST';
		site.BigMachines__process_id__c = 'TEST';
		site.BigMachines__action_id_copy__c = 'TEST';
		site.BigMachines__action_id_open__c = 'TEST';
		site.BigMachines__document_id__c = 'TEST';
		site.BigMachines__version_id__c = 'TEST';
		site.BigMachines__process__c = 'TEST';
		site.BigMachines__Is_Active__c = true;
		site.BigMachines__Primary_Commerce_Process__c = true;
		insert site;

		Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Site SGN')
			.getRecordTypeId();
		Account a = new Account(name = 'test', recordtypeid = RecordTypeIdContact);
		a.Parent_Unique_Id__c = math.random() + '12345';
		a.Unique_Id__c = 'SAP_SHIPTO_2387324';
		a.Primary_Bill_To_Unique_Id__c = math.random() + '43215';
		a.ERP_Account_Id__c = '99876564';
		a.Child_Unique_Id__c = math.random() + '21232';
		insert a;
		List<Contact> conlist = [SELECT Id, Name FROM Contact];
		//Assert Statements
		System.assertEquals(conlist.Size(), 3);
		System.assertNotEquals(a.Id, null);

		List<Opportunity> newlist = new List<Opportunity>();
		Opportunity oplist = new Opportunity();
		oplist.OwnerId = userInfo.getUserId();
		oplist.Name = 'test';
		oplist.AccountId = a.id;
		oplist.StageName = 'new';
		oplist.CurrencyIsoCode = 'USD';
		oplist.CloseDate = System.today();
		oplist.Demo_Onsite__c = false;
		oplist.Siebel_Row_Id__c = 'test';
		oplist.Lead_Source_ID__c = '1';
		oplist.Lead_Source_Name__c = '2';
		oplist.Primary_Contact__c = conlist[0].id;
		oplist.Quote_Revenue__c = 100;
		newlist.add(oplist);
		insert newlist;

		Campaign camp1 = new Campaign(Name = 'Test Campaign 1', IsActive = true, Siebel_Row_Id__c = '2');
		insert camp1;

		list<Opportunity> oplist1 = [
			SELECT
				Id,
				Name,
				Direct_Indirect__c,
				DM_Forecast__c,
				End_Customer_Account__c,
				Consignment_Flag__c,
				Lost_Order_Detail__c,
				Opportunity_Source__c,
				AccountId,
				FOB__c,
				Rev_Rec_At_Risk__c,
				Rep_Estimated_Amount__c,
				Type,
				End_Customer_Contact__c,
				Siebel_Row_Id__c,
				Demo_Onsite__c,
				Reason_Won_Lost__c,
				OwnerId,
				Description,
				Primary_Contact__c,
				Primary_Revenue_Committed_Flag__c,
				Amount,
				Rejection_Reason__c,
				CloseDate,
				StageName,
				Confidence__c,
				Status__c,
				Primary_Revenue_Committed_Flag_c__c,
				CreatedById,
				CurrencyIsoCode,
				Currency_Exchange_Date__c,
				CampaignId,
				Recurring_Order__c
			FROM Opportunity
			WHERE Id IN :newlist
		];
		BigMachines__Quote__c q = new BigMachines__Quote__c();
		q.BigMachines__Account__c = oplist1[0].AccountId;
		q.BigMachines__Opportunity__c = oplist1[0].Id;
		q.BigMachines__Site__c = site.Id;
		q.Quote_Revenue__c = 100;
		insert q;

		Map<Id, Opportunity> mapResult = new Map<id, Opportunity>();
		for (Opportunity op : oplist1) {
			mapResult.put(op.id, op);
		}
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'Analyst - Global'].Id;
		User u1 = new User(
			LastName = 'Test 1',
			Email = 'test1@test.com',
			Username = 'Test_test' + System.now().getTime() + '@test.com',
			Alias = 'test1',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			IsActive = true,
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert u1;

		oplist1[0].FOB__c = 'test23';
		oplist1[0].OwnerId = u1.Id;
		oplist1[0].Primary_Contact__c = conlist[1].Id;
		update oplist1;
		oplist1[0].Primary_Contact__c = conlist[0].Id;
		update oplist1;

		System.runAs(u1) {
			OpportunityContactRole primary = new OpportunityContactRole();

			for (OpportunityContactRole oppContactRole : [
				SELECT Id, IsPrimary
				FROM OpportunityContactRole
				WHERE IsPrimary = TRUE AND OpportunityId = :oplist1[0].Id
				LIMIT 1
			]) {
				primary = oppContactRole;
			}

			try {
				primary.IsPrimary = false;
				update primary;
			} catch (Exception ex) {
			}

			try {
				delete primary;
			} catch (Exception ex) {
			}

			OpportunityContactRole nonprimary = new OpportunityContactRole();

			for (OpportunityContactRole oppContactRole : [
				SELECT Id, IsPrimary
				FROM OpportunityContactRole
				WHERE IsPrimary = FALSE AND OpportunityId = :oplist1[0].Id
				LIMIT 1
			]) {
				nonprimary = oppContactRole;
			}

			try {
				nonprimary.IsPrimary = true;
				update nonprimary;
			} catch (Exception ex) {
			}
			try {
				delete q;
			} catch (Exception ex) {
			}
			//Assert Statements
			System.assertNotEquals(oplist.Id, null);
			OpportunityTriggerHandler.syncOpportunityWithSiebel(opList1, mapResult);
		}
	}

	@isTest
	static void testDataForSystemIntegrationUser() {
		Id systemIntegrationProfileId = [SELECT ID FROM Profile WHERE Name = 'Integration User'].Id;
		User systemIntegrationUser = new User(
			FirstName = 'System',
			LastName = 'Integration',
			Email = 'test1@test.com',
			Username = 'Test_test' + System.now().getTime() + '@test.com',
			Alias = 'test1',
			ProfileId = systemIntegrationProfileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			IsActive = true,
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert systemIntegrationUser;
		System.runAs(systemIntegrationUser) {
			BigMachines__Configuration_Record__c site = new BigMachines__Configuration_Record__c();
			site.BigMachines__bm_site__c = 'TEST';
			site.BigMachines__process_id__c = 'TEST';
			site.BigMachines__action_id_copy__c = 'TEST';
			site.BigMachines__action_id_open__c = 'TEST';
			site.BigMachines__document_id__c = 'TEST';
			site.BigMachines__version_id__c = 'TEST';
			site.BigMachines__process__c = 'TEST';
			site.BigMachines__Is_Active__c = true;
			site.BigMachines__Primary_Commerce_Process__c = true;
			insert site;

			Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get('Site SGN')
				.getRecordTypeId();
			Account a = new Account(name = 'test', recordtypeid = RecordTypeIdContact);
			a.Parent_Unique_Id__c = math.random() + '12345';
			a.Unique_Id__c = 'SAP_SHIPTO_2387324';
			a.Primary_Bill_To_Unique_Id__c = math.random() + '43215';
			a.ERP_Account_Id__c = '99876564';
			a.Child_Unique_Id__c = math.random() + '21232';
			insert a;
			List<Contact> conlist = [SELECT Id, Name FROM Contact];
			//Assert Statements
			System.assertEquals(conlist.Size(), 3);
			System.assertNotEquals(a.Id, null);

			List<Opportunity> newlist = new List<Opportunity>();
			Opportunity oplist = new Opportunity();
			oplist.OwnerId = userInfo.getUserId();
			oplist.Name = 'test';
			oplist.AccountId = a.id;
			oplist.StageName = 'new';
			oplist.CurrencyIsoCode = 'USD';
			oplist.CloseDate = System.today();
			oplist.Demo_Onsite__c = false;
			oplist.Opportunity_Source__c = 'Sales Created';
			oplist.Siebel_Row_Id__c = 'test';
			oplist.Lead_Source_ID__c = '1';
			oplist.Primary_Contact__c = conlist[0].id;
			oplist.Quote_Revenue__c = 100;
			newlist.add(oplist);
			insert newlist;

			Campaign camp1 = new Campaign(Name = 'Test Campaign 1', IsActive = true, Siebel_Row_Id__c = '1');
			insert camp1;

			list<Opportunity> oplist1 = [
				SELECT
					Id,
					Name,
					Direct_Indirect__c,
					DM_Forecast__c,
					End_Customer_Account__c,
					Consignment_Flag__c,
					Lost_Order_Detail__c,
					Opportunity_Source__c,
					AccountId,
					FOB__c,
					Rev_Rec_At_Risk__c,
					Rep_Estimated_Amount__c,
					Type,
					End_Customer_Contact__c,
					Siebel_Row_Id__c,
					Demo_Onsite__c,
					Reason_Won_Lost__c,
					OwnerId,
					Description,
					Primary_Contact__c,
					Primary_Revenue_Committed_Flag__c,
					Amount,
					Rejection_Reason__c,
					CloseDate,
					StageName,
					Confidence__c,
					Status__c,
					Primary_Revenue_Committed_Flag_c__c,
					CreatedById,
					CurrencyIsoCode,
					Currency_Exchange_Date__c,
					CampaignId,
					Recurring_Order__c
				FROM Opportunity
				WHERE Id IN :newlist
			];
			BigMachines__Quote__c q = new BigMachines__Quote__c();
			q.BigMachines__Account__c = oplist1[0].AccountId;
			q.BigMachines__Opportunity__c = oplist1[0].Id;
			q.BigMachines__Site__c = site.Id;
			q.Quote_Revenue__c = 100;
			insert q;

			Map<Id, Opportunity> mapResult = new Map<id, Opportunity>();
			for (Opportunity op : oplist1) {
				mapResult.put(op.id, op);
			}

			oplist1[0].FOB__c = 'test23';
			//oplist1[0].OwnerId =u1.Id;
			oplist1[0].Primary_Contact__c = conlist[1].Id;
			update oplist1;
			oplist1[0].Primary_Contact__c = conlist[0].Id;
			update oplist1;

			OpportunityContactRole primary = new OpportunityContactRole();

			for (OpportunityContactRole oppContactRole : [
				SELECT Id, IsPrimary
				FROM OpportunityContactRole
				WHERE IsPrimary = TRUE AND OpportunityId = :oplist1[0].Id
				LIMIT 1
			]) {
				primary = oppContactRole;
			}

			try {
				primary.IsPrimary = false;
				update primary;
			} catch (Exception ex) {
			}

			try {
				delete primary;
			} catch (Exception ex) {
			}

			OpportunityContactRole nonprimary = new OpportunityContactRole();

			for (OpportunityContactRole oppContactRole : [
				SELECT Id, IsPrimary
				FROM OpportunityContactRole
				WHERE IsPrimary = FALSE AND OpportunityId = :oplist1[0].Id
				LIMIT 1
			]) {
				nonprimary = oppContactRole;
			}

			try {
				nonprimary.IsPrimary = true;
				update nonprimary;
			} catch (Exception ex) {
			}
			try {
				delete q;
			} catch (Exception ex) {
			}
			//Assert Statements
			System.assertNotEquals(oplist.Id, null);

			OpportunityTriggerHandler.syncOpportunityWithSiebel(opList1, mapResult);
		}
	}
}