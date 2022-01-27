/****************************************************************************************************
 * Author Name   : Abinash Panigrahi
 * Class Name    : TerritoryRealignmentCallout_Batch
 * Created Date  : 10th December 2020
 * Description   : Trigger Territory Realignment for Accounts updated from Dataloader - Workaround flow
****************************************************************************************************
	@comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new TerritoryRealignmentCallout_Batch(), 25);
    @note : Always execute batch job with Batch size less than or equal to 25
****************************************************************************************************/

public class TerritoryRealignmentCallout_Batch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(
			'SELECT Id, TriggerAssignment__c FROM Account ' + 'WHERE TriggerAssignment__c = True '
		);
	}

	public void execute(Database.BatchableContext context, List<Account> scope) {
		Set<Id> accRecIds = new Set<Id>();
		for (Account obj : [
			SELECT Id
			FROM Account
			WHERE (ParentId IN :scope AND RecordType.Name = 'Ship To') OR Id IN :scope
		]) {
			accRecIds.add(obj.Id);
		}

		List<Territory_Realign__e> events = new List<Territory_Realign__e>();
		for (Id obj : accRecIds) {
			events.add(new Territory_Realign__e(RecordId__c = obj));
		}

		EventBus.publish(events);
	}

	public void finish(Database.BatchableContext context) {
	}
}