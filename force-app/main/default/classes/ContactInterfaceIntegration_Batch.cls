// ===========================================================================
//	Object	: ContactInterfaceIntegration_Batch
//	Company	: Keste @IDC
//	Author	: Abinash Panigrahi
//	Purpose	: Batch Class to send Callout to Siebel periodically to keep both CRM System in sync
//	Test Class : ContactInterfaceIntegration_Batch_Test
// ===========================================================================
global with sharing class ContactInterfaceIntegration_Batch implements Database.Batchable<sObject>, Schedulable {
	// Method Name: start
	// Author: Abinash Panigrahi
	// Description: Method to fetch all Contact records newly created or updated by
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Current DateTime
		//Datetime curr = System.Now().addHours(-1);
		//Define the Scope of Batch records to do processing.
		String query = 'Select Id From Contact Where Is_Siebel_Processed__c = true ORDER BY LastModifiedDate LIMIT 100';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash Panigrahi
	// Description:	Core method to do the callout
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Contact records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<Contact> records) {
		//Get all SF record ids
		Set<Id> conIds = new Set<Id>();
		List<Contact> toBeTriggered = new List<Contact>();
		//Loop through and add all
		for (Contact c : records) {
			conIds.add(c.Id);
			toBeTriggered.add(new Contact(Id = c.Id, Is_Siebel_Processed__c = false));
		}

		CommonUtilities.debug('conIds------->>>>>>>' + conIds);
		CommonUtilities.debug('toBeTriggered------->>>>>>>' + toBeTriggered);
		CommonUtilities.debug('Limits.getQueueableJobs()------->>>>>>>' + Limits.getQueueableJobs());

		//Mark Contact records - Siebel transaction done
		//Update records before callout to avoid Salesforce Standard errors
		//Exception Handling
		try {
			if (toBeTriggered.size() > 0) {
				update toBeTriggered;
			}
		} catch (Exception ex) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'ContactInterfaceIntegration_Batch',
				'execute',
				'Siebel Contact Sync Batch',
				'Update Contact records',
				ex.getMessage(),
				System.today()
			);
		}

		//Call Queable Class for Bulk record processing
		//Pass Object & DML Operation tag
		SiebelSync oSiebelSync = new SiebelSync();
		oSiebelSync.parentObjectAPIName = 'CONTACT';
		oSiebelSync.setRecordIds = conIds;
		oSiebelSync.OperationType = 'UPDATE';
		oSiebelSync.relatedOperationType = 'UPDATE';
		oSiebelSync.objectName = 'CONTACT';
		oSiebelSync.bulkJob = true;

		//Asynchronous Callout
		System.enqueueJob(oSiebelSync);
	}

	// Method Name: finish
	// Author: Abinash Panigrahi
	// Description: After Update Logic
	global void finish(Database.BatchableContext BC) {
	}

	//Scedhuler's Execute Method, which executes when scheduled time occures
	global void execute(SchedulableContext sc) {
		//Check if the batch is already is in process, if so, don't need to execute
		if ((CommonUtilities.isGoodToExecuteBatch('ContactInterfaceIntegration_Batch')) || Test.isRunningTest()) {
			//Executing the batch
			Database.executebatch(new ContactInterfaceIntegration_Batch(), 100);
		}
	}
	/*******************************************
	@comment : This below script is used to execute this batch job hourly.
	System.schedule('Contact Siebel Sync Batch', '0 0 0/1 1/1 * ? *', new ContactInterfaceIntegration_Schedulde());
	********************************************/

	/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new ContactInterfaceIntegration_Batch(), 100);
	********************************************/
}