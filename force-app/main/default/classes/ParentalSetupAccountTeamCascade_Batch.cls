// ===========================================================================
//  Object: ParentalSetupAccountTeamCascade_Batch
// Company: Keste @ IDC
//  Author: Abinash Panigrahi
// Purpose: Batch Class to setup Parenting structure based on External Unique Ids supplied in Integration
//					and Account Team Addition - Cascade up and Cascade down team members.
// ===========================================================================
// Changes Impact: AccountTriggerHandler, AccountTeamTriggerHandler
// ===========================================================================
global with sharing class ParentalSetupAccountTeamCascade_Batch implements Database.Batchable<sObject> {
	public static String ACCOUNT_ACCESSLEVEL = Label.ACCOUNTTEAM_ACCOUNT_ACCESSLEVEL;
	public static String CONTACT_ACCESSLEVEL = Label.ACCOUNTTEAM_CONTACT_ACCESSLEVEL;
	public static String OPPORTUNITY_ACCESSLEVEL = Label.ACCOUNTTEAM_OPPORTUNITY_ACCESSLEVEL;
	public static String CASE_ACCESSLEVEL = Label.ACCOUNTTEAM_CASE_ACCESSLEVEL;
	public static String TEAMMEMBER_ROLE = Label.ACCOUNTTEAM_TEAMMEMBER_ROLE;
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
	public static String SOLDTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SOLDTO;
	public static String BILLTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_BILLTO;
	public static String GSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_GLOBAL_SGN;
	public static String NSGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_NATIONAL_SGN;

	// Method Name: start
	// Author: Abinash panigrahi
	// Description: Method to fetch all Accounts who are not part of Acccount hierarchy
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext BC) {
		//Define the Scope of Batch records to do processing.
		List<String> recordTypeList = new List<String>();
		recordTypeList.add(SGN_RECORDTYPE_NAME);
		recordTypeList.add(SHIPTO_RECORDTYPE_NAME);
		recordTypeList.add(NSGN_RECORDTYPE_NAME);

		String query = 'SELECT Id, ParentId, Unique_Id__c, Parent_Unique_Id__c, Primary_Bill_To__c, Child_Unique_Id__c, Primary_Bill_To_Unique_Id__c,RecordTypeId, RecordType.Name FROM Account WHERE Exclude_From_Hierarchy__c = TRUE AND RecordType.Name IN: recordTypeList';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash panigrahi
	// Description: Update accounts with appropriate ParentIds inorder to setup Account Hierarchy
	//					Addition of Account Team Members in Account Hierarchy -- Cascading
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Account records fetched in start()
	// Return: Null
	global void execute(Database.BatchableContext BC, List<Account> records) {
		//Instance to store different recordtypes of Account
		List<Account> nsgnAccList = new List<Account>();
		List<Account> sgnAcclist = new List<Account>();
		List<Account> shipToAcclist = new List<Account>();

		Map<String, Schema.RecordTypeInfo> accountRTMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
		//Separation of Account records based on RecordTypeId
		for (Account a : records) {
			if (a.RecordTypeId == accountRTMap.get(NSGN_RECORDTYPE_NAME).getRecordTypeId())
				nsgnAccList.add(a);
			if (a.RecordTypeId == accountRTMap.get(SGN_RECORDTYPE_NAME).getRecordTypeId())
				sgnAcclist.add(a);
			if (a.RecordTypeId == accountRTMap.get(SHIPTO_RECORDTYPE_NAME).getRecordTypeId())
				shipToAcclist.add(a);
		}

		//Instance to store External Unique Ids
		Set<String> uniqueIds = new Set<String>();
		//Instance to map the relationship between Unique Ids and SF Record Ids
		Map<String, Id> uniqueIdMap = new Map<String, Id>();
		//Instance to store Account record to be Updated
		List<Account> toBeUpdateRec = new List<Account>();
		//Instance to sore AccountTeamMember record to be Inserted
		List<AccountTeamMember> toBeInsertRec = new List<AccountTeamMember>();
		//Instance to map the relationship between RecordId and related AccountTeamMember
		Map<Id, List<AccountTeamMember>> accTeamMemberMap = new Map<Id, List<AccountTeamMember>>();
		//Instance to store SGN RecordType Account Record
		List<Account> accListSGN = new List<Account>();
		//Instance to store the result of DML Operation
		Database.SaveResult[] srList;

		//**********NSGN Account Records Code Block***************
		//Loop Logic
		//Populate with External UniqueIds Set and Map Instance
		for (Account a : nsgnAccList) {
			if (a.Unique_Id__c != null) {
				//uniqueIdMap.put(a.Unique_Id__c, a.Id);
				uniqueIds.add(a.Unique_Id__c);
			}
			if (a.Parent_Unique_Id__c != null)
				uniqueIds.add(a.Parent_Unique_Id__c);
		}

		//Fetch related GSGN Account records
		for (Account a : [
			SELECT Id, Unique_Id__c
			FROM Account
			WHERE Unique_Id__c IN :uniqueIds AND RecordType.Name = :GSGN_RECORDTYPE_NAME
		]) {
			uniqueIdMap.put(a.Unique_Id__c, a.Id);
		}

		//Update ParentId field of NSGN Account records depending upon Map value
		for (Account a : nsgnAccList) {
			if (a.Parent_Unique_Id__c != null && uniqueIdMap.containsKey(a.Parent_Unique_Id__c)) {
				toBeUpdateRec.add(
					new Account(
						Id = a.Id,
						ParentId = uniqueIdMap.get(a.Parent_Unique_Id__c),
						Exclude_From_Hierarchy__c = false
					)
				);
			}
		}

		//Fetch related SGN Account recoprds
		for (Account a : [
			SELECT Id, Unique_Id__c, Parent_Unique_Id__c
			FROM Account
			WHERE Parent_Unique_Id__c IN :uniqueIds AND RecordType.Name = :SGN_RECORDTYPE_NAME AND ParentId = NULL
		]) {
			if (uniqueIdMap.containsKey(a.Parent_Unique_Id__c)) {
				toBeUpdateRec.add(
					new Account(
						Id = a.Id,
						ParentId = uniqueIdMap.get(a.Parent_Unique_Id__c),
						Exclude_From_Hierarchy__c = false
					)
				);
			}
		}

		//Exception Handling
		//Update Account records
		srList = Database.update(toBeUpdateRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Line 118 - Update SGN Account',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Fetch AccountTeamMember records related at SGN Account level
		accListSGN = [
			SELECT
				Id,
				ParentId,
				Parent.ParentId,
				(SELECT Id, AccountId, UserId FROM AccountTeamMembers WHERE User.isActive = TRUE)
			FROM Account
			WHERE Parent_Unique_Id__c IN :uniqueIds AND RecordType.Name = :SGN_RECORDTYPE_NAME
		];

		//Account Team Cascade Up from SGN level to higher Account hierarchy
		for (Account a : accListSGN) {
			if (a.AccountTeamMembers.size() > 0) {
				for (AccountTeamMember at : a.AccountTeamMembers) {
					if (a.ParentId != null) {
						toBeInsertRec.add(
							new AccountTeamMember(
								AccountId = a.ParentId,
								UserId = at.UserId,
								AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
								ContactAccessLevel = CONTACT_ACCESSLEVEL,
								CaseAccessLevel = CASE_ACCESSLEVEL,
								OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
								TeamMemberRole = TEAMMEMBER_ROLE
							)
						);
					}
					if (a.Parent.ParentId != null) {
						toBeInsertRec.add(
							new AccountTeamMember(
								AccountId = a.Parent.ParentId,
								UserId = at.UserId,
								AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
								ContactAccessLevel = CONTACT_ACCESSLEVEL,
								CaseAccessLevel = CASE_ACCESSLEVEL,
								OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
								TeamMemberRole = TEAMMEMBER_ROLE
							)
						);
					}
				}
			}
		}

		//Exception Handling
		//Insert AccountTeamMember records
		srList = Database.insert(toBeInsertRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Line 148 - Insert AccountTeamMember',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Clear all Instance values for further use
		toBeUpdateRec.clear();
		uniqueIds.clear();
		uniqueIdMap.clear();
		toBeInsertRec.clear();
		accListSGN.clear();

		//**********SHIPTO Account Records Code Block***************
		//Fetch Relational Query
		shipToAcclist = [
			SELECT
				Id,
				ParentId,
				Unique_Id__c,
				Parent_Unique_Id__c,
				Primary_Bill_To__c,
				Child_Unique_Id__c,
				Primary_Bill_To_Unique_Id__c,
				RecordTypeId,
				RecordType.Name,
				(SELECT Id, Ship_To__c FROM BillTos__r)
			FROM Account
			WHERE Id IN :shipToAcclist
		];
		//Loop Logic
		//Populate with External UniqueIds Set Instance
		for (Account a : shipToAcclist) {
			if (a.Parent_Unique_Id__c != null) {
				uniqueIds.add(a.Parent_Unique_Id__c);
			}
			if (a.Primary_Bill_To_Unique_Id__c != null) {
				uniqueIds.add(a.Primary_Bill_To_Unique_Id__c);
			}
			if (a.Child_Unique_Id__c != null) {
				uniqueIds.add(a.Child_Unique_Id__c);
			}
		}

		//Fetch related SGN and BillTo Account records
		for (Account a : [
			SELECT Id, Unique_Id__c
			FROM Account
			WHERE
				Unique_Id__c IN :uniqueIds
				AND (RecordType.Name = :SGN_RECORDTYPE_NAME
				OR RecordType.Name = :BILLTO_RECORDTYPE_NAME
				OR RecordType.Name = :SOLDTO_RECORDTYPE_NAME)
		]) {
			uniqueIdMap.put(a.Unique_Id__c, a.Id);
		}

		//Instance to store to be Inserted ShipToBillTo Junction object records
		Map<Id, ShipTo_BillTo__c> childBillToRec = new Map<Id, ShipTo_BillTo__c>();
		//Update ParentId field of ShipTo Account records depending upon Map value
		//Update PrimaryBillTo lookup field and Insert ShipToBillTo junction object record
		for (Account a : shipToAcclist) {
			//Temporary Account Object
			Account obj = new Account();
			obj.Id = a.Id;

			//Update ParentId field
			if (a.Parent_Unique_Id__c != null && uniqueIdMap.containsKey(a.Parent_Unique_Id__c)) {
				obj.ParentId = uniqueIdMap.get(a.Parent_Unique_Id__c);
			}
			//Update Primary BillTo field
			if (a.Primary_Bill_To_Unique_Id__c != null && uniqueIdMap.containsKey(a.Primary_Bill_To_Unique_Id__c)) {
				obj.Primary_Bill_To__c = uniqueIdMap.get(a.Primary_Bill_To_Unique_Id__c);
			}
			//Insert Child BillTo relationship record
			if (
				a.Child_Unique_Id__c != null &&
				uniqueIdMap.containsKey(a.Child_Unique_Id__c) &&
				a.BillTos__r.size() == 0
			) {
				childBillToRec.put(
					a.Id,
					new ShipTo_BillTo__c(Ship_To__c = a.Id, Bill_To__c = uniqueIdMap.get(a.Child_Unique_Id__c))
				);
			}
			//Exclude from Hierarchy Checkbox field value populated
			if (
				a.Parent_Unique_Id__c != null &&
				uniqueIdMap.containsKey(a.Parent_Unique_Id__c) &&
				a.Primary_Bill_To_Unique_Id__c == null &&
				a.Child_Unique_Id__c == null
			) {
				obj.Exclude_From_Hierarchy__c = false;
			}

			if (
				a.Parent_Unique_Id__c != null &&
				uniqueIdMap.containsKey(a.Parent_Unique_Id__c) &&
				a.Primary_Bill_To_Unique_Id__c != null &&
				uniqueIdMap.containsKey(a.Primary_Bill_To_Unique_Id__c) &&
				(a.Child_Unique_Id__c == null ||
				(uniqueIdMap.containsKey(a.Child_Unique_Id__c) && a.BillTos__r.size() == 0) ||
				a.BillTos__r.size() > 0)
			) {
				obj.Exclude_From_Hierarchy__c = false;
			}
			toBeUpdateRec.add(obj);
		}

		//Exception Handling
		//Insert BillToShipTo junction object records
		srList = Database.insert(childBillToRec.values(), false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Insert 221 - Insert BillToShipTo',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Exception Handling
		//Update Account records
		srList = Database.update(toBeUpdateRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Insert 233 - Update Shipto Account',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Fetch AccountTeamMember records related at SGN Account level
		accListSGN = [
			SELECT Id, Unique_Id__c, (SELECT Id, AccountId, UserId FROM AccountTeamMembers WHERE User.isActive = TRUE)
			FROM Account
			WHERE
				Unique_Id__c IN :uniqueIds
				AND (RecordType.Name = :SGN_RECORDTYPE_NAME
				OR RecordType.Name = :SOLDTO_RECORDTYPE_NAME)
		];

		//Map SGN Account RecordId with related AccountTeamMember records
		for (Account a : accListSGN) {
			if (a.AccountTeamMembers.size() > 0) {
				accTeamMemberMap.put(a.Id, a.AccountTeamMembers);
			}
		}

		//Account Team Cascade down from SGN level to ShipTo and BillTo level
		for (Account a : shipToAcclist) {
			if (
				a.Parent_Unique_Id__c != null &&
				uniqueIdMap.containsKey(a.Parent_Unique_Id__c) &&
				accTeamMemberMap.containsKey(uniqueIdMap.get(a.Parent_Unique_Id__c))
			) {
				for (AccountTeamMember at : accTeamMemberMap.get(uniqueIdMap.get(a.Parent_Unique_Id__c))) {
					toBeInsertRec.add(
						new AccountTeamMember(
							AccountId = a.Id,
							UserId = at.UserId,
							AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
							ContactAccessLevel = CONTACT_ACCESSLEVEL,
							CaseAccessLevel = CASE_ACCESSLEVEL,
							OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
							TeamMemberRole = TEAMMEMBER_ROLE
						)
					);

					if (
						a.Primary_Bill_To_Unique_Id__c != null &&
						uniqueIdMap.containsKey(a.Primary_Bill_To_Unique_Id__c)
					) {
						toBeInsertRec.add(
							new AccountTeamMember(
								AccountId = uniqueIdMap.get(a.Primary_Bill_To_Unique_Id__c),
								UserId = at.UserId,
								AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
								ContactAccessLevel = CONTACT_ACCESSLEVEL,
								CaseAccessLevel = CASE_ACCESSLEVEL,
								OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
								TeamMemberRole = TEAMMEMBER_ROLE
							)
						);
					}
					if (a.Child_Unique_Id__c != null && uniqueIdMap.containsKey(a.Child_Unique_Id__c)) {
						toBeInsertRec.add(
							new AccountTeamMember(
								AccountId = uniqueIdMap.get(a.Child_Unique_Id__c),
								UserId = at.UserId,
								AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
								ContactAccessLevel = CONTACT_ACCESSLEVEL,
								CaseAccessLevel = CASE_ACCESSLEVEL,
								OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
								TeamMemberRole = TEAMMEMBER_ROLE
							)
						);
					}
				}
			}
		}

		//Exception Handling
		//Insert AccountTeamMember records
		srList = Database.insert(toBeInsertRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Line 272 - Insert AccountTeamMember',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Clear all Instance values for further use
		toBeUpdateRec.clear();
		uniqueIds.clear();
		uniqueIdMap.clear();
		toBeInsertRec.clear();
		accListSGN.clear();

		//**********SGN Account Records Code Block***************
		//Loop Logic
		//Populate with External UniqueIds Set and Map Instance
		for (Account a : sgnAcclist) {
			if (a.Unique_Id__c != null) {
				uniqueIdMap.put(a.Unique_Id__c, a.Id);
				uniqueIds.add(a.Unique_Id__c);
			}
			if (a.Parent_Unique_Id__c != null) {
				uniqueIds.add(a.Parent_Unique_Id__c);
			}
		}

		//Fetch related NSGN Account records
		for (Account a : [
			SELECT Id, Unique_Id__c
			FROM Account
			WHERE Unique_Id__c IN :uniqueIds AND RecordType.Name = :NSGN_RECORDTYPE_NAME
		]) {
			uniqueIdMap.put(a.Unique_Id__c, a.Id);
		}

		//Update ParentId field of SGN Account records depending upon Map value
		for (Account a : sgnAcclist) {
			if (a.Parent_Unique_Id__c != null && uniqueIdMap.containsKey(a.Parent_Unique_Id__c)) {
				toBeUpdateRec.add(
					new Account(
						Id = a.Id,
						ParentId = uniqueIdMap.get(a.Parent_Unique_Id__c),
						Exclude_From_Hierarchy__c = false
					)
				);
			}
		}

		/*//Fetch related ShipTo Account recoprds
        for(Account a : [SELECT Id,Unique_Id__c,Parent_Unique_Id__c FROM Account WHERE Parent_Unique_Id__c IN: uniqueIds AND RecordType.Name =: SHIPTO_RECORDTYPE_NAME AND ParentId = NULL]){
        	if(uniqueIdMap.containsKey(a.Parent_Unique_Id__c)){
            	toBeUpdateRec.add(new Account(Id = a.Id, ParentId = uniqueIdMap.get(a.Parent_Unique_Id__c))); 
            }
        }*/

		//Exception Handling
		//Update Account records
		srList = Database.update(toBeUpdateRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Update Account',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Fetch AccountTeamMember records related at SGN Account level
		accListSGN = [
			SELECT
				Id,
				ParentId,
				Parent.ParentId,
				(SELECT Id, AccountId, UserId FROM AccountTeamMembers WHERE User.isActive = TRUE)
			FROM Account
			WHERE Id IN :sgnAcclist AND RecordType.Name = :SGN_RECORDTYPE_NAME
		];

		//Account Team Cascade Up from SGN level to higher Account hierarchy
		for (Account a : accListSGN) {
			if (a.AccountTeamMembers.size() > 0) {
				for (AccountTeamMember at : a.AccountTeamMembers) {
					if (a.ParentId != null) {
						toBeInsertRec.add(
							new AccountTeamMember(
								AccountId = a.ParentId,
								UserId = at.UserId,
								AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
								ContactAccessLevel = CONTACT_ACCESSLEVEL,
								CaseAccessLevel = CASE_ACCESSLEVEL,
								OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
								TeamMemberRole = TEAMMEMBER_ROLE
							)
						);
					}
					if (a.Parent.ParentId != null) {
						toBeInsertRec.add(
							new AccountTeamMember(
								AccountId = a.Parent.ParentId,
								UserId = at.UserId,
								AccountAccessLevel = ACCOUNT_ACCESSLEVEL,
								ContactAccessLevel = CONTACT_ACCESSLEVEL,
								CaseAccessLevel = CASE_ACCESSLEVEL,
								OpportunityAccessLevel = OPPORTUNITY_ACCESSLEVEL,
								TeamMemberRole = TEAMMEMBER_ROLE
							)
						);
					}
				}
			}
		}

		//Exception Handling
		//Insert AccountTeamMember records
		srList = Database.insert(toBeInsertRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'ParentalSetupAccountTeamCascade_Batch',
						'execute',
						'Batch Logic',
						'Line 353 - Insert AccountTeamMember',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Clear all Instance values for further use
		toBeUpdateRec.clear();
		uniqueIds.clear();
		uniqueIdMap.clear();
		toBeInsertRec.clear();
		accListSGN.clear();
	}

	// Method Name: finish
	// Author: Abinash panigrahi
	// Description: After Update Logic

	global void finish(Database.BatchableContext BC) {
	}
}