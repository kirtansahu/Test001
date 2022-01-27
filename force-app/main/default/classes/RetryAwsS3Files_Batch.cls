// ===========================================================================
//	Object	: RetryAwsS3Files_Batch
//	Company	: Keste @IDC
//	Author	: Basant Kumar Verma
//	Purpose	: Batch Class to retrigger Account Team Cascading logic for Inactive Users
// ===========================================================================
global with sharing class RetryAwsS3Files_Batch implements Database.Batchable<sObject> {
	private final String STATUS_NEW = 'New';
	private final String STATUS_ERROR = 'Error';
	private final String STATUS_RETRY = 'Retry';

	// Method Name: start
	// Author: Basant Kumar Verma
	// Description: Method to fetch all Case Where AWS S3 File need to be fetched
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Define the Scope of Batch records to do processing.
		Set<String> validRetryStatus = new Set<String>();
		validRetryStatus.add(STATUS_NEW);
		validRetryStatus.add(STATUS_ERROR);
		String query = 'Select Id, CaseNumber, Web_File_URL__c, Web_File_Name__c, Web_File_Type__c, Web_File_AWS_Integration_Status__c ';
		query += 'From Case Where Web_File_Name__c != null ';
		query += 'AND (Web_File_AWS_Integration_Status__c = null OR Web_File_AWS_Integration_Status__c IN :validRetryStatus)';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Basant Kumar Verma
	// Description:	Core method to do the callout
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Case records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<Case> records) {
		//Update Integration Status to Retry, so trigger will pick it up and retry the Integration
		for (Case ob : records) {
			ob.Web_File_AWS_Integration_Status__c = STATUS_RETRY;
		}

		//Update Account Team records
		if (records.size() > 0) {
			update records;
		}
	}

	// Method Name: finish
	// Author: Basant Kumar Verma
	// Description: After Update Logic
	global void finish(Database.BatchableContext BC) {
	}
}