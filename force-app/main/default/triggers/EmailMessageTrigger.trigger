// ===========================================================================
//  Object  : EmailMessageTrigger
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Dispatch Email Message trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger EmailMessageTrigger on EmailMessage(before delete, after insert) {
	//Dynamic Code Execution - Allow Execution ONLY and ONLY if ITs NOT BY-PASSED through metadata configuration
	if (DynamicCodeExecution.allowExecution('EmailMessageTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isBefore && Trigger.isDelete) {
			EmailMessageTriggerHandler.handleDeleteFASAndTechSupportCaseEmailMessage(Trigger.Old);
		}
		if (Trigger.isAfter && Trigger.isInsert) {
			EmailMessageTriggerHandler.recieverEmailQueueCase(Trigger.new);
			EmailMessageTriggerHandler.firstCaseAgentResponseTimeCalculation(Trigger.new);
		}
	}
}