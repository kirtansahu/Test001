// ===========================================================================
//  Object	: CPQQuoteTrigger
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Dispatch BigMachines__Quote__c trigger functionality.
// ===========================================================================
// Changes:
// ===========================================================================

trigger CPQQuoteTrigger on BigMachines__Quote__c (before delete, after update, after insert, after delete) {
    //Dynamic Code Execution
    if(DynamicCodeExecution.allowExecution('CPQQuoteTrigger') && !CommonUtilities.isMigrationUser()){

        // Sync Operation for Account Quote Junction Object
        if (Trigger.isAfter && Trigger.isInsert) {
            PricingAgreementAccountSync.processChanges(Trigger.new[0], null);
        }

        if (Trigger.isAfter && Trigger.isUpdate) {
            PricingAgreementAccountSync.processChanges(Trigger.new[0], Trigger.old[0]);
            PricingAgreementAccountSync.deleteRecords(Trigger.new[0], Trigger.old[0]);
        }
    }
}