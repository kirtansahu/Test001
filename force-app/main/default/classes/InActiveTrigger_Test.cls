// ===========================================================================
//  Object	: InActiveTrigger_Test
// 	Company	: Keste @ IDC
//  Author	: Basant Verma
// 	Purpose	: Test Class to Deploy Inactive Trigger
// ===========================================================================
@isTest
public class InActiveTrigger_Test {
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
		System.assert(oppObj.Id != null);
	}

	@isTest
	public static void testData() {
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
		oplist.Primary_Contact__c = conlist[0].id;
		newlist.add(oplist);
		insert newlist;
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
				Type,
				Rep_Estimated_Amount__c,
				Rev_Rec_At_Risk__c,
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

		Map<Id, Opportunity> mapResult = new Map<id, Opportunity>();
		for (Opportunity op : oplist1) {
			mapResult.put(op.id, op);
		}
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		User u1 = new User(
			LastName = 'Test 1',
			Email = 'test1@test.com',
			Username = 'Test_test_' + System.now().getTime() + '@test.com',
			Alias = 'test1',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			IsActive = false,
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert u1;
		oplist1[0].FOB__c = 'test23';
		oplist1[0].OwnerId = u1.Id;
		update oplist1;

		//Assert Statements
		System.assertNotEquals(oplist.Id, null);
		OpportunityTriggerHandler.syncOpportunityWithSiebel(opList1, mapResult);
	}
}