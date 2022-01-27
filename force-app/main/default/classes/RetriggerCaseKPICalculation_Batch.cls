// ===========================================================================
//  Object: RetriggerCaseKPICalculation_Batch
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Batch Class to retrigger Case KPI Calculation for Legacy Service Request
// ===========================================================================
// Changes Impact: OpportunityTriggerHandler
// ===========================================================================

global with sharing class RetriggerCaseKPICalculation_Batch implements Database.Batchable<sObject> {
	// Method Name: start
	// Author: Abinash panigrahi
	// Description: Method to fetch all legacy Service Request records
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Get Filter Condition Values
		String tsCase = 'Tech Support';
		String fasCase = 'FAS';
		String fasStatus = 'Closed';
		List<String> acceptedOrigin = new List<String>{ 'Web', 'Email', 'Instrument' };
		//Define the Scope of Batch records to do processing.
		String query = 'SELECT Id, Retrigger_Case_KPI__c FROM Case WHERE (Origin IN: acceptedOrigin AND RecordType.Name =: tsCase) OR (RecordType.Name =: fasCase AND Status =: fasStatus)';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash Panigrahi
	// Description:	Method to calculate Case KPI
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Opportunity records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<Case> records) {
		//Put Retrigger checkbox as marked true
		for (Case at : records) {
			at.Retrigger_Case_KPI__c = true;
		}

		//Update Case records
		Database.SaveResult[] srList = Database.update(records, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'RetriggerCaseKPICalculation_Batch',
						'execute',
						'Batch Logic',
						'Update Case',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Put Retrigger checkbox as marked true
		for (Case at : records) {
			at.Retrigger_Case_KPI__c = false;
		}

		//Update Case records
		srList = Database.update(records, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'RetriggerCaseKPICalculation_Batch',
						'execute',
						'Batch Logic',
						'Update Case',
						err.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	// Method Name: finish
	// Author: Abinash panigrahi
	// Description: After Update Logic
	global void finish(Database.BatchableContext BC) {
	}
}

/*******************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new RetriggerCaseKPICalculation_Batch());
********************************************/