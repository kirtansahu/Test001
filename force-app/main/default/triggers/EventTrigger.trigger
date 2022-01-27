// ===========================================================================
//  Object: EventTrigger
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Dispatch Event trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================

trigger EventTrigger on Event(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	//Using Custom Settings to Enable/Disable trigger logic
	if (DynamicCodeExecution.allowExecution('EventTrigger.EventTriggerMet') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isDelete && Trigger.isBefore) {
			EventTriggerHandler.handleDeleteFASAndTechSupportCaseEvent(Trigger.Old);
		}
		if (Trigger.isInsert && Trigger.isAfter) {
			EventTriggerHandler.updateOpportunity(Trigger.new, Trigger.oldmap);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			EventTriggerHandler.updateOpportunity(Trigger.new, Trigger.oldmap);
		}
		if (Trigger.isDelete && Trigger.isAfter) {
			EventTriggerHandler.uncheckRequestDemo(Trigger.old);
		}
	}
}