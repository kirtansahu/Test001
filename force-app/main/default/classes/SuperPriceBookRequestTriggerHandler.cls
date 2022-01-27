// ===========================================================================
//  Object	: SuperPriceBookRequestTriggerHandler
// 	Company	: Keste @ IDC
//  Author	: Adarsh Sharma
// 	Purpose	: Handler Class contains all logic for SuperPriceBookRequestTrigger.
// ===========================================================================
public class SuperPriceBookRequestTriggerHandler {
	// Method Name: createAndPopulateSuperPricebook
	// Author: Adarsh Sharma
	// Description: Method to create and populate Pricebook on super pricebook request
	// Parameter 1: triggerNew - List of the new versions of the Super Price Book Request records
	// Parameter 2: triggerOldMap - Map of the old versions of the Super Price Book Request records
	// Return: Null
	public static void createAndPopulateSuperPricebook(
		List<Super_Price_Book_Request__c> triggerNew,
		Map<Id, Super_Price_Book_Request__c> triggerOldMap
	) {
		// Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('SuperPriceBookRequestTriggerHandler.createAndPopulateSuperPricebook')
		) {
			Set<String> superPricebookNames = new Set<String>();
			Map<String, Pricebook2> mapSuperPricebooks = new Map<String, Pricebook2>();

			for (Super_Price_Book_Request__c spbrObj : triggerNew) {
				if (
					spbrObj.isActive__c &&
					(triggerOldMap == null ||
					(triggerOldMap != null &&
					spbrObj.isActive__c != triggerOldMap.get(spbrObj.Id).isActive__c))
				) {
					spbrObj.Status__c = 'Requested';
					superPricebookNames.add(spbrObj.Super_Pricebook_Name__c);
				}

				if (
					!spbrObj.isActive__c &&
					triggerOldMap != null &&
					spbrObj.isActive__c != triggerOldMap.get(spbrObj.Id).isActive__c
				) {
					superPricebookNames.add(spbrObj.Super_Pricebook_Name__c);
				}

				if (
					triggerOldMap != null &&
					spbrObj.Currency_Code__c != triggerOldMap.get(spbrObj.Id).Currency_Code__c
				) {
					superPricebookNames.add(spbrObj.Super_Pricebook_Name__c);
				}
			}

			if (superPricebookNames.size() > 0) {
				for (Pricebook2 pb : [
					SELECT Id, Name, isActive
					FROM Pricebook2
					WHERE Name IN :superPricebookNames AND Source_System__c = NULL
				]) {
					mapSuperPricebooks.put(pb.Name, pb);
				}

				for (Super_Price_Book_Request__c spbrObj : triggerNew) {
					if (
						spbrObj.isActive__c &&
						!mapSuperPricebooks.containsKey(spbrObj.Super_Pricebook_Name__c) &&
						(triggerOldMap == null ||
						(triggerOldMap != null &&
						spbrObj.isActive__c != triggerOldMap.get(spbrObj.Id).isActive__c))
					) {
						mapSuperPricebooks.put(spbrObj.Super_Pricebook_Name__c, createSuperPricebook(spbrObj));
					} else if (
						triggerOldMap != null &&
						mapSuperPricebooks.containsKey(spbrObj.Super_Pricebook_Name__c) &&
						(spbrObj.isActive__c != triggerOldMap.get(spbrObj.Id).isActive__c ||
						spbrObj.Currency_Code__c != triggerOldMap.get(spbrObj.Id).Currency_Code__c)
					) {
						mapSuperPricebooks.get(spbrObj.Super_Pricebook_Name__c).isActive = spbrObj.isActive__c;
						mapSuperPricebooks.get(spbrObj.Super_Pricebook_Name__c)
							.Currency_Code__c = spbrObj.Currency_Code__c;
					}
				}

				if (!mapSuperPricebooks.IsEmpty()) {
					upsert mapSuperPricebooks.values();

					for (Super_Price_Book_Request__c spbrObj : triggerNew) {
						if (mapSuperPricebooks.containsKey(spbrObj.Super_Pricebook_Name__c)) {
							spbrObj.Super_Pricebook__c = mapSuperPricebooks.get(spbrObj.Super_Pricebook_Name__c).Id;
						}
					}
				}
			}
		}
	}

	// Method Name: clonePBEForRelatedPricebook
	// Author: Adarsh Sharma
	// Description: Method to clone related pricebook's price book entry to super price book
	// Parameter 1: triggerNew - List of the new versions of the Super Price Book Request records
	// Parameter 2: triggerOldMap - Map of the old versions of the Super Price Book Request records
	// Return: Null
	public static void clonePBEForRelatedPricebook(
		List<Super_Price_Book_Request__c> triggerNew,
		Map<Id, Super_Price_Book_Request__c> triggerOldMap
	) {
		if (DynamicCodeExecution.allowExecution('SuperPriceBookRequestTriggerHandler.clonePBEForRelatedPricebook')) {
			Set<Id> setSuperPricebookRequestId = new Set<Id>();
			Set<Id> setRelatedPricebookId = new Set<Id>();

			for (Super_Price_Book_Request__c spbrObj : triggerNew) {
				if (
					spbrObj.isActive__c &&
					spbrObj.Super_Pricebook__c != null &&
					(triggerOldMap == null ||
					(triggerOldMap != null &&
					spbrObj.isActive__c != triggerOldMap.get(spbrObj.Id).isActive__c))
				) {
					setSuperPricebookRequestId.add(spbrObj.Id);
				}
			}

			if (setSuperPricebookRequestId.size() > 0) {
				for (Related_Pricebook__c relatedPricebookObj : [
					SELECT Id, Price_Book__c, Super_Price_Book_Request__r.Super_Pricebook__c
					FROM Related_Pricebook__c
					WHERE Super_Price_Book_Request__c IN :setSuperPricebookRequestId AND isActive__c = TRUE
				]) {
					setRelatedPricebookId.add(relatedPricebookObj.Id);
				}
			}

			if (setRelatedPricebookId.size() > 0) {
				updateRelatedPricebookStatus(setRelatedPricebookId);
			}
		}
	}

	// Method Name: createSuperPricebook
	// Author: Adarsh Sharma
	// Description: Method to create super price book request trigger
	// Parameter 1: Super_Price_Book_Request__c - Super Price Book Request record
	// Return: Null
	public static Pricebook2 createSuperPricebook(Super_Price_Book_Request__c spbrObj) {
		Pricebook2 oPricebook = new Pricebook2();
		oPricebook.Name = spbrObj.Super_Pricebook_Name__c;
		oPricebook.IsActive = spbrObj.isActive__c;
		oPricebook.Currency_Code__c = spbrObj.Currency_Code__c;
		return oPricebook;
	}

	// Method Name: updateRelatedPricebookStatus
	// Author: Adarsh Sharma
	// Description: Method to update Related pricebook status to Requested
	// Parameter 1: setRelatedPricebookIds - collection of related price book Id's
	// Return: Null
	public static void updateRelatedPricebookStatus(Set<Id> setRelatedPricebookIds) {
		List<Related_Pricebook__c> lstRelatedPricebook = new List<Related_Pricebook__c>();
		for (Id pbId : setRelatedPricebookIds) {
			lstRelatedPricebook.add(new Related_Pricebook__c(Id = pbId, Status__c = 'Requested'));
		}
		if (lstRelatedPricebook.size() > 0) {
			update lstRelatedPricebook;
		}
	}
}