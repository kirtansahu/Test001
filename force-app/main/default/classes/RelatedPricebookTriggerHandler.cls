// ===========================================================================
//  Object	: RelatedPricebookTriggerHandler
// 	Company	: Keste @ IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Handler Class contains all logic for RelatedPricebookTrigger.
// ===========================================================================
public class RelatedPricebookTriggerHandler {
	// Method Name: updateRelatedPricebookStatus
	// Author: Adarsh Sharma
	// Description: Method to update related pricebook's status to Requested
	// Parameter 1: triggerNew - List of the new versions of the Related Pricebook records
	// Parameter 2: triggerOldMap - Map of the old versions of the Related Pricebook records
	// Return: Null
	public static void updateRelatedPricebookStatus(
		List<Related_Pricebook__c> triggerNew,
		Map<Id, Related_Pricebook__c> triggerOldMap
	) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('RelatedPricebookTriggerHandler.updateRelatedPricebookStatus')) {
			Map<Id, Set<Related_Pricebook__c>> superPriceBookRequestMap = new Map<Id, Set<Related_Pricebook__c>>();
			for (Related_Pricebook__c pricebookObj : triggerNew) {
				if (
					pricebookObj.isActive__c &&
					pricebookObj.Price_Book__c != null &&
					(triggerOldMap == null ||
					(triggerOldMap != null &&
					pricebookObj.isActive__c != triggerOldMap.get(pricebookObj.Id).isActive__c))
				) {
					if (!superPriceBookRequestMap.containsKey(pricebookObj.Super_Price_Book_Request__c)) {
						superPriceBookRequestMap.put(
							pricebookObj.Super_Price_Book_Request__c,
							new Set<Related_Pricebook__c>()
						);
					}
					superPriceBookRequestMap.get(pricebookObj.Super_Price_Book_Request__c).add(pricebookObj);
				}
			}

			if (!superPriceBookRequestMap.isEmpty()) {
				for (Super_Price_Book_Request__c spbr : [
					SELECT Id
					FROM Super_Price_Book_Request__c
					WHERE Id IN :superPriceBookRequestMap.keySet() AND isActive__c = TRUE AND Super_Pricebook__c != NULL
				]) {
					for (Related_Pricebook__c pricebookObj : superPriceBookRequestMap.get(spbr.Id)) {
						pricebookObj.Status__c = 'Requested';
					}
				}
			}
		}
	}
}