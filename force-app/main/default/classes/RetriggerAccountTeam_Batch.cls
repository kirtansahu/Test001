// ===========================================================================
//  Object: RetriggerAccountTeam_Batch
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Batch Class to retrigger Account Team Cascading logic for Inactive Users
// ===========================================================================
// Changes Impact: UserTriggerHandler, AccountTeamTriggerHandler
// ===========================================================================

global with sharing class RetriggerAccountTeam_Batch implements Database.Batchable<sObject> {
	//Newly Activate UserIds
	Set<Id> userIds = new Set<Id>();

	//Constructor Initialization
	global RetriggerAccountTeam_Batch(Set<Id> newUserIds) {
		userIds = newUserIds;
	}

	//Constructor Initialization
	global RetriggerAccountTeam_Batch() {
		userIds = null;
	}

	// Method Name: start
	// Author: Abinash panigrahi
	// Description: Method to fetch all Account Team records assosiated with Inactive users
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Define the Scope of Batch records to do processing.
		String query = 'SELECT Id, IsUserActive__c, UserId__r.isActive FROM Account_Team__c ';
		if (userIds != null && userIds.size() > 0) {
			query += ' WHERE UserId__c IN: userIds';
		} else {
			query += ' WHERE ReTrigger__c = TRUE';
		}
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash panigrahi
	// Description:	Addition of Account Team Members in Account Hierarchy -- Cascading
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Account records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<Account_Team__c> records) {
		//Put IsUserActive__c checkbox as marked
		for (Account_Team__c at : records) {
			at.ReTrigger__c = false;
			if (at.UserId__r.isActive) {
				at.IsUserActive__c = true;
			} else {
				at.IsUserActive__c = false;
			}
		}

		//Update Account Team records
		if (records.size() > 0) {
			AccountTeamTriggerHandler.isReTriggerBatch = true;
			update records;
		}
		if (AccountTeamTriggerHandler.exceptionObForBatch != null) {
			throw AccountTeamTriggerHandler.exceptionObForBatch;
		}
	}

	// Method Name: finish
	// Author: Abinash panigrahi
	// Description: After Update Logic
	global void finish(Database.BatchableContext BC) {
	}
}