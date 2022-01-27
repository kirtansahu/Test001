// ===========================================================================
//  Object	: OpportunityContactRoleTriggerHandler
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Handler Class contains all logic for OpportunityContactRoleTrigger.
// ===========================================================================

public class OpportunityContactRoleTriggerHandler {
	public static Boolean isFromOpportunityTrigger = false;

	// Method Name: restrictDeletePrimaryRecord
	// Author: Abinash panigrahi
	// Description: Method to throw error message when Primary Opportunity Contact record is deleted
	// Parameter 1: oldRec - List of the old versions of the OpportunityContactRole records
	// Return: Null
	public static void restrictDeletePrimaryRecord(List<OpportunityContactRole> oldRec) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('OpportunityContactRoleTriggerHandler.restrictDeletePrimaryRecord')) {
			for (OpportunityContactRole ocr : oldRec) {
				if (
					ocr.IsPrimary == true &&
					!CommonUtilities.isSystemAdminUser() &&
					!CommonUtilities.isIntegrationOrMigrationUser()
				) {
					ocr.addError(Label.OPPORTUNITYCONTACT_DELETE_ERROR);
				}
			}
		}
	}

	// Method Name: restrictEditOpportunityContactRecord
	// Author: Abinash panigrahi
	// Description: Method to throw error message when any Opportunity Contact record is updated
	// Parameter 1: newRec - List of the new versions of the OpportunityContactRole records
	// Parameter 2: oldMap - Map of IDs to the old versions of the OpportunityContactRole records
	// Return: Null
	public static void restrictEditOpportunityContactRecord(
		List<OpportunityContactRole> newRec,
		Map<Id, OpportunityContactRole> oldMap
	) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution(
				'OpportunityContactRoleTriggerHandler.restrictEditOpportunityContactRecord'
			)
		) {
			for (OpportunityContactRole ocr : newRec) {
				if (
					!CommonUtilities.isSystemAdminUser() &&
					!CommonUtilities.isIntegrationOrMigrationUser() &&
					!isFromOpportunityTrigger
				) {
					if (
						(ocr.IsPrimary != oldMap.get(ocr.Id).IsPrimary && oldMap.get(ocr.Id).IsPrimary == false) ||
						ocr.ContactId != oldMap.get(ocr.Id).ContactId
					) {
						ocr.addError(Label.OPPORTUNITYCONTACT_EDIT_ERROR);
					}
					if (ocr.IsPrimary != oldMap.get(ocr.Id).IsPrimary && oldMap.get(ocr.Id).IsPrimary == true) {
						ocr.addError(Label.OPPORTUNITYCONTACT_EDIT_ERROR2);
					}
				}
			}
		}
	}

	// Method Name: avoidDuplicateOpportunityContactRecord
	// Author: Abinash panigrahi
	// Description: Method to throw error message when Duplicate Opportunity Contact record is created
	// Parameter 1: newRec - List of the new versions of the OpportunityContactRole records
	// Return: Null
	public static void avoidDuplicateOpportunityContactRecord(List<OpportunityContactRole> newRec) {
		//Instance to store duplicate records
		List<OpportunityContactRole> duplicates = new List<OpportunityContactRole>();
		Map<String, OpportunityContactRole> uniqueKeyMap = new Map<String, OpportunityContactRole>();
		Set<Id> oppIds = new Set<Id>();
		//Loop Instance
		//To figure out duplicate records within the inserted record batch
		for (OpportunityContactRole ocr : newRec) {
			String keyId = ocr.OpportunityId + '_' + ocr.ContactId;
			if (!uniqueKeyMap.containsKey(keyId)) {
				uniqueKeyMap.put(keyId, ocr);
				oppIds.add(ocr.OpportunityId);
			} else {
				duplicates.add(ocr);
			}
		}

		//Fetch all related Opportunity Contact records
		for (OpportunityContactRole ocr : [
			SELECT Id, OpportunityId, ContactId
			FROM OpportunityContactRole
			WHERE OpportunityId IN :oppIds
		]) {
			String keyId = ocr.OpportunityId + '_' + ocr.ContactId;
			if (uniqueKeyMap.containsKey(keyId)) {
				duplicates.add(uniqueKeyMap.get(keyId));
			}
		}

		//Throw error message for only duplicate Opportunity Contact records
		for (OpportunityContactRole ocr : duplicates) {
			ocr.addError(Label.OPPORTUNITYCONTACT_DUPLICATE_ERROR);
		}
	}
}