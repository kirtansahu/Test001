// ===========================================================================
//  Object	: SyncSiebelQuoteController
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller Class for Updating Siebel Quote Number & ID at Opportunity level.
// 	This Class should be running in without sharing mode, CPQ is expecting Siebel_Quote_Number__c
// 	& Siebel_Quote_ID__c to be updated on opportunity
// ===========================================================================

public without sharing class SyncSiebelQuoteController {
	public String retURL { get; set; }
	public BigMachines__Quote__c stdCntrlr { get; set; }
	//Standard Constructor
	public SyncSiebelQuoteController(ApexPages.StandardController sc) {
		if (Apexpages.currentPage().getParameters().containsKey('retURL')) {
			retURL = Apexpages.currentPage().getParameters().get('retURL');
		}
	}

	// Method Name: updateOpportunity
	// Author: Abinash panigrahi
	// Description: Initialisation Method to perform task onLoad of Page
	// Return: PageReference - Redirect to CPQ Edit Quote page
	public PageReference onLoad() {
		//Page Reference track
		PageReference pg = null;
		//Current Loggedin User
		Id currentUser = UserInfo.getUserId();

		//Fetch Oracle User record exist or not for Current Loggedin User
		BigMachines__Oracle_User__c oracleUser = null;

		for (BigMachines__Oracle_User__c objNew : [
			SELECT Id, BigMachines__Allow_Quote_Creation__c, BigMachines__Provisioned__c
			FROM BigMachines__Oracle_User__c
			WHERE BigMachines__Salesforce_User__c = :currentUser
			LIMIT 1
		]) {
			oracleUser = objNew;
		}

		//If CPQ access doesnot exist
		if (
			oracleUser == null ||
			(oracleUser != null &&
			oracleUser.BigMachines__Allow_Quote_Creation__c == false &&
			oracleUser.BigMachines__Provisioned__c == false)
		) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.QUOTE_LICENSE_MESSAGE));
		} else {
			//Redirect to CPQ Edit Quote Page
			pg = Page.BigMachines__QuoteCreate;
		}
		return pg;
	}
}