/********************************************************************************************************
 * Object   : OpportunityTeamMemberTrigger
 * Company  : Keste @IDC
 * Author   : Adarsh Sharma
 * Purpose  : Trigger to handle all Business Automation for Opportunity Team Member
 *              Includes Integration Callout Scenarios and Primary and Owner Management
 ********************************************************************************************************/
trigger OpportunityTeamMemberTrigger on OpportunityTeamMember(
	before insert,
	before delete,
	after insert,
	after update,
	after delete
) {
	//Dynamic Code Execution - Allow Execution ONLY and ONLY if ITs NOT BY-PASSED through metadata configuration
	if (DynamicCodeExecution.allowExecution('OpportunityTeamMemberTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isBefore && Trigger.isDelete) {
			//Restrict the deletion of Primary team member
			OpportunityTeamMemberTriggerHandler.checkAndNotAllowToDeletePrimaryTeamMember(Trigger.Old);
		} else if (Trigger.isAfter && Trigger.isInsert) {
			//Restrict Creation of Duplicate Primary Team Members
			OpportunityTeamMemberTriggerHandler.checkDuplicatePrimaryOppTeamMembers(Trigger.new, null);
			//Change the Opportunity Owner On Creation of Primary Team Members
			OpportunityTeamMemberTriggerHandler.updateOpportunityOwner(Trigger.New);
			//DO NOT execute for Integration or Migration user
			/*if(!CommonUtilities.isIntegrationOrMigrationUser()){
                //Sync Opportunity team Member With Sieble
                OpportunityTeamMemberTriggerHandler.syncOpportunityTeamMemberWithSiebel(trigger.New);
            }*/
		} else if (Trigger.isAfter && Trigger.isUpdate) {
			//Restrict Creation of Duplicate Primary Team Members
			OpportunityTeamMemberTriggerHandler.checkDuplicatePrimaryOppTeamMembers(Trigger.New, Trigger.OldMap);
		} else if (Trigger.isAfter && Trigger.isDelete) {
			//DO NOT execute for Integration or Migration user
			/*if(!CommonUtilities.isIntegrationOrMigrationUser()){
                //Sync Opportunity team Member With Sieble
                OpportunityTeamMemberTriggerHandler.syncDeletedOpportunityTeamMemberWithSiebel(trigger.Old);
            }*/
		}

		if (Trigger.isInsert && Trigger.isBefore) {
			// Populate team member's primary positions
			OpportunityTeamMemberTriggerHandler.populateUserPrimaryPosition(Trigger.new);
		}
	}
}