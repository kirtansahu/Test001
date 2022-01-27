// ===========================================================================
//  Object  : CaseTrigger
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Dispatch Case trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================
trigger CaseTrigger on Case(before insert, after insert, before update, after update, before delete) {
	if (DynamicCodeExecution.allowExecution('CaseTrigger') && !CommonUtilities.isMigrationUser()) {
		if (Trigger.isInsert && Trigger.isBefore) {
			CaseTriggerHandler.multipleEmailMessageHandleScenario(Trigger.new);
			CaseTriggerHandler.setupContactAccountValue(Trigger.new, null);
			CaseTriggerHandler.webEmailOriginCaseEmailQueue(Trigger.new);
			CaseTriggerHandler.automateCaseStatusSubstatusChange(Trigger.new, null);
		}
		if (Trigger.isInsert && Trigger.isAfter) {
			CaseTriggerHandler.checkForWebFile(Trigger.new, null);
			CaseTriggerHandler.maintainAgentKPIStats(Trigger.newMap.keyset(), true);
			CaseTriggerHandler.casePrimaryAssetCreationInert(Trigger.newMap);
			CaseTriggerHandler.emailMessageForWebAndInstrumentOrigin(Trigger.new);
		}
		if (Trigger.isUpdate && Trigger.isBefore) {
			CaseTriggerHandler.setupContactAccountValue(Trigger.new, Trigger.oldMap);
			CaseTriggerHandler.automateCaseStatusSubstatusChange(Trigger.new, Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			CaseTriggerHandler.mergeHandlePrimaryProducts(Trigger.new, Trigger.oldMap);
			CaseTriggerHandler.checkForWebFile(Trigger.new, Trigger.oldMap);
			if (!System.isBatch() && !System.isFuture()) {
				CaseTriggerHandler.maintainAgentKPIStats(Trigger.newMap.keyset(), false);
			}
			CaseTriggerHandler.calculateCaseResolutionTime(Trigger.new, Trigger.oldMap);
			CaseTriggerHandler.retriggerLegacyServiceRequest(Trigger.new, Trigger.oldMap);

			CaseTriggerHandler.caseCloseValidation(Trigger.newMap, Trigger.oldMap);
			CaseTriggerHandler.casePrimaryAssetCreationUpdate(Trigger.oldMap, Trigger.newMap);
		}
		if (Trigger.isDelete && Trigger.isBefore) {
			CaseTriggerHandler.handleKPIDeletion(Trigger.old);
		}
	}
}