// ===========================================================================
//  Object: RelatedPricebookTrigger
// Company: Keste @IDC
//  Author: Adarsh Sharma
// Purpose: Dispatch Related Pricebook trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger RelatedPricebookTrigger on Related_Pricebook__c(before insert, before update) {
	//Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('RelatedPricebookTrigger')) {
		if (Trigger.isBefore) {
			if (Trigger.isUpdate || Trigger.isInsert) {
				RelatedPricebookTriggerHandler.updateRelatedPricebookStatus(
					Trigger.new,
					(Trigger.isInsert ? null : Trigger.OldMap)
				);
			}
		}
	}
}