// ===========================================================================
//  Object	: SyncWithSiebelInterfaceController
// 	Company	: Keste @	IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller to handle Salesforce Contact and its Child records to be sync with Siebel Interface.
// ===========================================================================
public with sharing class SyncWithSiebelInterfaceController {
	// Method Name: siebelSyncIntegration
	// Author: Abinash panigrahi
	// Description: Method to send Contact record Outbound Integration request and handle response
	// Parameter 1: recordId - Fetched Current Contact record Id to be processed
	// Return: null
	@AuraEnabled
	public static void siebelSyncIntegration(String recordId) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('SyncWithSiebelInterfaceController.siebelSyncIntegration')) {
			//Call Integration Queable Class
			//Pass Object & DML Operation tag
			SiebelSync oSiebelSync = new SiebelSync();
			oSiebelSync.setRecordIds = new Set<Id>();
			oSiebelSync.setRecordIds.add(recordId);
			oSiebelSync.OperationType = 'UPDATE';
			oSiebelSync.relatedOperationType = 'UPDATE';
			oSiebelSync.objectName = 'CONTACT';
			oSiebelSync.parentObjectAPIName = 'CONTACT';
			if (Test.isRunningTest()) {
				oSiebelSync.bulkJob = true;
			}
			//Asynchronous Callout
			System.enqueueJob(oSiebelSync);
		}
	}

	// Method Name: checkPrimaryAccount
	// Author: Abinash panigrahi
	// Description: Method to check Primary Account assosiated with Contact record is Site SGN Record Type
	// Parameter 1: recordId - Fetched Current Contact record Id to be processed
	// Return: result - valid Contact record or not
	@AuraEnabled
	public static String checkPrimaryAccount(String recordId) {
		//Instance Defination
		String result = 'FALSE';
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('SyncWithSiebelInterfaceController.checkPrimaryAccount')) {
			for (Account acc : [
				SELECT Id, RecordTypeId
				FROM Account
				WHERE Id = :recordId AND Account.RecordType.Name = :Label.ACCOUNT_RECORD_SITE_SGN
			]) {
				result = 'TRUE';
			}
		}
		return result;
	}
}