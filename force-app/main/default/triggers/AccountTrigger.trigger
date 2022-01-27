// ===========================================================================
//  Object  : AccountTrigger
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Dispatch Account trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger AccountTrigger on Account(before insert, after insert, before update, after update, before delete) {
	if (DynamicCodeExecution.allowExecution('AccountTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			AccountTriggerHandler.populateCountryWiseOrganizationRegion(Trigger.new);
			AccountTriggerHandler.parentalSetup(Trigger.new);
			AccountTriggerHandler.rollupPriceBook(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isInsert && Trigger.isAfter) {
			AccountTriggerHandler.shipToBillToRelationSetup(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isBefore) {
			AccountTriggerHandler.populateCountryWiseOrganizationRegion(Trigger.new);
			AccountTriggerHandler.updateParentalSetup(Trigger.new, Trigger.oldMap);
			AccountTriggerHandler.rollupPriceBook(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			AccountTriggerHandler.shipToBillToRelationSetup(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.invokeAssetAccountBackendUpdate(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.tagChildAccountsTerritoryAlignment(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isDelete && Trigger.isBefore) {
			if (!CommonUtilities.isSystemAdminUser() && !AccountMergeRequestCtr.mergeInProcess) {
				Trigger.old.get(0).addError(Label.ACCOUNT_DELETION_ERROR);
			}
		}
	}
}