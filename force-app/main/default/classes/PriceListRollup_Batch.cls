// ===========================================================================
//  Object	: PriceListRollup_Batch
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Batch Class to perform Rollup of most frequently used PriceBook from ShipTo to SGN & SoldTo Recordtype Account.
// ===========================================================================
global with sharing class PriceListRollup_Batch implements Database.Batchable<sObject> {
	public static String SGN_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SITE_SGN;
	public static String SHIPTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SHIPTO;
	public static String SOLDTO_RECORDTYPE_NAME = Label.ACCOUNT_RECORD_SOLDTO;

	// Method Name: start
	// Author: Abinash panigrahi
	// Description: Method to fetch all ShipTo Account Records
	// Parameter 1: Database.BatchableContext
	// Return: Database.QueryLocator
	global Database.QueryLocator start(Database.BatchableContext bc) {
		//Define the Scope of Batch records to do processing.
		String query = 'SELECT Id, ParentId, Price_Book__c, Exclude_From_Rollup__c, Account_Status__c, Source_System__c FROM Account';
		query += ' WHERE Exclude_From_Rollup__c = TRUE AND ParentId != NULL AND RecordType.Name =: SHIPTO_RECORDTYPE_NAME ORDER BY ParentId';
		return Database.getQueryLocator(query);
	}

	// Method Name: execute
	// Author: Abinash panigrahi
	// Description: Update SGN and SoldTo Accounts with most frequently used PriceBook at ShipTo level
	// Parameter 1: Database.BatchableContext
	// Parameter 2: records - Account records fetched in start()
	// Return: Null

	global void execute(Database.BatchableContext bc, List<Account> records) {
		//Instance to store Parent RecordId of ShipTo Accounts
		Set<Id> parentIds = new Set<Id>();
		for (Account a : records) {
			parentIds.add(a.ParentId);
		}

		//Add missing Sibling Shipto records under heirarchy of SGN & SoldTo Account
		records.addAll(
			[
				SELECT Id, ParentId, Price_Book__c, Exclude_From_Rollup__c, Account_Status__c, Source_System__c
				FROM Account
				WHERE
					RecordType.Name = :SHIPTO_RECORDTYPE_NAME
					AND ParentId IN :parentIds
					AND Id NOT IN :records
					AND Price_Book__c != NULL
					AND Account_Status__c = 'Active'
			]
		);

		//Instance to store unique PriceBook Ids
		Set<Id> priceBookIds = new Set<Id>();
		//Instance to store the relationship between SGN & SoldTo RecordId and List of child's PriceBook RecordId
		Map<Id, List<Id>> priceBookMap = new Map<Id, List<Id>>();
		//Temporary Instance to store only SAP Pricebook related info
		Map<Id, List<Id>> tempMap = new Map<Id, List<Id>>();

		//Fetch Active E1 Account Pricebook -- High Priority
		for (Account a : records) {
			if (a.Price_Book__c != null && a.Account_Status__c == 'Active' && a.Source_System__c == 'E1') {
				priceBookIds.add(a.Price_Book__c);
				if (!priceBookMap.containsKey(a.ParentId)) {
					priceBookMap.put(a.ParentId, new List<Id>());
				}
				priceBookMap.get(a.ParentId).add(a.Price_Book__c);
			}
		}

		//Fetch Active SAP Account Pricebook -- Low Priority
		for (Account a : records) {
			if (
				!priceBookMap.containsKey(a.ParentId) &&
				a.Price_Book__c != null &&
				a.Account_Status__c == 'Active' &&
				a.Source_System__c == 'SAP'
			) {
				priceBookIds.add(a.Price_Book__c);
				if (!tempMap.containsKey(a.ParentId)) {
					tempMap.put(a.ParentId, new List<Id>());
				}
				tempMap.get(a.ParentId).add(a.Price_Book__c);
			}
		}

		//Merge SAP and E1 Pricebook Map -- Records to factor for Rollup logic
		priceBookMap.putAll(tempMap);

		//Instance to store to be updated SGN & SoldTo Account records
		List<Account> toBeUpdatedRec = new List<Account>();
		//Instance to store SGN RecordIds
		Set<Id> sgnIds = new Set<Id>();
		//Rollup of SGN/Soldto Pricebook to NULL -- Inactive Account & Pricebook is blank
		for (Account a : records) {
			if (
				(a.Price_Book__c == null ||
				a.Account_Status__c == 'Inactive') &&
				!priceBookMap.containsKey(a.ParentId) &&
				!sgnIds.contains(a.ParentId)
			) {
				sgnIds.add(a.ParentId);
				toBeUpdatedRec.add(new Account(Id = a.parentId, Price_Book__c = null));
			}
		}

		//Instance to store the relationship between PriceBook Name and Record Id and just reverse of it
		Map<String, Id> priceBookNameMap = new Map<String, Id>();
		Map<Id, String> priceBookMapReverse = new Map<Id, String>();
		//Loop Logic
		//Fetch all related PriceBook with Name
		for (PriceBook2 pb : [SELECT Id, Name FROM PriceBook2 WHERE Id IN :priceBookIds]) {
			if (pb.Name != null) {
				priceBookMapReverse.put(pb.Id, pb.Name.toLowerCase());
				priceBookNameMap.put(pb.Name.toLowerCase(), pb.Id);
			}
		}

		//Loop Logic
		//Figure out frequently used PriceBook at ShipTo level
		for (Id parentId : priceBookMap.keySet()) {
			//Instance to store the element counts
			Map<Id, Integer> count = new Map<Id, Integer>();
			//Logic to count the number of occurances of PriceBook
			for (Id pbId : priceBookMap.get(parentId)) {
				if (!count.containsKey(pbId)) {
					count.put(pbId, 0);
				}
				Integer currCount = count.get(pbId) + 1;
				count.put(pbId, currCount);
			}

			//Logic to identify most frequently occured PriceBook
			Id frequentPriceBook = count.isEmpty() ? null : new List<Id>(count.keyset())[0];
			for (Id pbId : count.keySet()) {
				frequentPriceBook = count.get(pbId) > count.get(frequentPriceBook) ? pbId : frequentPriceBook;
			}

			//Maximum Count
			Integer max = count.get(frequentPriceBook);

			//Instance to store Name in aplhabetical order
			List<String> nameSortList = new List<String>();
			for (Id pbId : count.keySet()) {
				if (count.get(pbId) == max && priceBookMapReverse.containsKey(pbId)) {
					nameSortList.add(priceBookMapReverse.get(pbId));
				}
			}

			//Sorting
			nameSortList.sort();

			//Add to Update Record list
			if (nameSortList.size() > 0) {
				toBeUpdatedRec.add(new Account(Id = parentId, Price_Book__c = priceBookNameMap.get(nameSortList[0])));
			}
		}

		//Exception Handling
		//Update Account records
		Database.SaveResult[] srList = Database.update(toBeUpdatedRec, false);
		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'PriceListRollup_Batch',
						'execute',
						'Batch Logic',
						'Update Account',
						err.getMessage(),
						System.today()
					);
				}
			}
		}

		//Instance to store rollup updated Checkbox
		List<Account> rollupUpdateRec = new List<Account>();
		//Loop Logic
		//Update Exclude from Rollup Checkbox
		for (Account a : records) {
			if (a.Exclude_From_Rollup__c == true) {
				rollupUpdateRec.add(new Account(Id = a.Id, Exclude_From_Rollup__c = false));
			}
		}

		//Exception Handling
		//Update Account records
		Database.SaveResult[] srListNew = Database.update(rollupUpdateRec, false);
		for (Database.SaveResult sr : srListNew) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					//Create Apex Log
					ExceptionHandlerController.createException(
						'PriceListRollup_Batch',
						'execute',
						'Batch Logic',
						'Update Account',
						err.getMessage(),
						System.today()
					);
				}
			}
		}
	}

	// Method Name: finish
	// Author: Abinash panigrahi
	// Description: After Update Logic
	global void finish(Database.BatchableContext bc) {
	}
}