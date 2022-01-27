/****************************************************************************************************
 * Author Name   : Adarsh Sharma
 * Class Name    : AccountMergeRequestBatch
 * Created Date  : 31st Dec 2019
 * Description   : To Process Account Merge Request
 * Test Class    : AccountMergeRequestBatch_Test
 ****************************************************************************************************/
global without sharing class AccountMergeRequestBatch implements Database.Batchable<sObject>, Database.Stateful {
	private static final String AMR_STATUS_REQUESTED = 'Requested';
	private static final String AMR_STATUS_PROCESSING_ACR = 'Processing - Account Contact Relation';
	private static final String AMR_STATUS_PROCESSING_AT = 'Processing - Account Team';
	private static final String AMR_STATUS_PROCESSING_STBT = 'Processing - ShipTo/BillTo';
	private static final String AMR_STATUS_PROCESSING_MERGE = 'Processing - Native Merge';
	private static final String AMR_STATUS_PROCESSING_AH = 'Processing - Account Hierarchy';
	private static final String AMR_STATUS_COMPLETED = 'Completed';
	private static final String AMR_STATUS_FAILED = 'Failed';
	private static final String AMR_FAILED_MESSAGE = 'Asyncronus Account Merge Request processing got failed while "{!status}".\nError message is "{!errorMessage}"';

	public static Map<String, String> accMergeErrorOverride {
		get {
			if (accMergeErrorOverride == null) {
				accMergeErrorOverride = new Map<String, String>();
				for (String keyValPair : Label.ACCOUNT_MERGE_OVERRIDE_ERROR.split(';')) {
					accMergeErrorOverride.put(keyValPair.split('=>')[0].trim(), keyValPair.split('=>')[1].trim());
				}
			}
			return accMergeErrorOverride;
		}
		set;
	}

	//Global Class Level Variables
	global Account_Merge_Request__c amr { get; set; }
	global String batchErrorMessage { get; set; }
	global Map<String, String> statusMap {
		get {
			if (statusMap == null) {
				statusMap = new Map<String, String>();
				statusMap.put(AMR_STATUS_REQUESTED, AMR_STATUS_PROCESSING_ACR);
				statusMap.put(AMR_STATUS_PROCESSING_ACR, AMR_STATUS_PROCESSING_AT);
				statusMap.put(AMR_STATUS_PROCESSING_AT, AMR_STATUS_PROCESSING_STBT);
				statusMap.put(AMR_STATUS_PROCESSING_STBT, AMR_STATUS_PROCESSING_MERGE);
				statusMap.put(AMR_STATUS_PROCESSING_MERGE, AMR_STATUS_PROCESSING_AH);
				statusMap.put(AMR_STATUS_PROCESSING_AH, AMR_STATUS_COMPLETED);
			}
			return statusMap;
		}
		protected set;
	}

	//Batch Constructor
	//Parameter 1: Account_Merge_Request__c amr - Account Merge Request Record
	global AccountMergeRequestBatch(Account_Merge_Request__c amr) {
		this.amr = amr;
	}

	//Batch's Start method to query all eligible Custom Price Book Entry records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String soql = '';
		batchErrorMessage = '';
		if (amr != null && statusMap != null && statusMap.containsKey(amr.Status__c)) {
			amr.Status__c = statusMap.get(amr.Status__c);
			if (amr.Status__c == AMR_STATUS_PROCESSING_ACR) {
				soql =
					'Select Id, ContactId, AccountId, IsDirect, Contact_Account_External_Id__c From AccountContactRelation WHERE AccountId = \'' +
					amr.Victim_Id__c +
					'\'';
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_AT) {
				soql = 'Select Id From Account_Team__c WHERE AccountId__c = \'' + amr.Victim_Id__c + '\'';
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_STBT) {
				soql =
					'Select Id, Ship_To__c, Bill_To__c, ShipTo_BillTo_External_Id__c From ShipTo_BillTo__c WHERE Ship_To__c  = \'' +
					amr.Victim_Id__c +
					'\' OR Bill_To__c  = \'' +
					amr.Victim_Id__c +
					'\'';
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_MERGE) {
				soql =
					'Select Id, Survivor_Id__c, Survivor_Unique_Id__c, Victim_Id__c, Victim_Unique_Id__c, Status__c From Account_Merge_Request__c Where Id = \'' +
					amr.Id +
					'\'';
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_AH) {
				soql =
					'Select Id, Name, Parent_Unique_Id__c, Child_Unique_Id__c,Parent_ERP_Account_Id__c,Primary_Bill_To_Unique_Id__c FROM Account WHERE Parent_Unique_Id__c = \'' +
					amr.Victim_Unique_Id__c +
					'\' OR Child_Unique_Id__c = \'' +
					amr.Victim_Unique_Id__c +
					'\' OR Primary_Bill_To_Unique_Id__c = \'' +
					amr.Victim_Unique_Id__c +
					'\'';
			}
			CommonUtilities.debug('soql------------' + soql);
			update amr;
		}
		return Database.getQueryLocator(soql);
	}

	//Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, list<sObject> scope) {
		Savepoint sp = Database.setSavepoint();
		try {
			//#1. Flag to notify Account Trigger that it's Account Merge process,
			//so DQ usres can allowed to delete account
			AccountMergeRequestCtr.mergeInProcess = true;

			//ALL PRE/POST MERGE ACTIONS
			//#2. Check the Status and perform the respective action
			if (amr.Status__c == AMR_STATUS_PROCESSING_ACR) {
				handleACR(scope);
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_AT) {
				// handleAccountTeam(scope);
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_STBT) {
				handleShipToBillTo(scope);
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_MERGE) {
				Map<String, Account> accMap = fetchAccountsForMerge(
					new Set<String>{ amr.Survivor_Unique_Id__c, amr.Victim_Unique_Id__c }
				);
				if (accMap.containsKey(amr.Survivor_Unique_Id__c) && accMap.containsKey(amr.Victim_Unique_Id__c)) {
					merge accMap.get(amr.Survivor_Unique_Id__c) accMap.get(amr.Victim_Unique_Id__c);
				}
			} else if (amr.Status__c == AMR_STATUS_PROCESSING_AH) {
				manageAccountHierarchy(scope);
			}
		} catch (Exception e) {
			Database.rollback(sp);
			batchErrorMessage +=
				'Exception Message: ' +
				e.getMessage() +
				'\n\nException Stack Trace: ' +
				e.getStackTraceString() +
				'\n\n\n';
			ExceptionHandlerController.createException(
				'AccountMergeRequestBatch',
				'execute',
				'Exception occured while ' + amr.Status__c,
				'Account Merge Request Asyncronus Batch',
				e.getMessage() +
				'\n' +
				e.getStackTraceString(),
				System.today()
			);
		}
	}

	// Method Name: handleACR
	// Author: Adarsh Sharma
	// Description: Method to Check for Duplicate Account Contact Relation and Delete them
	// Also Update the new External Ids for the records which going to be Merged
	// Parameter 1: List<AccountContactRelation> victimRecords - List of Victims's Child AccountContactRelation records
	private void handleACR(List<AccountContactRelation> victimRecords) {
		Map<Id, AccountContactRelation> victimACRs = new Map<Id, AccountContactRelation>();
		for (AccountContactRelation acr : victimRecords) {
			victimACRs.put(acr.ContactId, acr);
		}

		Map<Id, AccountContactRelation> survivorACR = new Map<Id, AccountContactRelation>();
		for (AccountContactRelation acr : [
			SELECT Id, ContactId
			FROM AccountContactRelation
			WHERE AccountId = :amr.Survivor_Id__c AND ContactId IN :victimACRs.keySet()
		]) {
			survivorACR.put(acr.ContactId, acr);
		}

		List<AccountContactRelation> duplicateACR = new List<AccountContactRelation>();
		List<AccountContactRelation> updateACRForExternalId = new List<AccountContactRelation>();
		for (AccountContactRelation acr : victimRecords) {
			if (survivorACR.containsKey(acr.ContactId)) {
				if (!acr.IsDirect) {
					duplicateACR.add(acr);
				} else {
					duplicateACR.add(survivorACR.get(acr.ContactId));

					acr.Contact_Account_External_Id__c = acr.ContactId + '_' + amr.Survivor_Id__c;
					updateACRForExternalId.add(acr);
				}
			} else {
				acr.Contact_Account_External_Id__c = acr.ContactId + '_' + amr.Survivor_Id__c;
				updateACRForExternalId.add(acr);
			}
		}

		if (duplicateACR.size() > 0) {
			delete duplicateACR;
		}

		if (updateACRForExternalId.size() > 0) {
			update updateACRForExternalId;
		}
	}

	// Method Name: handleShipToBillTo
	// Author: Adarsh Sharma
	// Description: Method to Check for Duplicate ShipTo/BillTo and Delete them
	// Also Update the new External Ids for the records which going to be Merged
	// Parameter 1: List<ShipTo_BillTo__c> victimRecords - List of Victims's Child ShipTo_BillTo__c records
	private void handleShipToBillTo(List<ShipTo_BillTo__c> victimRecords) {
		Map<String, ShipTo_BillTo__c> victimBTSTs = new Map<String, ShipTo_BillTo__c>();
		Map<String, String> victimToSurvivorExtIds = new Map<String, String>();
		for (ShipTo_BillTo__c btst : victimRecords) {
			victimBTSTs.put(btst.ShipTo_BillTo_External_Id__c, btst);
			String survivorExtId = btst.ShipTo_BillTo_External_Id__c.replace(amr.Victim_Id__c, amr.Survivor_Id__c);
			victimToSurvivorExtIds.put(btst.ShipTo_BillTo_External_Id__c, survivorExtId);
		}

		Map<String, ShipTo_BillTo__c> survivorBTST = new Map<String, ShipTo_BillTo__c>();
		for (ShipTo_BillTo__c btst : [
			SELECT Id, ShipTo_BillTo_External_Id__c
			FROM ShipTo_BillTo__c
			WHERE ShipTo_BillTo_External_Id__c IN :victimToSurvivorExtIds.values()
		]) {
			survivorBTST.put(btst.ShipTo_BillTo_External_Id__c, btst);
		}

		List<ShipTo_BillTo__c> duplicateBTST = new List<ShipTo_BillTo__c>();
		List<ShipTo_BillTo__c> updateBTSTForExternalId = new List<ShipTo_BillTo__c>();
		for (ShipTo_BillTo__c btst : victimRecords) {
			btst.ShipTo_BillTo_External_Id__c = btst.ShipTo_BillTo_External_Id__c.replace(
				amr.Victim_Id__c,
				amr.Survivor_Id__c
			);
			if (survivorBTST.containsKey(btst.ShipTo_BillTo_External_Id__c)) {
				duplicateBTST.add(btst);
			} else {
				updateBTSTForExternalId.add(btst);
			}
		}

		if (duplicateBTST.size() > 0) {
			delete duplicateBTST;
		}

		if (updateBTSTForExternalId.size() > 0) {
			update updateBTSTForExternalId;
		}
	}

	/*/ Method Name: handleAccountTeam
    // Author: Adarsh Sharma
    // Description: Method to Identify and Delete All Victim Account Team Records
    // Parameter 1: List<Account_Team__c> victimRecords - List of Victims's Child Account_Team__c records
    private void handleAccountTeam(List<Account_Team__c> victimRecords){
        if(victimRecords.size() > 0){
            delete victimRecords;
        }
    }*/

	// Method Name: manageAccountHierarchy
	// Author: Adarsh Sharma
	// Description: Method to change unique Ids from victimUniqueId to survivorUniqueId on all related Accounts
	// Parameter 1: List<Account> victimRecords - List of Victims's Child Account records
	private void manageAccountHierarchy(List<Account> victimRecords) {
		String SurvivorERPId = [
			SELECT Id, ERP_Account_Id__c, Unique_Id__c
			FROM Account
			WHERE Unique_Id__c = :amr.Survivor_Unique_Id__c
		]
		.ERP_Account_Id__c;
		for (Account acc : victimRecords) {
			if (acc.Parent_Unique_Id__c == amr.Victim_Unique_Id__c) {
				acc.Parent_Unique_Id__c = amr.Survivor_Unique_Id__c;
				acc.Parent_ERP_Account_Id__c = SurvivorERPId;
			}
			if (acc.Child_Unique_Id__c == amr.Victim_Unique_Id__c) {
				acc.Child_Unique_Id__c = amr.Survivor_Unique_Id__c;
			}
			if (acc.Primary_Bill_To_Unique_Id__c == amr.Victim_Unique_Id__c) {
				acc.Primary_Bill_To_Unique_Id__c = amr.Survivor_Unique_Id__c;
			}
		}
		update victimRecords;
	}

	// Method Name: fetchAccountsForMerge
	// Author: Adarsh Sharma
	// Description: Method to fect both Survivor and Victim Account records with all Updatable fields for Merge operation
	// Parameter 1: Set<String> accIds - Set of Account Uinique Ids
	// Return: Map<String, Account> - Map of Unique Id wise Accounts
	private Map<String, Account> fetchAccountsForMerge(Set<String> accIds) {
		Map<String, Account> accMap = new Map<String, Account>();
		String soql = 'SELECT Id, Unique_Id__c';
		Map<String, Schema.SObjectField> allFields = Schema.SObjectType.Account.fields.getMap();
		for (String fieldName : allFields.keySet()) {
			Schema.DescribeFieldResult desribeResult = allFields.get(fieldName).getDescribe();
			// Check if field is required and not was populated from the page-layout
			if (desribeResult.isUpdateable() && fieldName.toLowerCase() != 'unique_id__c') {
				soql += ',' + fieldName;
			}
		}
		soql += ' FROM ACCOUNT WHERE Unique_Id__c != NULL AND Unique_Id__c IN :accIds';
		for (Account acc : (List<Account>) Database.query(soql)) {
			accMap.put(acc.Unique_Id__c, acc);
		}
		return accMap;
	}

	//Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
		Boolean stopBatchExecution = false;
		if (!String.isBlank(batchErrorMessage)) {
			amr.Error_Message__c = AMR_FAILED_MESSAGE.replace('{!status}', amr.Status__c)
				.replace('{!errorMessage}', batchErrorMessage);
			amr.Status__c = AMR_STATUS_FAILED;
			amr.Generic_Error_Message__c = '';

			for (String keyStr : accMergeErrorOverride.keySet()) {
				if (batchErrorMessage.contains(keyStr)) {
					amr.Generic_Error_Message__c += accMergeErrorOverride.get(keyStr) + '\n';
				}
			}

			stopBatchExecution = true;
		} else {
			for (AsyncApexJob jbs : [
				SELECT Id, TotalJobItems, NumberOfErrors, Status, ExtendedStatus
				FROM AsyncApexJob
				WHERE Id = :BC.getJobId()
			]) {
				if (jbs.NumberOfErrors > 0) {
					amr.Error_Message__c = AMR_FAILED_MESSAGE.replace('{!status}', amr.Status__c)
						.replace('{!errorMessage}', jbs.ExtendedStatus);
					amr.Status__c = AMR_STATUS_FAILED;
					stopBatchExecution = true;
				}
			}
		}

		if (statusMap.containsKey(amr.Status__c) && statusMap.get(amr.Status__c) == AMR_STATUS_COMPLETED) {
			amr.Status__c = AMR_STATUS_COMPLETED;
			stopBatchExecution = true;
		}

		if (stopBatchExecution) {
			update amr;
		} else {
			Database.executeBatch(new AccountMergeRequestBatch(amr));
		}
	}
}