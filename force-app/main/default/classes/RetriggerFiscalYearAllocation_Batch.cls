// ===========================================================================
//  Object: RetriggerFiscalYearAllocation_Batch
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Batch Class to retrigger Opportunity Fiscal Year Allcocation based on Close Date
// ===========================================================================
// Changes Impact: OpportunityTriggerHandler
// ===========================================================================

global with sharing class RetriggerFiscalYearAllocation_Batch implements Database.Batchable<sObject> {
	//Input Year can be single or multiple - separated by ,
	String yearsInput;

	//Constructor Initialization
	global RetriggerFiscalYearAllocation_Batch(String years) {
		yearsInput = years;
	}

	//Constructor Initialization
	global RetriggerFiscalYearAllocation_Batch() {
		yearsInput = null;
	}

	// Method Name: start
	// Author: Abinash panigrahi
	// Description: Method to fetch all Opportunity records with non-allocated Fiscal Quarter info
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Calender Years
		List<Integer> years = new List<Integer>();
		//Define the Scope of Batch records to do processing.
		String query = 'SELECT Id, Retrigger_Fiscal_Quarter__c FROM Opportunity';
		//Conditional Query
		if (yearsInput != null) {
			for (String s : yearsInput.split(',')) {
				years.add(Integer.valueOf(s));
			}
			query += ' WHERE CALENDAR_YEAR(CloseDate) IN: years';
		} else {
			query += ' WHERE Fiscal_Quarter__c = null';
		}
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash Panigrahi
	// Description:	Method to calculate Fiscal Period of Opportunity based on Close Date
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Opportunity records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<Opportunity> records) {
		//Put Retrigger checkbox as marked true
		for (Opportunity at : records) {
			at.Retrigger_Fiscal_Quarter__c = true;
		}

		//Update Opportunity records
		Database.SaveResult[] srList = Database.update(records, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'RetriggerFiscalYearAllocation_Batch',
						'execute',
						'Batch Logic',
						'Update Opportunity',
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
	Database.executebatch(new RetriggerFiscalYearAllocation_Batch('xxxx'));
********************************************/