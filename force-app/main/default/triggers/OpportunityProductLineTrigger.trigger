/********************************************************************************************************
 * Object   : OpportunityProductLineTrigger
 * Company  : Keste @IDC
 * Author   : Adarsh Sharma
 * Purpose  : Trigger to handle all Integration Callout Scenarios for Opportunity Product Line
 ********************************************************************************************************/
trigger OpportunityProductLineTrigger on Opportunity_Product_Line__c(
	before insert,
	after insert,
	after update,
	after delete
) {
	//Trigger will be Executed Only and Only if ITs NOT BY-PASSED by Metadata Configuration
	if (DynamicCodeExecution.allowExecution('OpportunityProductLineTrigger') && !CommonUtilities.isMigrationUser()) {
		//Execute for After events Only and Only if the Logged in user is not Integration or Migration user
		if (Trigger.isBefore && Trigger.isInsert) {
			OpportunityProductLineTriggerHandler.prePopulateFields(Trigger.New);
		}
		/*if(trigger.isAfter && !CommonUtilities.isIntegrationOrMigrationUser()){
            if(trigger.isInsert){
                //Sycn With Siebel on Insert
                OpportunityProductLineTriggerHandler.syncOpportunityProductLineWithSiebel(trigger.New, null);
            }else if(trigger.isUpdate){
                //Sycn With Siebel on Update
                OpportunityProductLineTriggerHandler.syncOpportunityProductLineWithSiebel(trigger.New, trigger.OldMap);
            }else if(trigger.isDelete){
                //Sycn With Siebel on Deletion
                OpportunityProductLineTriggerHandler.syncDeletedOpportunityProductLineWithSiebel(trigger.Old);
            }
        }*/
	}
}