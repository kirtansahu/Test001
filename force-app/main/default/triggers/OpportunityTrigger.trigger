// ===========================================================================
//  Object  : OpportunityTrigger
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Dispatch Opportunity trigger functionality.
// ===========================================================================
trigger OpportunityTrigger on Opportunity(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	//  Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('OpportunityTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			OpportunityTriggerHandler.populateCurrencyPricebook(Trigger.new, Trigger.oldMap);
			OpportunityTriggerHandler.fiscalPeriodCalculate(Trigger.new, Trigger.oldMap);
			OpportunityTriggerHandler.PendingsladuedateInsert(Trigger.new);
			OpportunityTriggerHandler.Cloneupdate(Trigger.new);
			OpportunityTriggerHandler.populateChannelForSalesCreatedOpps(Trigger.new);
		}

		if (Trigger.isUpdate && Trigger.isBefore) {
			OpportunityTriggerHandler.populateCurrencyPricebook(Trigger.new, Trigger.oldMap);
			OpportunityTriggerHandler.fiscalPeriodCalculate(Trigger.new, Trigger.oldMap);
			OpportunityTriggerHandler.assignmentNotificationTrigger(Trigger.new, Trigger.oldMap);
			OpportunityTriggerHandler.PendingsladuedateUpdate(Trigger.new, Trigger.oldMap);
		}

		if (Trigger.isInsert && Trigger.isAfter) {
			OpportunityTriggerHandler.populateCampaign(Trigger.new, Trigger.oldmap);
			OpportunityTriggerHandler.createUpdateOpportunityTeamMember(Trigger.new, null);
			OpportunityTriggerHandler.createPrimaryOpportunityContactRole(Trigger.new, Trigger.oldmap);
		}

		if (Trigger.isUpdate && Trigger.isAfter) {
			/*if(!CommonUtilities.isIntegrationOrMigrationUser()){
                OpportunityTriggerHandler.syncOpportunityWithSiebel(trigger.new, Trigger.oldmap);
            }*/
			OpportunityTriggerHandler.populateCampaign(Trigger.new, Trigger.oldmap);
			OpportunityTriggerHandler.createUpdateOpportunityTeamMember(Trigger.new, Trigger.oldmap);
			OpportunityTriggerHandler.createPrimaryOpportunityContactRole(Trigger.new, Trigger.oldmap);
			OpportunityTriggerHandler.handleCurrencyChange(Trigger.new, Trigger.oldMap);
		}
	}
}