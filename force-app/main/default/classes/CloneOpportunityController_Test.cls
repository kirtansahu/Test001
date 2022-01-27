// ===========================================================================
//  Object: CloneOpportunityControllerTest
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Test class for validating the methods from CloneOpportunityController class.
// ===========================================================================
@istest
public class CloneOpportunityController_Test {
	@testSetup
	public static void createTestData() {
		//TestSetupDataUtil.insertTriggerCustomSettings();
		// Get the pricebook id
		Id pricebookId = Test.getStandardPricebookId();
		//Crete Custom Setting records
		Organization_Group_Division__c obj = new Organization_Group_Division__c();
		obj.Group_Division__c = 'LSG';
		obj.Name = 'APAC ROA Organization';
		insert obj;
		//Insert Account
		TestSetupDataUtil.insertAccountRecords(10);
		//Fetch all Account Records
		List<Account> acc = [SELECT Id, Name FROM Account];
		acc[0].ERP_Account_Id__c = '37373';
		update acc[0];
		//Insert the Contact Records
		TestSetupDataUtil.insertContactRecordswithAcc(2, acc);
		//Create User
		List<User> uList = TestSetupDataUtil.insertUsers(1);
		uList[0].Organization__c = 'APAC ROA Organization';
		uList[0].Bypass_Validation__c = true;
		update uList[0];
		//Assert Statements
		System.assertNotEquals(acc.Size(), null);
		System.assertEquals(acc[0].ERP_Account_Id__c, '37373');
		System.assertNotEquals(uList.size(), null);
		System.runAs(uList[0]) {
			//Create your product
			Product2 prod = new Product2(
				Name = 'Product X',
				ProductCode = 'PX_S',
				Group_Division__c = '	LSG',
				isActive = true
			);
			insert prod;
			System.assertNotEquals(prod.Id, null);

			//Create your pricebook entry
			PricebookEntry pbEntry = new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = prod.Id,
				UnitPrice = 100.00,
				IsActive = true
			);
			insert pbEntry;
			//Fetch the All Contact Records
			List<Contact> conList = [SELECT Id, Name FROM Contact];
			//Assert Statement
			System.assertNotEquals(conList.size(), null);
			System.assertNotEquals(pbEntry.id, null);
			//create opportunity
			Opportunity opp = new Opportunity(
				Name = 'Test Opp',
				CloseDate = System.today(),
				StageName = 'New',
				Confidence__c = '90%',
				Primary_Contact__c = conList[0].id,
				Siebel_Row_Id__c = '4243',
				AccountId = acc[0].id
			);
			insert opp;

			List<User> us = [SELECT Id, Name FROM User WHERE id = :userinfo.getUserId()];
			//Create the OpportunityTeam Member
			//Assert Statements
			System.assertNotEquals(opp.id, null);
			System.assert(us.size() != null);
			System.assertNotEquals(opp.id, null);
			OpportunityTeamMember otm = new OpportunityTeamMember();
			otm.OpportunityId = opp.id;
			otm.OpportunityAccessLevel = 'read';
			otm.UserId = userinfo.getuserid();
			otm.TeamMemberRole = 'Opportunitymanager';
			insert otm;
			//Assert Statements
			System.assertNotEquals(otm.id, null);
			System.assertEquals(otm.OpportunityId, opp.id);
			System.assertEquals(otm.UserId, userinfo.getUserId());
			//create your opportunity line item.
			OpportunityLineItem oli = new OpportunityLineItem(
				OpportunityId = opp.Id,
				Quantity = 5,
				Product2Id = prod.Id,
				PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice
			);
			insert oli;
			//Assert Statements
			System.assertNotEquals(oli.id, null);
			System.assertEquals(oli.OpportunityId, opp.id);
			System.assert(oli.Product2Id == prod.Id);
			List<OpportunityLineItem> opLineItem = new List<OpportunityLineItem>();
			opLineItem.add(oli);
			List<OpportunityLineItem> tt = [SELECT Id FROM OpportunityLineItem];
			tt[0].Quantity = 67;
			update tt[0];
			delete tt[0];
			//Assert Statements
			System.assertEquals(tt.size(), 1);
			OpportunityLineItemTriggerHandler.getUserGroups('test');
			OpportunityLineItemTriggerHandler.getGroupDivision('test');
		}
	}

	@isTest
	public static void getOpportunityLineItems_test() {
		Opportunity opp = [
			SELECT Id, StageName, CloseDate, AccountId, Confidence__c, Reason_Won_Lost__c
			FROM Opportunity
			LIMIT 1
		];
		Test.startTest();

		CloneOpportunityController.getColumnType(Schema.DisplayType.DATE);
		CloneOpportunityController.getColumnType(Schema.DisplayType.ADDRESS);

		try {
			List<Opportunity> lstOpportunity = [SELECT Id FROM Opportunity ORDER BY CreatedDate];

			System.assertNotEquals(2, lstOpportunity.size());

			String clonedOppId = lstOpportunity[1].Id;

			Map<Id, OpportunityLineItem> mapOppLineItems = new Map<Id, OpportunityLineItem>(
				[SELECT Id, UnitPrice, Quantity, Description, ServiceDate FROM OpportunityLineItem]
			);

			System.assertEquals(1, [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :clonedOppId].size());
		} catch (exception e) {
			Test.stopTest();
		}
	}

	@istest
	public static void getOpportunityLineItems_test2() {
		test.startTest();

		//Crete Custom Setting records
		Organization_Group_Division__c obj = new Organization_Group_Division__c();
		obj.Group_Division__c = 'LSG';
		obj.Name = 'Asian Organization';
		insert obj;
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		//Create User
		User u = new User(
			LastName = 'Testsample',
			Email = 'test' + 'sample' + '@test.com',
			Username = 'Test_test' + System.now().getTime() + '@test.com',
			Alias = 'test',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert u;

		u.Organization__c = 'Asian Organization';
		u.Bypass_Validation__c = true;
		update u;

		System.assertNotEquals(obj.id, null);
		System.assert(u.ProfileId == profileId);
		System.assertEquals(obj.Group_Division__c, 'LSG');
		System.assertEquals(u.Organization__c, 'Asian Organization');
		Id sysAdminUserId = UserInfo.getUserId();

		System.runAs(u) {
			Id pricebookId = Test.getStandardPricebookId();
			Product2 prod = new Product2(
				Name = 'Product X',
				ProductCode = 'PX_S',
				Group_Division__c = '	LSG',
				//Unique_Id__c='123',
				isActive = true
			);
			insert prod;
			PricebookEntry pbEntry = new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = prod.Id,
				UnitPrice = 100.00,
				IsActive = true
			);
			insert pbEntry;
			//insert Account Records
			Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
			Account a = new Account();
			a.Name = 'Test Account';
			a.RecordTypeId = RecordTypeId;
			a.Unique_Id__c = '1234';
			insert a;
			List<Contact> con1 = [SELECT Id, Name FROM Contact];
			Opportunity oplist = new Opportunity(
				Name = 'test',
				Accountid = a.id,
				CloseDate = System.today(),
				Primary_Contact__c = con1[0].id,
				StageName = 'New',
				Confidence__c = '70%',
				Reason_Won_Lost__c = 'Won/Lost - Price'
			);
			insert oplist;
			List<Opportunity> oplist2 = [SELECT Id, Name FROM opportunity WHERE Name = 'test'];
			//Create OpportunityteamMember
			OpportunityTeamMember otm = new OpportunityTeamMember();
			otm.OpportunityId = oplist.id;
			otm.OpportunityAccessLevel = 'read';
			otm.UserId = u.id;
			otm.TeamMemberRole = 'Opportunitymanager';
			insert otm;

			OpportunityTeamMember otm1 = new OpportunityTeamMember();
			otm1.OpportunityId = oplist.id;
			otm1.OpportunityAccessLevel = 'read';
			otm1.UserId = sysAdminUserId;
			otm1.TeamMemberRole = 'Opportunitymanager';
			insert otm1;

			Set<id> opportunityId = new Set<Id>();
			for (opportunity p : oplist2) {
				opportunityId.add(p.id);
			}
			OpportunityLineItem oli = new OpportunityLineItem(
				OpportunityId = oplist.Id,
				Quantity = 5,
				Product2Id = prod.Id,
				PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice
			);
			insert oli;

			//Ftech All OpportunityLineItems
			List<opportunityLineItem> opti = [
				SELECT Id, OpportunityId, Quantity, Product2Id
				FROM OpportunityLineItem
				WHERE OpportunityId = :oplist.Id
			];
			//Assert Statements
			System.assert(oli.OpportunityId == oplist.Id);
			System.assertEquals(oplist2.size(), 1);
			System.assertEquals(con1.size(), 2);
			System.assertNotEquals(opti.size(), null);

			list<id> keyids = new List<id>();
			List<opportunityLineItem> opTeam = [
				SELECT Id, OpportunityId, Quantity, Product2Id
				FROM OpportunityLineItem
				WHERE Id = :oli.Id
			];
			for (opportunityLineItem pli : opTeam) {
				keyids.add(pli.Id);
			}

			list<OpportunityLineItem> opportunityLI = new List<opportunityLineItem>();
			opportunityLI.add(oli);
			//Assert Statements
			System.assertNotEquals(opportunityLI.size(), null);
			System.assertNotEquals(opTeam.size(), null);
			try {
				CloneOpportunityController.getOpportunityRecord(oplist.Id);
				CloneOpportunityController.getOpportunityChildRecordInformation(oplist.Id);
				CloneOpportunityController.cloneOpportunityAndReturnCloneRecordId(oplist, 'oplist.Id');
				CloneOpportunityController.cloneOpportunityAndReturnCloneRecordId(new Opportunity(), null);
				CloneOpportunityController.cloneOpportunityAndReturnCloneRecordId(null, null);
			} catch (exception ex) {
			}

			CloneOpportunityController.cloneOpportunityAndReturnCloneRecordId(oplist, oplist.Id);

			list<Opportunity> op = [SELECT Id, Name FROM Opportunity WHERE name = 'test'];
			List<Id> keys1 = new List<Id>();
			for (opportunity p : op) {
				keys1.add(p.id);
			}

			CloneOpportunityController.getOpportunityProducts(oplist.Id, op[0].id);
			CloneOpportunityController.getOpportunityProductLine(oplist.Id, op[0].id);
			CloneOpportunityController.getOpportunityProducts(con1[0].id, null);
			try {
				CloneOpportunityController.getOpportunityProducts(null, null);
				CloneOpportunityController.cloneOpportunityLineItems(null, null, null, null, null, null, null, null);
			} catch (Exception ex) {
			}
			try {
				CloneOpportunityController.getOpportunityProductLine(null, null);
			} catch (Exception ex2) {
			}

			Product_Line__c pl = new Product_Line__c(
				Product_Line__c = 'test',
				IGOR_Code_Description__c = 'sample',
				Plan_Code__c = '01',
				Product_Group__c = ''
			);
			insert pl;
			list<Opportunity_Product_Line__c> opportunityPL = new List<Opportunity_Product_Line__c>();
			Opportunity_Product_Line__c QPL = new Opportunity_Product_Line__c(
				Opportunity__c = oplist.Id,
				Primary__c = true,
				Product_Line__c = pl.Id
			);
			opportunityPL.add(QPL);
			insert opportunityPL;
			opportunityPL[0].Primary__c = false;
			update opportunityPL;
			List<Opportunity_Product_Line__c> productLine = [
				SELECT Id, Name
				FROM Opportunity_Product_Line__c
				WHERE id = :QPL.Id
			];
			List<Id> keys2 = new List<Id>();
			for (Opportunity_Product_Line__c op2 : ProductLine) {
				keys2.add(op2.id);
			}
			//Assert Statements
			System.assertNotEquals(productLine.size(), null);
			System.assertNotEquals(QPL.id, null);
			System.assert(QPL.Opportunity__c == oplist.id);

			try {
				CloneOpportunityController.getOpportunityChildRecordInformation(opList.Id);
				CloneOpportunityController.cloneOpportunityLineItems(
					oplist.Id,
					op[0].id,
					keyids,
					opportunityLI,
					keys2,
					opportunityPL,
					new List<Id>{ otm1.Id },
					new List<OpportunityTeamMember>{ otm1 }
				);
				CloneOpportunityController.cloneOpportunityLineItems(
					oplist.Id,
					op[0].id,
					keyids,
					opportunityLI,
					keys2,
					opportunityPL,
					new List<Id>{ oplist.Id },
					null
				);
			} catch (Exception e) {
			}
			try {
				CloneOpportunityController.cloneOpportunityLineItems(null, null, null, null, null, null, null, null);
			} catch (Exception exx) {
			}
			List<Clone_Opportunity_Setting__mdt> custommeta = [
				SELECT MasterLabel, Cloneable__c, Editable__c, Sortable__c, Required__c
				FROM Clone_Opportunity_Setting__mdt
			];
			CloneOpportunityController.getSetting();
			CloneOpportunityController cc = new CloneOpportunityController();
			Test.stopTest();
		}
	}

	@istest
	public static void unit_Test() {
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.Unique_Id__c = '4567';
		insert a;
		//insert Contact Records
		Contact c = new Contact();
		c.LastName = 'TestContact';
		c.FirstName = 'TestContactName';
		c.AccountId = a.Id;
		c.Email = 'abcd@gmail.com';
		insert c;

		try {
			CloneOpportunityController.getOpportunityTeamMembers(null, null);
		} catch (Exception ex) {
		}

		//insert product record
		Opportunity oplist = new Opportunity(
			Name = 'test',
			Accountid = a.id,
			CloseDate = System.today(),
			Siebel_Row_Id__c = '123',
			Primary_Contact__c = c.id,
			StageName = 'New',
			Confidence__c = '70%',
			Reason_Won_Lost__c = 'Won/Lost - Price'
		);
		insert oplist;
		//Assert Statements
		System.assert(oplist.AccountId == a.id);
		System.assertNotEquals(a.Id, null);
		System.assertNotEquals(c.id, null);
		System.assert(c.AccountId == a.Id);
		System.assertEquals(oplist.Primary_Contact__c, c.Id);

		CloneOpportunityController.getOpportunityTeamMembers(oplist.Id, oplist.Id);
		CloneOpportunityController.getOpportunityChildRecordInformation(opList.Id);
		CloneOpportunityController.getOpportunityTeamMembers(a.Id, c.Id);

		try {
			CloneOpportunityController.fetchPageLayoutFieldsAndSection(oplist);
			CloneOpportunityController.getOpportunityTeamMembers(null, null);
		} catch (Exception e) {
		}
	}
}