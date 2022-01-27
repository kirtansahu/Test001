// ===========================================================================
//  Object: AccountTeamTrigger
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Dispatch Custom Account Team trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================

trigger AccountTeamTrigger on Account_Team__c(
	after insert,
	before insert,
	after update,
	before update,
	after delete,
	before delete
) {
	//Dynamic Code Execution
	if (
		DynamicCodeExecution.allowExecution('AccountTeamTrigger.AccountTeamTrigger') &&
		!CommonUtilities.isMigrationUser() &&
		!AccountMergeRequestCtr.mergeInProcess
	) {
		if (Trigger.isInsert && Trigger.isBefore) {
			AccountTeamTriggerHandler.activeUserCheck(Trigger.new);
		}
		if (Trigger.isInsert && Trigger.isAfter) {
			AccountTeamTriggerHandler.insertAccountTeamMember(Trigger.new);
			AccountTeamTriggerHandler.prospectAccountAccessAddition(Trigger.new);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			AccountTeamTriggerHandler.updateInactiveTeamMemeber(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isDelete && Trigger.isBefore) {
			AccountTeamTriggerHandler.deleteAccountTeamMember(Trigger.old);
		}
	}
}