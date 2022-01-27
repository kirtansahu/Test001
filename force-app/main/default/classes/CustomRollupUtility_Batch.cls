// ===========================================================================
//	Object	: CustomRollupUtility_Batch
//	Company	: Keste @IDC
//	Author	: Basant Kumar Verma
//	Purpose	: Batch Class to retrigger a custom rollup logic
// ===========================================================================
global with sharing class CustomRollupUtility_Batch implements Database.Batchable<sObject> {
	private String childObject, relationshipField, parentObject;
	private List<CustomRollupUtility.RollupFieldDetails> fieldDetails;

	//Controctor with all requored parameters
	public CustomRollupUtility_Batch(
		String childObject,
		String relationshipField,
		String parentObject,
		List<CustomRollupUtility.RollupFieldDetails> fieldDetails
	) {
		this.childObject = childObject;
		this.relationshipField = relationshipField;
		this.parentObject = parentObject;
		this.fieldDetails = fieldDetails;
	}

	// Method Name: start
	// Author: Basant Kumar Verma
	// Description: Method to fetch all child records and fetch
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, ' + relationshipField + ' ';
		String whereClause = ' WHERE ' + relationshipField + ' != NULL ';
		for (CustomRollupUtility.RollupFieldDetails fld : fieldDetails) {
			query += ', ' + fld.childField;
			whereClause += ' AND ' + fld.childField + ' != NULL ';
		}
		query += ' FROM ' + childObject + whereClause;
		query += ' ORDER BY ' + relationshipField;
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Basant Kumar Verma
	// Description:	Core method to do the callout
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - sObject records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<sObject> records) {
		CustomRollupUtility.doRollup(childObject, relationshipField, parentObject, fieldDetails, records, null);
	}

	// Method Name: finish
	// Author: Basant Kumar Verma
	// Description: After Update Logic
	global void finish(Database.BatchableContext BC) {
	}

	/***************************************************************************************************
    @comment : This below script is used to execute this batch job immediately.
	List<CustomRollupUtility.RollupFieldDetails> fieldDetails = new List<CustomRollupUtility.RollupFieldDetails>();
	fieldDetails.add(new CustomRollupUtility.RollupFieldDetails('Quote_Revenue__c', 'Quote_Revenue__c', CustomRollupUtility.ROLLUP_TYPE.SUM));
    CustomRollupUtility_Batch batchOb = new CustomRollupUtility_Batch(
        'BigMachines__Quote__c', 
        'BigMachines__Opportunity__c', 
        'Opportunity',
		fieldDetails
    );
    Database.executebatch(batchOb, 200);


	List<CustomRollupUtility.RollupFieldDetails> fieldDetails = new List<CustomRollupUtility.RollupFieldDetails>();
    fieldDetails.add(new CustomRollupUtility.RollupFieldDetails('Labor_Hours__c', 'Sum_of_Labor_Hours__c', CustomRollupUtility.ROLLUP_TYPE.SUM));
    fieldDetails.add(new CustomRollupUtility.RollupFieldDetails('Travel_Hours__c', 'Sum_of_Travel_Hours__c', CustomRollupUtility.ROLLUP_TYPE.SUM));
	CustomRollupUtility_Batch batchOb = new CustomRollupUtility_Batch(
        'Task', 
        'WhatId', 
        'Case',
		fieldDetails
    );
    Database.executebatch(batchOb, 200);
    ***************************************************************************************************/
}