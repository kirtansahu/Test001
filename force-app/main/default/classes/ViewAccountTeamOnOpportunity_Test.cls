// ===========================================================================
//	Class Name	: ViewAccountTeamOnOpportunity_Test
//	Company		: Keste @ IDC
//	Author		: Abinash Panigrahi
//	Purpose		: Used as test class for ViewAccountTeamOnOpportunity Controller
// ===========================================================================
@isTest(SeeAllData=true)
public class ViewAccountTeamOnOpportunity_Test {
	@isTest
	public static void unitTest() {
		// Fetch Account & Contact
		Id accId = [SELECT Id FROM Account WHERE ERP_Account_Id__c = '68782439' LIMIT 1].Id;
		Id conId = [SELECT Id FROM Contact WHERE AccountId = :accId AND Active_Status_Flag__c = 'Active' LIMIT 1].Id;

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

		Test.startTest();

		TeamWrapper result = ViewAccountTeamOnOpportunity.viewAccountTeamData(testRec.Id);
		ViewAccountTeamOnOpportunity.defineAccess(testRec.Id);
		ViewAccountTeamOnOpportunity.updateOpportunityTeam(result.lstAccTeam, result.lstOppTeam, testRec.Id);

		Test.stopTest();
	}
}