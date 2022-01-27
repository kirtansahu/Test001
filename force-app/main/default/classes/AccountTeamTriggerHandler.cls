// ===========================================================================
//  Object  : AccountTeamTriggerHandler
//  Company : Keste @ IDC
//  Author  : Abinash Panigrahi -yyyy
//  Purpose : Handler Class contains all logic for AccountTeamTrigger.
// ===========================================================================
public class AccountTeamTriggerHandler {
	//Static Boolean flag to avoid imidiate Execution also block Recursive calls
	public static Boolean avoidImidiateExecution = false;
	//Static Boolean String to Capture Error Message for batch jobs
	public static Exception exceptionObForBatch = null;
	public static Boolean isReTriggerBatch = false;

	public static String ACCOUNT_ACCESSLEVEL = Label.ACCOUNTTEAM_ACCOUNT_ACCESSLEVEL;
	public static String CONTACT_ACCESSLEVEL = Label.ACCOUNTTEAM_CONTACT_ACCESSLEVEL;
	public static String OPPORTUNITY_ACCESSLEVEL = Label.ACCOUNTTEAM_OPPORTUNITY_ACCESSLEVEL;
	public static String CASE_ACCESSLEVEL = Label.ACCOUNTTEAM_CASE_ACCESSLEVEL;
	public static String TEAMMEMBER_ROLE = Label.ACCOUNTTEAM_TEAMMEMBER_ROLE;
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
	public static String BILLTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_BILLTO;
	public static String GSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_GLOBAL_SGN;
	public static String NSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_NATIONAL_SGN;
	//public static Boolean DEBUG = FALSE;

	// Method Name: activeUserCheck
	// Author: Abinash panigrahi
	// Description: Method to control IsActiveUser__c checbox based on User Status
	// Parameter 1: newRec - List of the new versions of the Account_Team__c records
	// Return: Null
	public static void activeUserCheck(List<Account_Team__c> newRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTeamTriggerHandler.activeUserCheck')) {
			CommonUtilities.debug('Inside activeUserCheck Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Map Instance to store User RecordId and Active flag
			Map<Id, Boolean> userMap = new Map<Id, Boolean>();
			//Lopp Logic to populate the instance
			for (Account_Team__c at : newRec) {
				if (at.UserId__c != null) {
					userMap.put(at.UserId__c, false);
				}
			}
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Fetch related User records to determine their Active/Inactive status
			for (User u : [SELECT Id, isActive FROM User WHERE Id IN :userMap.keySet() AND isActive = TRUE]) {
				userMap.put(u.Id, u.IsActive);
			}

			CommonUtilities.debug('userMap------->>>>>>>' + userMap);

			//Loop Logic
			//Update Account Team records with IssActiveUser__c checkbox
			for (Account_Team__c at : newRec) {
				if (at.UserId__c != null && userMap.containsKey(at.UserId__c) && userMap.get(at.UserId__c)) {
					at.IsUserActive__c = true;
				}
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit activeUserCheck Method');
		}
	}

	// Method Name: updateInactiveTeamMemeber
	// Author: Abinash panigrahi
	// Description: Method to re-trigger all logic for User marked as activated
	// Parameter 1: newRec - List of the new versions of the Account_Team__c records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Account_Team__c records.
	// Return: Null
	public static void updateInactiveTeamMemeber(List<Account_Team__c> newRec, Map<Id, Account_Team__c> oldMap) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('AccountTeamTriggerHandler.updateInactiveTeamMemeber') &&
			!avoidImidiateExecution
		) {
			CommonUtilities.debug('Inside updateInactiveTeamMemeber Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store updated Account Team records
			List<Account_Team__c> toBeUpdateRec = new List<Account_Team__c>();
			//Check if IsActiveUser__c checkbox field is modified or not
			for (Account_Team__c at : newRec) {
				if (
					at.IsUserActive__c && (at.IsUserActive__c != oldMap.get(at.Id).IsUserActive__c || isReTriggerBatch)
				) {
					toBeUpdateRec.add(at);
				}
			}

			CommonUtilities.debug('toBeUpdateRec------->>>>>>>' + toBeUpdateRec);

			//Run the Trigger logic again for these updated Active User
			if (toBeUpdateRec.size() > 0) {
				insertAccountTeamMember(toBeUpdateRec);
			}
			CommonUtilities.debug('Exit updateInactiveTeamMemeber Method');
		}
	}

	// Method Name: insertAccountTeamMember
	// Author: Abinash panigrahi
	// Description: Method to insert standard AccountTeamMember records inorder to keep it in sync
	// Parameter 1: newRec - List of the new versions of the Account_Team__c records
	// Return: Null
	// Changes Impact: AccountTriggerHandler, ParentalSetupAccountTeamCascade_Batch
	public static void insertAccountTeamMember(List<Account_Team__c> newRecs) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('AccountTeamTriggerHandler.insertAccountTeamMember') &&
			!avoidImidiateExecution
		) {
			CommonUtilities.debug('Inside insertAccountTeamMember Method');
			CommonUtilities.debug('newRecs------->>>>>>>' + newRecs);

			//Instance to store only records assosiated with Active users
			List<Account_Team__c> newRec = new List<Account_Team__c>();
			//Active User Check Condition
			for (Account_Team__c at : newRecs) {
				String recordType = at.Account_Unique_Id__c;
				if (at.IsUserActive__c && recordType != null && recordType.contains('_SGN_')) {
					newRec.add(at);
				}
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Instance to store unique Account Ids
			Set<Id> siteSGNIds = new Set<Id>();
			Set<Id> nsgnIds = new Set<Id>();
			Set<Id> shipToIds = new Set<Id>();

			//Instance to store the relationship between AccountId and custom Account Teams
			Map<Id, List<Account_Team__c>> accountTeamMap = new Map<Id, List<Account_Team__c>>();

			//Loop Logic
			//To populate the accountTeamMap relationship with all existing values
			for (Account_Team__c at : newRec) {
				siteSGNIds.add(at.AccountId__c);

				//Check if Account Team already exist
				if (!accountTeamMap.containsKey(at.AccountId__c)) {
					accountTeamMap.put(at.AccountId__c, new List<Account_Team__c>());
				}
				//Update the map with current Account Team value
				accountTeamMap.get(at.AccountId__c).add(at);
			}

			CommonUtilities.debug('siteSGNIds------->>>>>>>' + siteSGNIds);
			CommonUtilities.debug('accountTeamMap------->>>>>>>' + accountTeamMap);
			CommonUtilities.debug('accountTeamMap.size()------->>>>>>>' + accountTeamMap.size());

			//Loop Logic
			//NSGN Account-- Cascade Up Account Team from Site SGN Accounts
			//Fetch all related Parent Account records
			for (Account a : [
				SELECT Id, ParentId
				FROM Account
				WHERE Id IN :siteSGNIds AND RecordType.Name = :SGN_RECORDTYPE_NAME
			]) {
				//Null Check
				if (a.ParentId != null) {
					nsgnIds.add(a.ParentId);

					List<Account_Team__c> nsgnAccTeam;
					//Check if Account Team already exists
					if (accountTeamMap.get(a.ParentId) != null) {
						nsgnAccTeam = accountTeamMap.get(a.ParentId);
					} else {
						nsgnAccTeam = new List<Account_Team__c>();
					}
					//Load up Site SGN Account's Account Team records
					List<Account_Team__c> siteSGNAccTeam = accountTeamMap.get(a.Id);
					//Replicate Account Team records
					for (Account_Team__c at : siteSGNAccTeam) {
						Account_Team__c obj = new Account_Team__c(
							AccountId__c = a.ParentId,
							UserId__c = at.UserId__c,
							TeamMemberRole__c = at.TeamMemberRole__c,
							AccountAccessLevel__c = at.AccountAccessLevel__c,
							CaseAccessLevel__c = at.CaseAccessLevel__c,
							ContactAccessLevel__c = at.ContactAccessLevel__c,
							OpportunityAccessLevel__c = at.OpportunityAccessLevel__c
						);
						nsgnAccTeam.add(obj);
					}

					//Update Map values
					accountTeamMap.put(a.ParentId, nsgnAccTeam);
				}
			}

			CommonUtilities.debug('nsgnIds------->>>>>>>' + nsgnIds);
			CommonUtilities.debug('accountTeamMap------->>>>>>>' + accountTeamMap);
			CommonUtilities.debug('accountTeamMap.size()------->>>>>>>' + accountTeamMap.size());
			//Loop Logic
			//GSGN Account-- Cascade Up Account Team from NSGN Accounts
			//Fetch all related Parent Account records
			for (Account a : [
				SELECT Id, ParentId
				FROM Account
				WHERE Id IN :nsgnIds AND RecordType.Name = :NSGN_RECORDTYPE_NAME
			]) {
				//Null Check
				if (a.ParentId != null) {
					List<Account_Team__c> gsgnAccTeam;
					//Check if Account Team already exists
					if (accountTeamMap.get(a.ParentId) != null) {
						gsgnAccTeam = accountTeamMap.get(a.ParentId);
					} else {
						gsgnAccTeam = new List<Account_Team__c>();
					}
					//Load up NSGN Account's Account Team records
					List<Account_Team__c> nsgnAccTeam = accountTeamMap.get(a.Id);
					//Replicate Account Team records
					for (Account_Team__c at : nsgnAccTeam) {
						Account_Team__c obj = new Account_Team__c(
							AccountId__c = a.ParentId,
							UserId__c = at.UserId__c,
							TeamMemberRole__c = at.TeamMemberRole__c,
							AccountAccessLevel__c = at.AccountAccessLevel__c,
							CaseAccessLevel__c = at.CaseAccessLevel__c,
							ContactAccessLevel__c = at.ContactAccessLevel__c,
							OpportunityAccessLevel__c = at.OpportunityAccessLevel__c
						);
						gsgnAccTeam.add(obj);
					}

					//Update Map values
					accountTeamMap.put(a.ParentId, gsgnAccTeam);
				}
			}

			CommonUtilities.debug('accountTeamMap------->>>>>>>' + accountTeamMap);
			CommonUtilities.debug('accountTeamMap.size()------->>>>>>>' + accountTeamMap.size());

			//Instance to store BillTo UniqueIds
			Set<String> billToUniqueIds = new Set<String>();

			//Loop Logic
			//ShipTo Account-- Cascade Down Account Team from Site SGN Accounts
			//Fetch all related Child Account records
			for (Account a : [
				SELECT Id, ParentId, Primary_Bill_To_Unique_Id__c, Child_Unique_Id__c
				FROM Account
				WHERE ParentId IN :siteSGNIds AND RecordType.Name = :SHIPTO_RECORDTYPE_NAME
			]) {
				//Null Check
				if (a.ParentId != null) {
					shipToIds.add(a.Id);

					//Populate Billto UniqueIds
					if (a.Primary_Bill_To_Unique_Id__c != null) {
						billToUniqueIds.add(a.Primary_Bill_To_Unique_Id__c);
					}
					if (a.Child_Unique_Id__c != null) {
						billToUniqueIds.add(a.Child_Unique_Id__c);
					}
					List<Account_Team__c> shipToAccTeam;
					//Check if Account Team already exists
					if (accountTeamMap.get(a.Id) != null) {
						shipToAccTeam = accountTeamMap.get(a.Id);
					} else {
						shipToAccTeam = new List<Account_Team__c>();
					}
					//Load up NSGN Account's Account Team records
					List<Account_Team__c> siteSGNAccTeam = accountTeamMap.get(a.ParentId);
					//Replicate Account Team records
					for (Account_Team__c at : siteSGNAccTeam) {
						Account_Team__c obj = new Account_Team__c(
							AccountId__c = a.Id,
							UserId__c = at.UserId__c,
							TeamMemberRole__c = at.TeamMemberRole__c,
							AccountAccessLevel__c = at.AccountAccessLevel__c,
							CaseAccessLevel__c = at.CaseAccessLevel__c,
							ContactAccessLevel__c = at.ContactAccessLevel__c,
							OpportunityAccessLevel__c = at.OpportunityAccessLevel__c
						);
						shipToAccTeam.add(obj);
					}

					//Update Map values
					accountTeamMap.put(a.Id, shipToAccTeam);
				}
			}

			CommonUtilities.debug('accountTeamMap------->>>>>>>' + accountTeamMap);
			CommonUtilities.debug('accountTeamMap.size()------->>>>>>>' + accountTeamMap.size());
			CommonUtilities.debug('billToUniqueIds------->>>>>>>' + billToUniqueIds);
			CommonUtilities.debug('billToUniqueIds.size()------->>>>>>>' + billToUniqueIds.size());

			//Instance to map the relationship between BillTo UniqueIds and RecordIds
			Map<String, Id> billToIdMap = new Map<String, Id>();
			//Fetch related BillTo Recordtype Accounts
			for (Account a : [SELECT Id, Unique_Id__c FROM Account WHERE Unique_Id__c IN :billToUniqueIds]) {
				billToIdMap.put(a.Unique_Id__c, a.Id);
			}

			CommonUtilities.debug('billToIdMap------->>>>>>>' + billToIdMap);
			CommonUtilities.debug('billToIdMap.size()------->>>>>>>' + billToIdMap.size());

			//Loop Logic
			//BillTo Account-- Cascade Down Account Team from ShipTo Accounts
			//Fetch all related Child Account records
			for (Account a : [
				SELECT Id, ParentId, Primary_Bill_To_Unique_Id__c, Child_Unique_Id__c
				FROM Account
				WHERE Id IN :shipToIds AND RecordType.Name = :SHIPTO_RECORDTYPE_NAME
			]) {
				//Check for NULL values
				if (a.Primary_Bill_To_Unique_Id__c != null && billToIdMap.get(a.Primary_Bill_To_Unique_Id__c) != null) {
					List<Account_Team__c> billToAccTeam;
					//Check if Account Team already exists
					if (accountTeamMap.get(billToIdMap.get(a.Primary_Bill_To_Unique_Id__c)) != null) {
						billToAccTeam = accountTeamMap.get(billToIdMap.get(a.Primary_Bill_To_Unique_Id__c));
					} else {
						billToAccTeam = new List<Account_Team__c>();
					}
					//Load up ShipTo Account's Account Team records
					List<Account_Team__c> shipToAccTeam = accountTeamMap.get(a.Id);
					//Replicate Account Team records
					for (Account_Team__c at : shipToAccTeam) {
						Account_Team__c obj = new Account_Team__c(
							AccountId__c = billToIdMap.get(a.Primary_Bill_To_Unique_Id__c),
							UserId__c = at.UserId__c,
							TeamMemberRole__c = at.TeamMemberRole__c,
							AccountAccessLevel__c = at.AccountAccessLevel__c,
							CaseAccessLevel__c = at.CaseAccessLevel__c,
							ContactAccessLevel__c = at.ContactAccessLevel__c,
							OpportunityAccessLevel__c = at.OpportunityAccessLevel__c
						);
						billToAccTeam.add(obj);
					}

					//Update Map values
					accountTeamMap.put(billToIdMap.get(a.Primary_Bill_To_Unique_Id__c), billToAccTeam);
				}

				//Check for NULL values
				if (a.Child_Unique_Id__c != null && billToIdMap.get(a.Child_Unique_Id__c) != null) {
					List<Account_Team__c> billToAccTeam;
					//Check if Account Team already exists
					if (accountTeamMap.get(billToIdMap.get(a.Child_Unique_Id__c)) != null) {
						billToAccTeam = accountTeamMap.get(billToIdMap.get(a.Child_Unique_Id__c));
					} else {
						billToAccTeam = new List<Account_Team__c>();
					}

					//Load up ShipTo Account's Account Team records
					List<Account_Team__c> shipToAccTeam = accountTeamMap.get(a.Id);
					//Replicate Account Team records
					for (Account_Team__c at : shipToAccTeam) {
						Account_Team__c obj = new Account_Team__c(
							AccountId__c = billToIdMap.get(a.Child_Unique_Id__c),
							UserId__c = at.UserId__c,
							TeamMemberRole__c = at.TeamMemberRole__c,
							AccountAccessLevel__c = at.AccountAccessLevel__c,
							CaseAccessLevel__c = at.CaseAccessLevel__c,
							ContactAccessLevel__c = at.ContactAccessLevel__c,
							OpportunityAccessLevel__c = at.OpportunityAccessLevel__c
						);
						billToAccTeam.add(obj);
					}

					//Update Map values
					accountTeamMap.put(billToIdMap.get(a.Child_Unique_Id__c), billToAccTeam);
				}
			}

			CommonUtilities.debug('accountTeamMap------->>>>>>>' + accountTeamMap);
			CommonUtilities.debug('accountTeamMap.size()------->>>>>>>' + accountTeamMap.size());

			//Instance to store all to be inserted AccountTeamMember records
			Set<AccountTeamMember> toInsertRec = new Set<AccountTeamMember>();
			List<AccountTeamMember> toInsertRecList = new List<AccountTeamMember>();
			Map<String, Account_Team__c> customAccountTeamMap = new Map<String, Account_Team__c>();
			//Populate AccountTeamMember records by replica of Custom Account Team records
			for (Id i : accountTeamMap.keySet()) {
				List<Account_Team__c> temp = accountTeamMap.get(i);
				for (Account_Team__c at : temp) {
					String uniqueKey = at.AccountId__c + '_' + at.UserId__c;
					if (!customAccountTeamMap.containsKey(uniqueKey)) {
						AccountTeamMember obj = new AccountTeamMember();
						obj.AccountId = at.AccountId__c;
						obj.UserId = at.UserId__c;
						obj.AccountAccessLevel = ACCOUNT_ACCESSLEVEL;
						obj.ContactAccessLevel = CONTACT_ACCESSLEVEL;
						obj.CaseAccessLevel = CASE_ACCESSLEVEL;
						obj.OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL;
						obj.TeamMemberRole = TEAMMEMBER_ROLE;
						toInsertRec.add(obj);
						customAccountTeamMap.put(uniqueKey, at);
					}
				}
			}

			CommonUtilities.debug('toInsertRec------->>>>>>>' + toInsertRec);
			CommonUtilities.debug('toInsertRec.size()------->>>>>>>' + toInsertRec.size());

			toInsertRecList.addAll(toInsertRec);

			CommonUtilities.debug('toInsertRecList------->>>>>>>' + toInsertRecList);
			CommonUtilities.debug('toInsertRecList.size()------->>>>>>>' + toInsertRecList.size());

			//Exception Handling
			//Insert AccountTeamMember
			try {
				if (toInsertRecList.size() > 0) {
					//insert toInsertRecList;
					Database.SaveResult[] lstInsertResult = Database.insert(toInsertRecList, false);
					List<Account_Team__c> lstATToUpdate = new List<Account_Team__c>();
					for (Integer i = 0; i < toInsertRecList.size(); i++) {
						Database.SaveResult insertResult = lstInsertResult[i];
						if (!insertResult.isSuccess()) {
							AccountTeamMember at = toInsertRecList[i];
							String uniqueKey = at.AccountId + '_' + at.UserId;
							if (
								customAccountTeamMap.containsKey(uniqueKey) &&
								customAccountTeamMap.get(uniqueKey).Id != null
							) {
								Account_Team__c customAt = new Account_Team__c(
									Id = customAccountTeamMap.get(uniqueKey).Id
								);
								customAt.ReTrigger__c = true;
								customAt.IsUserActive__c = false;
								lstATToUpdate.add(customAt);
							}
						}
					}
					if (lstATToUpdate.size() > 0) {
						avoidImidiateExecution = true;
						update lstATToUpdate;
					}
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'AccountTeamTriggerHandler',
					'insertAccountTeamMember',
					'Trigger Logic',
					'Insert AccountTeamMember',
					ex.getMessage(),
					System.today()
				);
				CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
				if (System.isBatch()) {
					exceptionObForBatch = ex;
				}
			}
			CommonUtilities.debug('Exit insertAccountTeamMember Method');
		}
	}

	// Method Name: deleteAccountTeamMember
	// Author: Abinash panigrahi
	// Description: Method to delete standard AccountTeamMember records inorder to keep it in sync
	// Parameter 1: oldRec - List of the deleted versions of the Account_Team__c records
	// Return: Null
	// Changes Impact: AccountTriggerHandler, ParentalSetupAccountTeamCascade_Batch
	public static void deleteAccountTeamMember(List<Account_Team__c> oldRecs) {
		//if(boolean.valueOf(Label.AccountTeam_deleteAccountTeamMember)){
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTeamTriggerHandler.deleteAccountTeamMember')) {
			CommonUtilities.debug('Inside deleteAccountTeamMember Method');
			CommonUtilities.debug('oldRecs------->>>>>>>' + oldRecs);

			//Instance to store duplicate record counts
			Map<String, List<Account_Team__c>> duplicateCount = new Map<String, List<Account_Team__c>>();
			Map<String, List<Account_Team__c>> matchDuplicate = new Map<String, List<Account_Team__c>>();
			//Instance to set Account and User recordids
			Set<Id> accIds = new Set<Id>();
			Set<Id> userIds = new Set<Id>();
			//Loop Logic
			//Maintain Count within the Batch Record domain
			for (Account_Team__c at : oldRecs) {
				if (!duplicateCount.containsKey(at.Match_Duplicate__c)) {
					duplicateCount.put(at.Match_Duplicate__c, new List<Account_Team__c>());
				}
				duplicateCount.get(at.Match_Duplicate__c).add(at);

				accIds.add(at.AccountId__c);
				userIds.add(at.UserId__c);
			}
			//Loop Logic
			//Maintain Duplicate record Count within the entire Org domain
			for (Account_Team__c at : [
				SELECT Id, Match_Duplicate__c
				FROM Account_Team__c
				WHERE
					Match_Duplicate__c IN :duplicateCount.keySet()
					AND AccountId__c IN :accIds
					AND UserId__c IN :userIds
			]) {
				if (!matchDuplicate.containsKey(at.Match_Duplicate__c)) {
					matchDuplicate.put(at.Match_Duplicate__c, new List<Account_Team__c>());
				}
				matchDuplicate.get(at.Match_Duplicate__c).add(at);
			}

			CommonUtilities.debug('duplicateCount------->>>>>>>' + duplicateCount);
			CommonUtilities.debug('duplicateCount.size()------->>>>>>>' + duplicateCount.size());
			CommonUtilities.debug('matchDuplicate------->>>>>>>' + matchDuplicate);
			CommonUtilities.debug('matchDuplicate.size()------->>>>>>>' + matchDuplicate.size());

			//Instance to store the records to be Deleted
			List<Account_Team__c> oldRec = new List<Account_Team__c>();
			//Loop Logic
			//If duplicate record exists, ignore Delete Cascading Logic of Account Team Member
			for (String s : duplicateCount.keyset()) {
				if (duplicateCount.get(s).size() == matchDuplicate.get(s).size()) {
					oldRec.addAll(duplicateCount.get(s));
				}
			}

			CommonUtilities.debug('oldRec------->>>>>>>' + oldRec);
			CommonUtilities.debug('oldRec.size()------->>>>>>>' + oldRec.size());

			//Instance to store Account RecordIds of deleted custom Account Team
			Set<Id> siteSGNIds = new Set<Id>();
			//Instance to store User assosiated with deleted custom Account Team
			Map<Id, List<Id>> userAccountMap = new Map<Id, List<Id>>();
			//Loop Logic
			//To Populate above Instances with values
			for (Account_Team__c at : oldRec) {
				siteSGNIds.add(at.AccountId__c);

				if (!userAccountMap.containsKey(at.AccountId__c)) {
					userAccountMap.put(at.AccountId__c, new List<Id>());
				}
				userAccountMap.get(at.AccountId__c).add(at.UserId__c);
			}

			CommonUtilities.debug('siteSGNIds------->>>>>>>' + siteSGNIds);
			CommonUtilities.debug('siteSGNIds.size()------->>>>>>>' + siteSGNIds.size());
			CommonUtilities.debug('userAccountMap------->>>>>>>' + userAccountMap);
			CommonUtilities.debug('userAccountMap.size()------->>>>>>>' + userAccountMap.size());
			//Instance to store the relationship between SGN Account records with its whole Account Hierarchy records
			Map<Id, Set<Id>> accHierarchyMap = new Map<Id, Set<Id>>();
			//Loop Logic
			//Fetch all SGN Account RecordType along with NSGN and GSGN RecordId
			//To populate Account Hierarchy map
			for (Account a : [
				SELECT Id, ParentId, Parent.ParentId
				FROM Account
				WHERE Id IN :siteSGNIds AND RecordType.Name = :SGN_RECORDTYPE_NAME
			]) {
				//Null Check
				if (!accHierarchyMap.containsKey(a.Id)) {
					accHierarchyMap.put(a.Id, new Set<Id>());
				}
				//Account recordId present higher in Account hierarchy
				if (a.ParentId != null) {
					accHierarchyMap.get(a.Id).add(a.ParentId);
				}
				if (a.Parent.ParentId != null) {
					accHierarchyMap.get(a.Id).add(a.Parent.ParentId);
				}
			}

			CommonUtilities.debug('accHierarchyMap------->>>>>>>' + accHierarchyMap);
			CommonUtilities.debug('accHierarchyMap.size()------->>>>>>>' + accHierarchyMap.size());

			//Instance to store BillTo record UniqueIds
			Set<String> billToUniqueIds = new Set<String>();
			//Loop Logic
			//Fetch all ShipTo Account RecordType related to SGNs
			//To populate Account Hierarchy map
			for (Account a : [
				SELECT Id, ParentId, Primary_Bill_To_Unique_Id__c, Child_Unique_Id__c
				FROM Account
				WHERE ParentId IN :siteSGNIds AND RecordType.Name = :SHIPTO_RECORDTYPE_NAME
			]) {
				if (a.Primary_Bill_To_Unique_Id__c != null) {
					billToUniqueIds.add(a.Primary_Bill_To_Unique_Id__c);
				}
				if (a.Child_Unique_Id__c != null) {
					billToUniqueIds.add(a.Child_Unique_Id__c);
				}

				if (!accHierarchyMap.containsKey(a.ParentId)) {
					accHierarchyMap.put(a.ParentId, new Set<Id>());
				}
				accHierarchyMap.get(a.ParentId).add(a.Id);
			}

			CommonUtilities.debug('accHierarchyMap------->>>>>>>' + accHierarchyMap);
			CommonUtilities.debug('accHierarchyMap.size()------->>>>>>>' + accHierarchyMap.size());
			CommonUtilities.debug('billToUniqueIds------->>>>>>>' + billToUniqueIds);
			CommonUtilities.debug('billToUniqueIds.size()------->>>>>>>' + billToUniqueIds.size());

			//Instance to map the relationship between BillTo UniqueIds and RecordIds
			Map<String, Id> billToIdMap = new Map<String, Id>();
			//Fetch related BillTo Recordtype Accounts
			for (Account a : [SELECT Id, Unique_Id__c FROM Account WHERE Unique_Id__c IN :billToUniqueIds]) {
				billToIdMap.put(a.Unique_Id__c, a.Id);
			}

			CommonUtilities.debug('billToIdMap------->>>>>>>' + billToIdMap);
			CommonUtilities.debug('billToIdMap.size()------->>>>>>>' + billToIdMap.size());

			//Loop Logic
			//Fetch all related Junction Object records which refers to ShipTo-BillTo relationship
			//Fetch BillTo Account RecordIds
			for (Account a : [
				SELECT Id, ParentId, Primary_Bill_To_Unique_Id__c, Child_Unique_Id__c
				FROM Account
				WHERE ParentId IN :siteSGNIds AND RecordType.Name = :SHIPTO_RECORDTYPE_NAME
			]) {
				if (!accHierarchyMap.containsKey(a.ParentId)) {
					accHierarchyMap.put(a.ParentId, new Set<Id>());
				}

				if (a.Primary_Bill_To_Unique_Id__c != null && billToIdMap.get(a.Primary_Bill_To_Unique_Id__c) != null) {
					accHierarchyMap.get(a.ParentId).add(billToIdMap.get(a.Primary_Bill_To_Unique_Id__c));
				}

				if (a.Child_Unique_Id__c != null && billToIdMap.get(a.Child_Unique_Id__c) != null) {
					accHierarchyMap.get(a.ParentId).add(billToIdMap.get(a.Child_Unique_Id__c));
				}
			}

			CommonUtilities.debug('accHierarchyMap------->>>>>>>' + accHierarchyMap);
			CommonUtilities.debug('accHierarchyMap.size()------->>>>>>>' + accHierarchyMap.size());

			//Instance to accumulate all Account RecordIds
			Set<Id> allAccountIds = new Set<Id>();
			allAccountIds.addAll(siteSGNIds);
			for (Set<Id> idSet : accHierarchyMap.values()) {
				for (Id i : idSet) {
					allAccountIds.add(i);
				}
			}

			CommonUtilities.debug('allAccountIds------->>>>>>>' + allAccountIds);
			CommonUtilities.debug('allAccountIds.size()------->>>>>>>' + allAccountIds.size());

			//Instance to store standard AccountTeamMember records which is to be deleted
			Set<AccountTeamMember> toBeDeletedRec = new Set<AccountTeamMember>();
			List<AccountTeamMember> toBeDeletedRecList = new List<AccountTeamMember>();
			//Loop Logic
			//Fetch only relevant AccountTeamMember records assosiated with deleted Custom Account team
			//Populate above Instance with values
			for (AccountTeamMember atm : [
				SELECT Id, AccountId, UserId
				FROM AccountTeamMember
				WHERE AccountId IN :allAccountIds AND UserId IN :userIds
			]) {
				for (Id i : siteSGNIds) {
					if (accHierarchyMap.get(i) != null && userAccountMap.get(i) != null) {
						if (
							(accHierarchyMap.get(i).contains(atm.AccountId) &&
							userAccountMap.get(i).contains(atm.UserId)) ||
							(i == atm.AccountId && userAccountMap.get(i).contains(atm.UserId))
						) {
							toBeDeletedRec.add(new AccountTeamMember(Id = atm.Id));
						}
					}
				}
			}

			CommonUtilities.debug('toBeDeletedRec------->>>>>>>' + toBeDeletedRec);
			CommonUtilities.debug('toBeDeletedRec.size()------->>>>>>>' + toBeDeletedRec.size());

			toBeDeletedRecList.addAll(toBeDeletedRec);

			//Exception Handling
			//Delete AccountTeamMember
			try {
				if (toBeDeletedRecList.size() > 0) {
					delete toBeDeletedRecList;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'AccountTeamTriggerHandler',
					'deleteAccountTeamMember',
					'Trigger Logic',
					'Delete AccountTeamMember',
					ex.getMessage(),
					System.today()
				);
				CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
			}

			//Instance to store Parent Account record info - unique User, ParentId and Grand ParentId
			Set<Id> parentAccIds = new Set<Id>();
			Set<Id> grandParentAccIds = new Set<Id>();
			Set<Id> userRecordIds = new Set<Id>();
			//Instance to store string combination of Parent/GrandParent Account and User recordId
			Set<String> parentAccUnique = new Set<String>();
			Set<String> grandParentAccUnique = new Set<String>();

			//Loop Logic
			//To find sibling SGN record belonging to same Hierarchy and similar Account Team records
			for (Account_Team__c at : oldRec) {
				//Store Parent Related Information -- For Sibling Account Team record Logic
				if (at.Parent_Id__c != null || at.Parent_Id__c != '') {
					userRecordIds.add(at.UserId__c);
					parentAccIds.add(at.Parent_Id__c);
					if (at.Hierarchy__c != null)
						parentAccUnique.add(at.Hierarchy__c);
				}
				if (at.Parent_New_Id__c != null || at.Parent_New_Id__c != '') {
					userRecordIds.add(at.UserId__c);
					grandParentAccIds.add(at.Parent_New_Id__c);
					if (at.Hierarchy_New__c != null)
						grandParentAccUnique.add(at.Hierarchy_New__c);
				}
			}

			CommonUtilities.debug('userRecordIds------->>>>>>>' + userRecordIds);
			CommonUtilities.debug('userRecordIds.size()------->>>>>>>' + userRecordIds.size());
			CommonUtilities.debug('parentAccIds------->>>>>>>' + parentAccIds);
			CommonUtilities.debug('parentAccIds.size()------->>>>>>>' + parentAccIds.size());
			CommonUtilities.debug('grandParentAccIds------->>>>>>>' + grandParentAccIds);
			CommonUtilities.debug('grandParentAccIds.size()------->>>>>>>' + grandParentAccIds.size());
			CommonUtilities.debug('parentAccUnique------->>>>>>>' + parentAccUnique);
			CommonUtilities.debug('parentAccUnique.size()------->>>>>>>' + parentAccUnique.size());
			CommonUtilities.debug('grandParentAccUnique------->>>>>>>' + grandParentAccUnique);
			CommonUtilities.debug('grandParentAccUnique.size()------->>>>>>>' + grandParentAccUnique.size());

			//Sibling Record Identification Logic
			//Instance to store already existing Account Team records string combination
			Set<String> siblingRecordExist = new Set<String>();
			//Fetch related sibling Account Team records to decide whether to skip Delete Cascading for hierarchy at NSGN and GSGN
			for (Account_Team__c at : [
				SELECT Id, Hierarchy_New__c, Hierarchy__c
				FROM Account_Team__c
				WHERE
					UserId__c IN :userRecordIds
					AND UserId__r.isActive = TRUE
					AND Id NOT IN :oldRec
					AND ((Parent_Id__c IN :parentAccIds
					AND Hierarchy__c IN :parentAccUnique)
					OR (Parent_New_Id__c IN :grandParentAccIds
					AND Parent_Id__c NOT IN :parentAccIds
					AND Hierarchy_New__c IN :grandParentAccUnique))
			]) {
				if (at.Hierarchy__c != null || at.Hierarchy__c != '')
					siblingRecordExist.add(at.Hierarchy__c);
				if (at.Hierarchy_New__c != null || at.Hierarchy_New__c != '')
					siblingRecordExist.add(at.Hierarchy_New__c);
			}

			CommonUtilities.debug('siblingRecordExist------->>>>>>>' + siblingRecordExist);
			CommonUtilities.debug('siblingRecordExist.size()------->>>>>>>' + siblingRecordExist.size());

			//Instance to store all to be inserted AccountTeamMember records
			List<AccountTeamMember> toInsertRecList = new List<AccountTeamMember>();
			//Populate AccountTeamMember records by replica of Custom Account Team records
			for (String s : siblingRecordExist) {
				if (s != null && s.contains('_')) {
					String[] tempIds = s.split('_');
					if (tempIds.size() == 2 && !tempIds.contains(null)) {
						AccountTeamMember obj = new AccountTeamMember();
						obj.AccountId = tempIds[0];
						obj.UserId = tempIds[1];
						obj.AccountAccessLevel = ACCOUNT_ACCESSLEVEL;
						obj.ContactAccessLevel = CONTACT_ACCESSLEVEL;
						obj.CaseAccessLevel = CASE_ACCESSLEVEL;
						obj.OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL;
						obj.TeamMemberRole = TEAMMEMBER_ROLE;
						toInsertRecList.add(obj);
					}
				}
			}

			CommonUtilities.debug('toInsertRecList------->>>>>>>' + toInsertRecList);
			CommonUtilities.debug('toInsertRecList.size()------->>>>>>>' + toInsertRecList.size());

			//Exception Handling
			//Insert AccountTeamMember
			try {
				if (toInsertRecList.size() > 0) {
					insert toInsertRecList;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'AccountTeamTriggerHandler',
					'deleteAccountTeamMember',
					'Trigger Logic',
					'Insert AccountTeamMember',
					ex.getMessage(),
					System.today()
				);
				CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
			}

			CommonUtilities.debug('Exit deleteAccountTeamMember Method');
		}
	}

	// Method Name: prospectAccountAccessAddition
	// Author: Abinash panigrahi
	// Description: Method to give Sales Rep access to Prospect Account - exlcluding No Account Links
	// Parameter 1: newRec - List of the new versions of the Account_Team__c records
	// Return: Null
	public static void prospectAccountAccessAddition(List<Account_Team__c> newRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountTeamTriggerHandler.prospectAccountAccessAddition')) {
			CommonUtilities.debug('Inside prospectAccountAccessAddition Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Add Account Teams - Sales Rep
			List<AccountTeamMember> userToBeAdded = new List<AccountTeamMember>();
			for (Account_Team__c rec : newRec) {
				//Check if only Prospect Account
				if (rec.Account_Record_Type__c == 'Prospect') {
					AccountTeamMember obj = new AccountTeamMember();
					obj.AccountId = rec.AccountId__c;
					obj.UserId = rec.UserId__c;
					obj.AccountAccessLevel = ACCOUNT_ACCESSLEVEL;
					obj.ContactAccessLevel = CONTACT_ACCESSLEVEL;
					obj.CaseAccessLevel = CASE_ACCESSLEVEL;
					obj.OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL;
					obj.TeamMemberRole = TEAMMEMBER_ROLE;
					userToBeAdded.add(obj);
				}
			}

			//Insert Account Team Member records
			try {
				if (userToBeAdded.size() > 0) {
					insert userToBeAdded;
				}
			} catch (Exception ex) {
				//Create Apex Log
				ExceptionHandlerController.createException(
					'AccountTeamTriggerHandler',
					'prospectAccountAccessAddition',
					'Trigger Logic',
					'Insert AccountTeamMember',
					ex.getMessage(),
					System.today()
				);
				CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
			}

			CommonUtilities.debug('Exit prospectAccountAccessAddition Method');
		}
	}
}
