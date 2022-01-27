/********************************************************************************************************
 * Object	: CaseRelatedProductsTrigger
 * Company	: Keste @IDC
 * Author	: Adarsh Sharma
 * Purpose	: Trigger to default the first inserted Case Related Product as primary and populate primary product on case
 ********************************************************************************************************/
trigger CaseRelatedProductsTrigger on Case_Related_Products__c(
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete
) {
	//Dynamic Code Execution - Allow Execution ONLY and ONLY if ITs NOT BY-PASSED through metadata configuration
	if (DynamicCodeExecution.allowExecution('CaseRelatedProductsTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isBefore) {
			if (Trigger.isInsert) {
				//Default the first inserted Case Related Product as primary
				CaseRelatedProductsTriggerHandler.primaryCaseRelatedProducts(Trigger.New);
			}
			if (Trigger.isUpdate) {
				//Uncheck the primary check box on update case lookup
				CaseRelatedProductsTriggerHandler.uncheckPrimaryOnCaseChange(Trigger.New, Trigger.OldMap);
			}
			if (Trigger.isDelete) {
				//Not allow to delete E1 Complaint Product record
				CaseRelatedProductsTriggerHandler.doNotAllowToDeleteE1ComplaintProduct(Trigger.Old);
			}
		}
		if (Trigger.isAfter) {
			if (Trigger.isInsert || Trigger.isUpdate) {
				//Populate primary product on case
				CaseRelatedProductsTriggerHandler.populateCasePrimaryProduct(
					Trigger.new,
					(Trigger.isUpdate ? Trigger.oldMap : null)
				);
				//Populate E1 details on Case
				CaseRelatedProductsTriggerHandler.UpdateCaseE1Details(
					Trigger.new,
					(Trigger.isUpdate ? Trigger.oldMap : null)
				);
			} else if (Trigger.isDelete) {
				//Remove Primary Product on Case
				CaseRelatedProductsTriggerHandler.removeCasePrimaryProduct(Trigger.old);
			}
		}
	}
}