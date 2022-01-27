// ===========================================================================
//  Object	: CaseRelatedAssetsTriggerHandler
// 	Company	: Keste @IDC
//  Author	: Pradeep Chanda
// 	Purpose	: Handler Class contains all logic for CaseRelatedAssetsTrigger.
// ===========================================================================
public class CaseRelatedAssetsTriggerHandler {
	// Author: Pradeep Chanda
	// Description: Method to throw error message when the user tries to deleted primary Asset.
	// Parameter 1: newMap - Map of IDs to the new versions of the Case Asset records
	public static void assetDeleteValidation(Map<id, Case_Related_Assets__c> oldMap) {
		if (DynamicCodeExecution.allowExecution('CaseAssetTriggerHandler.assetDeleteValidation')) {
			List<ID> caseAssetRecords = new List<Id>();
			String caseAssetDeleteErrMessage = System.Label.CASE_ASSET_UPDATE_DELETE_ERROR_MESSAGE;
			Set<Id> caseIdSet = new Set<Id>();
			List<Case> caseList = new List<Case>();
			Map<Id, Id> caseAssetMap = new Map<Id, Id>();
			for (Object assetRec : Trigger.oldMap.values()) {
				Case_Related_Assets__c assetrecord = (Case_Related_Assets__c) assetRec;
				caseIdSet.add(assetrecord.Case__c);
			}
			caseList = [SELECT Id, AssetId FROM Case WHERE Id IN :caseIdSet];
			for (Case caseRecord : caseList) {
				caseAssetMap.put(caseRecord.id, caseRecord.AssetId);
			}

			for (Object caseAssetId : Trigger.oldMap.values()) {
				Case_Related_Assets__c caseAssetRecord = (Case_Related_Assets__c) caseAssetId;
				if (
					oldMap.get(caseAssetRecord.Id).Primary__c == true &&
					caseAssetMap.get(caseAssetRecord.Case__c) == oldMap.get(caseAssetRecord.id).Asset__c
				) {
					Trigger.oldMap.get(caseAssetRecord.id).addError(caseAssetDeleteErrMessage);
				}
			}
		}
	}

	// Author: Pradeep Chanda
	// Description: Method to throw error message when the Case asset is modified in the related object.
	// Parameter 1: oldMap - Map of IDs to the old versions of the Case records
	// Parameter 2: newMap - Map of IDs to the new versions of the Case records
	public static void assetUpdateValidation(
		Map<id, Case_Related_Assets__c> oldMap,
		Map<id, Case_Related_Assets__c> newMap
	) {
		if (DynamicCodeExecution.allowExecution('CaseAssetTriggerHandler.assetUpdateValidation')) {
			List<ID> caseAssetRecords = new List<Id>();
			String caseAssetUpdateErrMessage = System.Label.CASE_ASSET_UPDATE_DELETE_ERROR_MESSAGE;

			Set<Id> caseIdSet = new Set<Id>();
			List<Case> caseList = new List<Case>();
			Map<Id, Id> caseAssetMap = new Map<Id, Id>();
			for (Case_Related_Assets__c assetRec : oldMap.values()) {
				caseIdSet.add(assetRec.Case__c);
			}
			caseList = [SELECT Id, AssetId FROM Case WHERE Id IN :caseIdSet];
			for (Case caseRecord : caseList) {
				caseAssetMap.put(caseRecord.id, caseRecord.AssetId);
			}
			for (Id id1 : Trigger.newMap.keySet()) {
				if (
					oldMap.get(id1).Primary__c == true &&
					caseAssetMap.get(oldMap.get(id1).Case__c) == oldMap.get(id1).Asset__c
				) {
					Trigger.newMap.get(id1).addError(caseAssetUpdateErrMessage);
				}
			}
		}
	}
}