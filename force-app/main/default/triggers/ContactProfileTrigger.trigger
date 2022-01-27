// ===========================================================================
//  Object  : ContactProfileTrigger
//  Company : Keste @ IDC
//  Author  : Abinash Panigrahi
//  Purpose : Contact_Profile__c trigger functionality
// ===========================================================================
trigger ContactProfileTrigger on Contact_Profile__c(after insert, after delete) {
	/*****************************************************
	 * @comment : Commenting out Callout Logic at Contact Childs Record Level action
	 * NEW CONTACT INTERFACE CHANGE REQUEST
	 ******************************************************/

	/*****************************************************
    If(DynamicCodeExecution.allowExecution('ContactProfileTrigger.ContactProfileTrigger') && !CommonUtilities.isIntegrationOrMigrationUser()){
        if(Trigger.isInsert && Trigger.isAfter){
            //ContactProfileHandler.onAfterInsert(trigger.new);
        }
        if(Trigger.isDelete && Trigger.isAfter){
            //ContactProfileHandler.onAfterDelete(trigger.oldMap);
        }
    }
    *****************************************************/
}