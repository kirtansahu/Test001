// ===========================================================================
//  Class	: TerritoryAutomationRequest_Schedulde
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Scheduler Class to execute Business Automation Request - Opportunity Alignment, Ownership Transfer etc
// ===========================================================================
global class TerritoryAutomationRequest_Schedulde implements Schedulable {
	//Execute method whcih will get executed when scheduled time occures
	global void execute(SchedulableContext sc) {
		// Fetch Business Request Record with Submitted Request
		// Check for Territory Alignment
		Territory_Automation_Request__c oppRec = new Territory_Automation_Request__c();
		Territory_Automation_Request__c terrRec = new Territory_Automation_Request__c();
		for (Territory_Automation_Request__c obj : [
			SELECT
				Id,
				Request_Type__c,
				Close_Date_From__c,
				Close_Date_To__c,
				Region__c,
				Opportunity_Stage__c,
				Existing_Owner__c,
				New_Owner__c,
				Territory_Label__c
			FROM Territory_Automation_Request__c
			WHERE
				Status__c = 'Submitted'
				AND Request_Type__c IN ('Opportunity Realignment', 'Opportunity Team Member Change')
			ORDER BY CreatedDate ASC
			LIMIT 1
		]) {
			oppRec = obj;
		}
		for (Territory_Automation_Request__c obj : [
			SELECT Id, Request_Type__c
			FROM Territory_Automation_Request__c
			WHERE Status__c = 'Submitted' AND Request_Type__c IN ('Territory Rule Sync', 'Territory Hierarchy Sync')
			ORDER BY CreatedDate ASC
			LIMIT 1
		]) {
			terrRec = obj;
		}

		// Null Check - Object & Parameter
		if (
			oppRec != null &&
			oppRec.Request_Type__c == 'Opportunity Realignment' &&
			oppRec.Close_Date_From__c != null &&
			oppRec.Close_Date_To__c != null &&
			oppRec.Region__c != null &&
			oppRec.Opportunity_Stage__c != null
		) {
			// Create Object Instance
			OpportunityAssignment_Batch specialInstance = new OpportunityAssignment_Batch();
			specialInstance.CloseDateFromValue = oppRec.Close_Date_From__c;
			specialInstance.CloseDateToValue = oppRec.Close_Date_To__c;
			specialInstance.OrgRegionValue = oppRec.Region__c;
			specialInstance.SalesStageValue = oppRec.Opportunity_Stage__c.split(';');
			specialInstance.IsBusinessAutomationJob = true;

            // Execute Batch Job
            if (!Test.isRunningTest()) {
                Database.executebatch(specialInstance, 1);
            }
		}

		if (
			oppRec != null &&
			oppRec.Request_Type__c == 'Opportunity Team Member Change' &&
			oppRec.Existing_Owner__c != null &&
			oppRec.New_Owner__c != null &&
			oppRec.Territory_Label__c != null &&
			!Test.isRunningTest()
		) {
			Database.executebatch(
				new OpportunityTeamSwap_Batch(oppRec.Existing_Owner__c, oppRec.New_Owner__c, oppRec.Territory_Label__c),
				2000
			);
		}

		if (terrRec != null && terrRec.Request_Type__c == 'Territory Rule Sync' && !Test.isRunningTest()) {
			Database.executebatch(new TerritoryRule_Batch(), 1);
		}

		if (terrRec != null && terrRec.Request_Type__c == 'Territory Hierarchy Sync' && !Test.isRunningTest()) {
			Database.executebatch(new TerritoryAlignment_Batch(), 1);
		}

		// Mark Record as Processed
		if (terrRec.Id != null) {
			update new Territory_Automation_Request__c(Id = terrRec.Id, Status__c = 'Completed');
			// Mark all Sibling record as Processed
			List<Territory_Automation_Request__c> siblingRec = new List<Territory_Automation_Request__c>();
			for (Territory_Automation_Request__c obj : [
				SELECT Id, Request_Type__c
				FROM Territory_Automation_Request__c
				WHERE Status__c = 'Submitted' AND Request_Type__c = :terrRec.Request_Type__c
			]) {
				obj.Request_Type__c = 'Completed';
				siblingRec.add(obj);
			}
			if (siblingRec.size() > 0) {
				update siblingRec;
			}
		}
		if (oppRec.Id != null) {
			update new Territory_Automation_Request__c(Id = oppRec.Id, Status__c = 'Completed');
		}
	}

	/*******************************************
    @comment : This below script is used to execute this batch job hourly.
    System.schedule('Business Territory Automation Request Batch Job', '0 0 0/1 1/1 * ? *', new TerritoryAutomationRequest_Schedulde());
    System.schedule('Business Territory Automation Request Batch Job', '0 30 0/1 1/1 * ? *', new TerritoryAutomationRequest_Schedulde());
    ********************************************/
}