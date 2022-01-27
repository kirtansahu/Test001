/****************************************************************************************************
 * Author Name   : Abinash Panigrahi
 * Class Name    : OpportunityTeamSwap_Batch
 * Created Date  : 15th July 2020
 * Description   : To Mass Transfer Record Ownership and Swap Opportunity Team Members
 * Test Class    : OpportunityTeamSwapBatch_Test
****************************************************************************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new OpportunityTeamSwap_Batch(), 200);
****************************************************************************************************/

global class OpportunityTeamSwap_Batch implements Database.Batchable<sObject>, Database.Stateful {
	// Class Level Variables
	public Id EXISTING_SALESREP_USER;
	public Id NEW_SALESREP_USER;
	public String POSITION;

	// Custom Exception
	public virtual class CustomException extends Exception {
	}

	// Overide Default Constructor 
	global OpportunityTeamSwap_Batch(Id existinguser, Id newuser, String territoryname) {
		this.EXISTING_SALESREP_USER = existinguser;
		this.NEW_SALESREP_USER = newuser;
		this.POSITION = territoryname;
	}

	// Batch's Start method to query all eligible Opportunity Team Member records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		// Prepare Query String to extract data
		String soql = 'SELECT Id, UserId, OpportunityId, Position__c, isPrimary__c ';
		soql += ' FROM OpportunityTeamMember WHERE UserId =: EXISTING_SALESREP_USER';
		soql += ' AND Position__c =: POSITION';

		// Return Query Results
		return Database.getQueryLocator(soql);
	}

	// Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, List<OpportunityTeamMember> records) {
		// Create Instance to store Opp teams records
		List<OpportunityTeamMember> toBeInsertedSalesRep = new List<OpportunityTeamMember>();

		// Iterate through loop
		for (OpportunityTeamMember oppTeam : records) {
			// Preapre exact clone record
			OpportunityTeamMember obj = new OpportunityTeamMember();
			obj.Position__c = oppTeam.Position__c;
			obj.UserId = NEW_SALESREP_USER;
			obj.OpportunityId = oppTeam.OpportunityId;
			obj.isPrimary__c = oppTeam.isPrimary__c;
			obj.OpportunityAccessLevel = Label.OppTeamMember_OppAccessLevel;
			obj.TeamMemberRole = Label.OppTeamMember_OppTeamMemberRole;

			// Add to collection
			toBeInsertedSalesRep.add(obj);
		}

		// Debug Logs for reference
		System.debug('toBeInsertedSalesRep------------' + toBeInsertedSalesRep);
		System.debug('toBeInsertedSalesRep.size()------------' + toBeInsertedSalesRep.size());

		// Exception Handling
		try {
			// Bypass Trigger Logic
			OpportunityTriggerHandler.isFromAssignmentRuleJob = true;
			OpportunityTeamMemberTriggerHandler.isFromAssignmentRuleJob = true;

			// Bypass Email Notification
			OpportunityTriggerHandler.isFromBulkUpdateJob = true;

			// Clear out Existing Opportunity Team Members
            Database.delete(records, false);

			// Then add New folks to Opportunity
            Database.insert(toBeInsertedSalesRep, false);
		} catch (System.DmlException err) {
			// Create Apex Log
			createExceptionLogs(toBeInsertedSalesRep, 'Insert & Delete Opportunity Team Member', err);
			return;
		}
	}

	// Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
	}

	//Capture Error Message in full discrete info -- stamp to Apex_Log__c
	//Comment and Uncomment code line based on level of Error logs needed
	public void createExceptionLogs(List<SObject> lstRecords, String objective, System.DmlException err) {
		//Prepare Meaningful Error Message
		String linebreak = '\n**************************************\n';
		String genericErrorMessage = '';
		String specificErrorMessage = '';

		for (Integer i = 0; i < err.getNumDml(); i++) {
			specificErrorMessage += linebreak + 'DISPALY ERROR MESSAGE: ' + String.valueOf(err.getDmlMessage(i));
			specificErrorMessage += linebreak + 'DISPALY RECORD: ' + String.valueOf(lstRecords.get(err.getDmlIndex(i)));
		}

		genericErrorMessage += linebreak + 'DISPALY ERROR MESSAGE: ' + String.valueOf(err.getMessage());
		genericErrorMessage += linebreak + 'DISPALY # FAILED ROWS : ' + String.valueOf(err.getNumDml());
		genericErrorMessage += linebreak + 'DISPALY STACK TRACE: ' + String.valueOf(err.getStackTraceString());

		//Add record to custom Apex Log object for capturing
		insert new Apex_Log__c(
			Location__c = 'OpportunityTeamSwap_Batch',
			Method_name__c = 'execute',
			Application_Name__c = 'Batch Logic',
			Log_Comments__c = objective,
			Integration_Request__c = genericErrorMessage,
			Integration_Response__c = specificErrorMessage,
			Fixed_Date__c = System.today()
		);

		//Throw Exception for Error Visibility
		throw new CustomException('Data Issue Encountered');
	}
}

/*******************************************
    @comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new OpportunityTeamSwap_Batch(), 200z);
    ********************************************/