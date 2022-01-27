// ===========================================================================
//  Object  : CustomRollup_Task
//  Company : Keste @ IDC
//  Author  : Basant Kumar Verma
//  Purpose : Trigger to handle the rollup details
// ===========================================================================
trigger CustomRollup_Task on Task(after delete, after insert, after undelete, after update) {
	if (DynamicCodeExecution.allowExecution('CustomRollup_Task')) {
		if (Trigger.isAfter) {
			List<CustomRollupUtility.RollupFieldDetails> fieldDetails = new List<CustomRollupUtility.RollupFieldDetails>();
			fieldDetails.add(
				new CustomRollupUtility.RollupFieldDetails(
					'Labor_Hours__c',
					'Sum_of_Labor_Hours__c',
					CustomRollupUtility.ROLLUP_TYPE.SUM
				)
			);
			fieldDetails.add(
				new CustomRollupUtility.RollupFieldDetails(
					'Travel_Hours__c',
					'Sum_of_Travel_Hours__c',
					CustomRollupUtility.ROLLUP_TYPE.SUM
				)
			);

			CustomRollupUtility.doRollup('Task', 'WhatId', 'Case', fieldDetails, Trigger.new, Trigger.oldMap);
		}
	}
}