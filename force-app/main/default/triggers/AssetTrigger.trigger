// ===========================================================================
//  Object  : AccountTrigger
//   Company  : Keste @IDC
//  Author  : Jayaram Bevara
//   Purpose  : Dispatch Asset trigger functionality.
// ===========================================================================
trigger AssetTrigger on Asset(before delete) {
	if (Trigger.isDelete && Trigger.isBefore) {
		if (!CommonUtilities.isIntegrationOrMigrationUser()) {
			AssetTriggerHandler.handleBeforeDelete(Trigger.Old);
		}
	}
}