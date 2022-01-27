// ===========================================================================
//  Object: PastdueBatchable
//  Author: Vijay Rayala
// Purpose: Batch Class to update pastdue Open Opportunities where closedate < Today
// ===========================================================================

global class PastdueBatchable implements database.Batchable<sObject> {
	public static Exception exceptionObForBatch = null;

	// Method Name: start
	// Author: Vijay Rayala
	// Description: Method to fetch all Open Opportunities records where closedate < Today
	// Parameter 1: Database.BatchableContext
	// Return: Database.getQueryLocator
	global database.QueryLocator start(database.BatchableContext BC) {
		//string query='select id,StageName,CloseDate,isClosed,Past_Due_Triggered__c from Opportunity where isclosed=false and Past_Due_Triggered__c=false and closedate <today';
		return database.getQueryLocator(
			'select id,StageName,CloseDate,isClosed,Past_Due_Triggered__c from Opportunity where isclosed=false and Past_Due_Triggered__c=false and closedate <today'
		);
	}

	// Method Name: execute
	// Author: Vijay Rayala
	// Description: Update Past due checkbox for the Queried records
	// Parameter 1: Database.BatchableContext
	// Parameter 2: scope- Opportunity fetched in start()

	global void execute(database.BatchableContext BC, List<Opportunity> scope) {
		try {
			list<Opportunity> opplist = new List<opportunity>();
			boolean b;
			for (Opportunity opp : scope) {
				opp.Past_Due_Triggered__c = true;
				if (opp.Past_Due_Triggered__c == true) {
					b = true;
				}
				opplist.add(opp);
			}
			if (opplist.size() > 0) {
				update opplist;
			}
		} catch (Exception ex) {
			//Create Apex Log
			ExceptionHandlerController.createException(
				'PastdueBatchable',
				'DueDateExepction',
				'Past duedate check',
				'updateopportunity',
				ex.getMessage(),
				System.today()
			);
			CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
			if (System.isBatch()) {
				exceptionObForBatch = ex;
			}
		}
	}
	// Method Name: finish
	// Author: Vijay Rayala
	// Description: After Update Logic
	global void finish(database.BatchableContext BC) {
	}
}