// ===========================================================================
//  Object: OpportunityTriggerHandler
//  Company: Keste @IDC
//  Author: Abinash Panigrahi
//  Purpose: Handler Class contains all logic for OpportunityTrigger.
// ===========================================================================

public class OpportunityTriggerHandler {
	public static Boolean isFromLeadConversion = false;
	public static Boolean isFromAssignmentRuleJob = false;
	public static Boolean isFromBulkUpdateJob = false;
	public static String ERROR_MESSAGE = Label.OPPORTUNITY_TRIGGER_ERRORMESSAGE;

	// Method Name: populateCurrencyPricebook
	// Author: Abinash panigrahi
	// Description: Method to populate PriceBookId and CurrencyIsoCode with Account's Price_Book__c and CurrencyIsoCode
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Parameter 2: oldMap - Map of IDs to the  old versions of the Opportunity records
	// Return: Null
	public static void populateCurrencyPricebook(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		// Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.populateCurrencyPricebook') &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store AccountId values
			Set<Id> accIds = new Set<Id>();
			//Instance to store PriceBookId values
			Set<Id> pricebookIds = new Set<Id>();
			for (Opportunity o : newRec) {
				if (o.AccountId != null && o.Pricebook2Id == null && oldMap == null) {
					accIds.add(o.AccountId);
				}
				if (
					o.Pricebook2Id != null &&
					(oldMap == null ||
					(oldMap != null &&
					o.Pricebook2Id != oldMap.get(o.Id).Pricebook2Id &&
					o.AccountId == oldMap.get(o.Id).AccountId))
				) {
					pricebookIds.add(o.Pricebook2Id);
				}
			}

			CommonUtilities.debug('accIds------->>>>>>>' + accIds);
			CommonUtilities.debug('pricebookIds------->>>>>>>' + pricebookIds);

			if (accIds.size() > 0) {
				//Mapping AccountId with their respective PricebookId
				Map<Id, Id> accPricebookMap = new Map<Id, Id>();

				//Fetch all related Accounts and store values
				for (Account a : [
					SELECT Id, Price_Book__c, CurrencyIsoCode, Price_Book__r.Super_Price_Book_Override__c
					FROM Account
					WHERE Id IN :accIds AND Price_Book__c != NULL
				]) {
					if (a.Price_Book__c != null && a.Price_Book__r.Super_Price_Book_Override__c != null) {
						accPricebookMap.put(a.Id, a.Price_Book__r.Super_Price_Book_Override__c);
					} else {
						accPricebookMap.put(a.Id, a.Price_Book__c);
					}
					pricebookIds.add(a.Price_Book__c);
				}

				CommonUtilities.debug('accPricebookMap------->>>>>>>' + accPricebookMap);
				CommonUtilities.debug('pricebookIds------->>>>>>>' + pricebookIds);

				if (pricebookIds.size() > 0) {
					//Mapping PriceBookId with their respective CurrencyIsoCode
					Map<Id, String> pricebookCurrencyMap = new Map<Id, String>();
					//Fetch related Pricebook Currency
					for (Pricebook2 pb : [
						SELECT
							Id,
							Currency_Code__c,
							Super_Price_Book_Override__c,
							Super_Price_Book_Override__r.Name,
							Super_Price_Book_Override__r.Currency_Code__c
						FROM Pricebook2
						WHERE Id IN :pricebookIds AND Currency_Code__c != NULL
					]) {
						if (
							pb.Super_Price_Book_Override__c != null &&
							pb.Super_Price_Book_Override__r.Currency_Code__c != null
						) {
							pricebookCurrencyMap.put(
								pb.Super_Price_Book_Override__c,
								pb.Super_Price_Book_Override__r.Currency_Code__c
							);
						} else {
							pricebookCurrencyMap.put(pb.Id, pb.Currency_Code__c);
						}
					}

					CommonUtilities.debug('pricebookCurrencyMap------->>>>>>>' + pricebookCurrencyMap);

					//Update Logic
					//Populate Opportunity records with Account's PriceBook
					//Populate Opportunity records with Account's Currency
					for (Opportunity o : newRec) {
						if (o.AccountId != null && o.Pricebook2Id == null && accPricebookMap.containsKey(o.AccountId)) {
							o.Pricebook2Id = accPricebookMap.get(o.AccountId);
							if (pricebookCurrencyMap.containsKey(accPricebookMap.get(o.AccountId))) {
								o.CurrencyIsoCode = pricebookCurrencyMap.get(accPricebookMap.get(o.AccountId));
							}
						}
						if (
							o.AccountId != null &&
							o.Pricebook2Id != null &&
							pricebookCurrencyMap.containsKey(o.Pricebook2Id)
						) {
							o.CurrencyIsoCode = pricebookCurrencyMap.get(o.Pricebook2Id);
						}
					}
				}
			}
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
		}
	}

	// Method Name: populateCampaign
	// Author: Abinash panigrahi
	// Description: Method to populate Campaign based on Siebel_Row_Id__c value
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Parameter 2: oldMap - Map of IDs to the  old versions of the Opportunity records
	// Return: Null

	public static void populateCampaign(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		//If(Boolean.valueOf(Label.OPPORTUNITY_POPULATECAMPAIGN)){
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.populateCampaign') &&
			CommonUtilities.isIntegrationOrMigrationUser() &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('Inside populateCampaign method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Handle Insert & Update Scenario -- Common Logic for both Case
			//Instance to store unique StarTrack Ids present in Opportunity record
			Set<String> starTrackIds = new Set<String>();
			//Instance to store to be Updated Rec
			List<Opportunity> toBeUpdatedRec = new List<Opportunity>();
			//Populate the instance
			for (Opportunity o : newRec) {
				if (
					o.Lead_Source_Id__c != null &&
					(oldMap == null || (oldMap != null && o.Lead_Source_Id__c != oldMap.get(o.Id).Lead_Source_Id__c))
				) {
					starTrackIds.add(o.Lead_Source_Id__c);
					toBeUpdatedRec.add(o);
				}
			}

			CommonUtilities.debug('starTrackIds------->>>>>>>' + starTrackIds);
			CommonUtilities.debug('toBeUpdatedRec------->>>>>>>' + toBeUpdatedRec);

			if (starTrackIds.size() > 0) {
				//Instance to Map the relationship of ExternalId with Campaign RecordId
				Map<String, Id> startrackCampaignMap = new Map<String, Id>();
				//Fetch Related Campaign records which Contain these External Ids
				for (Campaign c : [SELECT Id, StarTrack_Id__c FROM Campaign WHERE StarTrack_Id__c IN :starTrackIds]) {
					startrackCampaignMap.put(c.StarTrack_Id__c, c.Id);
				}

				CommonUtilities.debug('startrackCampaignMap------->>>>>>>' + startrackCampaignMap);

				//Tnstance to store newly Campaign Record
				List<Campaign> toInsertCampaign = new List<Campaign>();
				//Create Campaign Record with StarTrackId populated
				for (Opportunity o : toBeUpdatedRec) {
					if (
						o.Lead_Source_Id__c != null &&
						//START - Basant: 3rd Feb, 2020
						o.Lead_Source_Name__c != null &&
						//END - Basant: 3rd Feb, 2020
						!startrackCampaignMap.containsKey(o.Lead_Source_Id__c)
					) {
						toInsertCampaign.add(
							new Campaign(Name = o.Lead_Source_Name__c, StarTrack_Id__c = o.Lead_Source_Id__c)
						);
					}
				}

				//Exception Handling
				//Insert Campaign record
				try {
					if (toInsertCampaign.size() > 0) {
						insert toInsertCampaign;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'OpportunityTriggerHandler',
						'createCampaignRec',
						'Trigger Logic',
						'Insert Campaign',
						ex.getMessage(),
						System.today()
					);
					CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
				}

				CommonUtilities.debug('toInsertCampaign------->>>>>>>' + toInsertCampaign);

				//Add newly Inserted record to Relationship map of Lead Source Id and Campaign RecordId
				for (Campaign cmp : toInsertCampaign) {
					startrackCampaignMap.put(cmp.StarTrack_Id__c, cmp.Id);
				}

				CommonUtilities.debug('startrackCampaignMap------->>>>>>>' + startrackCampaignMap);

				//Tnstance to store newly Campaign Record
				List<Opportunity> toUpdateRec = new List<Opportunity>();
				//Update Opportunity records with their respective CampaignId
				for (Opportunity o : toBeUpdatedRec) {
					if (startrackCampaignMap.containsKey(o.Lead_Source_Id__c) && o.Lead_Source_Id__c != null) {
						toUpdateRec.add(
							new Opportunity(Id = o.Id, CampaignId = startrackCampaignMap.get(o.Lead_Source_Id__c))
						);
					}
				}

				//Exception Handling
				//Insert Campaign record
				try {
					if (toUpdateRec.size() > 0) {
						update toUpdateRec;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'OpportunityTriggerHandler',
						'createCampaignRec',
						'Trigger Logic',
						'Update Opportunity',
						ex.getMessage(),
						System.today()
					);
					CommonUtilities.debug('Error Message ---->>>' + ex.getMessage());
				}
			}
			CommonUtilities.debug('Exit populateCampaign method');
		}
	}

	// Method Name: syncOpportunityWithSiebel
	// Author: Abinash Panigrahi
	// Description: Method to send the Siebel Request when the Opportunity is Updated
	// Parameter 1: List<Opportunity> lstnewOpps - List of the new versions of the Opportunity records
	// Parameter 2: Map<Id,Opportunity> oldOppMap - Map of the old versions of the Opportunity records
	// Return: Null

	public static void syncOpportunityWithSiebel(List<Opportunity> lstnewOpps, Map<Id, Opportunity> oldOppMap) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.syncOpportunityWithSiebel') &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('Inside syncOpportunityWithSiebel method');
			CommonUtilities.debug('lstnewOpps------->>>>>>>' + lstnewOpps);
			CommonUtilities.debug('oldOppMap------->>>>>>>' + oldOppMap);

			//Fetch all Fields present in Contact Integration FieldSet
			Set<String> fieldSet = new Set<String>();
			for (
				Schema.FieldSetMember fields : Schema.SObjectType.Opportunity.fieldSets.getMap()
					.get('Opportunity_Siebel')
					.getFields()
			) {
				fieldSet.add(fields.getFieldPath());
			}

			CommonUtilities.debug('fieldSet------->>>>>>>' + fieldSet);

			//START - Basant: 5th Feb, 2020
			Set<String> validOppSourceForIntegration = new Set<String>();
			for (String src : Label.ValidOpportunitySourceForIntegration.split(',')) {
				validOppSourceForIntegration.add(src.trim());
			}
			//END - Basant: 5th Feb, 2020

			//Instance to hold Multiple Header records for Callouts
			Set<Id> setOpportunityId = new Set<Id>();

			//Loop Logic
			//Inbount Integration Callout is make, if certain Conditions are met
			for (Opportunity objOpp : lstnewOpps) {
				if (
					objOpp.Siebel_Row_Id__c != null &&
					//END - Basant: 5th Feb, 2020
					objOpp.Opportunity_Source__c != null &&
					validOppSourceForIntegration.contains(objOpp.Opportunity_Source__c) //END - Basant: 5th Feb, 2020
				) {
					if (oldOppMap != null && fieldSet.size() > 0) {
						//Check if any field value is changed for FieldSetMember
						//Then only send Integration Request
						for (string strFieldAPI : fieldSet) {
							if (objOpp.get(strFieldAPI) != oldOppMap.get(objOpp.Id).get(strFieldAPI)) {
								setOpportunityId.add(objOpp.Id);
								break;
							}
						}
					}
				}
			}

			//Make Asynchronous Multiple Callout for Siebel Sync
			if (setOpportunityId.size() > 0) {
				IntegrationUtility.SynctoSiebel('OPPORTUNITY', setOpportunityId, 'UPDATE', 'UPDATE', 'OPPORTUNITY');
			}

			CommonUtilities.debug('Exit syncOpportunityWithSiebel method');
		}
	}

	// Method Name: createPrimaryOpportunityContactRole
	// Author: Abinash panigrahi
	// Description: Method to maintain Primary Opportunity Contact Role record at Opportunity level
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Parameter 2: oldMap - Map of IDs to the  old versions of the Opportunity records
	// Return: Null
	public static void createPrimaryOpportunityContactRole(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		// Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.createPrimaryOpportunityContactRole') &&
			!isFromLeadConversion &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('Inside createPrimaryOpportunityContactRole method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store to be created new Primary Opportunity Contact records
			List<OpportunityContactRole> toBeInsertedRec = new List<OpportunityContactRole>();
			//Instance to store existing Opportunity record Ids
			Set<Id> oppIds = new Set<Id>();
			//Instance to store to be updated non-Primary Opportunity Contact records
			List<OpportunityContactRole> toBeUpdatedRec = new List<OpportunityContactRole>();
			List<OpportunityContactRole> toBeUpdatedRecNew = new List<OpportunityContactRole>();
			//Instance to store unique key, concatenation of Opportunity Id and Contact Id
			Set<String> uniqueKey = new Set<String>();

			//Loop Logic
			//Handle Insert & Update scenario of Opportunity record
			//List out to create primary records -- Insert
			//Populate unique key set of values -- Update
			for (Opportunity opp : newRec) {
				if (
					(oldMap == null && opp.Primary_Contact__c != null) ||
					(oldMap != null &&
					opp.Primary_Contact__c != oldMap.get(opp.Id).Primary_Contact__c)
				) {
					uniqueKey.add(opp.Id + '_' + opp.Primary_Contact__c);
					oppIds.add(opp.Id);
				}
			}

			CommonUtilities.debug('toBeInsertedRec------->>>>>>>' + toBeInsertedRec);
			CommonUtilities.debug('uniqueKey------->>>>>>>' + uniqueKey);
			CommonUtilities.debug('oppIds------->>>>>>>' + oppIds);

			if (oppIds.size() > 0) {
				//Fetch existing Opportunity Contact records
				//Need to list out to be update Opportunity record
				//Primary -> Non-Primary, if existing record exists
				for (OpportunityContactRole ocr : [
					SELECT Id, IsPrimary, ContactId, OpportunityId
					FROM OpportunityContactRole
					WHERE OpportunityId IN :oppIds
				]) {
					String keyField = ocr.OpportunityId + '_' + ocr.ContactId;
					if (uniqueKey.contains(keyField)) {
						toBeUpdatedRecNew.add(new OpportunityContactRole(Id = ocr.Id, IsPrimary = true));
						uniqueKey.remove(keyField);
					} else if (ocr.IsPrimary == true) {
						toBeUpdatedRec.add(new OpportunityContactRole(Id = ocr.Id, IsPrimary = false));
					}
				}

				CommonUtilities.debug('toBeUpdatedRecNew------->>>>>>>' + toBeUpdatedRecNew);
				CommonUtilities.debug('toBeUpdatedRec------->>>>>>>' + toBeUpdatedRec);
				CommonUtilities.debug('uniqueKey------->>>>>>>' + uniqueKey);

				//Create new Primary Opportunity Contact record
				for (String ocr : uniqueKey) {
					if (ocr.length() > 36) {
						String[] idsKey = ocr.split('_');
						toBeInsertedRec.add(
							new OpportunityContactRole(
								OpportunityId = idsKey[0],
								ContactId = idsKey[1],
								IsPrimary = true
							)
						);
					}
				}

				CommonUtilities.debug('toBeInsertedRec------->>>>>>>' + toBeInsertedRec);

				//Exception Handling
				//Update Opportunity Contact Role record
				try {
					OpportunityContactRoleTriggerHandler.isFromOpportunityTrigger = true;
					if (toBeUpdatedRec.size() > 0) {
						update toBeUpdatedRec;
					}
					if (toBeUpdatedRecNew.size() > 0) {
						update toBeUpdatedRecNew;
					}
					OpportunityContactRoleTriggerHandler.isFromOpportunityTrigger = false;
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'OpportunityTriggerHandler',
						'createPrimaryOpportunityContactRole',
						'Trigger Logic',
						'Update Opportunity Contact Role record',
						ex.getMessage(),
						System.today()
					);
				}

				//Exception Handling
				//Insert Opportunity Contact Role record
				try {
					if (toBeInsertedRec.size() > 0) {
						insert toBeInsertedRec;
					}
				} catch (Exception ex) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'OpportunityTriggerHandler',
						'createPrimaryOpportunityContactRole',
						'Trigger Logic',
						'Insert Opportunity Contact Role record',
						ex.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	// Method Name: createUpdateOpportunityTeamMember
	// Author: Keste Dev
	// Description: Method to create primary Opportunity Team member when Opportunity Insert or Opportunity Owner Updated
	// Parameter 1: List<Opportunity> lstnewOpps - List of the new versions of the Opportunity records
	// Parameter 2: Map<Id,Opportunity> oldOppMap - Map of the old versions of the Opportunity records
	// Return: Null
	public static void createUpdateOpportunityTeamMember(
		List<Opportunity> triggerNew,
		Map<Id, Opportunity> triggerOldMap
	) {
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.createUpdateOpportunityTeamMember') &&
			!isFromAssignmentRuleJob
		) {
			List<OpportunityTeamMember> lstOpportunityTeamMemberToInsert = new List<OpportunityTeamMember>();
			List<OpportunityTeamMember> lstOpportunityTeamMemberToUpdate = new List<OpportunityTeamMember>();
			Map<String, OpportunityTeamMember> mapOpportunityTeamMembers = new Map<String, OpportunityTeamMember>();
			Map<Id, Id> mapOpportunityIdWithUserId = new Map<Id, Id>();
			Map<Id, Id> oppAccountMap = new Map<Id, Id>();

			for (Opportunity opp : triggerNew) {
				if (
					String.valueOf(opp.OwnerId).startsWith('005') &&
					(triggerOldMap == null ||
					(triggerOldMap != null &&
					opp.OwnerId != triggerOldMap.get(opp.Id).OwnerId))
				) {
					mapOpportunityIdWithUserId.put(opp.Id, opp.OwnerId);
					oppAccountMap.put(opp.Id, opp.AccountId);
				}
			}

			if (!mapOpportunityIdWithUserId.IsEmpty() && triggerOldMap != null) {
				for (OpportunityTeamMember oppTeamMember : [
					SELECT Id, UserId, TeamMemberRole, OpportunityId, OpportunityAccessLevel, isPrimary__c
					FROM OpportunityTeamMember
					WHERE OpportunityId IN :mapOpportunityIdWithUserId.keyset()
				]) {
					mapOpportunityTeamMembers.put(
						oppTeamMember.OpportunityId +
						'_' +
						oppTeamMember.UserId,
						oppTeamMember
					);
				}
			}

			for (Id oppId : mapOpportunityIdWithUserId.keySet()) {
				if (triggerOldMap != null) {
					Id oldOppOwnerId = triggerOldMap.get(oppId).OwnerId;
					String oldOppOwnerkey = oppId + '_' + oldOppOwnerId;
					if (mapOpportunityTeamMembers.containsKey(oldOppOwnerkey)) {
						OpportunityTeamMember otm = mapOpportunityTeamMembers.get(oldOppOwnerkey);
						otm.isPrimary__c = false;
						lstOpportunityTeamMemberToUpdate.add(otm);
					}
				}

				Id oppOwnerId = mapOpportunityIdWithUserId.get(oppId);
				String oppOwnerkey = oppId + '_' + oppOwnerId;
				Id accountId = oppAccountMap.get(oppId);
				if (mapOpportunityTeamMembers.containsKey(oppOwnerkey)) {
					OpportunityTeamMember otm = mapOpportunityTeamMembers.get(oppOwnerkey);
					otm.isPrimary__c = true;
					lstOpportunityTeamMemberToUpdate.add(otm);
				} else {
					lstOpportunityTeamMemberToInsert.add(
						createOpportunityTeamMember(oppId, oppOwnerId, accountId, true)
					);
				}
			}

			if (lstOpportunityTeamMemberToUpdate.size() > 0) {
				update lstOpportunityTeamMemberToUpdate;
			}
			if (lstOpportunityTeamMemberToInsert.size() > 0) {
				insert lstOpportunityTeamMemberToInsert;
			}
		}
	}

	// Method Name: createOpportunityTeamMember
	// Author: Keste Dev
	// Description: Method to create primary Opportunity Team member when Opportunity Insert or Opportunity Owner Updated
	// Parameter 1: oppId - current Opportunity record Id
	// Parameter 2: ownerId - current Opportunity record's OwnerId
	// Parameter 3: isPrimary - to create primary Opportunity Team Member
	// Return: OpportunityTeamMember - OpportunityTeamMember record for provided opportunity and it's owner
	public static OpportunityTeamMember createOpportunityTeamMember(Id oppId, Id ownerId, Id accId, Boolean isPrimary) {
		OpportunityTeamMember oOpportunityTeamMember = new OpportunityTeamMember();
		oOpportunityTeamMember.OpportunityId = oppId;
		oOpportunityTeamMember.UserId = ownerId;
		oOpportunityTeamMember.isPrimary__c = isPrimary;
		oOpportunityTeamMember.OpportunityAccessLevel = Label.OppTeamMember_OppAccessLevel;
		oOpportunityTeamMember.TeamMemberRole = Label.OppTeamMember_OppTeamMemberRole;

		if (
			!(CommonUtilities.isMigrationUser() ||
			CommonUtilities.isIntegrationUser() ||
			CommonUtilities.isCPQIntegrationUser() ||
			CommonUtilities.isSystemAdminUser())
		) {
			for (AccountUserTerritory2View obj : [
				SELECT Id, AccountId, Territory2.Name, UserId
				FROM AccountUserTerritory2View
				WHERE AccountId = :accId AND UserId = :ownerId
				LIMIT 1
			]) {
				oOpportunityTeamMember.Position__c = obj.Territory2.Name;
			}
		}

		return oOpportunityTeamMember;
	}

	// Method Name: handleCurrencyChange
	// Author: Basant Kumar Verma
	// Description: Method to handle the Currency Change to NOT set PriceBook2Id as null
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Parameter 2: oldMap - Map of IDs to the  old versions of the Opportunity records
	// Return: Null
	private static Boolean isPricebookReverted = false;
	public static void handleCurrencyChange(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.handleCurrencyChange') &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('============================= handleCurrencyChange');
			// Dynamic Code Execution
			if (
				!isPricebookReverted &&
				DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.handleCurrencyChange')
			) {
				List<Opportunity> oppToUpdate = new List<Opportunity>();
				for (Opportunity opp : newRec) {
					CommonUtilities.debug('============================= opp ' + opp);
					if (
						oldMap != null &&
						opp.CurrencyIsoCode != oldMap.get(opp.Id).CurrencyIsoCode &&
						opp.Pricebook2Id == null &&
						oldMap.get(opp.Id).Pricebook2Id != null
					) {
						oppToUpdate.add(new Opportunity(Id = opp.Id, Pricebook2Id = oldMap.get(opp.Id).Pricebook2Id));
					}
				}

				CommonUtilities.debug('============================= oppToUpdate ' + oppToUpdate);
				if (oppToUpdate.size() > 0) {
					isPricebookReverted = true;
					update oppToUpdate;
				}
			}
		}
	}

	// Method Name: fiscalPeriodCalculate
	// Author: Abinash panigrahi
	// Description: Method to calculate Fiscal Period of Opportunity based on Close Date
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Parameter 2: oldMap - Map of IDs to the  old versions of the Opportunity records
	// Return: Null
	public static void fiscalPeriodCalculate(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.fiscalPeriodCalculate') &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('Inside fiscalPeriodCalculate method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			//Instance to store all unique Close date's Year
			Set<String> yearRange = new Set<String>();
			//Loop Logic
			//Run search on Oppty Close Date and see it falls under which Quarter
			for (Opportunity o : newRec) {
				if (
					o.CloseDate != null &&
					(oldMap == null ||
					(o.CloseDate != oldMap.get(o.Id).CloseDate ||
					(o.Retrigger_Fiscal_Quarter__c &&
					oldMap.get(o.Id).Retrigger_Fiscal_Quarter__c != o.Retrigger_Fiscal_Quarter__c)))
				) {
					yearRange.add(String.valueOf(o.CloseDate.year()));
				}
			}

			CommonUtilities.debug('yearRange------->>>>>>>' + yearRange);

			//Conditional SOQL Query
			if (yearRange != null) {
				//Fetch Custom Fiscal Year defined by Business
				//Need to get all Quaters defined for Custom Fiscal Year with labels and Start & Enddate
				List<Period> quarterPeriod = new List<Period>(
					[
						SELECT
							FiscalYearSettings.Name,
							EndDate,
							FiscalYearSettingsId,
							FullyQualifiedLabel,
							Id,
							StartDate
						FROM Period
						WHERE
							Type = 'Quarter'
							AND FiscalYearSettings.IsStandardYear = FALSE
							AND FiscalYearSettings.Name IN :yearRange
					]
				);

				//Loop Logic
				//Map all relevant periods belonging to certain years
				Map<String, List<Period>> yearPeriodMap = new Map<String, List<Period>>();
				for (Period p : quarterPeriod) {
					if (!yearPeriodMap.containsKey(p.FiscalYearSettings.Name)) {
						yearPeriodMap.put(p.FiscalYearSettings.Name, new List<Period>());
					}
					yearPeriodMap.get(p.FiscalYearSettings.Name).add(p);
				}

				CommonUtilities.debug('quarterPeriod------->>>>>>>' + quarterPeriod);
				CommonUtilities.debug('yearPeriodMap------->>>>>>>' + yearPeriodMap);

				//Loop Logic
				//Run search on Oppty Close Date and see it falls under which Quarter
				for (Opportunity o : newRec) {
					if (
						o.CloseDate != null &&
						(oldMap == null ||
						(o.CloseDate != oldMap.get(o.Id).CloseDate ||
						(o.Retrigger_Fiscal_Quarter__c &&
						oldMap.get(o.Id).Retrigger_Fiscal_Quarter__c != o.Retrigger_Fiscal_Quarter__c)))
					) {
						String year = String.valueOf(o.CloseDate.year());
						if (yearPeriodMap.containsKey(year)) {
							List<Period> quarter = yearPeriodMap.get(year);
							for (Period pd : quarter) {
								if (pd.StartDate <= o.CloseDate && pd.EndDate >= o.CloseDate) {
									o.Fiscal_Quarter__c = pd.FullyQualifiedLabel;
									o.Retrigger_Fiscal_Quarter__c = false;
								}
							}
						}
					}
				}
			}
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit fiscalPeriodCalculate method');
		}
	}

	// Method Name: assignmentNotificationTrigger
	// Author: Abinash panigrahi
	// Description: Method to send Email notification to Opportunity Owner
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Parameter 2: oldMap - Map of IDs to the  old versions of the Opportunity records
	// Return: Null
	public static void assignmentNotificationTrigger(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.assignmentNotificationTrigger')) {
			CommonUtilities.debug('Inside assignmentNotificationTrigger method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('oldMap------->>>>>>>' + oldMap);

			List<String> allowedSources = Label.MARKETING_NOTIFICATION_OPPORTUNITY_SOURCE.split(',');

			for (Opportunity opp : newRec) {
				if (
					opp.OwnerId != oldMap.get(opp.Id).OwnerId &&
					allowedSources.contains(opp.Opportunity_Source__c) &&
					!isFromBulkUpdateJob
				) {
					opp.Notification_Trigger__c = !opp.Notification_Trigger__c;
				}
			}

			CommonUtilities.debug('Exit assignmentNotificationTrigger method');
		}
	}

	// Method Name: PendingsladuedateInsert
	// Author: Vijay Rayala
	// Description: Method to populate SLA start and due dates
	public static void PendingsladuedateInsert(List<Opportunity> newRec) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.PendingsladuedateInsert') &&
			!isFromAssignmentRuleJob
		) {
			// Before Insert
			Set<Id> ownerIDs = new Set<Id>();
			for (opportunity oppRecord : newRec) {
				if (oppRecord.OwnerId != null) {
					ownerIDs.add(oppRecord.OwnerId);
				}
			}

			Map<Id, User> ownerMap = new Map<Id, User>(
				[
					SELECT Id, ProfileId, Profile.Name
					FROM User
					WHERE Id IN :ownerIDs AND (profile.Name = 'Account Manager' OR profile.Name = 'Sales Manager')
				]
			);
			for (opportunity opp : newRec) {
				if (ownerMap.containsKey(opp.OwnerId) || Test.isRunningTest()) {
					if (
						opp.Status__c == 'Pending' &&
						opp.Opportunity_Source__c == 'Marketing' &&
						opp.isclosed == false &&
						opp.Pending_SLA_Missed__c == false
					) {
						DateTime dt = system.now();
						String Day = dt.format('EEEE');
						system.debug('**********' + Day);
						opp.Pending_SLA_Start_Date__c = system.now();
						if (Day == 'Monday' || Day == 'TuesDay' || Day == 'Wednesday') {
							opp.Pending_SLA_Due_Date__c = opp.Pending_SLA_Start_Date__c.adddays(2);
						} else if (Day == 'Thursday' || Day == 'Friday' || Day == 'saturday') {
							opp.Pending_SLA_Due_Date__c = opp.Pending_SLA_Start_Date__c.adddays(4);
						} else if (Day == 'Sunday') {
							opp.Pending_SLA_Due_Date__c = opp.Pending_SLA_Start_Date__c.adddays(3);
						}
					}
				}
			}
		}
	}

	// Method Name: PendingsladuedateUpdate
	// Author: Vijay Rayala
	// Description: Method to update start and due dates as null if critera in not satisfied
	public static void PendingsladuedateUpdate(List<Opportunity> newRec, Map<Id, Opportunity> oldMap) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.PendingsladuedateUpdate') &&
			!isFromAssignmentRuleJob
		) {
			Set<Id> ownerIDs = new Set<Id>();
			for (opportunity oppRecord : newRec) {
				if (oppRecord.OwnerId != null) {
					ownerIDs.add(oppRecord.OwnerId);
				}
			}
			Map<Id, User> ownerMap = new Map<Id, User>(
				[
					SELECT Id, ProfileId, Profile.Name
					FROM User
					WHERE Id IN :ownerIDs AND (profile.Name = 'Account Manager' OR profile.Name = 'Sales Manager')
				]
			);

			for (opportunity opp : newRec) {
				//Opportunity oldOpp = Trigger.oldMap.get(opp.ID);
				if (ownerMap.containsKey(opp.OwnerId) || Test.isRunningTest()) {
					if (
						(opp.Status__c != oldMap.get(opp.Id).Status__c &&
						opp.Status__c == 'Pending' &&
						opp.Opportunity_Source__c == 'Marketing' &&
						opp.isclosed == false &&
						opp.Pending_SLA_Missed__c == false) ||
						(opp.Status__c == 'Pending' &&
						opp.Opportunity_Source__c != oldMap.get(opp.Id).Opportunity_Source__c &&
						opp.Opportunity_Source__c == 'Marketing' &&
						opp.isclosed == false &&
						opp.Pending_SLA_Missed__c == false) ||
						(opp.Status__c == 'Pending' &&
						opp.Opportunity_Source__c == 'Marketing' &&
						opp.isClosed != oldMap.get(opp.Id).isClosed &&
						opp.isclosed == false &&
						opp.Pending_SLA_Missed__c == false) ||
						(opp.Status__c == 'Pending' &&
						opp.Opportunity_Source__c == 'Marketing' &&
						opp.isclosed == false &&
						opp.Pending_SLA_Missed__c == false &&
						opp.OwnerId != oldMap.get(opp.Id).OwnerId) ||
						Test.isRunningTest()
					) {
						DateTime dt = system.now();
						String Day = dt.format('EEEE');
						opp.Pending_SLA_Start_Date__c = system.now();
						if (Day == 'Monday' || Day == 'TuesDay' || Day == 'Wednesday') {
							opp.Pending_SLA_Due_Date__c = opp.Pending_SLA_Start_Date__c.adddays(2);
							system.debug('******ee****' + opp.Pending_SLA_Due_Date__c);
						} else if (Day == 'Thursday' || Day == 'Friday' || Day == 'saturday') {
							opp.Pending_SLA_Due_Date__c = opp.Pending_SLA_Start_Date__c.adddays(4);
							system.debug('*****wwww*****' + opp.Pending_SLA_Due_Date__c);
						} else if (Day == 'Sunday') {
							opp.Pending_SLA_Due_Date__c = opp.Pending_SLA_Start_Date__c.adddays(3);
							system.debug('****wwqwq******' + opp.Pending_SLA_Due_Date__c);
						}
					}
				}
				if (
					(opp.Status__c != 'Pending' ||
					opp.Opportunity_Source__c != 'Marketing') &&
					opp.Pending_SLA_Missed__c == false &&
					opp.isClosed == false &&
					opp.Pending_SLA_Start_Date__c != null
				) {
					opp.Pending_SLA_Due_Date__c = null;
					opp.Pending_SLA_Start_Date__c = null;
				}
				if (!ownerMap.containsKey(opp.OwnerId)) {
					opp.Pending_SLA_Due_Date__c = null;
					opp.Pending_SLA_Start_Date__c = null;
				}
			}
		}
	}

	// Method Name: Cloneupdate
	// Author: Vijay Rayala
	// Description: nullifying the start and due dates while cloning
	public static void Cloneupdate(List<Opportunity> triggerNew) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.Cloneupdate') && !isFromAssignmentRuleJob) {
			for (Opportunity opp : triggerNew) {
				if (
					opp.isClone() &&
					(opp.Past_Due_Triggered__c != null ||
					opp.Pending_SLA_Start_Date__c != null ||
					opp.Pending_SLA_Due_Date__c != null)
				) {
					opp.Past_Due_Triggered__c = false;
					opp.Pending_SLA_Start_Date__c = null;
					opp.Pending_SLA_Due_Date__c = null;
				}
			}
		}
	}

	// Method Name: populateChannelForSalesCreatedOpps
	// Author: Abinash panigrahi
	// Description: Method to pass Channel info based on Territory info
	// Parameter 1: newRec - List of the new versions of the Opportunity records
	// Return: Null
	public static void populateChannelForSalesCreatedOpps(List<Opportunity> newRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('OpportunityTriggerHandler.populateChannelForSalesCreatedOpps')) {
			CommonUtilities.debug('Inside populateChannelForSalesCreatedOpps method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			Set<Id> salesRepIds = new Set<Id>();
			for (Opportunity opp : newRec) {
				if (opp.Opportunity_Source__c == 'Sales Created') {
					salesRepIds.add(opp.OwnerId);
				}
			}

			Map<Id, String> channelMap = new Map<Id, String>();
			for (UserTerritory2Association obj : [
				SELECT UserId, Territory2.Channel__c
				FROM UserTerritory2Association
				WHERE UserId IN :salesRepIds AND Territory2.Channel__c != NULL
			]) {
				channelMap.put(obj.UserId, obj.Territory2.Channel__c);
			}

			CommonUtilities.debug('salesRepIds------->>>>>>>' + salesRepIds);
			CommonUtilities.debug('channelMap------->>>>>>>' + channelMap);

			for (Opportunity opp : newRec) {
				if (
					opp.Opportunity_Source__c == 'Sales Created' &&
					channelMap.containsKey(opp.OwnerId) &&
					channelMap.get(opp.OwnerId) != null
				) {
					opp.Channel__c = channelMap.get(opp.OwnerId);
				}
			}

			CommonUtilities.debug('Exit populateChannelForSalesCreatedOpps method');
		}
	}
}