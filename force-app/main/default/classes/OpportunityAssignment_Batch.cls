/****************************************************************************************************
 * Author Name   : Abinash Panigrahi
 * Class Name    : OpportunityAssignment_Batch
 * Created Date  : 29th June 2020
 * Description   : To Assign Opportunity based on Custom Rules in place based on PL Code/SKU
 * Test Class    : OpportunityAssignmentBatch_Test
****************************************************************************************************
	@comment : This below script is used to execute this batch job immediately.
	Database.executebatch(new OpportunityAssignment_Batch(), 1);
****************************************************************************************************/

global class OpportunityAssignment_Batch implements Database.Batchable<sObject>, Database.Stateful {
	// Class Level Variables
	global List<String> ALLOWED_OPPORTUNITY_SOURCE = new List<String>();
	global List<String> ACTIVE_ORG_REGION = new List<String>();
	global List<String> SALES_CREATED_ALLOWED_REGIONS = new List<String>();
	global Map<String, Id> DEFAULT_OPPORTUNITY_OWNER = new Map<String, Id>();
	global String DEFAULT_TERRITORY_TYPE_NAME;
	global String MAIN_TERRITORY_MODEL_NAME;

	// Automation Request Parameter
	global Date CloseDateFromValue;
	global Date CloseDateToValue;
	global String OrgRegionValue;
	global List<String> SalesStageValue;
	global Boolean IsBusinessAutomationJob;

	//Custom Exception
	public virtual class CustomException extends Exception {
	}

	// Overide Default Constructor 
	global OpportunityAssignment_Batch() {
		// Fetch Territory Setting Custom Metadata Types Config data -- 'Parent Territory Node'
		// Assumption: Only One Org-Specific record should exist
		Parent_Territory_Node__mdt config = [
			SELECT
				Id,
				Territory_Model_Name__c,
				AP__c,
				AP_GWI__c,
				EMEA__c,
				GC__c,
				JP__c,
				LATAM__c,
				NA__c,
				Region__c,
				Opportunity_Source__c,
				Type__c
			FROM Parent_Territory_Node__mdt
			LIMIT 1
		];

		// Get Allowed Opportunity Source to be part of Assignment Flow
		ALLOWED_OPPORTUNITY_SOURCE = String.valueOf(config.Opportunity_Source__c).split(',');

		// List of all Active Region in Organisation
		ACTIVE_ORG_REGION = String.valueOf(config.Region__c).split(',');

		// Fetch Default Territory Type Code for exclusion
		DEFAULT_TERRITORY_TYPE_NAME = config.Type__c;
		MAIN_TERRITORY_MODEL_NAME = config.Territory_Model_Name__c;

		// Store Mapping of Region-based Default Users
		for (String region : ACTIVE_ORG_REGION) {
			DEFAULT_OPPORTUNITY_OWNER.put(region.replace('_', '-'), String.valueOf(config.get(region + '__c')));
		}

		// Debug Logs for reference
		System.debug('config------------' + config);
		System.debug('ALLOWED_OPPORTUNITY_SOURCE------------' + ALLOWED_OPPORTUNITY_SOURCE);
		System.debug('ACTIVE_ORG_REGION------------' + ACTIVE_ORG_REGION);
		System.debug('DEFAULT_OPPORTUNITY_OWNER------------' + DEFAULT_OPPORTUNITY_OWNER);
	}

	// Batch's Start method to query all eligible Opportunity records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		// Current DateTime Stamp - Past One Hour
		Datetime currentTime = System.Now().addHours(-1);

		// Prepare Query String to extract data
		String soql = 'SELECT Id, AccountId, Channel__c, Region__c, ';
		soql += 'Opportunity_Source__c, CreatedDate, Retrigger_Assignment__c,  ';
		soql += '(SELECT Id, SKU_No__c FROM OpportunityLineItems), ';
		soql += '(SELECT Id, PL_Code__c FROM Opportunity_Product_Line__r), ';
		soql += '(SELECT Id FROM OpportunityTeamMembers) ';
		soql += 'FROM Opportunity ';

		// Conditional WHERE clause -- Normal or Business Request
		if (
			CloseDateFromValue == null &&
			CloseDateToValue == null &&
			OrgRegionValue == null &&
			SalesStageValue == null
		) {
			soql += 'WHERE ( CreatedDate >=: currentTime OR ';
			soql += 'Retrigger_Assignment__c = true ) AND ';
			soql += 'Opportunity_Source__c IN: ALLOWED_OPPORTUNITY_SOURCE AND ';
			soql += 'Region__c IN: ACTIVE_ORG_REGION AND ';
			soql += 'Channel__c != NULL AND AccountId != NULL ';

			// Mark not Bulk Job
			IsBusinessAutomationJob = false;
		} else {
			System.debug('CloseDateFromValue------------' + CloseDateFromValue);
			System.debug('CloseDateToValue------------' + CloseDateToValue);
			System.debug('OrgRegionValue------------' + OrgRegionValue);
			System.debug('SalesStageValue------------' + SalesStageValue);

			soql += 'WHERE CloseDate >=: CloseDateFromValue AND ';
			soql += 'CloseDate <=: CloseDateToValue  AND ';
			soql += 'StageName IN: SalesStageValue AND ';
			soql += 'Region__c =: OrgRegionValue AND ';
			soql += 'Channel__c != NULL AND AccountId != NULL ';
		}

		return Database.getQueryLocator(soql);
	}

	// Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, List<Opportunity> records) {
		// Debug Logs for reference
		System.debug('records------------' + records);
		System.debug('records.size()------------' + records.size());

		// Always Process Single Stagging Records -- Do set Batch Size during execution
		if (records.size() > 1) {
			return;
		} else {
			// Instantiate Stagging Records
			Opportunity obj = records[0];

			// Debug Logs for reference
			System.debug('obj------------' + obj);

			// Get Channel Info from Header -- Will needed for Assignment logic later
			String channel = obj.Channel__c;

			// Get Organization Region -- based on Primary Account country
			String region = obj.Region__c;

			// Store Product Line Name and SKU Name
			String oPLCode, oSKUNumber;
			Boolean isSKU = false, isPL = false;

			// Check if child Opportunity Product Line is present or not
			// Expected: One Product Line should be present at Maximum
			if (obj.Opportunity_Product_Line__r.size() > 0) {
				// Mark is exist flag true
				isPL = true;

				// Get PL Code value
				// If Multiple PL Code exist -- pick first one randomly
				oPLCode = obj.Opportunity_Product_Line__r[0].PL_Code__c;
			}

			// Repeat Same logic for Opportunity Product records
			if (obj.OpportunityLineItems.size() > 0) {
				isSKU = true;
				oSKUNumber = obj.OpportunityLineItems[0].SKU_No__c;
			}

			// Debug Logs for reference
			System.debug('oSKUNumber------------' + oSKUNumber);
			System.debug('oPLCode------------' + oPLCode);

			// Get Users assigned to Account from Territory Model
			// Equivalent Statement of Account Team
			AggregateResult agr = [
				SELECT Count(Id) recordCount
				FROM AccountUserTerritory2View
				WHERE AccountId = :obj.AccountId
			];

			Integer countAccountAssignedUsers = Integer.valueOf(agr.get('recordCount'));

			// Debug Logs for reference
			System.debug('countAccountAssignedUsers------------' + countAccountAssignedUsers);

			// If No Users present at Primary Acount level Scenario handling
			// Assign to default Opportunity Owner region-wise
			if (countAccountAssignedUsers == 0) {
				// Check If Default User exist or not
				// Applicable for Marketting
				if (
					obj.Opportunity_Source__c == 'Marketing' &&
					region != null &&
					DEFAULT_OPPORTUNITY_OWNER.containsKey(region) &&
					DEFAULT_OPPORTUNITY_OWNER.get(region) != null
				) {
					// Add Primary Opportunity Team Member
					obj.OwnerId = DEFAULT_OPPORTUNITY_OWNER.get(region);

					// Debug Logs for reference
					System.debug('obj.OwnerId------------' + obj.OwnerId);

					// Instance to store value
					List<OpportunityTeamMember> oppTeamList = obj.OpportunityTeamMembers;
					Opportunity oppObjRec = new Opportunity(
						Id = obj.Id,
						OwnerId = obj.OwnerId,
						Retrigger_Assignment__c = false
					);

					// Exception Handling
					try {
						// Bypass Trigger Logic
						OpportunityTriggerHandler.isFromAssignmentRuleJob = true;
						OpportunityTeamMemberTriggerHandler.isFromAssignmentRuleJob = true;

						// Bypass Email Notification
						if (IsBusinessAutomationJob) {
							OpportunityTriggerHandler.isFromBulkUpdateJob = true;
						}

						// Flush Opportunity Team members
						if (oppTeamList.size() > 0) {
							delete oppTeamList;
						}

						// Update Opportunity Primary Team Member
						update oppObjRec;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(oppTeamList, 'Update Primary Opportunity Team Member', err);
						return;
					}
				}

				// Skip all other lines of code execution
				return;
			}

			// Store mapping for Team members as per Territory type
			Map<String, List<Id>> territoryTypeUsermap = new Map<String, List<Id>>();
			Map<Id, String> userTerritoryMap = new Map<Id, String>();

			// Fetch all assigned Territories at Account level
			for (AccountUserTerritory2View team : [
				SELECT Id, UserId, Territory2.Territory2Type.MasterLabel, Territory2.Name
				FROM AccountUserTerritory2View
				WHERE AccountId = :obj.AccountId
			]) {
				// Null Check and Type code is not default
				String typeCode = team.Territory2.Territory2Type.MasterLabel;
				if (typeCode != DEFAULT_TERRITORY_TYPE_NAME) {
					// Map Relationship value
					if (!territoryTypeUsermap.containsKey(typeCode)) {
						territoryTypeUsermap.put(typeCode, new List<Id>());
					}

					territoryTypeUsermap.get(typeCode).add(team.UserId);
				}

				// Position value
				userTerritoryMap.put(team.UserId, team.Territory2.Name);
			}

			// Debug Logs for reference
			System.debug('territoryTypeUsermap------------' + territoryTypeUsermap);
			System.debug('territoryTypeUsermap.size()------------' + territoryTypeUsermap.size());

			// Gather unique values of Territory Type code
			Set<String> typeCodesSet = territoryTypeUsermap.keySet();

			// IMPORTANT
			// Find all Opportunity Assignment Rules based on certain condition
			// Region, Channel, Territory Type, PL Code or SKU #

			String query = 'SELECT Id, Priority__c, Priority_Order__c, Territory_Type_Code__c, ';
			query += 'Assign_Type__c, Channel__c, Comp_Component__c, Division__c, ';
			query += 'PL_Code__c, SKU__c, Region__c ';
			query += 'FROM Territory_Opportunity_Assignment_Rule__c ';
			query += 'WHERE Channel__c =: channel AND Region__c =: region AND ';
			query += 'Territory_Type_Code__c IN: typeCodesSet AND ';
			//query += 'Territory_Model_Name__c =: MAIN_TERRITORY_MODEL_NAME AND ';

			// Priority: If both PL and SKU exist as Child attribute
			// Then pick PL -- Business Future Goal to move toward Product Line
			if (isSKU) {
				query += ' Assign_Type__c = \'PL\' AND PL_Code__c =: oSKUNumber ';
				// query += ' Assign_Type__c = \'SKU\' AND SKU__c =: oSKUNumber ';
			} else if (isPL) {
				query += ' Assign_Type__c = \'PL\' AND PL_Code__c =: oPLCode ';
			} else {
				// Edge Case Scenario: If neither PL Code nor SKU exist at Opportunity level
				// Skip all other lines of code execution
				return;
			}

			// Dynamic Query Execute to get result condition based
			List<SObject> queryResults = Database.query(query);

			// Execute further logic, only if proper Opportunity Rules are found
			if (queryResults.size() > 0) {
				// Type-cast Custom rule Object
				List<Territory_Opportunity_Assignment_Rule__c> assignmentRules = (List<Territory_Opportunity_Assignment_Rule__c>) queryResults;

				// Debug Logs for reference
				System.debug('assignmentRules------------' + assignmentRules);
				System.debug('assignmentRules.size()------------' + assignmentRules.size());

				// Store Priority info based on Territory Type code
				Map<String, Integer> territoryTypePriority = new Map<String, Integer>();
				Set<String> assignedTerritoryTypes = new Set<String>();

				// Store Opportunity Ownership details
				String primaryTerritoryCodeName;
				Id opportunityOwnerId;

				// Loop through Opportunity Assignment Rule records
				for (Territory_Opportunity_Assignment_Rule__c rules : assignmentRules) {
					// Keep track of all codes
					assignedTerritoryTypes.add(rules.Territory_Type_Code__c);

					// Check if Priority flag is Y
					if (rules.Priority__c) {
						territoryTypePriority.put(
							rules.Territory_Type_Code__c,
							Integer.valueOf(rules.Priority_Order__c)
						);
					}
				}

				// Debug Logs for reference
				System.debug('territoryTypePriority------------' + territoryTypePriority);
				System.debug('assignedTerritoryTypes------------' + assignedTerritoryTypes);

				// Scenario 1 :  Person with Channel of Opty and Priority = Y and Priority Order is null =  Primary
				// Condition -- If and only If One Territory Code is having Priority = Y
				if (territoryTypePriority.size() == 1) {
					// Get Primary Territory info
					primaryTerritoryCodeName = (new List<String>(territoryTypePriority.keySet())[0]);

					// Debug Logs for reference
					System.debug('Scenario 1 : primaryTerritoryCodeName ------------' + primaryTerritoryCodeName);
				}

				// Scenario 2 : Person with Channel of Opty and Priority = Y and Priority Order is not null then Priority Order assign Primary from lowest to Highest
				// Condition -- If more than one Territory Code is having Priority = Y
				if (territoryTypePriority.size() > 1) {
					// Get Get Primary Territory info -- If Priority Order value exist
					Integer count = 0;
					Boolean noOrderPresent = false;
					for (String code : territoryTypePriority.keySet()) {
						// Priority Order -- Null Check
						Integer order = territoryTypePriority.get(code);
						if (order != null) {
							// Priority Order Comparision
							if (count < order) {
								count = order;
								noOrderPresent = true;

								// Found Primary Territory Type Code
								primaryTerritoryCodeName = code;
							}
						}
					}

					// Get Primary Territory info -- If Priority Order doesnot value exist
					if (!noOrderPresent) {
						// Found Primary Territory Type Code
						primaryTerritoryCodeName = (new List<String>(territoryTypePriority.keySet())[0]);
					}

					// Debug Logs for reference
					System.debug('Scenario 2 : primaryTerritoryCodeName ------------' + primaryTerritoryCodeName);
				}

				// Scenario 3 : Person with Channel of Opty and no Priority = Primary Team Member. If the channel is repeated on multiple Territory Type Codes for the same PL then the territory with the lowest alpha numeric value wins primary
				// Condition -- No Priority found
				if (territoryTypePriority.size() == 0) {
					// Sort with Alphanumeric name values
					List<String> codes = new List<String>(assignedTerritoryTypes);
					codes.sort();

					// Get Primary Territory info
					primaryTerritoryCodeName = codes[0];

					// Debug Logs for reference
					System.debug('Scenario 3 : primaryTerritoryCodeName ------------' + primaryTerritoryCodeName);
				}

				// Assign Opportunity Ownership
				if (
					primaryTerritoryCodeName != null &&
					territoryTypeUsermap.containsKey(primaryTerritoryCodeName) &&
					territoryTypeUsermap.get(primaryTerritoryCodeName).size() > 0
				) {
					// Check Territory Code is having Users assigned under it on Primary Account
					opportunityOwnerId = territoryTypeUsermap.get(primaryTerritoryCodeName)[0];

					// Debug Logs for reference
					System.debug('opportunityOwnerId ------------' + opportunityOwnerId);
				}

				// Prepare Opportunity Team Members list
				List<OpportunityTeamMember> oppTeams = new List<OpportunityTeamMember>();

				// Loop through all Territory codes we got from Opportunity Rules
				for (String territoryCode : assignedTerritoryTypes) {
					// Check Territory Code is having Users assigned under it on Primary Account
					if (
						territoryTypeUsermap.containsKey(territoryCode) &&
						territoryTypeUsermap.get(territoryCode).size() > 0
					) {
						// Loop through User list
						for (Id userId : territoryTypeUsermap.get(territoryCode)) {
							// Create Opportunity Team Member records
							OpportunityTeamMember oTeam = new OpportunityTeamMember();
							oTeam.OpportunityId = obj.Id;
							oTeam.UserId = userId;
							oTeam.OpportunityAccessLevel = Label.OppTeamMember_OppAccessLevel;
							oTeam.TeamMemberRole = Label.OppTeamMember_OppTeamMemberRole;

							// Mark Primary User
							if (userId == opportunityOwnerId) {
								oTeam.isPrimary__c = true;
							}

							// Add Territory Name equivalent to Position
							if (userTerritoryMap.containsKey(userId)) {
								oTeam.Position__c = userTerritoryMap.get(userId);
							}

							// Add to collection
							oppTeams.add(oTeam);
						}
					}
				}

				// Debug Logs for reference
				System.debug('oppTeams ------------' + oppTeams);
				System.debug('oppTeams.size() ------------' + oppTeams.size());
				System.debug('obj.OpportunityTeamMembers ------------' + obj.OpportunityTeamMembers);

				// Turn Reassignment Flag and Owner Change
				Opportunity toBeAssignedOppty = new Opportunity(
					Id = obj.Id,
					Retrigger_Assignment__c = false,
					OwnerId = opportunityOwnerId
				);

				// Insert Opportunity Team Members
				if (oppTeams.size() > 0) {
					// Exception Handling
					try {
						// Bypass Trigger Logic
						OpportunityTriggerHandler.isFromAssignmentRuleJob = true;
						OpportunityTeamMemberTriggerHandler.isFromAssignmentRuleJob = true;

						// Bypass Email Notification
						if (IsBusinessAutomationJob) {
							OpportunityTriggerHandler.isFromBulkUpdateJob = true;
						}

						// Clear out Existing Opportunity Team Members
						if (obj.OpportunityTeamMembers.size() > 0) {
							delete obj.OpportunityTeamMembers;
						}

						// Then add New folks to Opportunity
						insert oppTeams;

						// Update Opportunity Header
						update toBeAssignedOppty;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(oppTeams, 'Insert & Delete Opportunity Team Member', err);
						return;
					}
				}

				// Send Assignment Email Notification to Opportunity Owner
				//
				//
			} else {
				// Edge Case Scenario: If No rules found for Opportunity
				// Skip all other lines of code execution

				// Check If Default User exist or not
				if (
					obj.Opportunity_Source__c == 'Marketing' &&
					region != null &&
					DEFAULT_OPPORTUNITY_OWNER.containsKey(region) &&
					DEFAULT_OPPORTUNITY_OWNER.get(region) != null
				) {
					// Add Primary Opportunity Team Member
					obj.OwnerId = DEFAULT_OPPORTUNITY_OWNER.get(region);

					// Debug Logs for reference
					System.debug('obj.OwnerId------------' + obj.OwnerId);

					// Instance to store value
					List<OpportunityTeamMember> oppTeamList = obj.OpportunityTeamMembers;
					Opportunity oppObjRec = new Opportunity(
						Id = obj.Id,
						OwnerId = obj.OwnerId,
						Retrigger_Assignment__c = false
					);

					// Exception Handling
					try {
						// Bypass Trigger Logic
						OpportunityTriggerHandler.isFromAssignmentRuleJob = true;
						OpportunityTeamMemberTriggerHandler.isFromAssignmentRuleJob = true;

						// Bypass Email Notification
						if (IsBusinessAutomationJob) {
							OpportunityTriggerHandler.isFromBulkUpdateJob = true;
						}

						// Flush Opportunity Team members
						if (oppTeamList.size() > 0) {
							delete oppTeamList;
						}

						// Update Opportunity Primary Team Member
						update oppObjRec;
					} catch (System.DmlException err) {
						// Create Apex Log
						createExceptionLogs(oppTeamList, 'Update Primary Opportunity Team Member', err);
						return;
					}
				}
				// Skip all other lines of code execution
				return;
			}
		}
	}

	// Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
	}

	// Capture Error Message in full discrete info -- stamp to Apex_Log__c
	// Comment and Uncomment code line based on level of Error logs needed
	public void createExceptionLogs(List<SObject> lstRecords, String objective, System.DmlException err) {
		// Prepare Meaningful Error Message
		String linebreak = '\n**************************************\n';
		String genericErrorMessage = '';
		String specificErrorMessage = '';

		for (Integer i = 0; i < err.getNumDml(); i++) {
			specificErrorMessage += linebreak + 'DISPALY ERROR MESSAGE: ' + String.valueOf(err.getDmlMessage(i));
			specificErrorMessage += linebreak + 'DISPALY RECORD: ' + String.valueOf(lstRecords.get(err.getDmlIndex(i)));
		}

		// Maximum Character Limit -- Strip out execessive characters
		if (specificErrorMessage.length() > 30000) {
			specificErrorMessage = specificErrorMessage.substring(0, 30000);
		}

		genericErrorMessage += linebreak + 'DISPALY ERROR MESSAGE: ' + String.valueOf(err.getMessage());
		genericErrorMessage += linebreak + 'DISPALY # FAILED ROWS : ' + String.valueOf(err.getNumDml());
		genericErrorMessage += linebreak + 'DISPALY STACK TRACE: ' + String.valueOf(err.getStackTraceString());

		// Add record to custom Apex Log object for capturing
		insert new Apex_Log__c(
			Location__c = 'OpportunityAssignment_Batch',
			Method_name__c = 'execute',
			Application_Name__c = 'Batch Logic',
			Log_Comments__c = objective,
			Integration_Request__c = genericErrorMessage,
			Integration_Response__c = specificErrorMessage,
			Fixed_Date__c = System.today()
		);

		// Throw Exception for Error Visibility
		throw new CustomException('Data Issue Encountered');
	}
}

/*******************************************
    @comment : This below script is used to execute this batch job hourly.
    System.schedule('Opportunity Rule Assignment Batch Job', '0 10 0/1 1/1 * ? *', new OpportunityAssignmentBatch_Schedulde());
    ********************************************/

/*******************************************
    @comment : This below script is used to execute this batch job immediately.
    Database.executebatch(new OpportunityAssignment_Batch(), 1);
    ********************************************/