// ===========================================================================
//  Object  : ProductTrigger
//  Company : Keste @IDC
//  Author  : Jayaram Bevara
//  Purpose : Dispatch Product trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger ProductTrigger on Product2(after update) {
	if (Trigger.isUpdate && Trigger.isAfter) {
		if (!CommonUtilities.isMigrationUser()) {
			ProductTriggerHandler.invokeAssetProductBackendUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}