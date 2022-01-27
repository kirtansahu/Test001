// ===========================================================================
//  Object	: OpportunityAssignmentBatch_Test
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Unit Test Class for OpportunityTrigger and OpportunityTriggerHandler.
// ===========================================================================
@isTest
public class OpportunityAssignmentBatch_Test {
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
		Test.startTest();
		System.schedule(
			'Opportunity Rule Assignment Batch Job Test New',
			'0 10 0/1 1/1 * ? *',
			new OpportunityAssignmentBatch_Schedulde()
		);
		Test.stopTest();
	}
}