// ===========================================================================
//  Object: OpportunityLineItemTrigger
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Dispatch OpportunityLineItem trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================

trigger OpportunityLineItemTrigger on OpportunityLineItem(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	//Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('OpportunityLineItemTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			OpportunityLineItemTriggerHandler.productUserDivisionCheck(Trigger.new);
			//OpportunityLineItemTriggerHandler.updateOpportunityLineItemAsPrimary(Trigger.new);
		} /*else if(!CommonUtilities.isIntegrationOrMigrationUser()){
            if(trigger.isInsert && trigger.isAfter){
                OpportunityLineItemTriggerHandler.syncOpportunityLineItemWithSiebel(trigger.New, null);
            }else if(trigger.isUpdate && trigger.isAfter){
                OpportunityLineItemTriggerHandler.syncOpportunityLineItemWithSiebel(trigger.New, trigger.OldMap);
            }else if(trigger.isDelete && trigger.isAfter){
                OpportunityLineItemTriggerHandler.syncDeletedOpportunityLineItemWithSiebel(trigger.Old);
            }
        }*/
        if(Trigger.isBefore){
            if(trigger.isInsert){
                OpportunityLineItemTriggerHandler.populateOppProducts(trigger.new);
            }
            if(trigger.isUpdate){
                OpportunityLineItemTriggerHandler.populateOppProducts(trigger.new);
            }
        }
        if(Trigger.isAfter && Trigger.isDelete){
            OpportunityLineItemTriggerHandler.populateOppProducts(trigger.old);
        }
	}
}