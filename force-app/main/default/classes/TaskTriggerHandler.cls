// ===========================================================================
//  Object: TaskTriggerHandler
// Company: Keste @ IDC
//  Author: Abinash Panigrahi
// Purpose: Handler Class contains all logic for Task Trigger.
// ===========================================================================
public without sharing class TaskTriggerHandler {
	public static String TASK_DEMO_TYPE = LABEL.TASK_DEMO_TYPE;
	public static String SOBJECT_DESC_NAME = LABEL.SOBJECT_DESC_NAME;
	public static String OPPORTUNITY_PREFIX = '006';
	public static String CASE_PREFIX = '500';
	public static String CANT_UPDATE_LABOR_TRAVEL_HOURS_MSG = Label.CANT_UPDATE_LABOR_TRAVEL_HOURS_MSG;

	// Method Name: updateOpportunity
	// Author: Abinash Panigrahi
	// Description: Method to update Demo Onsite Checkbox to checked on related Opportunity record
	// Parameter 1: newRec - List of the new versions of the Task records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Task records
	// Return: Null
	public static void updateOpportunity(List<Task> newRec, Map<Id, Task> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('TaskTriggerHandler.updateOpportunity')) {
			//Instance to store all related Opportunity Ids
			Set<Id> oppIds = new Set<Id>();
			//Differentiate Demo type Event and then capture related Opportunity Id populated in WhatId
			for (Task e : newRec) {
				//Check Event Type
				if (
					e.Type == TASK_DEMO_TYPE &&
					e.WhatId != null &&
					(oldMap == null || (e.Type != oldMap.get(e.Id).Type || e.WhatId != oldMap.get(e.Id).WhatId))
				) {
					//Get Object Type based on WhatId
					CommonUtilities.debug(e.Type);
					CommonUtilities.debug(e.WhatId);
					if (String.valueOf(e.WhatId).startswith(OPPORTUNITY_PREFIX)) {
						oppIds.add(e.WhatId);
					}
				}
			}

			//Conditional SOQL Query
			if (oppIds != null) {
				//Fetch Opportunity records
				List<Opportunity> toBeUpdated = new List<Opportunity>(
					[SELECT Id, Request_Demo__c FROM Opportunity WHERE Id IN :oppIds]
				);

				//Update Demo onSite Checkbox
				for (Opportunity o : toBeUpdated) {
					o.Request_Demo__c = true;
				}
				//Exception Handling
				//Update Opportunity records
				try {
					if (toBeUpdated.size() > 0) {
						update toBeUpdated;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'TaskTriggerHandler',
						'updateOpportunity',
						'Trigger Logic',
						'Update Opportunity',
						ex.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	// Method Name: updateDueDate
	// Author: Abinash Panigrahi
	// Description: If a task is created and no due date is filled in, due date will default to today
	// Parameter 1: newRec - List of the new versions of the Task records
	// Return: Null
	public static void updateDueDate(List<Task> newRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('TaskTriggerHandler.updateDueDate')) {
			//Loop through normal task
			for (Task t : newRec) {
				//If Due Date is Blank, then Due Date will default to today
				if (t.ActivityDate == null && !t.IsRecurrence) {
					t.ActivityDate = System.today();
				}
			}
		}
	}

	// Method Name: validationFASCases
	// Author: Abinash Panigrahi
	// Description: If a task is created and no Date of Activity is populated - throw error message
	// Parameter 1: newRec - List of the new versions of the Task records
	// Return: Null
	public static void validationFASCases(List<Task> newRec, Map<Id, Task> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('TaskTriggerHandler.updateDueDate')) {
			//RAID LOG
			//Add Validation check to see if Due Date is Blank -- Only NA Owner FAS Cases

			List<String> taskTypesAllowed = String.valueOf(Label.TASK_TYPE_FAS_FILTERS).split(',');

			//Get all Task assosiated with FAS Cases
			Set<Id> caseIds = new Set<Id>();
			for (Task tk : newRec) {
				//Check WhatId is Case Prefix RecordId or not
				if (tk.WhatId != null && String.valueOf(tk.WhatId).startsWith(Label.CASE_RECORDID_PREFIX)) {
					caseIds.add(tk.WhatId);
				}
			}

			CommonUtilities.debug('caseIds------->>>>>>>' + caseIds);

			//Conditional SOQL Query
			if (caseIds != null) {
				Map<Id, Case> fasRecords = new Map<Id, Case>(
					[
						SELECT Id, RecordTypeId, Owner_Region__c
						FROM Case
						WHERE
							Id IN :caseIds
							AND RecordType.Name = :Label.TASK_CUSTOM_VALIDATION_RECORDTYPE
							AND Owner_Region__c = :Label.TASK_CUSTOM_VALIDATION_REGION
					]
				);

				CommonUtilities.debug('fasRecords------->>>>>>>' + fasRecords);

				//Conditional Execution -- FAS Cases
				if (fasRecords.size() > 0) {
					//Throw Error message from Trigger
					for (Task tk : newRec) {
						if (
							fasRecords.containsKey(tk.WhatId) &&
							tk.Date_of_Activity__c == null &&
							taskTypesAllowed.contains(tk.Type)
						) {
							CommonUtilities.debug('tk.Date_of_Activity__c------->>>>>>>' + tk.Date_of_Activity__c);
							tk.Date_of_Activity__c.addError(Label.TASK_CUSTOM_VALIDATION_ERRORMESSAGE);
						}
					}
				}
			}
		}
	}

	// Method Name: updateClosedCase
	// Author: Abinash Panigrahi
	// Description: Method to update Closed Case to Reopen once ant task is created related to that case
	// Parameter 1: newRec - List of the new versions of the Task records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Task records
	// Return: Null
	public static void updateClosedCase(List<Task> newRec) {
		System.debug('Inside updateClosedCase Method');
		System.debug('newRec------->>>>>>>' + newRec);

		Set<Id> caseIds = new Set<Id>();
		for (Task t : newRec) {
			if (t.WhatId != null && String.valueOf(t.WhatId).startswith(Label.CASE_RECORDID_PREFIX)) {
				caseIds.add(t.WhatId);
			}
		}

		if (caseIds != null) {
			//Conditional SOQL Query
			List<Case> toBeUpdateRec = new List<Case>(
				[
					SELECT Id, Status
					FROM Case
					WHERE
						Id IN :caseIds
						AND Status = 'Closed'
						AND Origin != 'Chat'
						AND RecordType.Name != :Label.TASK_CASE_FILTER_RECORDTYPE
				]
			);

			//Change Case Status
			for (Case cs : toBeUpdateRec) {
				cs.Status = Label.CASE_REOPEN_BY_TASK;
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
					'TaskTriggerHandler',
					'updateClosedCase',
					'Trigger Logic',
					'Update Case',
					ex.getMessage(),
					System.today()
				);
			}
		}
		System.debug('newRec------->>>>>>>' + newRec);
		System.debug('Exit updateClosedCase Method');
	}

	// Method Name: allowLaborTravelHoursOnlyForFASCASE
	// Author: Adarsh Sharma
	// Description: Method to not allow users can track labor/travel hours only under fas cases
	// Parameter 1: newRec - List of the new versions of the Task records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Task records
	// Return: Null
	public static void allowLaborTravelHoursOnlyForFASCASE(List<Task> triggerNew, Map<Id, Task> triggerOldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('TaskTriggerHandler.AllowLaborTravelHoursOnlyForFASCASE')) {
			Set<Id> setCaseId = new Set<Id>();
			Set<Id> setFASCaseId = new Set<Id>();
			Set<Id> setOwnerId = new Set<Id>();
			Set<Id> setUpdatedTaskOwnerId = new Set<Id>();
			Set<Id> setInvalidOwnerId = new Set<Id>();
			Set<String> setAdminProfileName = new Set<String>{ 'System Administrator' };
			Set<String> setProfileName = new Set<String>{
				'Integration User',
				'CPQ Integration User',
				'Data Quality Team',
				'Data Management Team (Japan)'
			};

			for (Task oTask : triggerNew) {
				if (
					(oTask.Travel_Hours__c != null || oTask.Labor_Hours__c != null) &&
					((triggerOldMap == null) ||
					(triggerOldMap != null &&
					((oTask.Travel_Hours__c != triggerOldMap.get(oTask.Id).Travel_Hours__c) ||
					(oTask.Labor_Hours__c != triggerOldMap.get(oTask.Id).Labor_Hours__c))))
				) {
					setUpdatedTaskOwnerId.add(oTask.OwnerId);
					if (oTask.WhatId != null && String.valueOf(oTask.WhatId).startsWith(CASE_PREFIX)) {
						setCaseId.add(oTask.WhatId);
					}
				}
			}

			if (setUpdatedTaskOwnerId.size() > 0) {
				//Get Recordtype for Tech Support and FAS
				List<String> caseRecordTypeName = caseRecordTypes(Label.CASE_ASSIGNMENT_RECORDTYPE_FILTER);

				if (setCaseId.size() > 0) {
					for (Case oCase : [
						SELECT Id
						FROM Case
						WHERE Id IN :setCaseId AND RecordType.Name IN :caseRecordTypeName
					]) {
						setFASCaseId.add(oCase.Id);
					}
				}

				for (Task oTask : triggerNew) {
					if (
						(oTask.Travel_Hours__c != null ||
						oTask.Labor_Hours__c != null) &&
						!setFASCaseId.contains(oTask.WhatId) &&
						setUpdatedTaskOwnerId.contains(oTask.OwnerId)
					) {
						setOwnerId.add(oTask.OwnerId);
					}
				}

				if (setOwnerId.size() > 0) {
					for (User oUser : [
						SELECT Id, Profile.Name, Bypass_Validation__c
						FROM User
						WHERE Id IN :setOwnerId
					]) {
						if (setAdminProfileName.contains(oUser.Profile.Name) && !oUser.Bypass_Validation__c) {
							setInvalidOwnerId.add(oUser.Id);
						} else if (
							!setProfileName.contains(oUser.Profile.Name) &&
							!setAdminProfileName.contains(oUser.Profile.Name)
						) {
							setInvalidOwnerId.add(oUser.Id);
						}
					}
				}

				if (setInvalidOwnerId.size() > 0) {
					for (Task oTask : triggerNew) {
						if (
							(oTask.Travel_Hours__c != null ||
							oTask.Labor_Hours__c != null) &&
							!setFASCaseId.contains(oTask.WhatId) &&
							setInvalidOwnerId.contains(oTask.OwnerId) &&
							setUpdatedTaskOwnerId.contains(oTask.OwnerId)
						) {
							oTask.addError(CANT_UPDATE_LABOR_TRAVEL_HOURS_MSG);
						}
					}
				}
			}
		}
	}

	// Method Name: handleDeleteFASAndTechSupportCase
	// Author: Adarsh Sharma
	// Description: Method to add validation users cannot delete task/event/email if the tech support/fas case status closed
	// Parameter 1: newRec - List of the new versions of the Task records
	// Return: Null
	public static void handleDeleteFASAndTechSupportCaseTask(List<Task> triggerOld) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('TaskTriggerHandler.handleDeleteFASAndTechSupportCaseTask')) {
			//Get Recordtype for Tech Support and FAS
			List<String> caseRecordTypeName = caseRecordTypes(Label.CASE_FAS_Tech_RECORDTYPE_FILTER);
			//Get Case Status to Restrict the Task Creation and Deletion
			List<String> caseStatusList = caseStatus(Label.CASE_STATUS_RESTRICTION_FOR_TASK_CREATION);
			//Get Case Origin to Allow the Task Creation and Deletion
			List<String> caseOriginList = caseOrigin(Label.CASE_ORIGIN_ACCEPTED_VALUES_FOR_TASK_CREATION);
			Set<Id> setCaseId = new Set<Id>();
			Set<Id> setCloseFASAndTechSupportCaseId = new Set<Id>();

			for (Task oTask : triggerOld) {
				if (oTask.WhatId != null && String.valueOf(oTask.WhatId).startsWith(CASE_PREFIX)) {
					setCaseId.add(oTask.WhatId);
				}
			}

			if (setCaseId.size() > 0) {
				for (Case oCase : [
					SELECT Id
					FROM Case
					WHERE
						Id IN :setCaseId
						AND RecordType.Name IN :caseRecordTypeName
						AND Status IN :caseStatusList
						AND Origin NOT IN :caseOriginList
				]) {
					setCloseFASAndTechSupportCaseId.add(oCase.Id);
				}
			}

			if (setCloseFASAndTechSupportCaseId.size() > 0) {
				for (Task oTask : triggerOld) {
					if (
						oTask.WhatId != null &&
						String.valueOf(oTask.WhatId).startsWith(CASE_PREFIX) &&
						setCloseFASAndTechSupportCaseId.contains(oTask.WhatId)
					) {
						if (!CommonUtilities.isSystemAdminUserWithByPassValidation) {
							oTask.addError(Label.TASK_CANT_DELETE_TASK);
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
	//Single Method to parse Case Status
	public static List<String> caseStatus(String customLabel) {
		List<String> caseStatusList = new List<String>();
		if (String.isNotBlank(customLabel) && String.isNotEmpty(customLabel)) {
			caseStatusList = customLabel.split(',');
		}
		return caseStatusList;
	}
	//Single Method to parse Case Origin
	public static List<String> caseOrigin(String customLabel) {
		List<String> caseOriginList = new List<String>();
		if (String.isNotBlank(customLabel) && String.isNotEmpty(customLabel)) {
			caseOriginList = customLabel.split(',');
		}
		return caseOriginList;
	}
}