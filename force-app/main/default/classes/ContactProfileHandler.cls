// ===========================================================================
//  Object	: ContactProfileHandler
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Handler Class for Contact_Profile__c, this is to sync the Contact Profile records with Siebel
// ===========================================================================
public class ContactProfileHandler {
	/*****************************************************
	 * @comment : Commenting out Callout Logic at Contact Childs Record Level action. As per new Design decision - its not need anymore.
	 * NEW CONTACT INTERFACE CHANGE REQUEST
	 ******************************************************/

	/****************************************************
    // Method Name: onAfterInsert
    // Author: Abinash Panigrahi/Vasavi Poranki
    // Description: Method to send the Siebel Request when the Contact Profile is Inserted
    // Parameter 1: lstnewConProfiles - List of the new versions of the Contact Profile records
    // Return: Null
    public static void onAfterInsert(List<Contact_Profile__c> lstnewConProfiles){
       // Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('ContactProfileHandler.onAfterInsert')){
            //Instance to store Contact record Ids
            Set<Id> stConIds = new Set<Id>();
            for(Contact_Profile__c objCPs : lstnewConProfiles){
                stConIds.add(objCPs.Contact__c);
            }
            //Call Utility method to make Callouts
            if(stConIds != null && stConIds.size() > 0){
                IntegrationUtility.SynctoSiebel('CONTACT', stConIds, 'UPDATE', 'INSERT', 'CONTACT_PROFILE__C');
            }
        }
    }

    // Method Name: onAfterDelete
    // Author: Abinash Panigrahi/Vasavi Poranki
    // Description: Method to send the Siebel Request when the Contact Profile is Deleted
    // Parameter 1: mpOldCPs - Map of the old versions of the Contact Profile records
    // Return: Null
    public static void onAfterDelete(Map<Id,Contact_Profile__c> mpOldCPs){
       //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('ContactProfileHandler.onAfterDelete')){
            //Instance to hold Multiple Header and Child records for Callouts
            List<sObjectRecordWrapper> lstsObjectRecordWrapper = new List<sObjectRecordWrapper>();
            
            //Multiple Callout Siebel Sync funcationality
            for(Contact_Profile__c objCP : mpOldCPs.values()){                
                lstsObjectRecordWrapper.add(new sObjectRecordWrapper(objCP.Contact_External_Id__c, objCP.Profile_Unique_Id__c, 'CONTACT_PROFILE__C', objCP.Child_Profile_Id__c, objCP.Tier_Type__c));
            }
            
            //Asynchronous Callout
            if(lstsObjectRecordWrapper.size()>0){
        		IntegrationUtility.syncDeleteRecordWithSiebel(lstsObjectRecordWrapper, 'CONTACT_PROFILE__C');
            }
        }
    }
    ******************************************************/
}