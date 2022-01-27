// ===========================================================================
//  Class Name  : QuoteProductSyncController
//  Company     : Keste @ IDC
//  Author      : Abinash Panigrahi
//  Purpose     : Controller Class for Lightning Component: QuoteProductSync
// ===========================================================================
public with sharing class QuoteProductSyncController {
	//Inner Class to be used as Wrapper Class
	//Will load all data to Lightning component in a single callout
	public class ProductWrapper {
		@AuraEnabled
		public List<BigMachines__Quote_Product__c> quoteProducts;
		@AuraEnabled
		public List<OpportunityLineItem> opportunityProducts;
		@AuraEnabled
		public Boolean showData;
		@AuraEnabled
		public Boolean showComponent;
		@AuraEnabled
		public String quoteHeader;
		@AuraEnabled
		public String oppHeader;
		@AuraEnabled
		public String quotePricelist;
		@AuraEnabled
		public String oppPricelist;
		@AuraEnabled
		public String errorMessage;
		@AuraEnabled
		public Id oppRecId;
	}

	// Method Name: doInit
	// Description: AuraEnabled Method to fetch all required information
	// Parameter 1: String quoteId - Quote record Id for which products need to be fetched
	// Return: resultProducts
	@AuraEnabled
	public static ProductWrapper doInit(String quoteId) {
		ProductWrapper results = new ProductWrapper();
		if (quoteId != null) {
			//Fetch Quote record based on record Id
			BigMachines__Quote__c quoteObj = new BigMachines__Quote__c();
			for (BigMachines__Quote__c qt : [
				SELECT
					Id,
					BigMachines__Opportunity__c,
					Name,
					Quote_Name__c,
					BigMachines_Quote_Type__c,
					BigMachines__Opportunity__r.Name,
					BigMachines__Opportunity__r.Opportunity_Number__c,
					BigMachines__Description__c,
					Price_List__c,
					BigMachines__Opportunity__r.Pricebook2.ERP_Pricelist_Id__c,
					BigMachines__Opportunity__r.Pricebook2.Name
				FROM BigMachines__Quote__c
				WHERE Id = :quoteId
			]) {
				quoteObj = qt;
			}
			results.oppRecId = quoteObj.BigMachines__Opportunity__c;

			//Fetch related Quote Product records based on Quote record Id
			List<BigMachines__Quote_Product__c> quoteProductsobj = new List<BigMachines__Quote_Product__c>();
			for (BigMachines__Quote_Product__c qp : [
				SELECT
					Id,
					Name,
					CurrencyIsoCode,
					BigMachines__Quote__c,
					BigMachines__Quote__r.Name,
					BigMachines__Description__c,
					BigMachines__External_Id__c,
					BigMachines__Prep_Delete__c,
					BigMachines__Product__c,
					BigMachines__Quantity__c,
					BigMachines__Sales_Price__c,
					BigMachines__Synchronization_Id__c,
					BigMachines__Total_Price__c,
					Product_Name__c,
					Product_Alias_Name__c
				FROM BigMachines__Quote_Product__c
				WHERE BigMachines__Quote__c = :quoteId
			]) {
				quoteProductsobj.add(qp);
			}
			results.quoteProducts = quoteProductsobj;

			//Fetch Opportunity Product records based on Quote's Opportunity record Id
			List<OpportunityLineItem> oppProductsObj = new List<OpportunityLineItem>();
			for (OpportunityLineItem op : [
				SELECT Id, Name, Product2Id, UnitPrice, TotalPrice, ListPrice, Quantity, SKU_Number__c, SKU_Name__c
				FROM OpportunityLineItem
				WHERE OpportunityId = :quoteObj.BigMachines__Opportunity__c
			]) {
				oppProductsObj.add(op);
			}
			results.opportunityProducts = oppProductsObj;

			//Get the Quote Product count to decide whether to show Data or not
			//results.showData = results.quoteProducts.size()>0 ? false : true;
			if (quoteProductsobj.size() > 0) {
				results.showData = false;
			} else {
				results.showData = true;
			}

			//Get the Quote Type to decide whether to decide component or not
			//results.showComponent = String.valueOf(Label.QUOTESYNC_ALLOWEDTYPES).split(';').contains(results.quote.BigMachines_Quote_Type__c) ? false : true;
			String[] allowedTypes = String.valueOf(Label.QUOTESYNC_ALLOWEDTYPES).split(';');
			if (allowedTypes.contains(quoteObj.BigMachines_Quote_Type__c)) {
				results.showComponent = false;
			} else {
				results.showComponent = true;
			}

			//Get the Error Message dependent on certain condition
			//results.errorMessage = results.showComponent ? Label.VIEWQUOTESYNC_ERRORMESSAGE2 : results.showData ? Label.VIEWQUOTESYNC_ERRORMESSAGE : null;
			if (results.showData) {
				results.errorMessage = Label.VIEWQUOTESYNC_ERRORMESSAGE;
			}
			if (results.showComponent) {
				results.errorMessage = Label.VIEWQUOTESYNC_ERRORMESSAGE2;
			}

			//Get Datatable Header dynamic text display
			if (quoteObj.Quote_Name__c == null) {
				results.quoteHeader =
					Label.VIEWQUOTESYNC_SUCCESSMESSAGE +
					' ' +
					quoteObj.BigMachines_Quote_Type__c +
					' #' +
					quoteObj.Name;
			} else {
				results.quoteHeader =
					Label.VIEWQUOTESYNC_SUCCESSMESSAGE +
					' ' +
					quoteObj.BigMachines_Quote_Type__c +
					' #' +
					quoteObj.Name +
					' - ' +
					quoteObj.Quote_Name__c;
			}
			results.oppHeader =
				Label.VIEWQUOTESYNC_SUCCESSMESSAGE2 +
				' ' +
				quoteObj.BigMachines__Opportunity__r.Opportunity_Number__c +
				' ' +
				quoteObj.BigMachines__Opportunity__r.Name;

			//Get Pricebook List at Header level
			results.quotePricelist = quoteObj.Price_List__c;
			results.oppPricelist = quoteObj.BigMachines__Opportunity__r.Pricebook2.ERP_Pricelist_Id__c;
			if (results.oppPricelist == null) {
				results.oppPricelist = quoteObj.BigMachines__Opportunity__r.Pricebook2.Name;
			}
		}
		return results;
	}

	// Method Name: opportunityProductData
	// Description: AuraEnabled Method to fetch the Opportunity Product from provided Quote record Id
	// Parameter 1: String oppId - Quote's Opportunity record Id for which products need to be fetched
	// Return: resultProducts
	@AuraEnabled
	public static List<OpportunityLineItem> opportunityProductData(String oppId) {
		List<OpportunityLineItem> resultProducts = new List<OpportunityLineItem>();
		if (oppId != null) {
			resultProducts = [
				SELECT Id, Name, Product2Id, UnitPrice, TotalPrice, ListPrice, Quantity, SKU_Number__c, SKU_Name__c
				FROM OpportunityLineItem
				WHERE OpportunityId = :oppId
			];
		}
		return resultProducts;
	}

	// Method Name: upsertOpportunityProducts
	// Description: AuraEnabled Method to perform Upsert Opperation for Opportunity Products
	// Parameter 1: quoteProductRecords - Selected Quote Product records for sync
	// Return: result - Success/Error message
	@AuraEnabled
	public static String upsertOpportunityProducts(
		List<BigMachines__Quote_Product__c> quoteProductRecords,
		String oppId
	) {
		String resultStr = 'SUCCESS';
		if (quoteProductRecords != null && oppId != null) {
			Set<Id> existingProducts = new Set<Id>();
			for (OpportunityLineItem oli : [
				SELECT Id, Product2Id
				FROM OpportunityLineItem
				WHERE OpportunityId = :oppId
			]) {
				existingProducts.add(oli.Product2Id);
			}
			List<OpportunityLineItem> syncProducts = new List<OpportunityLineItem>();
			for (BigMachines__Quote_Product__c qp : [
				SELECT
					Id,
					BigMachines__Product__c,
					BigMachines__Sales_Price__c,
					BigMachines__Quote__r.BigMachines__Opportunity__c,
					BigMachines__Quantity__c,
					BigMachines__Description__c,
					Product_Alias_Name__c,
					BigMachines__Quote__c
				FROM BigMachines__Quote_Product__c
				WHERE Id IN :quoteProductRecords
			]) {
				OpportunityLineItem obj = new OpportunityLineItem();
				obj.Description = qp.BigMachines__Description__c;
				obj.OpportunityId = oppId;
				obj.Product2Id = qp.BigMachines__Product__c;
				obj.Quantity = qp.BigMachines__Quantity__c;
				obj.UnitPrice = qp.BigMachines__Sales_Price__c;
				obj.Opportunity_Product_External_Id__c =
					qp.BigMachines__Quote__r.BigMachines__Opportunity__c +
					'_' +
					qp.BigMachines__Product__c;
				obj.BigMachines__Origin_Quote__c = qp.BigMachines__Quote__c;
				obj.Include_on_Quote__c = false;
				syncProducts.add(obj);
			}

			if (syncProducts.size() > 0) {
				OpportunityLineItemTriggerHandler.QUOTE_SYNC = true;
				Schema.SObjectField externalId = OpportunityLineItem.Fields.Opportunity_Product_External_Id__c;
				List<Database.UpsertResult> results = Database.upsert(syncProducts, externalId, false);
				for (Database.UpsertResult sr : results) {
					if (!sr.isSuccess()) {
						Database.Error err = sr.getErrors()[0];
						ExceptionHandlerController.createException(
							'QuoteProductSyncController',
							'quoteProductData',
							'Controller Logic',
							'Upsert Opportunity Products',
							err.getMessage(),
							System.today()
						);
						resultStr = 'ERROR';
					}
				}
			}
		}

		return resultStr;
	}
}