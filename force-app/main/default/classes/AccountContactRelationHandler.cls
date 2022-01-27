// ===========================================================================
//  Class Name 	: AccountContactRelationHandler
// 	Company  	: Keste @ IDC
//  Author  	: Vasavi Poranki/Vasavi Poranki -yyy
// 	Purpose  	: After Inserting AccountContact record this class will send a callout to integrate the records with Siebel System
// 	Test Class  : AccountContactRelationHandler_Test
// ===========================================================================
public class AccountContactRelationHandler {
	// Method Name: shiptoCheck
	// Author: Abinash Panigrahi/Vasavi Poranki
	// Description: Method to update Contact header info with child Shipto Accounts present or not
	// Parameter 1: lstnewACRelations - List of the new versions of the Account Contact Relation records
	// Return: Null
	public static void shiptoCheck(List<AccountContactRelation> lstnewACRelations) {
		//Get all Related ShipTo accounts and note their parent Contact
		Set<Id> conIds = new Set<Id>();
		List<Contact> contactHeaderUpdate = new List<Contact>();
		for (AccountContactRelation obj : lstnewACRelations) {
			if (obj.Account_Record_Type__c == 'SHIPTO') {
				conIds.add(obj.ContactId);
			}
		}

		//Pick only Contact with out-dated info -- turn on Is Shipto Exist checkbox for Insert scenario and opposite for delete
		for (Contact obj : [
			SELECT
				Id,
				Is_Shipto_Exist__c,
				(SELECT Id FROM AccountContactRelations WHERE Account_Record_Type__c = 'SHIPTO')
			FROM Contact
			WHERE Id IN :conIds
		]) {
			if (obj.AccountContactRelations.size() > 0 && !obj.Is_Shipto_Exist__c) {
				contactHeaderUpdate.add(new Contact(Id = obj.Id, Is_Shipto_Exist__c = true));
			} else if (obj.AccountContactRelations.size() == 0 && obj.Is_Shipto_Exist__c) {
				contactHeaderUpdate.add(new Contact(Id = obj.Id, Is_Shipto_Exist__c = false));
			}
		}

		//Update Contact records
		if (contactHeaderUpdate.size() > 0) {
			update contactHeaderUpdate;
		}
	}

	// Method Name: calloutConditionCheck
	// Author: Abinash Panigrahi
	// Description: Method to validate for Integration - Callout not send for Prospect Contacts and Target System not null
	// Parameter 1: lstnewACRelations - List of the new versions of the Account Contact Relation records
	// Return: conRecIds - Set of Contact Record Id
	public static Set<Id> calloutConditionCheck(List<AccountContactRelation> lstnewACRelations) {
		//Ignore all Direct Account relationship
		Set<Id> conRecIds = new Set<Id>();
		for (AccountContactRelation objACs : lstnewACRelations) {
			if (!objAcs.IsDirect) {
				conRecIds.add(objACs.ContactId);
			}
		}

		//Filter out Prospect related Contacts and valid Target Exeternal system stamped
		for (Contact obj : [
			SELECT Id, List_of_Target_Systems__c, Is_Account_NAL__c, Account_RecordType__c
			FROM Contact
			WHERE Id IN :conRecIds
		]) {
			if (
				(obj.Account_RecordType__c == 'Prospect' && obj.Is_Account_NAL__c == false) ||
				obj.List_of_Target_Systems__c == null
			) {
				conRecIds.remove(obj.Id);
			}
		}

		return conRecIds;
	}

	// Method Name: makeCallout
	// Author: Abinash Panigrahi/Vasavi Poranki
	// Description: Method to send the External System Request when the Account Contact Relation is Inserted/Deleted
	// Parameter 1: lstnewACRelations - List of the new versions of the Account Contact Relation records
	// Return: Null
	public static void makeCallout(List<AccountContactRelation> lstnewACRelations) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('AccountContactRelationHandler.makeCallout')) {
			CommonUtilities.debug('Inside makeCallout method');

			//Shipto Information reflect at Header
			shiptoCheck(lstnewACRelations);

			//Allowed Contact Record Ids for Callout
			Set<Id> stConIds = calloutConditionCheck(lstnewACRelations);

			//Call Utility method to make Callouts
			if (stConIds != null && stConIds.size() > 0) {
				IntegrationUtility.SynctoSiebelNew(
					'CONTACT',
					stConIds,
					'UPDATE',
					'INSERT',
					'ACCOUNTCONTACTRELATION',
					false
				);
			}

			CommonUtilities.debug('Exit makeCallout method');
		}
	}

	/*****************************************************
	 * @comment : Commenting out Callout Logic at Contact Childs Record Level action. As per new Design decision - its not need anymore.
	 * NEW CONTACT INTERFACE CHANGE REQUEST
	 ******************************************************/

	/****************************************************

    // Method Name: onAfterDelete
    // Author: Abinash Panigrahi/Vasavi Poranki
    // Description: Method to send the Siebel Request when the Account Contact Relation is Deleted
    // Parameter 1: mpOldCPs - Map of the old versions of the Account Contact Relation records
    // Return: Null
    public static void onAfterDelete(Map<Id, AccountContactRelation> mpOldACRelations){

        //Instance to hold Multiple Header and Child records for Callouts 
        List<sObjectRecordWrapper> lstsObjectRecordWrapper = new List<sObjectRecordWrapper>();

        //Multiple Callout Siebel Sync funcationality
        for(AccountContactRelation objACs : mpOldACRelations.values()){
            lstsObjectRecordWrapper.add(new sObjectRecordWrapper(objACs.Contact_External_Id__c, objACs.Account_Unique_Id__c, 'ACCOUNTCONTACTRELATION', null));
        }
        
        //Asynchronous Callout
        if(lstsObjectRecordWrapper.size()>0){
            IntegrationUtility.syncDeleteRecordWithSiebel(lstsObjectRecordWrapper, 'ACCOUNTCONTACTRELATION');
        }
    }
    ****************************************************/
}
