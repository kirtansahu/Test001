// ===========================================================================
//  Object	: CreateAgreementVFController
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller Class to redirect BigMachine Create Quote screen and pass specific parameters at page level, Custom error message based on Region & User Profile
// ===========================================================================
public without sharing class CreateAgreementVFController {
	public Account stdCntrlr { get; set; }
	public Id accId { get; set; }

	//Standard Constructor
	public CreateAgreementVFController(ApexPages.StandardController sc) {
		accId = null;
		if (sc != null && sc.getId() != null) {
			accId = sc.getId();
		}
	}

	// Method Name: onLoad
	// Author: Abinash panigrahi
	// Description: Display Conditional Error Message based on certain conditions
	// Return: PageReference - Redirect to CPQ Create Quote page
	public PageReference onLoad() {
		PageReference pg = null;
		if (String.isNotBlank(accId) && accId != null) {
			//Fetch Current Account record data
			Account obj = null;
			for (Account acc : [
				SELECT Id, Applicable_Agreement__c, Country__c
				FROM Account
				WHERE Id = :accId
				LIMIT 1
			]) {
				obj = acc;
			}

			//Current Loogedin User
			User currentUser = [
				SELECT Id, Profile.Name, Organization__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
			];

			//Fetch Oracle User record exist or not for Current Loggedin User
			BigMachines__Oracle_User__c oracleUser = null;

			for (BigMachines__Oracle_User__c objNew : [
				SELECT
					Id,
					BigMachines__Allow_Quote_Creation__c,
					BigMachines__Provisioned__c
				FROM BigMachines__Oracle_User__c
				WHERE BigMachines__Salesforce_User__c = :currentUser.Id
				LIMIT 1
			]) {
				oracleUser = objNew;
			}

			//Fetch Create Agreement Access defination based on Region & Profile Name
			Agreement_Access__mdt accessDef = null;
			Boolean allowCreation = false;

			for (Agreement_Access__mdt objNew : [
				SELECT
					Id,
					Full_Create_Access_User_Profiles__c,
					Partial_Create_Access_User_Profiles__c,
					E_Agreement_Allowed_Countries__c,
					F_Agreement_Allowed_Countries__c,
					H_Agreement_Allowed_Countries__c
				FROM Agreement_Access__mdt
				LIMIT 1
			]) {
				accessDef = objNew;
				if (
                    accessDef.Full_Create_Access_User_Profiles__c
                        .split(',')
						.contains(currentUser.Profile.Name) ||
                    (accessDef.Partial_Create_Access_User_Profiles__c
                        .split(',')
						.contains(currentUser.Profile.Name) &&
					String.valueOf(
							accessDef.get(
								obj.Applicable_Agreement__c +
								'_Agreement_Allowed_Countries__c'
							)
						)
						.split(',')
						.contains(obj.Country__c))
				) {
					allowCreation = true;
				}
			}

			//If CPQ access doesnot exist
			if (
				oracleUser == null ||
				(oracleUser != null &&
				oracleUser.BigMachines__Allow_Quote_Creation__c == false &&
				oracleUser.BigMachines__Provisioned__c == false)
			) {
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.Severity.ERROR,
						Label.QUOTE_LICENSE_MESSAGE
					)
				);
			} else if (
				accessDef == null || (accessDef != null && !allowCreation)
			) {
				// If Agreement access doesnot exist
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.Severity.ERROR,
						Label.QUOTE_AGREEMENT_MESSAGE
					)
				);
			} else {
				//All Necessary permission available, then proceed
				pg = Page.BigMachines__QuoteCreate;
				System.debug('pg.getParameters()' + pg.getParameters());
				pg.getParameters().put('actId', obj.Id);
				pg.setRedirect(true);
			}
		}
		return pg;
	}

	// Method Name: back
	// Author: Abinash panigrahi
	// Description: Return to Opportunity record
	// Return: PageReference - Redirect to Parent Opportunity
	public PageReference back() {
		PageReference pg = new PageReference('/' + accId);
		return pg;
	}
}