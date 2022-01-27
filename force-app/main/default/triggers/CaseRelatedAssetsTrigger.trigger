// ===========================================================================
//  Object  : CaseAssetTrigger
//  Company : Keste @IDC
//  Author  : Pradeep Chanda
//  Purpose : Dispatch Case Asset trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger CaseRelatedAssetsTrigger on Case_Related_Assets__c(before update, after update, before delete) {
	if (DynamicCodeExecution.allowExecution('CaseRelatedAssetsTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isDelete && Trigger.isBefore) {
			CaseRelatedAssetsTriggerHandler.assetDeleteValidation(Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			CaseRelatedAssetsTriggerHandler.assetUpdateValidation(Trigger.oldMap, Trigger.newMap);
		}
	}
}