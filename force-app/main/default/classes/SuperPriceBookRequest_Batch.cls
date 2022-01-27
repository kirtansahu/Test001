/****************************************************************************************************
 * Author Name   : Basant Verma
 * Class Name    : SuperPriceBookRequest_Batch
 * Created Date  : 12th Nov 2019
 * Description   : To Create/Updates the Super Price Book to have corresponding PriceBookEntry records
 * Test Class    : SuperPriceBookRequest_Batch_Test
 ****************************************************************************************************/
global with sharing class SuperPriceBookRequest_Batch implements Database.Batchable<sObject>, Database.Stateful {
	//Global Class Level Variables
	global Related_Pricebook__c relatedPriceBook { get; set; }
	global String statusStr { get; set; }

	//Batch Constructor
	//Parameter 1: Related_Pricebook__c relatedPriceBook - Related Price Book Record Id
	global SuperPriceBookRequest_Batch(Related_Pricebook__c relatedPriceBook) {
		this.relatedPriceBook = relatedPriceBook;
		this.statusStr = 'Completed';
	}

	//Batch's Start method to query all eligible Custom Price Book Entry records
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String soql = 'SELECT Id, Pricebook2Id, Product2Id, CurrencyIsoCode, UnitPrice, Start_Date__c, ';
		soql +=
			' UseStandardPrice, IsActive From PricebookEntry Where Pricebook2Id = \'' +
			relatedPriceBook.Price_Book__c +
			'\'';
		CommonUtilities.debug('soql------------' + soql);

		//Update the Child Related Pricebook to Processing
		relatedPriceBook.Status__c = 'Processing';
		update relatedPriceBook;

		//Update the Parent Super Price Book Request to Processing
		if (relatedPriceBook.Super_Price_Book_Request__r.Status__c != 'Processing') {
			relatedPriceBook.Super_Price_Book_Request__r.Status__c = 'Processing';
			update relatedPriceBook.Super_Price_Book_Request__r;
		}
		return Database.getQueryLocator(soql);
	}

	//Batch's Execute method to execute and process the scoped records
	global void execute(Database.BatchableContext BC, list<PricebookEntry> listPBEs) {
		try {
			Set<String> currencyISOCodes = new Set<String>();
			Set<String> productIds = new Set<String>();
			Map<String, PricebookEntry> existingPBEs = new Map<String, PricebookEntry>();
			List<PricebookEntry> pbeToInsert = new List<PricebookEntry>();
			List<PricebookEntry> pbeToUpdate = new List<PricebookEntry>();

			for (PricebookEntry pbe : listPBEs) {
				currencyISOCodes.add(pbe.CurrencyIsoCode);
				productIds.add(pbe.Product2Id);
			}

			for (PricebookEntry pbe : [
				SELECT
					Id,
					Pricebook2Id,
					Product2Id,
					CurrencyIsoCode,
					UnitPrice,
					Start_Date__c,
					UseStandardPrice,
					IsActive
				FROM PricebookEntry
				WHERE
					Pricebook2Id = :relatedPriceBook.Super_Price_Book_Request__r.Super_Pricebook__c
					AND Product2Id IN :productIds
					AND CurrencyISOCode IN :currencyISOCodes
			]) {
				String pbeKey = pbe.Pricebook2Id + '.' + pbe.Product2Id + '.' + pbe.CurrencyIsoCode;
				existingPBEs.put(pbeKey, pbe);
			}

			for (PricebookEntry srcPBE : listPBEs) {
				String pbeKey =
					relatedPriceBook.Super_Price_Book_Request__r.Super_Pricebook__c +
					'.' +
					srcPBE.Product2Id +
					'.' +
					srcPBE.CurrencyIsoCode;
				if (existingPBEs.containsKey(pbeKey)) {
					PricebookEntry existingPBE = existingPBEs.get(pbeKey);
					if (existingPBE.Start_Date__c == null || existingPBE.Start_Date__c < srcPBE.Start_Date__c) {
						existingPBE.UnitPrice = srcPBE.UnitPrice;
						existingPBE.Start_Date__c = srcPBE.Start_Date__c;
						existingPBE.UseStandardPrice = srcPBE.UseStandardPrice;
						existingPBE.IsActive = srcPBE.IsActive;
						pbeToUpdate.add(existingPBE);
					}
				} else {
					PricebookEntry pbeCloneObj = srcPBE.clone(false, true, false, false);
					pbeCloneObj.Pricebook2Id = relatedPriceBook.Super_Price_Book_Request__r.Super_Pricebook__c;
					pbeToInsert.add(pbeCloneObj);
					existingPBEs.put(pbeKey, pbeCloneObj);
				}
			}

			System.debug('============== pbeToInsert ' + pbeToInsert);
			if (pbeToInsert.size() > 0) {
				insert pbeToInsert;
			}
			System.debug('============== pbeToUpdate ' + pbeToUpdate);
			if (pbeToUpdate.size() > 0) {
				update pbeToUpdate;
			}
		} catch (Exception e) {
			statusStr = e.getMessage() + '\n' + e.getStackTraceString();
			ExceptionHandlerController.createException(
				'SuperPriceBookRequest_Batch',
				'execute',
				'Batch Execution',
				'Price Book Entry Create/Update',
				statusStr,
				System.today()
			);
			CommonUtilities.debug('================== statusStr ' + statusStr);
		}
	}

	//Batch Class's Finish method
	global void finish(Database.BatchableContext BC) {
		if (statusStr == 'Completed') {
			relatedPriceBook.Status__c = 'Completed';
		} else {
			relatedPriceBook.Status__c = 'Failed';
		}
		update relatedPriceBook;

		Map<String, Integer> statusMap = new Map<String, Integer>();
		for (AggregateResult agr : [
			SELECT Status__c, COUNT(Id) noOfRecords
			FROM Related_Pricebook__c
			WHERE Super_Price_Book_Request__c = :relatedPriceBook.Super_Price_Book_Request__r.Id AND isActive__c = TRUE
			GROUP BY Status__c
		]) {
			statusMap.put(String.valueOf(agr.get('Status__c')), Integer.valueOf(agr.get('noOfRecords')));
		}

		if (!statusMap.containsKey('Requested')) {
			Super_Price_Book_Request__c spr = new Super_Price_Book_Request__c(
				Id = relatedPriceBook.Super_Price_Book_Request__r.Id
			);
			if (statusMap.containsKey('Failed')) {
				spr.Status__c = 'Failed';
			} else {
				spr.Status__c = 'Completed';
			}
			update spr;
		}

		//to execute the next Related Pricebook Record
		checkRequestedRecordsAndExecute();
	}

	public static void checkRequestedRecordsAndExecute() {
		//Check If there is any record to be processed
		for (Related_Pricebook__c rp : [
			SELECT
				Id,
				Status__c,
				Price_Book__c,
				Super_Price_Book_Request__r.Id,
				Super_Price_Book_Request__r.Status__c,
				Super_Price_Book_Request__r.Super_Pricebook__c
			FROM Related_Pricebook__c
			WHERE isActive__c = TRUE AND Status__c = 'Requested'
			ORDER BY CreatedDate
			LIMIT 1
		]) {
			//Executing the batch
			Database.executebatch(new SuperPriceBookRequest_Batch(rp), 2000);
		}
	}
}