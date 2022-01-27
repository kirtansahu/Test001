// ===========================================================================
//  Object  : ContactTrigger
//  Company : Keste @ IDC
//  Author  : Abinash Panigrahi
//  Purpose : Dispatch Contact trigger functionality.
// ===========================================================================
trigger ContactTrigger on Contact(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	//Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('ContactTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			//ContactTriggerHandler.uppercaseMailingAddress(Trigger.new,Trigger.oldMap);
			ContactTriggerHandler.prePopulateFields(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.phoneDataStandards(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.duplicateRuleCheck(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.siebelRecordIdentification(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isInsert && Trigger.isAfter) {
			ContactTriggerHandler.duplicateRecordCreation(Trigger.new);
			ContactTriggerHandler.createCampaignRec(Trigger.new, Trigger.oldMap);

			if (CommonUtilities.IsSiebelContactSync == false) {
				CommonUtilities.IsSiebelContactSync = true;
				ContactTriggerHandler.onAfterInsert(Trigger.new);
			}
		}
		if (Trigger.isUpdate && Trigger.isBefore) {
			//ContactTriggerHandler.uppercaseMailingAddress(Trigger.new,Trigger.oldMap);
			ContactTriggerHandler.prePopulateFields(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.phoneDataStandards(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.duplicateRuleCheck(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.retriggerShipToInfo(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.siebelRecordIdentification(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			ContactTriggerHandler.duplicateRecordCreation(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.createCampaignRec(Trigger.new, Trigger.oldMap);
			ContactTriggerHandler.invokeAssetContactBackendUpdate(Trigger.new, Trigger.oldMap);
			if (CommonUtilities.IsSiebelContactSync == false) {
				CommonUtilities.IsSiebelContactSync = true;
				ContactTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
			}
		}
		if (Trigger.isDelete && Trigger.isBefore) {
			ContactTriggerHandler.duplicateRecordCreation(Trigger.old, Trigger.isDelete);
			ContactTriggerHandler.cloneErrorHandling(Trigger.oldMap.keySet());
			ContactTriggerHandler.restrictWebEnabledContact(Trigger.old);
		}
		if (Trigger.isDelete && Trigger.isAfter) {
			if (!CommonUtilities.isIntegrationOrMigrationUser()) {
				//ContactTriggerHandler.onAfterDelete(trigger.oldMap);
			}
		}
	}
}