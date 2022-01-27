/****************************************************************************************************
 * Author Name   : Abinash Panigrahi
 * Class Name    : TerritoryRealignmentCalloutTrigger
 * Created Date  : 10th Januray 2021
 * Description   : Trigger Territory Realignment for Accounts updated from Dataloader - Workaround flow
 ****************************************************************************************************/
trigger TerritoryRealignmentCalloutTrigger on Territory_Realign__e(after insert) {
	Integer counter = 0;
	Set<String> recordIds = new Set<String>();
	for (Territory_Realign__e eventRec : Trigger.New) {
		counter++;
		if (counter > 25) {
			break;
		}
		recordIds.add(eventRec.RecordId__c);
		EventBus.TriggerContext.currentContext().setResumeCheckpoint(eventRec.ReplayId);
	}
	AccountTriggerHandler.triggerPlatformEventAPICallout(new List<String>(recordIds));
}