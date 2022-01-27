/****************************************************************************************************
 * Author Name   : Abinash Panigrahi
 * Class Name    : TerritoryAlignment_Batch
 * Created Date  : 29th June 2020
 * Description   : To Setup Territory Hierarchy Structure and their respective User assosiation based on Staging Object records
 * Test Class    : TerritoryAlignmentBatch_Test
****************************************************************************************************
    @comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new TerritoryAlignment_Batch(), 1);
    @note : Always execute batch job with Batch size equal to 1
****************************************************************************************************/

global class TerritoryAlignment_Batch implements Database.Batchable<sObject>, Database.Stateful {
	// Class Level Variables
	global Id MAIN_TERRITORY_MODEL;
	global Id DEFAULT_TERRITORY_TYPE;
	global String ACCOUNT_ACCESS_LEVEL;
	global String OPPORTUNITY_ACCESS_LEVEL;
	global String CASE_ACCESS_LEVEL;
	global String TERRITORY_ROLE_NAME;
	global Integer MAXIMUM_HIERARCHY_DEPTH;
	global String MAIN_TERRITORY_MODEL_NAME;
	global String DEFAULT_TERRITORY_TYPE_NAME;

	// Instance to be reused in all Batch Iteration
	global List<Territory_Hierarchy__c> ALL_RECORDS = new List<Territory_Hierarchy__c>();
	global List<Apex_Log__c> APEX_LOGS = new List<Apex_Log__c>();

	// Custom Exception
	public virtual class CustomException extends Exception {
	}

	// Overide Default Constructor 
	global TerritoryAlignment_Batch() {
		// Get Custom Metadata Config data -- 'Parent Territory Node'
		// Assumption: Only One Org-Specific record should exist
		Parent_Territory_Node__mdt config = [
			SELECT
				Id,
				MasterLabel,
				Territory_Model_Name__c,
				Account_Access_Level__c,
				Case_Access_Level__c,
				Opportunity_Access_Level__c,
				Territory_Role_Name__c,
				Depth_of_Hierarchy__c,
				Type__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];

		// Fetch Territory Model, Type & Linking Territory(Grand Parent) Record Id
		// Consideration: Make sure to populate placeholder value with Name or Label(not DeveloperName)
		List<Territory2Model> territoryModel = new List<Territory2Model>(
			[SELECT Id FROM Territory2Model WHERE Name = :config.Territory_Model_Name__c LIMIT 1]
		);
		MAIN_TERRITORY_MODEL_NAME = config.Territory_Model_Name__c;
		if (territoryModel.size() == 0) {
			Territory2Model obj = new Territory2Model();
			obj.Name = config.Territory_Model_Name__c;
			obj.DeveloperName = config.Territory_Model_Name__c.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll(' ', '');
			insert obj;
			MAIN_TERRITORY_MODEL = obj.Id;
		} else {
			MAIN_TERRITORY_MODEL = territoryModel[0].Id;
		}

		// Fetch Default Territory Type
		// Consideration: Make sure to create Territory Type beforehand - Type is not creatable in Apex
		List<Territory2Type> territoryType = new List<Territory2Type>(
			[SELECT Id FROM Territory2Type WHERE MasterLabel = :config.Type__c LIMIT 1]
		);
		DEFAULT_TERRITORY_TYPE_NAME = config.Type__c;
		if (territoryType.size() == 1) {
			DEFAULT_TERRITORY_TYPE = territoryType[0].Id;
		}

		// Get All Values which needs to be hard-coded
		// Required Attributes for Territory Record Creation
		ACCOUNT_ACCESS_LEVEL = config.Account_Access_Level__c;
		OPPORTUNITY_ACCESS_LEVEL = config.Opportunity_Access_Level__c;
		CASE_ACCESS_LEVEL = config.Case_Access_Level__c;
		TERRITORY_ROLE_NAME = config.Territory_Role_Name__c;
		MAXIMUM_HIERARCHY_DEPTH = (Integer) config.Depth_of_Hierarchy__c;

		// Debug Logs for reference
		System.debug('config------------' + config);
		System.debug('MAIN_TERRITORY_MODEL------------' + MAIN_TERRITORY_MODEL);
		System.debug('TERRITORY_ROLE_NAME------------' + TERRITORY_ROLE_NAME);
		System.debug('MAXIMUM_HIERARCHY_DEPTH------------' + MAXIMUM_HIERARCHY_DEPTH);
	}

	// Batch's Start method to query all eligible Territory Hierarchy Stagging Object records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String tierFields = ' ';
		for (Integer i = 1; i <= MAXIMUM_HIERARCHY_DEPTH; i++) {
			tierFields += 'Tier' + i + '_Label__c, ';
			tierFields += 'Tier' + i + '_User__c, ';
			tierFields += 'Tier' + i + '_Type__c, ';
			tierFields += 'Tier' + i + '_Channel__c, ';
			tierFields += 'Salesforce_Level' + i + '_TerritoryId__c, ';
			if (i == MAXIMUM_HIERARCHY_DEPTH) {
				tierFields = tierFields.removeEnd(', ');
			}
		}

		String soql =
			'SELECT Id, Name, Role_in_Territory__c, Is_Active__c,' +
			tierFields +
			' FROM Territory_Hierarchy__c';
		soql += ' WHERE Is_Batch_Processed__c = false AND Is_Active__c = true AND';
		soql += ' Territory_Model_Name__c =: MAIN_TERRITORY_MODEL_NAME';
		System.debug('soql------------' + soql);

		return Database.getQueryLocator(soql);
	}

	// Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, list<Territory_Hierarchy__c> records) {
		// Debug Logs for reference
		System.debug('records------------' + records);
		System.debug('records.size()------------' + records.size());

		// Always Process Single Stagging Records -- Do set Batch Size during execution
		if (records.size() > 1) {
			return;
		} else {
			// Instantiate Stagging Records
			Territory_Hierarchy__c obj = records[0];

			// Debug Logs for reference
			System.debug('obj------------' + obj);

			// Cretae Database Image for Rollback
			Savepoint sp = Database.setSavepoint();

			/******** STEP 0 : Handle Update Scenario Flow  *********/

			// Define Attributes to store relationship data
			Map<Id, Id> territoryUserUpdateMap = new Map<Id, Id>();
			Map<Id, String> territoryTypeUpdateMap = new Map<Id, String>();
			Set<String> uniqueUserTerritorySet = new Set<String>();
			Set<Id> uniqueTerritorySet = new Set<Id>();
			Map<String, Id> territoryTypeNewMap = new Map<String, Id>();
			List<UserTerritory2Association> userAssosiationUpdateList = new List<UserTerritory2Association>();
			List<Territory2> territoryUpdateList = new List<Territory2>();
			List<UserTerritory2Association> userAssosiationNewList = new List<UserTerritory2Association>();
			List<UserTerritory2Association> userAssosiationModifyList = new List<UserTerritory2Association>();
			Map<Id, Integer> tierLevelValueMap = new Map<Id, Integer>();
			Map<Id, String> territoryChannelUpdateMap = new Map<Id, String>();
			Map<Id, String> roleUpdateMap = new Map<Id, String>();

			// Validate RecordIds are populated -- Check Update Records
			for (Integer i = 1; i <= MAXIMUM_HIERARCHY_DEPTH; i++) {
				// Prepare Custom Field API Name
				String tierHierarachyUser = 'Tier' + i + '_User__c';
				String tierHierarachySFId = 'Salesforce_Level' + i + '_TerritoryId__c';
				String tierHierarachyType = 'Tier' + i + '_Type__c';
				String tierHierarachyChannel = 'Tier' + i + '_Channel__c';

				// Null Value Check
				if (obj.get(tierHierarachySFId) != null) {
					Id territoryUser = (Id) obj.get(tierHierarachyUser);
					Id territorySFId = (Id) obj.get(tierHierarachySFId);
					String territoryType = (String) obj.get(tierHierarachyType);
					String territoryChannel = (String) obj.get(tierHierarachyChannel);

					// Territory Backend SF Id records
					uniqueTerritorySet.add(territorySFId);

					// Store Relationship -- User Update
					if (territoryUser != null) {
						territoryUserUpdateMap.put(territorySFId, territoryUser);
						uniqueUserTerritorySet.add(territorySFId + '_' + territoryUser);
					}

					// Territory Type Update
					if (territoryType != null) {
						territoryTypeUpdateMap.put(territorySFId, territoryType);
					}

					// Territory Channel Update
					if (territoryChannel != null) {
						territoryChannelUpdateMap.put(territorySFId, territoryChannel);
					}

					// Territory Level Update
					tierLevelValueMap.put(territorySFId, i);

					// Role in Territory
					if (i == 6) {
						roleUpdateMap.put(territorySFId, obj.Role_in_Territory__c);
					}
				}
			}

			// Proceed further if found Territory Salesforce Record Id
			if (uniqueTerritorySet.size() > 0) {
				// Debug Logs for reference
				System.debug('uniqueTerritorySet------------' + uniqueTerritorySet);
				System.debug('territoryUserUpdateMap------------' + territoryUserUpdateMap);
				System.debug('territoryTypeUpdateMap------------' + territoryTypeUpdateMap);
				System.debug('uniqueUserTerritorySet------------' + uniqueUserTerritorySet);
				System.debug('tierLevelValueMap------------' + tierLevelValueMap);
				System.debug('territoryChannelUpdateMap------------' + territoryChannelUpdateMap);

				// Fetch Existing Assigned Users at Territory level
				for (UserTerritory2Association associationRecord : [
					SELECT Id, UserId, Territory2Id
					FROM UserTerritory2Association
					WHERE
						Territory2.Territory2ModelId = :MAIN_TERRITORY_MODEL
						AND Territory2Id IN :territoryUserUpdateMap.keySet()
				]) {
					// Prepare Unique Combination key
					String uniqueCombinationId = associationRecord.Territory2Id + '_' + associationRecord.UserId;

					// Donot delete if no change detected
					if (uniqueUserTerritorySet.contains(uniqueCombinationId)) {
						territoryUserUpdateMap.remove(associationRecord.Territory2Id);
						if (roleUpdateMap.containsKey(associationRecord.Territory2Id)) {
							userAssosiationModifyList.add(
								new UserTerritory2Association(
									Id = associationRecord.Id,
									RoleInTerritory2 = roleUpdateMap.get(associationRecord.Territory2Id)
								)
							);
						}
					} else {
						userAssosiationUpdateList.add(associationRecord);
					}
				}

				// Prepare New Assigned Users at Territory level
				for (Id terrId : territoryUserUpdateMap.keySet()) {
					// Create new Instance of Association record
					UserTerritory2Association rec = new UserTerritory2Association();
					rec.UserId = territoryUserUpdateMap.get(terrId);
					rec.Territory2Id = terrId;

					// Role in Territory
					if (roleUpdateMap.containsKey(terrId)) {
						rec.RoleInTerritory2 = roleUpdateMap.get(terrId);
					}

					// Add to Collection
					userAssosiationNewList.add(rec);
				}

				// Debug Logs for reference
				System.debug('userAssosiationUpdateList------------' + userAssosiationUpdateList);
				System.debug('userAssosiationNewList------------' + userAssosiationNewList);

				// Delete Changed User Association Records
				if (userAssosiationUpdateList.size() > 0) {
					// Exception Handling
					try {
						delete userAssosiationUpdateList;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(
							userAssosiationUpdateList,
							'Delete User Territory Assignment Records',
							err,
							sp,
							obj
						);
						return;
					}
                }

                // Update Same User Association Records
				if (userAssosiationModifyList.size() > 0) {
					// Exception Handling
					try {
						update userAssosiationModifyList;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(
							userAssosiationUpdateList,
							'Update User Territory Assignment Records',
							err,
							sp,
							obj
						);
						return;
					}
				}

				// Insert New User Association Records
				if (userAssosiationNewList.size() > 0) {
					// Exception Handling
					try {
						insert userAssosiationNewList;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(
							userAssosiationNewList,
							'Update User Territory Assignment Records',
							err,
							sp,
							obj
						);
						return;
					}
				}

				// Fetch Territory Type defined in Org
				for (Territory2Type terrType : [
					SELECT Id, MasterLabel
					FROM Territory2Type
					WHERE MasterLabel IN :territoryTypeUpdateMap.values()
				]) {
					territoryTypeNewMap.put(terrType.MasterLabel, terrType.Id);
				}

				// Fetch Existing Territory present
				for (Territory2 terr : [
					SELECT Id, Territory2TypeId, Tier_Level__c, Channel__c
					FROM Territory2
					WHERE Id IN :uniqueTerritorySet AND Territory2ModelId = :MAIN_TERRITORY_MODEL
				]) {
					Territory2 currTerrObjRec = new Territory2();
					currTerrObjRec.Id = terr.Id;

					// Null Check
					if (territoryTypeNewMap.containsKey(territoryTypeUpdateMap.get(terr.Id))) {
						// Matching Condition
						if (terr.Territory2TypeId != territoryTypeNewMap.get(territoryTypeUpdateMap.get(terr.Id))) {
							// Add to Collection
							currTerrObjRec.Territory2TypeId = territoryTypeNewMap.get(
								territoryTypeUpdateMap.get(terr.Id)
							);
						}
					}

					if (tierLevelValueMap.containsKey(terr.Id)) {
						if (terr.Tier_Level__c != tierLevelValueMap.get(terr.Id)) {
							currTerrObjRec.Tier_Level__c = tierLevelValueMap.get(terr.Id);
						}
					}

					if (territoryChannelUpdateMap.containsKey(terr.Id)) {
						if (terr.Channel__c != territoryChannelUpdateMap.get(terr.Id)) {
							currTerrObjRec.Channel__c = territoryChannelUpdateMap.get(terr.Id);
						}
					}

					territoryUpdateList.add(currTerrObjRec);
				}

				// Debug Logs for reference
				System.debug('territoryTypeNewMap------------' + territoryTypeNewMap);
				System.debug('territoryUpdateList------------' + territoryUpdateList);

				// Update Territory Records with Type Codes
				if (territoryUpdateList.size() > 0) {
					// Exception Handling
					try {
						update territoryUpdateList;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(
							territoryUpdateList,
							'Update Territory Records with Type Codes',
							err,
							sp,
							obj
						);
						return;
					}
				}

				// Skip Execution of further lines
				ALL_RECORDS.add(
					new Territory_Hierarchy__c(Id = obj.Id, Is_Batch_Processed__c = true, Error_Message__c = '')
				);
				return;
			}

			/******** STEP 1 : Pre-Processing Stagging Records  *********/

			// Define Attributes to store relationship data
			Map<String, Id> territoryMap = new Map<String, Id>();
			Map<String, Id> salesRepMap = new Map<String, Id>();
			Map<String, String> typeGroupMap = new Map<String, String>();
			Map<String, String> parentChildMap = new Map<String, String>();
			Map<Integer, String> tierLevelMap = new Map<Integer, String>();
			Map<String, String> tierChannelMap = new Map<String, String>();
			String lastTierHierarachyName = '';

			// Check all Tier Hierarachy Level Columns individually
			for (Integer i = 1; i <= MAXIMUM_HIERARCHY_DEPTH; i++) {
				// Prepare Custom Field API Name
				String tierHierarachyName = 'Tier' + i + '_Label__c';
				String tierHierarachyUser = 'Tier' + i + '_User__c';
				String tierHierarachyType = 'Tier' + i + '_Type__c';
				String tierHierarachyChannel = 'Tier' + i + '_Channel__c';

				// Null Value Check
				if (obj.get(tierHierarachyName) != null) {
					String territoryName = (String) obj.get(tierHierarachyName);
					Id territoryUser = (Id) obj.get(tierHierarachyUser);
					String territoryType = (String) obj.get(tierHierarachyType);
					String territoryChannel = (String) obj.get(tierHierarachyChannel);

					// Territory Name and SF Record Id Mapping
					territoryMap.put(territoryName, null);

					// Territory Name and SF Record Id Mapping
					if (territoryType != null) {
						typeGroupMap.put(territoryName, territoryType);
					}

					// Tier Level and Territory Name Mapping
					tierLevelMap.put(i, territoryName);

					// Parent-Child Territory Name Mapping
					// Handle Skip Hierarchy Level Scenario
					for (Integer j = i - 1; j > 0; j--) {
						String parentTierName = 'Tier' + j + '_Label__c';
						if (i == 1) {
							break;
						} else if (obj.get(parentTierName) != null) {
							// Drill down the Tier to find linked Parent
							parentChildMap.put(territoryName, (String) obj.get(parentTierName));
							break;
						}
					}

					// Territory Name and Sales Rep User Id Mapping
					if (territoryUser != null) {
						salesRepMap.put(territoryName, territoryUser);
					}

					// Capture Ending Territory node
					if (i == 6) {
						lastTierHierarachyName = territoryName;
					}

					// Capture Channel for Sales Rep
					if (territoryChannel != null) {
						tierChannelMap.put(territoryName, territoryChannel);
					}
				}
			}

			// Debug Logs for reference
			System.debug('territoryMap------------' + territoryMap);
			System.debug('parentChildMap------------' + parentChildMap);
			System.debug('tierLevelMap------------' + tierLevelMap);
			System.debug('typeGroupMap------------' + typeGroupMap);
			System.debug('salesRepMap------------' + salesRepMap);
			System.debug('tierChannelMap------------' + tierChannelMap);
			System.debug('lastTierHierarachyName------------' + lastTierHierarachyName);

			/******** STEP 2 : Fetch all existing Territories records and Map it against Name  *********/

			for (Territory2 rec : [
				SELECT Id, Name
				FROM Territory2
				WHERE
					Name IN :territoryMap.keySet()
					AND DeveloperName != NULL
					AND Territory2ModelId = :MAIN_TERRITORY_MODEL
			]) {
				if (territoryMap.containsKey(rec.Name)) {
					territoryMap.put(rec.Name, rec.Id);
				}
			}

			// Debug Logs for reference
			System.debug('territoryMap------------' + territoryMap);

			/******** STEP 3 : Get Sales Rep Name and SF User Record Id using Login Name  *********/

			Map<Id, String> nameMap = new Map<Id, String>();
			for (User rec : [SELECT Id, Name FROM User WHERE Id IN :salesRepMap.values()]) {
				nameMap.put(rec.Id, rec.Name);
			}

			Map<String, String> userSFIdMap = new Map<String, String>();
			for (String terrName : salesRepMap.keySet()) {
				userSFIdMap.put(terrName, nameMap.get(salesRepMap.get(terrName)));
			}

			// Debug Logs for reference
			System.debug('nameMap------------' + nameMap);
			System.debug('userSFIdMap------------' + userSFIdMap);

			/******** STEP 4 : Gather-up Territory Grouping info as per Business Rule *********/

			// Fetch Existing Territory Type present in org
			Map<String, Id> typeGroupSFIdMap = new Map<String, Id>();
			for (Territory2Type rec : [
				SELECT Id, MasterLabel
				FROM Territory2Type
				WHERE MasterLabel IN :typeGroupMap.values()
			]) {
				typeGroupSFIdMap.put(rec.MasterLabel, rec.Id);
			}

			// Transform Mapping Relationship - Territory Name and Type SF Id
			Map<String, Id> territoryTypeSFIDMap = new Map<String, Id>();
			for (String str : typeGroupMap.keySet()) {
				if (typeGroupMap.get(str) != null && typeGroupSFIdMap.containsKey(typeGroupMap.get(str))) {
					territoryTypeSFIDMap.put(str, typeGroupSFIdMap.get(typeGroupMap.get(str)));
				}
			}

			// Debug Logs for reference
			System.debug('typeGroupSFIdMap------------' + typeGroupSFIdMap);
			System.debug('territoryTypeSFIDMap------------' + territoryTypeSFIDMap);

			/******** STEP 5 : Create Territory Hierarchy Structure -- Tier Level wise  *********/

			for (Integer i = 1; i <= MAXIMUM_HIERARCHY_DEPTH; i++) {
				if (
					tierLevelMap.containsKey(i) &&
					tierLevelMap.get(i) != null &&
					territoryMap.get(tierLevelMap.get(i)) == null
				) {
					// Get Territory Info
					String territoryName = tierLevelMap.get(i);
					// Prepare Territory record to be inserted
					Territory2 currentTerritory = new Territory2();

					// Populate all required values
					currentTerritory.Name = territoryName;
					currentTerritory.Territory2ModelId = MAIN_TERRITORY_MODEL;
					currentTerritory.AccountAccessLevel = ACCOUNT_ACCESS_LEVEL;
					currentTerritory.CaseAccessLevel = CASE_ACCESS_LEVEL;
					currentTerritory.OpportunityAccessLevel = OPPORTUNITY_ACCESS_LEVEL;

					// Tier Level
					currentTerritory.Tier_Level__c = i;

					// Channel Info
					if (tierChannelMap.containsKey(territoryName)) {
						currentTerritory.Channel__c = tierChannelMap.get(territoryName);
					}

					// Generate Random Number to have Unique Developer Name
					currentTerritory.DeveloperName =
						'X_' +
						territoryName.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll(' ', '') +
						'_' +
						String.valueOf(Integer.valueof((Math.random() * 10000)));

					// Decide Parent Linking
					if (i == 1) {
						currentTerritory.ParentTerritory2Id = null;
					} else if (territoryMap.containsKey(parentChildMap.get(territoryName)) != null) {
						currentTerritory.ParentTerritory2Id = territoryMap.get(parentChildMap.get(territoryName));
					}

					// Primary Sales Rep Name - UI Tweaks
					/*if(userSFIdMap.containsKey(str)){
                        currentTerritory.Primary_Sales_Rep__c = userSFIdMap.get(str);
                    }*/

					// Territory Classification or Grouping
					if (territoryTypeSFIDMap.containsKey(territoryName)) {
						currentTerritory.Territory2TypeId = territoryTypeSFIDMap.get(territoryName);
					} else {
						currentTerritory.Territory2TypeId = DEFAULT_TERRITORY_TYPE;
					}

					// Debug Logs for reference
					System.debug('currentTerritory------------' + currentTerritory);

					// Insert Territory records
					if (currentTerritory != null) {
						// Exception Handling
						try {
							insert currentTerritory;
						} catch (System.DmlException err) {
							// Create Apex Log
							List<Territory2> recordlst = new List<Territory2>();
							recordlst.add(currentTerritory);
							createExceptionLogs(recordlst, 'Insert Territory2 Records', err, sp, obj);
							return;
						}
					}

					// Update Territory Name-Id Mapping
					territoryMap.put(currentTerritory.Name, currentTerritory.Id);

					// Debug Logs for reference
					System.debug('territoryMap------------' + territoryMap);
				}
			}

			/******** STEP 6 : Get Sales Representative Assosiation with Territory  *********/

			Set<String> userAssosiation = new Set<String>();
			for (UserTerritory2Association record : [
				SELECT Id, UserId, Territory2Id
				FROM UserTerritory2Association
				WHERE
					Territory2.Territory2ModelId = :MAIN_TERRITORY_MODEL
					AND Territory2Id IN :territoryMap.values()
					AND UserId IN :salesRepMap.values()
			]) {
				userAssosiation.add(String.valueOf(record.Territory2Id) + '_' + String.valueOf(record.UserId));
			}

			// Debug Logs for reference
			System.debug('userAssosiation------------' + userAssosiation);

			/******** STEP 7 : Assign Sales Representative with their respective Territory *********/

			// Loop through Territoty Assignment
			// Prepare List of records to be Inserted
			List<UserTerritory2Association> lstRecords = new List<UserTerritory2Association>();
			for (String terName : salesRepMap.keySet()) {
				// Check Territory SF Id exist and SalesRep association with Territory info is present
				if (
					territoryMap.containsKey(terName) &&
					territoryMap.get(terName) != null &&
					salesRepMap.containsKey(terName) &&
					salesRepMap.get(terName) != null
				) {
					// Create new Instance of Association record
					UserTerritory2Association rec = new UserTerritory2Association();
					rec.UserId = salesRepMap.get(terName);
					rec.Territory2Id = territoryMap.get(terName);
					// User Role -- Last Territory nodes
					if (
						lastTierHierarachyName != '' &&
						lastTierHierarachyName == terName &&
						obj.Role_in_Territory__c != null
					) {
						rec.RoleInTerritory2 = obj.Role_in_Territory__c;
					}

					// Avoid Duplicate Record Set Creation
					String uniqueCombination = String.valueOf(rec.Territory2Id) + '_' + String.valueOf(rec.UserId);
					if (!userAssosiation.contains(uniqueCombination)) {
						lstRecords.add(rec);
					}
				}
			}

			// Debug Logs for reference
			System.debug('lstRecords------------' + lstRecords);

			// Insert Assignment records
			if (lstRecords.size() > 0) {
				// Exception Handling
				try {
					insert lstRecords;
				} catch (System.DmlException err) {
					// Create Apex Log
					createExceptionLogs(lstRecords, 'Insert User Territory Assignment Records', err, sp, obj);
					return;
				}
			}

			/******** STEP 8 : Mark all picked up Stagging Object records as Batch Processed *********/

			// Update Territory SF Id back
			for (Integer i = 1; i <= MAXIMUM_HIERARCHY_DEPTH; i++) {
				// Prepare Custom Field API Name
				String tierHierarachyName = 'Tier' + i + '_Label__c';
				String territorySFId = 'Salesforce_Level' + i + '_TerritoryId__c';
				// Null Check
				if (
					obj.get(tierHierarachyName) != null &&
					territoryMap.containsKey((String) obj.get(tierHierarachyName))
				) {
					// Check if already or newly inserted territory
					String territoryName = (String) obj.get(tierHierarachyName);
					if (territoryMap.get(territoryName) != null) {
						obj.put(territorySFId, territoryMap.get(territoryName));
					}
				}
			}

			obj.Is_Batch_Processed__c = true;
			obj.Error_Message__c = '';
			ALL_RECORDS.add(obj);
		}
	}

	// Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
		// Debug Logs for reference
		System.debug('ALL_RECORDS------------' + ALL_RECORDS);
		System.debug('APEX_LOGS------------' + APEX_LOGS);

		// Update Stagging Object records
		if (ALL_RECORDS.size() > 0) {
			// Exception Handling
			try {
				update ALL_RECORDS;
			} catch (Exception err) {
				// Create Apex Log
				ExceptionHandlerController.createException(
					'TerritoryAlignment_Batch',
					'finish',
					'Batch Logic',
					'Update Territory Hirerarchy Stage',
					err.getMessage(),
					System.today()
				);
			}
		}

		// Capture Error Logs and Post
		if (APEX_LOGS.size() > 0) {
			insert APEX_LOGS;
		}
	}

	// Capture Error Message in full discrete info -- stamp to Apex_Log__c
	// Comment and Uncomment code line based on level of Error logs needed
	public void createExceptionLogs(
		List<SObject> lstRecords,
		String objective,
		System.DmlException err,
		Savepoint sp,
		Territory_Hierarchy__c obj
	) {
		String linebreak = '\n**************************************\n';
		String genericErrorMessage = '';
		String specificErrorMessage = '';

		for (Integer i = 0; i < err.getNumDml(); i++) {
			specificErrorMessage += linebreak + 'DISPLAY ERROR MESSAGE: ' + String.valueOf(err.getDmlMessage(i));
			specificErrorMessage += linebreak + 'DISPLAY RECORD: ' + String.valueOf(lstRecords.get(err.getDmlIndex(i)));
		}

		// Maximum Character Limit -- Strip out execessive characters
		if (specificErrorMessage.length() > 30000) {
			specificErrorMessage = specificErrorMessage.substring(0, 30000);
		}

		genericErrorMessage += linebreak + 'DISPLAY ERROR MESSAGE: ' + String.valueOf(err.getMessage());
		genericErrorMessage += linebreak + 'DISPLAY # FAILED ROWS : ' + String.valueOf(err.getNumDml());
		genericErrorMessage += linebreak + 'DISPLAY STACK TRACE: ' + String.valueOf(err.getStackTraceString());

		// Add record to custom Apex Log object for capturing
		APEX_LOGS.add(
			new Apex_Log__c(
				Location__c = 'TerritoryAlignment_Batch',
				Method_name__c = 'execute',
				Application_Name__c = 'Batch Logic',
				Log_Comments__c = objective,
				Integration_Request__c = genericErrorMessage,
				Integration_Response__c = specificErrorMessage,
				Fixed_Date__c = System.today()
			)
		);

		// Update Stagging Table record with Error Message for Business View
		ALL_RECORDS.add(
			new Territory_Hierarchy__c(
				Id = obj.Id,
				Is_Batch_Processed__c = false,
				Error_Message__c = specificErrorMessage + genericErrorMessage
			)
		);

		// Database Rollback to previous Saved Image
		Database.rollback(sp);

		// Throw Exception for Error Visibility
		throw new CustomException('Data Issue Encountered');
	}
}