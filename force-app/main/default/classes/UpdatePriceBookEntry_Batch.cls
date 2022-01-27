/****************************************************************************************************
 * Author Name   : Vasavi Keste
 * Class Name    : UpdatePriceBookEntry_Batch
 * Created Date  : 29th May 2018
 * Description   : To create/update Standard and native PricebookEntry from Custom Price_Book_Entry__c
 * Test Class    : UpdatePriceBookEntry_Batch_Test
 ****************************************************************************************************/
global with sharing class UpdatePriceBookEntry_Batch implements Database.Batchable<sObject>, Database.Stateful {
	//Global Class Level Variables
	global Id standardPriceBookId { get; set; }
	global Set<Id> priceBooksToProcess { get; set; }

	//Batch Constructor
	//Parameter 1: Id standardPriceBookId - Standard Price Book Record Id
	//Parameter 2: Set<Id> priceBooksToProcess - Set of Price Book Record Ids to be processed
	global UpdatePriceBookEntry_Batch(Id standardPriceBookId, Set<Id> priceBooksToProcess) {
		this.standardPriceBookId = standardPriceBookId;
		this.priceBooksToProcess = priceBooksToProcess;
	}

	//Batch's Start method to query all eligible Custom Price Book Entry records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String soql = 'SELECT Id, Name, Product__c, Price_Book__c, Price_Book__r.Currency_Code__c, ';
		soql += ' Start_Date__c, End_Date__c, List_Price__c, Last_Batch_Processed_Date__c, ';
		soql += ' Last_Error_Message__c ';
		soql += ' FROM Price_Book_Entry__c ';
		soql += ' WHERE Start_Date__c <= Today AND Price_Book__r.IsActive = true ';
		soql += ' AND Product__c != null AND Price_Book__c != null AND List_Price__c != null';
		soql += ' AND Last_Batch_Processed_Date__c = null AND Price_Book__r.Currency_Code__c != null ';
		if (priceBooksToProcess != null && priceBooksToProcess.size() > 0) {
			soql += ' AND Price_Book__c IN :priceBooksToProcess ';
		}
		soql += ' ORDER BY Product__c, Price_Book__c, Start_Date__c DESC';
		CommonUtilities.debug('soql------------' + soql);
		return Database.getQueryLocator(soql);
	}

	//Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, list<Price_Book_Entry__c> lstCustomPBEs) {
		Set<Id> setProductIds = new Set<Id>();
		Set<Id> setPriceBookIds = new Set<Id>();

		Map<String, Price_Book_Entry__c> mapCustomPriceBookEntry = new Map<String, Price_Book_Entry__c>();
		Map<String, PricebookEntry> mapNativePriceBookEntry = new Map<String, PricebookEntry>();

		List<PricebookEntry> nativePBEsToUpsert = new List<PricebookEntry>();

		setPriceBookIds.add(standardPriceBookId);
		//Prepare data for mapCustomPriceBookEntry ==> Map of Unique Key and Price_Book_Entry__c
		for (Price_Book_Entry__c objCPbe : lstCustomPBEs) {
			setProductIds.add(objCPbe.Product__c);
			setPriceBookIds.add(objCPbe.Price_Book__c);
			String pbeKey =
				objCPbe.Product__c +
				'.' +
				objCPbe.Price_Book__c +
				'.' +
				objCPbe.Price_Book__r.Currency_Code__c;
			if (!mapCustomPriceBookEntry.containsKey(pbeKey)) {
				mapCustomPriceBookEntry.put(pbeKey, objCPbe);
			}
			objCPbe.Last_Batch_Processed_Date__c = System.now();
			objCPbe.Last_Error_Message__c = null;
		}

		//Fetch All Active Super Pricebooks where the Current Set of Pricebooks are configured as related pricebook
		Map<Id, Set<Id>> relatedToSuperPricebooks = new Map<Id, Set<Id>>();
		for (Related_Pricebook__c rp : [
			SELECT Price_Book__c, Super_Price_Book_Request__r.Super_Pricebook__c
			FROM Related_Pricebook__c
			WHERE
				Price_Book__c IN :setPriceBookIds
				AND isActive__c = TRUE
				AND Super_Price_Book_Request__r.isActive__c = TRUE
				AND Super_Price_Book_Request__r.Super_Pricebook__c != NULL
		]) {
			setPriceBookIds.add(rp.Super_Price_Book_Request__r.Super_Pricebook__c);
			if (!relatedToSuperPricebooks.containsKey(rp.Price_Book__c)) {
				relatedToSuperPricebooks.put(rp.Price_Book__c, new Set<Id>());
			}
			relatedToSuperPricebooks.get(rp.Price_Book__c).add(rp.Super_Price_Book_Request__r.Super_Pricebook__c);
		}

		//Retrieve Existing PricebookEntry records
		for (PricebookEntry pbe : [
			SELECT Id, Product2Id, PriceBook2Id, Pricebook2.IsStandard, CurrencyIsoCode, UnitPrice, Start_Date__c
			FROM PricebookEntry
			WHERE Product2Id IN :setProductIds AND PriceBook2Id IN :setPriceBookIds
		]) {
			mapNativePriceBookEntry.put(pbe.Product2Id + '.' + pbe.PriceBook2Id + '.' + pbe.CurrencyIsoCode, pbe);
		}

		//CREATE/UPDATE NATIVE AND STANDARD PRICEBOOKENTRY
		for (Price_Book_Entry__c objCPbe : mapCustomPriceBookEntry.values()) {
			Set<Id> allPriceBooksToProcess = new Set<Id>();
			allPriceBooksToProcess.add(objCPbe.Price_Book__c);
			if (relatedToSuperPricebooks.containsKey(objCPbe.Price_Book__c)) {
				allPriceBooksToProcess.addAll(relatedToSuperPricebooks.get(objCPbe.Price_Book__c));
			}

			for (Id pbId : allPriceBooksToProcess) {
				String pbeKey = objCPbe.Product__c + '.' + pbId + '.' + objCPbe.Price_Book__r.Currency_Code__c;

				if (mapNativePriceBookEntry.containsKey(pbeKey)) {
					PricebookEntry pbe = mapNativePriceBookEntry.get(pbeKey);
					if (pbe.Start_Date__c == null || pbe.Start_Date__c <= objCPbe.Start_Date__c) {
						pbe.UnitPrice = objCPbe.List_Price__c;
						pbe.Start_Date__c = objCPbe.Start_Date__c;
						nativePBEsToUpsert.add(pbe);
					}
				} else {
					String stdPBEKey =
						objCPbe.Product__c +
						'.' +
						standardPriceBookId +
						'.' +
						objCPbe.Price_Book__r.Currency_Code__c;
					if (!mapNativePriceBookEntry.containsKey(stdPBEKey)) {
						PricebookEntry pbe = createPricebookEntry(objCPbe, standardPriceBookId);
						nativePBEsToUpsert.add(pbe);
						mapNativePriceBookEntry.put(stdPBEKey, pbe);
					}

					String customPBEKey =
						objCPbe.Product__c +
						'.' +
						pbId +
						'.' +
						objCPbe.Price_Book__r.Currency_Code__c;
					if (!mapNativePriceBookEntry.containsKey(customPBEKey)) {
						PricebookEntry pbe = createPricebookEntry(objCPbe, pbId);
						nativePBEsToUpsert.add(pbe);
						mapNativePriceBookEntry.put(customPBEKey, pbe);
					}
				}
			}
		}

		if (nativePBEsToUpsert.size() > 0) {
			upsert nativePBEsToUpsert;
		}

		if (lstCustomPBEs.size() > 0) {
			update lstCustomPBEs;
		}
	}

	//Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
	}

	//CREATE NATIVE AND STANDARD PRICEBOOKENTRY RECORDS
	public PricebookEntry createPricebookEntry(Price_Book_Entry__c objSPbe, Id priceBookId) {
		PricebookEntry oPricebookEntry = new PricebookEntry();
		oPricebookEntry.Pricebook2Id = priceBookId;
		oPricebookEntry.Product2Id = objSPbe.Product__c;
		if (objSPbe.Price_Book__c != null && objSPbe.Price_Book__r.Currency_Code__c != null) {
			oPricebookEntry.CurrencyIsoCode = objSPbe.Price_Book__r.Currency_Code__c;
		}
		oPricebookEntry.UnitPrice = objSPbe.List_Price__c;
		oPricebookEntry.Start_Date__c = objSPbe.Start_Date__c;
		oPricebookEntry.UseStandardPrice = false;
		oPricebookEntry.IsActive = true;
		return oPricebookEntry;
	}
}