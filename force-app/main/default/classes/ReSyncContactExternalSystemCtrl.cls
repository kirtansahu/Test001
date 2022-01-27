// ===========================================================================
//  Object	: ReSyncContactExternalSystemCtrl
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller Class for sending out forced callout to External System - Web, E1 & SAP
// ===========================================================================
public with sharing class ReSyncContactExternalSystemCtrl {
	// Method Name: doCallouts
	// Description: AuraEnabled Method to publish Contact record to OFM forecibly
	// Parameter 1: String objOppId - Opportunity record Id
	// Return: response - String literal to display as toast message
	@AuraEnabled
	public static String doCallouts(String objContactId) {
		String response;
		//Null Check
		if (objContactId != null) {
			Set<Id> conId = new Set<Id>();
			conId.add((Id) objContactId);
			//Get Contact record info -- decide if callout needs to happen or not
			for (Contact obj : [
				SELECT Id, List_of_Target_Systems__c, Is_Account_NAL__c, Account_RecordType__c
				FROM Contact
				WHERE Id IN :conId
			]) {
				if (
					!(obj.Account_RecordType__c == 'Prospect' && obj.Is_Account_NAL__c == false) &&
					obj.List_of_Target_Systems__c != null
				) {
					//Make Callout to OFM
					IntegrationUtility.SynctoSiebelNew('CONTACT', conId, 'UPDATE', 'UPDATE', 'CONTACT', false);
					response = 'SUCCESS';
				}
			}
		}
		if (response == null) {
			response = 'ERROR';
		}
		return response;
	}
}