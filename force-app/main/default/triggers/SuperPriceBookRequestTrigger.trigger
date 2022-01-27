// ===========================================================================
//  Object: SuperPriceBookRequestTrigger
// Company: Keste @IDC
//  Author: Adarsh Sharma
// Purpose: Dispatch Super Price Book Request trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger SuperPriceBookRequestTrigger on Super_Price_Book_Request__c(
	before insert,
	before update,
	after insert,
	after update
) {
	//Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('SuperPriceBookRequestTrigger')) {
		if (Trigger.isBefore) {
			if (Trigger.isUpdate || Trigger.isInsert) {
				SuperPriceBookRequestTriggerHandler.createAndPopulateSuperPricebook(
					Trigger.new,
					(Trigger.isInsert ? null : Trigger.oldMap)
				);
			}
		} else if (Trigger.isAfter) {
			if (Trigger.isUpdate || Trigger.isInsert) {
				SuperPriceBookRequestTriggerHandler.clonePBEForRelatedPricebook(
					Trigger.new,
					(Trigger.isInsert ? null : Trigger.oldMap)
				);
			}
		}
	}
}