// ===========================================================================
//  Object: TaskTrigger
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Dispatch Task trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================

trigger TaskTrigger on Task(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	//Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('TaskTrigger.TaskTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			if (!CommonUtilities.isIntegrationOrMigrationUser()) {
				TaskTriggerHandler.updateDueDate(Trigger.new);
				TaskTriggerHandler.validationFASCases(Trigger.new, Trigger.oldMap);
				TaskTriggerHandler.allowLaborTravelHoursOnlyForFASCASE(Trigger.new, null);
				TaskTriggerHandler.handleDeleteFASAndTechSupportCaseTask(Trigger.new);
			}
		}

		if (Trigger.isUpdate && Trigger.isBefore) {
			if (!CommonUtilities.isIntegrationOrMigrationUser()) {
				//TaskTriggerHandler.validationFASCases(Trigger.new, Trigger.oldMap);
				TaskTriggerHandler.allowLaborTravelHoursOnlyForFASCASE(Trigger.new, Trigger.oldMap);
			}
		}

		if (Trigger.isDelete && Trigger.isBefore) {
			if (!CommonUtilities.isIntegrationOrMigrationUser()) {
				TaskTriggerHandler.handleDeleteFASAndTechSupportCaseTask(Trigger.Old);
			}
		}

		if (Trigger.isInsert && Trigger.isAfter) {
			TaskTriggerHandler.updateOpportunity(Trigger.new, Trigger.oldmap);
			TaskTriggerHandler.updateClosedCase(Trigger.new);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			TaskTriggerHandler.updateOpportunity(Trigger.new, Trigger.oldmap);
		}
	}
}