// ===========================================================================
//	Class	: LeadRemainderNotification_Test
//  Company	: Keste @ IDC
//  Author	: Adarsh SHarma
//  Purpose	: Test Class for LeadRemainderNotification_Batch and LeadRemainderNotification_Schedule
// ===========================================================================
@isTest
public class LeadRemainderNotification_Test {
	@isTest
	public static void testLeadReminderNotification() {
		Lead oLead = new Lead();
		oLead.LastName = 'test lead';
		oLead.Status = 'New';
		oLead.Opportunity_Name__c = 'test Opportunity';
		oLead.Company = 'test company';
		oLead.IsNewLeadReminder__c = false;
		oLead.Lead_Rejection_Reason__c = null;
		insert oLead;

		oLead = [SELECT Id, Status, Status_Capture_Change__c FROM Lead];
		oLead.Status_Capture_Change__c = system.today();
		update oLead;

		Test.startTest();
		System.schedule('Lead Remainder Notification 1', '0 0 0/1 1/1 * ? *', new LeadRemainderNotification_Schedule());
		Test.stopTest();
	}
}