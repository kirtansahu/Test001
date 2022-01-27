// ===========================================================================
//  Object  : OpportunityContactRoleTrigger
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Dispatch Opportunity Contact Role trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger OpportunityContactRoleTrigger on OpportunityContactRole(
	before insert,
	after insert,
	before update,
	after update,
	before delete
) {
	if (DynamicCodeExecution.allowExecution('OpportunityContactRoleTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			OpportunityContactRoleTriggerHandler.avoidDuplicateOpportunityContactRecord(Trigger.new);
		}
		if (Trigger.isUpdate && Trigger.isBefore) {
			OpportunityContactRoleTriggerHandler.restrictEditOpportunityContactRecord(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isDelete && Trigger.isBefore) {
			OpportunityContactRoleTriggerHandler.restrictDeletePrimaryRecord(Trigger.old);
		}
	}
}