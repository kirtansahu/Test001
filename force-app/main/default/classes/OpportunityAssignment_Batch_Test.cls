// ===========================================================================
//  Object  :  OpportunityAssignment_Batch_Test
//  Company  : Keste @IDC
//  Author  :  Abinash Panigrahi
//  Purpose  : Test Class to get coverage for OpportunityAssignment_Batch
// ===========================================================================

@isTest(SeeAllData=true)
public class OpportunityAssignment_Batch_Test {
	@isTest
	public static void unitTest() {
		Test.startTest();

		// Fetch Account & Contact
		Id accId = [SELECT Id FROM Account WHERE ERP_Account_Id__c = '68782439' LIMIT 1].Id;
		Id conId = [SELECT Id FROM Contact WHERE AccountId = :accId AND Active_Status_Flag__c = 'Active' LIMIT 1].Id;
		Id pctId = [SELECT Id FROM Product_Line__c WHERE Name = '1TU' LIMIT 1].Id;

		// Create Opportunity
		Opportunity testRec = new Opportunity();
		testRec.Name = 'Test Opportunity';
		testRec.AccountId = accId;
		testRec.Primary_Contact__c = conId;
		testRec.Opportunity_Source__c = 'Marketing';
		testRec.Channel__c = 'TSS A';
		testRec.StageName = 'New';
		testRec.CloseDate = System.today();
		insert testRec;

		// Create Line Item
		Opportunity_Product_Line__c testRec2 = new Opportunity_Product_Line__c();
		testRec2.Opportunity__c = testRec.Id;
		testRec2.Product_Line__c = pctId;
		insert testRec2;

		// Run Batch
		Database.executeBatch(new OpportunityAssignment_Batch(), 1);

		Test.stopTest();
	}

	@isTest
	public static void unitTest2() {
		Test.startTest();

		// Fetch Account & Contact
		Id accId = [SELECT Id FROM Account WHERE RecordType.Name = 'Global SGN' AND Region__c != NULL LIMIT 1].Id;
		Id conId = [SELECT Id FROM Contact WHERE Active_Status_Flag__c = 'Active' LIMIT 1].Id;
		Id pctId = [SELECT Id FROM Product_Line__c WHERE Name = '1TU' LIMIT 1].Id;

		// Create Opportunity
		Opportunity testRec = new Opportunity();
		testRec.Name = 'Test Opportunity';
		testRec.AccountId = accId;
		testRec.Primary_Contact__c = conId;
		testRec.Opportunity_Source__c = 'Marketing';
		testRec.Channel__c = 'TSS A';
		testRec.StageName = 'New';
		testRec.CloseDate = System.today();
		insert testRec;

		// Create Line Item
		Opportunity_Product_Line__c testRec2 = new Opportunity_Product_Line__c();
		testRec2.Opportunity__c = testRec.Id;
		testRec2.Product_Line__c = pctId;
		insert testRec2;

		// Run Batch
		Database.executeBatch(new OpportunityAssignment_Batch(), 1);

		Test.stopTest();
	}

	@isTest
	public static void unitTest3() {
		Test.startTest();

		// Fetch Account & Contact
		Id accId = [SELECT Id FROM Account WHERE ERP_Account_Id__c = '68782439' LIMIT 1].Id;
		Id conId = [SELECT Id FROM Contact WHERE AccountId = :accId AND Active_Status_Flag__c = 'Active' LIMIT 1].Id;
		Id pctId = [SELECT Id FROM Product_Line__c WHERE Name = 'Cell Culture Media & Reagents' LIMIT 1].Id;

		// Create Opportunity
		Opportunity testRec = new Opportunity();
		testRec.Name = 'Test Opportunity';
		testRec.AccountId = accId;
		testRec.Primary_Contact__c = conId;
		testRec.Opportunity_Source__c = 'Marketing';
		testRec.Channel__c = 'TSS A';
		testRec.StageName = 'New';
		testRec.CloseDate = System.today();
		insert testRec;

		// Create Line Item
		Opportunity_Product_Line__c testRec2 = new Opportunity_Product_Line__c();
		testRec2.Opportunity__c = testRec.Id;
		testRec2.Product_Line__c = pctId;
		insert testRec2;

		// Run Batch
		Database.executeBatch(new OpportunityAssignment_Batch(), 1);

		Test.stopTest();
	}

	@isTest
	public static void unitTest4() {
		Test.startTest();

		// Error Run
		List<Opportunity> testRec = new List<Opportunity>();
		try {
			// Scramble Data
			testRec.add(new Opportunity(Name = 'Test Opportunity'));
			insert testRec;
		} catch (DMLException err) {
			try {
				// Run Exception Message
				OpportunityAssignment_Batch obje = new OpportunityAssignment_Batch();
				obje.createExceptionLogs(testRec, 'Test', err);
			} catch (Exception ex) {
			}
		}

		Test.stopTest();
	}
}