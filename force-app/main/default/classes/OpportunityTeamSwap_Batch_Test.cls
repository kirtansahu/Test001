// ===========================================================================
//  Object  :  OpportunityTeamSwap_Batch_Test
//  Company  : Keste @IDC
//  Author  :  Abinash Panigrahi
//  Purpose  : Test Class to get coverage for OpportunityTeamSwap_Batch
// ===========================================================================

@isTest
public class OpportunityTeamSwap_Batch_Test {
	@isTest
	public static void unitTest() {
		Test.startTest();

		// Insert Base Records
		List<Account> accRecs = TestSetupDataUtil.insertAccountRecords(1);
		List<Contact> conRecs = TestSetupDataUtil.insertContactRecordswithAccount(1, accRecs);
		List<User> usrRecs = TestSetupDataUtil.insertUsers(1);

		// Insert Opportunity
		Opportunity testRec = new Opportunity();
		testRec.Name = 'Test Opportunity';
		testRec.AccountId = accRecs[0].Id;
		testRec.Primary_Contact__c = conRecs[0].Id;
		testRec.Opportunity_Source__c = 'Marketing';
		testRec.Channel__c = 'TSS A';
		testRec.StageName = 'New';
		testRec.CloseDate = System.today();
		insert testRec;

		// Update Position
		OpportunityTeamMember testAsc = [
			SELECT Id, Position__c
			FROM OpportunityTeamMember
			WHERE OpportunityId = :testRec.Id
		];
		testAsc.Position__c = 'Test';
		update testAsc;

		// Run Batch
		OpportunityTeamSwap_Batch obje = new OpportunityTeamSwap_Batch(UserInfo.getUserId(), usrRecs[0].Id, 'Test');
		Database.executeBatch(obje);

		// Error Run
		List<Opportunity> testRecList = new List<Opportunity>();
		try {
			// Scramble Data
			testRecList.add(new Opportunity(Name = 'Test Opportunity'));
			insert testRecList;
		} catch (DMLException err) {
			try {
				// Run Exception Message
				obje.createExceptionLogs(testRecList, 'Test', err);
			} catch (Exception ex) {
			}
		}

		Test.stopTest();
	}
}