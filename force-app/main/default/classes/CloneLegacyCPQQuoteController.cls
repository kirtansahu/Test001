// ===========================================================================
//  Object	: CloneLegacyCPQQuoteController
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller Class to redirect Clone CPQ Site after reset Opportunity Header
// 	This Class should be running in without sharing mode, CPQ is expecting Siebel_Quote_Number__c, Siebel_Quote_ID__c
// 	& Siebel_Quote_Type__c to be updated on opportunity
// ===========================================================================
// ===========================================================================

public with sharing class CloneLegacyCPQQuoteController {
	public BigMachines__Quote__c stdCntrlr { get; set; }
	public Id quoteId { get; set; }

	//Standard Constructor
	public CloneLegacyCPQQuoteController(ApexPages.StandardController sc) {
		quoteId = null;
		if (sc != null && sc.getId() != null) {
			quoteId = sc.getId();
		}
	}

	// Method Name: updateOpportunity
	// Author: Abinash panigrahi
	// Description: Initialisation Method to perform task onLoad of Page
	// Return: PageReference - Redirect to CPQ Edit Quote page
	public PageReference onLoad() {
		PageReference pg = null;

		if (String.isNotBlank(quoteId)) {
			//Fetch Current Legacy quote record data
			BigMachines__Quote__c obj = null;
			for (BigMachines__Quote__c ob : [
				SELECT
					Id,
					RecordTypeId,
					BigMachines__Opportunity__c,
					BigMachines__Account__c
				FROM BigMachines__Quote__c
				WHERE Id = :quoteId
			]) {
				obj = ob;
			}

			if (obj != null) {
				//Fetch Related Opportunity
				Opportunity opp = null;
				for (Opportunity ob : [
					SELECT
						Id,
						Siebel_Quote_Number__c,
						AccountId,
						Siebel_Quote_Type__c
					FROM Opportunity
					WHERE Id = :obj.BigMachines__Opportunity__c
				]) {
					opp = ob;
				}

				if (opp != null) {
					opp.Siebel_Quote_Number__c = null;
					opp.Siebel_Quote_ID__c = null;
					opp.Siebel_Quote_Type__c = null;

					//Update Opportunity
					//Exception Handling
					try {
						update opp;
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'ViewLegacyCPQQuoteController',
							'onLoad',
							'Apex Controller',
							'Update Opportunity',
							ex.getMessage(),
							System.today()
						);
					}
				}

				/* Orace Comment - Workaround Solution --> {!URLFOR($Site.Prefix)}/apex/{!$Setup.BigMachines__NamespaceSettings__c.BigMachines__Underscore_Prefix__c}QuoteEdit?id={!BigMachines__Quote__c.Id}&actId={!BigMachines__Quote__c.BigMachines__AccountId__c}&clone=true */

				//Redirect to CPQ Clone Quote Page
				pg = Page.BigMachines__QuoteEdit;

				//Pass required parameters
				pg.getParameters().put('Id', obj.Id);
				pg.getParameters().put('actId', obj.BigMachines__Account__c);
				pg.getParameters().put('clone', 'true');
				//Force Redirect
				pg.setRedirect(true);
			} else {
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.Severity.ERROR,
						Label.QUOTE_ERROR_MESSAGE
					)
				);
			}
		} else {
			ApexPages.addMessage(
				new ApexPages.Message(
					ApexPages.Severity.ERROR,
					Label.QUOTE_ERROR_MESSAGE
				)
			);
		}
		return pg;
	}
}