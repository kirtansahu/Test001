// ===========================================================================
//  Object: EventTriggerHandler
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Handler Class contains all logic for EventTrigger.
// ===========================================================================
public class EventTriggerHandler {
	public static String EVENT_DEMO_TYPE = LABEL.EVENT_DEMO_TYPE;
	public static String OPPORTUNITY_PREFIX = '006';
	public static String TASK_DEMO_TYPE = LABEL.TASK_DEMO_TYPE;
	public static String CASE_PREFIX = '500';

	// Method Name: updateOpportunity
	// Author: Abinash panigrahi
	// Description: Method to update Demo Onsite Checkbox to checked on related Opportunity record
	// Parameter 1: newRec - List of the new versions of the Event records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Event records
	// Return: Null
	public static void updateOpportunity(List<Event> newRec, Map<Id, Event> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('EventTriggerHandler.updateOpportunity')) {
			//Instance to store all related Opportunity Ids with Event details
			Map<Id, Event> mapOpportuntiyEvent = new Map<Id, Event>();
			//Instance to store all related Opportunities to update
			List<Opportunity> lstOpportunityToUpdate = new List<Opportunity>();

			//Differentiate Demo type Event and then capture related Opportunity Id populated in WhatId
			for (Event oEvent : newRec) {
				//Check Event Type
				//Get Object Type based on WhatId
				if (
					oEvent.Type == EVENT_DEMO_TYPE &&
					(oldMap == null ||
					oEvent.Type != oldMap.get(oEvent.Id).Type) &&
					oEvent.WhatId != null &&
					String.valueOf(oEvent.WhatId).startswith(OPPORTUNITY_PREFIX)
				) {
					if (!mapOpportuntiyEvent.containsKey(oEvent.WhatId)) {
						mapOpportuntiyEvent.put(oEvent.WhatId, oEvent);
					}
				}
			}

			if (!mapOpportuntiyEvent.IsEmpty()) {
				//Fetch Opportunity records, Update Demo onSite Checkbox
				for (Opportunity opp : [
					SELECT Id, Request_Demo__c, First_Demo_Request__c
					FROM Opportunity
					WHERE Id IN :mapOpportuntiyEvent.keyset()
				]) {
					opp.Request_Demo__c = true;
					if (oldMap == null && mapOpportuntiyEvent.containsKey(opp.Id)) {
						opp.First_Demo_Request__c = mapOpportuntiyEvent.get(opp.Id).StartDateTime;
					}
					lstOpportunityToUpdate.add(opp);
				}
			}
			//Exception Handling
			//Update Opportunity records
			try {
				if (lstOpportunityToUpdate.size() > 0) {
					update lstOpportunityToUpdate;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'EventTriggerHandler',
					'updateOpportunity',
					'Trigger Logic',
					'Update Opportunity',
					ex.getMessage(),
					System.today()
				);
			}
		}
	}

	// Method Name: uncheckRequestDemo
	// Author: Abinash panigrahi
	// Description: Method to uncheck Request Demo Checkbox on related Opportunity record
	// Parameter 1: oldRec - List of the old versions of the Event records
	// Return: Null
	public static void uncheckRequestDemo(List<Event> oldRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('EventTriggerHandler.updateOpportunity')) {
			CommonUtilities.debug('=============== oldRec ' + oldRec);
			//Instance to store related Opportunity RecordIds
			Set<Id> oppIds = new Set<Id>();
			for (Event evt : oldRec) {
				if (
					evt.Type == EVENT_DEMO_TYPE &&
					evt.WhatId != null &&
					String.valueOf(evt.WhatId).startswith(OPPORTUNITY_PREFIX)
				) {
					oppIds.add(evt.WhatId);
				}
			}
			CommonUtilities.debug('=============== oppIds ' + oppIds);
			//Instance to store to be Update Opportunity records
			List<Opportunity> toBeUpdateRec = new List<Opportunity>();
			//Fetch related Opportunity using Relational Query
			for (Opportunity o : [
				SELECT
					Id,
					(SELECT Id FROM Events WHERE Type = :EVENT_DEMO_TYPE),
					(SELECT Id FROM Tasks WHERE Type = :TASK_DEMO_TYPE)
				FROM Opportunity
				WHERE Id = :oppIds
			]) {
				CommonUtilities.debug('=============== o ' + o);
				CommonUtilities.debug('=============== o.Events.size() ' + o.Events.size());
				CommonUtilities.debug('=============== o.Tasks.size() ' + o.Tasks.size());
				if (o.Events.size() == 0 && o.Tasks.size() == 0) {
					toBeUpdateRec.add(new Opportunity(Id = o.Id, Request_Demo__c = false));
				}
			}

			//Exception Handling
			//Update Opportunity records
			try {
				if (toBeUpdateRec.size() > 0) {
					update toBeUpdateRec;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'EventTriggerHandler',
					'uncheckRequestDemo',
					'Trigger Logic',
					'Update Opportunity',
					ex.getMessage(),
					System.today()
				);
			}
		}
	}

	// Method Name: handleDeleteFASAndTechSupportCaseEvent
	// Author: Adarsh Sharma
	// Description: Method to add validation users cannot delete event if the tech support/fas case status closed
	// Parameter 1: newRec - List of the new versions of the Task records
	// Return: Null
	public static void handleDeleteFASAndTechSupportCaseEvent(List<Event> triggerOld) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('EventTrigger.handleDeleteFASAndTechSupportCaseEvent')) {
			//Get Recordtype for Tech Support and FAS
			List<String> caseRecordTypeNames = caseRecordTypes(Label.CASE_FAS_Tech_RECORDTYPE_FILTER);

			Set<Id> setCaseId = new Set<Id>();
			Set<Id> setCloseFASAndTechSupportCaseId = new Set<Id>();

			for (Event oEvent : triggerOld) {
				if (oEvent.WhatId != null && String.valueOf(oEvent.WhatId).startsWith(CASE_PREFIX)) {
					setCaseId.add(oEvent.WhatId);
				}
			}

			if (setCaseId.size() > 0) {
				for (Case oCase : [
					SELECT Id
					FROM Case
					WHERE Id IN :setCaseId AND RecordType.Name IN :caseRecordTypeNames AND IsClosed = TRUE
				]) {
					setCloseFASAndTechSupportCaseId.add(oCase.Id);
				}
			}

			if (setCloseFASAndTechSupportCaseId.size() > 0) {
				for (Event oEvent : triggerOld) {
					if (
						oEvent.WhatId != null &&
						String.valueOf(oEvent.WhatId).startsWith(CASE_PREFIX) &&
						setCloseFASAndTechSupportCaseId.contains(oEvent.WhatId)
					) {
						if (!CommonUtilities.isSystemAdminUserWithByPassValidation) {
							oEvent.addError(Label.EVENT_CANNOT_DELETED);
						}
					}
				}
			}
		}
	}

	//Single Method to parse Case Record Types
	public static List<String> caseRecordTypes(String customLabel) {
		List<String> caseRecordType = new List<String>();
		if (String.isNotBlank(customLabel) && String.isNotEmpty(customLabel)) {
			caseRecordType = customLabel.split(',');
		}
		return caseRecordType;
	}
}