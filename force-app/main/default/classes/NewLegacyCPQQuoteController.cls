// ===========================================================================
//  Object	: NewLegacyCPQQuoteController
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller Class to reset Opportunity Header with Legacy Quote related fields
// 	This Class should be running in without sharing mode, CPQ is expecting Siebel_Quote_Number__c, Siebel_Quote_ID__c
// 	& Siebel_Quote_Type__c to be updated on opportunity
// ===========================================================================

public without sharing class NewLegacyCPQQuoteController {
	//Parent Opportunity Record Id
	public String oppId { get; set; }

	//Standard Constructor
	public NewLegacyCPQQuoteController(ApexPages.StandardSetController sc) {
		oppId = null;
		if (ApexPages.currentPage().getParameters().containsKey('Id')) {
			oppId = ApexPages.currentPage().getParameters().get('Id');
		}
	}

	// Method Name: updateOpportunity
	// Author: Abinash panigrahi
	// Description: Reset Quote related fields at Opportunity Header level
	// Return: PageReference - Redirect to CPQ Create Quote page
	public PageReference onLoad() {
		PageReference pg = null;
		if (String.isNotBlank(oppId) && oppId != null) {
			//Fetch Current Opportunity record data
			Opportunity obj = null;
			for (Opportunity opp : [
				SELECT Id, Siebel_Quote_Type__c, Siebel_Quote_Number__c, Siebel_Quote_ID__c
				FROM Opportunity
				WHERE Id = :oppId
			]) {
				obj = opp;
			}

			//Current Loogedin User
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
				//Instance to store Edit Accesslevel info of Current loggedin user
				Boolean accesslevel = false;

				//NULL Check
				if (obj != null && currentUser != null) {
					//Fetch the User Record Access related info
					//Primary Opportunity Team Member record & Current User
					UserRecordAccess accessObj = [
						SELECT HasEditAccess, RecordId
						FROM UserRecordAccess
						WHERE RecordId = :oppId AND UserId = :currentUser
						LIMIT 1
					];
					accesslevel = accessObj.HasEditAccess;
				}

				//If Current User has Edit access to record
				//Allow to create Quote
				if (accesslevel && obj != null) {
					obj.Siebel_Quote_Number__c = null;
					obj.Siebel_Quote_ID__c = null;
					obj.Siebel_Quote_Type__c = null;

					//Update Opportunity
					//Exception Handling
					try {
						update obj;
					} catch (Exception ex) {
						//Create Apex Log
						ExceptionHandlerController.createException(
							'CreateLegacyCPQQuoteController',
							'onLoad',
							'Apex Controller',
							'Update Opportunity',
							ex.getMessage(),
							System.today()
						);
					}

					//Instance of PageReference class
					pg = Page.BigMachines__QuoteCreate;
					pg.getParameters().put('oppId', obj.Id);
					pg.setRedirect(true);
				} else {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.QUOTE_ACCESS_MESSAGE));
				}
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.QUOTE_ERROR_MESSAGE));
		}
		return pg;
	}

	// Method Name: back
	// Author: Abinash panigrahi
	// Description: Return to Opportunity record
	// Return: PageReference - Redirect to Parent Opportunity
	public PageReference back() {
		PageReference pg = new PageReference('/' + oppId);
		return pg;
	}
}