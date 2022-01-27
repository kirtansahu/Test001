// ===========================================================================
//  Object: ModifyStandardAccountTeam_Batch
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Batch Class to change Accesslevel for Standard Account Team records on User reactivation
// ===========================================================================
// Changes Impact: UserTriggerHandler, AccountTeamTriggerHandler
// ===========================================================================

global with sharing class ModifyStandardAccountTeam_Batch implements Database.Batchable<sObject> {
	public static String ACCOUNT_ACCESSLEVEL = Label.ACCOUNTTEAM_ACCOUNT_ACCESSLEVEL;
	public static String CONTACT_ACCESSLEVEL = Label.ACCOUNTTEAM_CONTACT_ACCESSLEVEL;
	public static String OPPORTUNITY_ACCESSLEVEL = Label.ACCOUNTTEAM_OPPORTUNITY_ACCESSLEVEL;
	public static String CASE_ACCESSLEVEL = Label.ACCOUNTTEAM_CASE_ACCESSLEVEL;

	//Newly Activate UserIds
	Set<Id> userIds = new Set<Id>();

	//Constructor Initialization
	global ModifyStandardAccountTeam_Batch(Set<Id> newUserIds) {
		userIds = newUserIds;
	}

	// Method Name: start
	// Author: Abinash panigrahi
	// Description: Method to fetch all Standard Account Team records
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Define the Scope of Batch records to do processing.
		String access = 'Read';
		String query = 'SELECT Id, AccountAccessLevel, ContactAccessLevel FROM AccountTeamMember WHERE UserId IN: userIds AND User.IsActive = TRUE AND AccountAccessLevel =: access';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash panigrahi
	// Description:	Change Accesslevel for Standard Account Team records on User reactivation
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Account records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<AccountTeamMember> records) {
		//Put IsUserActive__c checkbox as marked
		for (AccountTeamMember atm : records) {
			atm.AccountAccessLevel = ACCOUNT_ACCESSLEVEL;
			atm.ContactAccessLevel = CONTACT_ACCESSLEVEL;
			atm.OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL;
			atm.CaseAccessLevel = CASE_ACCESSLEVEL;
		}

		//Exception Handling
		//Update Account Team records
		try {
			if (records.size() > 0) {
				update records;
			}
		} catch (Exception ex) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'ModifyStandardAccountTeam_Batch',
				'execute',
				'Standard Account Team Modify Access Level Batch',
				'Update Standard Account Team',
				ex.getMessage(),
				System.today()
			);
		}
	}

	// Method Name: finish
	// Author: Abinash panigrahi
	// Description: After Update Logic
	global void finish(Database.BatchableContext BC) {
	}
}