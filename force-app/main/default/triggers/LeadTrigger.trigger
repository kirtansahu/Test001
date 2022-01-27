// ===========================================================================
//  Object	: LeadTrigger
// 	Company	: Keste @IDC
//	Author	: Abinash Panigrahi
//	Purpose	: Dispatch Lead trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================

trigger LeadTrigger on Lead(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	//Dynamic Code Execution
	if (DynamicCodeExecution.allowExecution('LeadTrigger.LeadTrigger')) {
		if (Trigger.isInsert && Trigger.isBefore) {
			LeadTriggerHandler.primaryRelationSetup(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.statusChangeCaptureRemainder(Trigger.New, Trigger.oldMap);
		}
		if (Trigger.isInsert && Trigger.isAfter) {
			LeadTriggerHandler.createCampaignRec(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.createdByApexSharingRule(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.campaignHistoryMaintain(Trigger.New, Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isBefore) {
			LeadTriggerHandler.primaryRelationSetup(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.statusChangeCaptureRemainder(Trigger.New, Trigger.oldMap);
		}
		if (Trigger.isUpdate && Trigger.isAfter) {
			LeadTriggerHandler.createCampaignRec(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.createdByApexSharingRule(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.campaignHistoryMaintain(Trigger.New, Trigger.oldMap);
			LeadTriggerHandler.chatterPostLeadStatusNotification(Trigger.New, Trigger.oldMap);
		}
	}
}