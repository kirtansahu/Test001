public without sharing class ProductTriggerHandler {
	// Method Name: invokeAssetProductBackendUpdate
	// Author: Jayaram B
	// Description: Method to Pass All Name Field Updated Product records to AssetHandler
	// Parameter 1: newRec - List of the new versions of the Product records
	// Parameter 2: oldMap - Map of IDs to the old versions of the Product records
	// Return: Null
	public static void invokeAssetProductBackendUpdate(List<Product2> newRec, Map<Id, Product2> oldMap) {
		if (DynamicCodeExecution.allowExecution('ProductTriggerHandler.invokeAssetProductBackendUpdate')) {
			//Map to hold the Name Field Updated Product2 Records
			Map<Id, Product2> mapProdNameUpdate = new Map<Id, Product2>();
			for (Product2 prodRecData : newRec) {
				//Check Name Filed Updatd or Not
				if (oldMap.get(prodRecData.Id).Name != prodRecData.Name) {
					mapProdNameUpdate.put(prodRecData.Id, prodRecData);
				}
			}
			if (mapProdNameUpdate.size() > 0) {
				//Pass the Name Field Updated Product2 Records to the AssetTriggerHandler
				AssetTriggerHandler.updateBackendSearchFields(mapProdNameUpdate, 'Product');
			}
		}
	}
}