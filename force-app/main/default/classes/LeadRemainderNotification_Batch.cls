// ===========================================================================
//  Object	: LeadRemainderNotification_Batch
// 	Company	: Keste @ IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Batch Class to send Email/Chatter Notification to Lead Owner if
// 	Status is not Changed from New to In Progress for more than XX days
// ===========================================================================

global class LeadRemainderNotification_Batch implements Database.Batchable<sObject> {
	public static String LEAD_STATUS_NEW = 'New';
	public static String USER_PREFIX = '005';

	// Method Name: start
	// Author: Adarsh Sharma
	// Description: Method to fetch all Lead records not modified from past XX days
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext bc) {
		//Define the Scope of Batch records to do processing.
		date today = system.today();
		String query = 'SELECT Id, OwnerId, IsNewLeadReminder__c, Status_Capture_Change__c FROM Lead';
		query += '  WHERE Status =: LEAD_STATUS_NEW AND Status_Capture_Change__c =: today';
		query += ' AND IsNewLeadReminder__c = false';
		query += ' ORDER BY Status_Capture_Change__c asc';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Adarsh Sharma
	// Description: Send Email Notification to Lead Owner if Lead is not followed up
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Lead records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext bc, List<Lead> scope) {
		List<Lead> lstLeadToUpdate = new List<Lead>();

		for (Lead oLead : scope) {
			if (String.valueOf(oLead.OwnerId).startsWith(USER_PREFIX)) {
				oLead.IsNewLeadReminder__c = true;
				oLead.Status_Capture_Change__c = oLead.Status_Capture_Change__c.addDays(1);
				lstLeadToUpdate.add(oLead);
			}
		}

		if (lstLeadToUpdate.size() > 0) {
			update lstLeadToUpdate;
		}
	}

	// Method Name: finish
	// Author: Adarsh Sharma
	// Description: After Update Logic
	global void finish(Database.BatchableContext bc) {
	}
}