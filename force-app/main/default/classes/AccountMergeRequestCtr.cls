// ===========================================================================
//  Object	: AccountMergeRequestCtr
// 	Company	: Keste @ IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Lightning Component Controller to Account Merge Request.
// ===========================================================================
public without sharing class AccountMergeRequestCtr {
	public static Boolean mergeInProcess = false;
	private static final String MISSING_SURVIVER_UNIQUE_ID = Label.ACCOUNT_MERGE_MISSING_SURVIVER_UNIQUE_ID;
	private static final String MISSING_VICTIM_UNIQUE_ID = Label.ACCOUNT_MERGE_MISSING_VICTIM_UNIQUE_ID;
	private static final String INVALID_SURVIVER_UNIQUE_ID = Label.ACCOUNT_MERGE_INVALID_SURVIVER_UNIQUE_ID;
	private static final String INVALID_VICTIM_UNIQUE_ID = Label.ACCOUNT_MERGE_INVALID_VICTIM_UNIQUE_ID;
	private static final String RECORD_TYPES_MISSMATCH_FOR_MERGE = Label.ACCOUNT_MERGE_RECORD_TYPES_MISSMATCH_FOR_MERGE;
	private static final String COUNTRY_MISSMATCH_FOR_MERGE = Label.ACCOUNT_MERGE_COUNTRY_MISSMATCH_FOR_MERGE;
	private static final String SURVIVER_VICTIM_CANT_SAME = Label.ACCOUNT_MERGE_SURVIVER_VICTIM_CANT_SAME;
	private static final String DATA_QUALITY_TEAM_PROFILE = Label.ACCOUNT_MERGE_DATA_QUALITY_TEAM_PROFILE;
	private static final String SYSTEM_ADMIN_PROFILE = Label.ACCOUNT_MERGE_SYSTEM_ADMIN_PROFILE;
	private static final String INVALID_USER_PROFILE = Label.ACCOUNT_MERGE_INVALID_USER_PROFILE;
	private static final String UNKNOWN_ERROR = Label.ACCOUNT_MERGE_UNKNOWN_ERROR;
	private static final String UNABLE_TO_FETCH_ACCOUNTS = Label.ACCOUNT_MERGE_UNABLE_TO_FETCH_ACCOUNTS;
	private static final String ACCOUNT_RECORD_TYPE_NAME_SITE_SGN = Label.ACCOUNT_RECORD_SITE_SGN;
	private static final String ACCOUNT_RECORD_TYPE_NAME_SITE_PROSPECT = Label.ACCOUNT_RECORD_PROSPECT;
	private static final String REQUEST_ALREADY_IN_PROGRESS = Label.ACCOUNT_MERGE_REQUEST_ALREADY_IN_PROGRESS;

	private static final String AMR_STATUS_REQUESTED = 'Requested';
	private static final String AMR_STATUS_COMPLETED = 'Completed';
	private static final String AMR_STATUS_FAILED = 'Failed';

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

	// Method Name: checkForValidProfile
	// Author: Adarsh Sharma
	// Description: Method which will check the profile of logged in user, return error message if its not System Admin or Data Quality Team
	// Return: RequestResult - Wrapper Class of Message and a Success Flag
	@AuraEnabled
	public static RequestResult checkForValidProfile() {
		RequestResult result = new RequestResult();
		result.isSuccess = false;
		result.statusMessage = INVALID_USER_PROFILE;
		Set<String> validProfiles = new Set<String>();
		validProfiles.add(DATA_QUALITY_TEAM_PROFILE);
		validProfiles.add(SYSTEM_ADMIN_PROFILE);
		for (Profile p : [
			SELECT Id, Name
			FROM Profile
			WHERE Id = :UserInfo.getProfileId() AND NAME IN :validProfiles
		]) {
			result.isSuccess = true;
			result.statusMessage = null;
		}
		return result;
	}

	// Method Name: getAccountDetails
	// Author: Adarsh Sharma
	// Description: Method which will fecth both Survivor and Victim Account details from their external Ids
	// Parameter 1: String survivorUniqueId - Unique External Id of Survivor Account
	// Parameter 2: String victimUniqueId - Unique External Id of Victim Account
	// Return: AccountMergeRequestWarpper - Wrapper Class of both Surviver and Victim Account Details and error messages
	@AuraEnabled
	public static AccountMergeRequestWarpper getAccountDetails(String survivorUniqueId, String victimUniqueId) {
		AccountMergeRequestWarpper res = new AccountMergeRequestWarpper(survivorUniqueId, victimUniqueId);
		return res;
	}

	// Method Name: processAccountMerging
	// Author: Adarsh Sharma
	// Description: Method to start Processing the Account Merge Request
	// Parameter 1: String survivorUniqueId - Unique External Id of Survivor Account
	// Parameter 2: String victimUniqueId - Unique External Id of Victim Account
	// Return: RequestResult - Wrapper Class of Message and a Success Flag
	@AuraEnabled
	public static RequestResult processAccountMerging(String survivorUniqueId, String victimUniqueId) {
		MergeRequestUtility util = new MergeRequestUtility();
		return util.processAccountMerging(survivorUniqueId, victimUniqueId);
	}

	// Method Name: processAccountMergingAsync
	// Author: Adarsh Sharma
	// Description: Method to start Processing the Account Merge Request - Asyncronusly
	// Parameter 1: String survivorUniqueId - Unique External Id of Survivor Account
	// Parameter 2: String victimUniqueId - Unique External Id of Victim Account
	// Return: RequestResult - Wrapper Class of Message and a Success Flag
	@AuraEnabled
	public static RequestResult processAccountMergingAsync(String survivorUniqueId, String victimUniqueId) {
		MergeRequestUtility util = new MergeRequestUtility();
		return util.processAccountMergingAsync(survivorUniqueId, victimUniqueId);
	}

	/****************************************************************************************
	 * All Wrapper Classes
	 ****************************************************************************************/
	// Class Name: RequestResult
	// Author: Adarsh Sharma
	// Description: Wrapper Class of Message and a Success Flag
	public class RequestResult {
		@AuraEnabled
		public Boolean isSuccess = false;
		@AuraEnabled
		public String statusMessage = null;
	}

	// Class Name: AccountMergeRequestWarpper
	// Author: Adarsh Sharma
	// Description: Wrapper Class of both Surviver and Victim Account Details and error messages
	public class AccountMergeRequestWarpper {
		@AuraEnabled
		public AccountRequestWarpper survivor { get; set; }
		@AuraEnabled
		public AccountRequestWarpper victim { get; set; }
		@AuraEnabled
		public List<String> errorMessages { get; set; }
		@AuraEnabled
		public Boolean isAllValid { get; set; }
		@AuraEnabled
		public Integer numberOfChildRecords { get; set; }

		// Constructor: AccountMergeRequestWarpper
		// Author: Adarsh Sharma
		// Description: Constructor to construct the Wrapper Class record
		// Parameter 1: String survivorUniqueId - Unique External Id of Survivor Account
		// Parameter 2: String victimUniqueId - Unique External Id of Victim Account
		public AccountMergeRequestWarpper(String survivorUniqueId, String victimUniqueId) {
			survivor = new AccountRequestWarpper(survivorUniqueId);
			victim = new AccountRequestWarpper(victimUniqueId);
			isAllValid = false;
			numberOfChildRecords = 0;
			errorMessages = new List<String>();
			List<String> softErrors = new List<String>();
			if (String.isBlank(survivor.uniqueId)) {
				softErrors.add(MISSING_SURVIVER_UNIQUE_ID);
			} else if (String.isBlank(victim.uniqueId)) {
				softErrors.add(MISSING_VICTIM_UNIQUE_ID);
			} else if (!survivor.accountFound && !String.isBlank(survivor.uniqueId)) {
				errorMessages.add(INVALID_SURVIVER_UNIQUE_ID);
			} else if (!victim.accountFound && !String.isBlank(victim.uniqueId)) {
				errorMessages.add(INVALID_VICTIM_UNIQUE_ID);
			} else if (survivor.accountFound && victim.accountFound) {
				//There Should not be an Account Merge Request with either Survivor or Victim Account
				Set<String> accUniqueIds = new Set<String>();
				accUniqueIds.add(survivorUniqueId);
				accUniqueIds.add(victimUniqueId);
				for (Account_Merge_Request__c amr : [
					SELECT Id, Survivor_Unique_Id__c, Victim_Unique_Id__c, Status__c
					FROM Account_Merge_Request__c
					WHERE
						Status__c != :AMR_STATUS_COMPLETED
						AND Status__c != :AMR_STATUS_FAILED
						AND (Survivor_Unique_Id__c IN :accUniqueIds
						OR Victim_Unique_Id__c IN :accUniqueIds)
				]) {
					errorMessages.add(
						REQUEST_ALREADY_IN_PROGRESS.replace('{!survivorUniqueId}', amr.Survivor_Unique_Id__c)
							.replace('{!victimUniqueId}', amr.Victim_Unique_Id__c)
					);
				}

				//Both Account Should not be same
				if (survivor.accountObject.Id == victim.accountObject.Id) {
					errorMessages.add(SURVIVER_VICTIM_CANT_SAME);
				}
				//Account Record Type Check
				if (survivor.accountObject.RecordType.Name != victim.accountObject.RecordType.Name) {
					if (
						survivor.accountObject.RecordType.Name != ACCOUNT_RECORD_TYPE_NAME_SITE_SGN ||
						victim.accountObject.RecordType.Name != ACCOUNT_RECORD_TYPE_NAME_SITE_PROSPECT
					) {
						errorMessages.add(RECORD_TYPES_MISSMATCH_FOR_MERGE);
					}
				}
				//Account Country Check
				if (survivor.accountObject.Country__c != victim.accountObject.Country__c) {
					errorMessages.add(COUNTRY_MISSMATCH_FOR_MERGE);
				}

				if (errorMessages.size() == 0 && softErrors.size() == 0) {
					isAllValid = true;
					for (AggregateResult agr : [
						SELECT Count(Id) recordCount
						FROM AccountContactRelation
						WHERE AccountId = :victim.accountObject.Id
					]) {
						numberOfChildRecords += Integer.valueOf(agr.get('recordCount'));
					}

					/*for(AggregateResult agr : [Select Count(Id) recordCount From Account_Team__c Where AccountId__c = :victim.accountObject.Id]){
                        numberOfChildRecords += Integer.valueOf(agr.get('recordCount'));
                    }*/

					for (AggregateResult agr : [
						SELECT Count(Id) recordCount
						FROM ShipTo_BillTo__c
						WHERE Ship_To__c = :victim.accountObject.Id OR Bill_To__c = :victim.accountObject.Id
					]) {
						numberOfChildRecords += Integer.valueOf(agr.get('recordCount'));
					}

					for (AggregateResult agr : [
						SELECT Count(Id) recordCount
						FROM Account
						WHERE
							Parent_Unique_Id__c = :victimUniqueId
							OR Child_Unique_Id__c = :victimUniqueId
							OR Primary_Bill_To_Unique_Id__c = :victimUniqueId
					]) {
						numberOfChildRecords += Integer.valueOf(agr.get('recordCount'));
					}
				}
			}
		}
	}

	// Wrapper Class: AccountRequestWarpper
	// Author: Adarsh Sharma
	// Description: Warpper Class to hold a single account record and its status
	public class AccountRequestWarpper {
		@AuraEnabled
		public String uniqueId { get; set; }
		@AuraEnabled
		public Boolean accountFound { get; set; }
		@AuraEnabled
		public Account accountObject { get; set; }

		// Constructor: AccountRequestWarpper
		// Author: Adarsh Sharma
		// Description: Constructor to construct the Wrapper Class record
		// Parameter 1: String uniqueId - Unique External Id of Account
		public AccountRequestWarpper(String uniqueId) {
			this.uniqueId = uniqueId;
			this.accountFound = false;
			for (Account ob : [
				SELECT
					Id,
					Name,
					RecordType.Name,
					Price_Book__c,
					Street_f__c,
					City_f__c,
					State_f__c,
					Zip_Postal_Code_f__c,
					Country__c,
					ERP_Account_Id__c,
					Customer_Segment__c,
					Unique_Id__c
				FROM Account
				WHERE Unique_Id__c != NULL AND Unique_Id__c = :this.uniqueId
			]) {
				this.accountObject = ob;
				this.accountFound = true;
			}
		}
	}

	// Wrapper Class: MergeRequestUtility
	// Author: Adarsh Sharma
	// Description: Warpper Class hold all Merge related utility methods, Its also running code in System Mode (Withot Sharing)
	public without sharing class MergeRequestUtility {
		// Method Name: processAccountMerging
		// Author: Adarsh Sharma
		// Description: Method to Process Merge request
		// Parameter 1: String survivorUniqueId - Unique External Id of Survivor Account
		// Parameter 2: String victimUniqueId - Unique External Id of Victim Account
		public AccountMergeRequestCtr.RequestResult processAccountMerging(
			String survivorUniqueId,
			String victimUniqueId
		) {
			AccountMergeRequestCtr.RequestResult result = new AccountMergeRequestCtr.RequestResult();
			result.isSuccess = false;
			result.statusMessage = AccountMergeRequestCtr.UNKNOWN_ERROR;
			Map<String, Account> accMap = fetchAccountsForMerge(new Set<String>{ survivorUniqueId, victimUniqueId });
			if (accMap.containsKey(survivorUniqueId) && accMap.containsKey(victimUniqueId)) {
				Savepoint sp = Database.setSavepoint();
				try {
					Account survivorAccount = accMap.get(survivorUniqueId);
					Account victimAccount = accMap.get(victimUniqueId);

					//#1. Flag to notify Account Trigger that it's Account Merge process,
					//so DQ usres can allowed to delete account
					AccountMergeRequestCtr.mergeInProcess = true;

					//ALL PRE MERGE ACTIONS
					//#2. Identify Duplicate Account Contact Records and Delete Them
					//Also Handle the Contact_Account_External_Id__c field
					handleACR(survivorAccount.Id, victimAccount.Id);

					/*/#3. Remove All Victim Account Teams as they Don't need to be moved
					 handleAccountTeam(victimAccount.Id);*/

					//#4. Identify Duplicate Account Contact Records and Delete Them
					//Also Handle the Contact_Account_External_Id__c field
					handleShipToBillTo(survivorAccount.Id, victimAccount.Id);

					//#5. NATIVE MERGE ACTION
					merge survivorAccount victimAccount;

					//#6. Manage Account Hierarchy
					manageAccountHierarchy(survivorUniqueId, victimUniqueId);

					result.isSuccess = true;
				} catch (Exception ex) {
					Database.rollback(sp);
					result.isSuccess = false;
					result.statusMessage = ex.getMessage();
					for (String keyStr : accMergeErrorOverride.keySet()) {
						if (result.statusMessage.contains(keyStr)) {
							result.statusMessage = accMergeErrorOverride.get(keyStr);
						}
					}
					ExceptionHandlerController.createException(
						'AccountMergeRequestCtr',
						'processAccountMerging',
						'Account Merge Request Operation',
						'Account Merge Request Operation',
						ex.getMessage() +
						'\n' +
						ex.getStackTraceString(),
						System.today()
					);
				}
			} else {
				result.statusMessage = AccountMergeRequestCtr.UNABLE_TO_FETCH_ACCOUNTS;
			}
			return result;
		}

		// Method Name: processAccountMergingAsync
		// Author: Adarsh Sharma
		// Description: Method to Process Merge request - Async
		// Parameter 1: String survivorUniqueId - Unique External Id of Survivor Account
		// Parameter 2: String victimUniqueId - Unique External Id of Victim Account
		public AccountMergeRequestCtr.RequestResult processAccountMergingAsync(
			String survivorUniqueId,
			String victimUniqueId
		) {
			AccountMergeRequestCtr.RequestResult result = new AccountMergeRequestCtr.RequestResult();
			result.isSuccess = true;
			result.statusMessage = AccountMergeRequestCtr.UNKNOWN_ERROR;
			Map<String, Account> accMap = fetchAccountsForMerge(new Set<String>{ survivorUniqueId, victimUniqueId });

			if (accMap.containsKey(survivorUniqueId) && accMap.containsKey(victimUniqueId)) {
				Account_Merge_Request__c amr = new Account_Merge_Request__c();
				amr.Survivor_Unique_Id__c = survivorUniqueId;
				amr.Survivor_Id__c = accMap.get(survivorUniqueId).Id;
				amr.Victim_Unique_Id__c = victimUniqueId;
				amr.Victim_Id__c = accMap.get(victimUniqueId).Id;
				amr.Status__c = AMR_STATUS_REQUESTED;
				insert amr;
				Database.executeBatch(new AccountMergeRequestBatch(amr));
			}
			return result;
		}

		// Method Name: handleACR
		// Author: Adarsh Sharma
		// Description: Method to Check for Duplicate Account Contact Relation and Delete them
		// Also Update the new External Ids for the records which going to be Merged
		// Parameter 1: String survivorAccId - Survivor Account Id
		// Parameter 2: String victimAccId - Victim Account Id
		private void handleACR(Id survivorAccId, Id victimAccId) {
			Map<Id, AccountContactRelation> survivorACR = new Map<Id, AccountContactRelation>();
			for (AccountContactRelation acr : [
				SELECT Id, ContactId
				FROM AccountContactRelation
				WHERE AccountId = :survivorAccId
			]) {
				survivorACR.put(acr.ContactId, acr);
			}

			List<AccountContactRelation> duplicateACR = new List<AccountContactRelation>();
			List<AccountContactRelation> updateACRForExternalId = new List<AccountContactRelation>();
			for (AccountContactRelation acr : [
				SELECT Id, ContactId, AccountId, IsDirect, Contact_Account_External_Id__c
				FROM AccountContactRelation
				WHERE AccountId = :victimAccId
			]) {
				if (survivorACR.containsKey(acr.ContactId)) {
					if (!acr.IsDirect) {
						duplicateACR.add(acr);
					} else {
						duplicateACR.add(survivorACR.get(acr.ContactId));

						acr.Contact_Account_External_Id__c = acr.ContactId + '_' + survivorAccId;
						updateACRForExternalId.add(acr);
					}
				} else {
					acr.Contact_Account_External_Id__c = acr.ContactId + '_' + survivorAccId;
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
		// Parameter 1: String survivorAccId - Survivor Account Id
		// Parameter 2: String victimAccId - Victim Account Id
		private void handleShipToBillTo(Id survivorAccId, Id victimAccId) {
			Map<String, ShipTo_BillTo__c> survivorRecords = new Map<String, ShipTo_BillTo__c>();
			for (ShipTo_BillTo__c ob : [
				SELECT Id, Ship_To__c, Bill_To__c, ShipTo_BillTo_External_Id__c
				FROM ShipTo_BillTo__c
				WHERE Ship_To__c = :survivorAccId OR Bill_To__c = :survivorAccId
			]) {
				survivorRecords.put(ob.ShipTo_BillTo_External_Id__c, ob);
			}

			List<ShipTo_BillTo__c> duplicateRecords = new List<ShipTo_BillTo__c>();
			List<ShipTo_BillTo__c> updateForExternalId = new List<ShipTo_BillTo__c>();
			for (ShipTo_BillTo__c ob : [
				SELECT Id, Ship_To__c, Bill_To__c, ShipTo_BillTo_External_Id__c
				FROM ShipTo_BillTo__c
				WHERE Ship_To__c = :victimAccId OR Bill_To__c = :victimAccId
			]) {
				ob.ShipTo_BillTo_External_Id__c = ob.ShipTo_BillTo_External_Id__c.replace(victimAccId, survivorAccId);
				if (survivorRecords.containsKey(ob.ShipTo_BillTo_External_Id__c)) {
					duplicateRecords.add(ob);
				} else {
					updateForExternalId.add(ob);
				}
			}

			if (duplicateRecords.size() > 0) {
				delete duplicateRecords;
			}

			if (updateForExternalId.size() > 0) {
				update updateForExternalId;
			}
		}

		/*/ Method Name: handleAccountTeam
        // Author: Adarsh Sharma
        // Description: Method to Identify and Delete All Victim Account Team Records
        // Parameter 1: String victimAccId - Victim Account Id
        private void handleAccountTeam(Id victimAccId){
            List<Account_Team__c> victimAccountTeams = new List<Account_Team__c>([Select Id From Account_Team__c WHERE AccountId__c = :victimAccId]);
            if(victimAccountTeams.size() > 0){
                delete victimAccountTeams;
            }
        }*/

		// Method Name: manageAccountHierarchy
		// Author: Basant Verma
		// Description: Method to change unique Ids from victimUniqueId to survivorUniqueId on all related Accounts
		// Parameter 1: survivorUniqueId - Survivor Account's Unique Id
		// Parameter 2: victimUniqueId - Victim Account's Unique Id
		// Return: void
		private void manageAccountHierarchy(String survivorUniqueId, String victimUniqueId) {
			List<Account> victimsChildAccounts = new List<Account>(
				[
					SELECT
						Id,
						Name,
						Parent_Unique_Id__c,
						Child_Unique_Id__c,
						Parent_ERP_Account_Id__c,
						Primary_Bill_To_Unique_Id__c
					FROM Account
					WHERE
						Parent_Unique_Id__c = :victimUniqueId
						OR Child_Unique_Id__c = :victimUniqueId
						OR Primary_Bill_To_Unique_Id__c = :victimUniqueId
				]
			);
			String SurvivorERPId = [
				SELECT Id, ERP_Account_Id__c, Unique_Id__c
				FROM Account
				WHERE Unique_Id__c = :survivorUniqueId
			]
			.ERP_Account_Id__c;
			for (Account acc : victimsChildAccounts) {
				if (acc.Parent_Unique_Id__c == victimUniqueId) {
					acc.Parent_Unique_Id__c = survivorUniqueId;
					acc.Parent_ERP_Account_Id__c = SurvivorERPId;
				}
				if (acc.Child_Unique_Id__c == victimUniqueId) {
					acc.Child_Unique_Id__c = survivorUniqueId;
				}
				if (acc.Primary_Bill_To_Unique_Id__c == victimUniqueId) {
					acc.Primary_Bill_To_Unique_Id__c = survivorUniqueId;
				}
			}
			update victimsChildAccounts;
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
	}
}