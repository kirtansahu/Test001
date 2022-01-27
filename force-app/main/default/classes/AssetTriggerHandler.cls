public without sharing class AssetTriggerHandler {
	// Method Name: handleBeforeDelete
	// Author: Jayaram Bevara
	// Description: Method to handle Before Deletion Event
	// Parameter 1: OldRecList - List of the old versions of the Asset records
	// Return: Null
	public static void handleBeforeDelete(List<Asset> triggerOld) {
		if (DynamicCodeExecution.allowExecution('AssetTriggerHandler.handleBeforeDelete')) {
			//Split the Values from the Custom Label and add to the List
			List<String> assetDeleteAccessProdiles = String.valueOf(Label.ASSET_RECORD_DELETE_ACCESS_PROFILES)
				.split(',');
			//Get the Profile Name from Login User Profile Id
			String logginUserProfileName = CommonUtilities.getLoginUserProfileName(userinfo.getProfileId());
			for (Asset assetRec : triggerOld) {
				if (!assetDeleteAccessProdiles.Contains(logginUserProfileName)) {
					//Throw the error while profile don't have access for deletion
					assetRec.addError(Label.ASSET_DELETION_ERROR);
				}
			}
		}
	}
	// Method Name: updateBackendSearchFields
	// Author: Jayaram Bevara
	// Description: Method to handle Update Account,Contact Or Product Backend Fields
	// Parameter 1: mapUpdatedValues - Map of the Sobject Values
	// Parameter 2: strSObjectName - SObject Name
	// Return: Null
	public static void updateBackendSearchFields(Map<id, SObject> mapUpdatedValues, String strSObjectName) {
		List<Asset> listUpdateAssetRecs = new List<Asset>();
		for (Asset assetRec : [
			SELECT
				id,
				AccountId,
				ContactId,
				Product2Id,
				Account_Name_Backend__c,
				Contact_Name_Backend__c,
				Product_Name_Backend__c
			FROM asset
			WHERE
				AccountId IN :mapUpdatedValues.KeySet()
				OR ContactId IN :mapUpdatedValues.KeySet()
				OR Product2Id IN :mapUpdatedValues.KeySet()
		]) {
			Asset updateAssetRec = new Asset(id = assetRec.Id);
			if (strSObjectName == 'Account' && mapUpdatedValues.containsKey(assetRec.AccountId)) {
				updateAssetRec.Account_Name_Backend__c = (String) mapUpdatedValues.get(assetRec.AccountId).get('Name');
			} else if (strSObjectName == 'Contact' && mapUpdatedValues.containsKey(assetRec.ContactId)) {
				updateAssetRec.Contact_Name_Backend__c =
					(String) mapUpdatedValues.get(assetRec.ContactId).get('FirstName') +
					' ' +
					(String) mapUpdatedValues.get(assetRec.ContactId).get('LastName');
			} else if (strSObjectName == 'Product' && mapUpdatedValues.containsKey(assetRec.Product2Id)) {
				updateAssetRec.Product_Name_Backend__c = (String) mapUpdatedValues.get(assetRec.Product2Id).get('Name');
			}
			listUpdateAssetRecs.add(updateAssetRec);
		}
		if (listUpdateAssetRecs.size() > 0) {
			update listUpdateAssetRecs;
		}
	}
}