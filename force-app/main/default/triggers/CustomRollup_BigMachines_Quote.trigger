// ===========================================================================
//  Object  : CustomRollup_BigMachines_Quote
//  Company : Keste @ IDC
//  Author  : Basant Kumar Verma
//  Purpose : Trigger to handle the rollup details
// ===========================================================================
trigger CustomRollup_BigMachines_Quote on BigMachines__Quote__c(
	after delete,
	after insert,
	after undelete,
	after update
) {
	if (DynamicCodeExecution.allowExecution('CustomRollup_BigMachines_Quote')) {
		if (Trigger.isAfter) {
			List<CustomRollupUtility.RollupFieldDetails> fieldDetails = new List<CustomRollupUtility.RollupFieldDetails>();
			fieldDetails.add(
				new CustomRollupUtility.RollupFieldDetails(
					'Quote_Revenue__c',
					'Quote_Revenue__c',
					CustomRollupUtility.ROLLUP_TYPE.SUM
				)
			);
			CustomRollupUtility.doRollup(
				'BigMachines__Quote__c',
				'BigMachines__Opportunity__c',
				'Opportunity',
				fieldDetails,
				Trigger.new,
				Trigger.oldMap
			);
		}
	}
}