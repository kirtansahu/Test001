// ===========================================================================
//  Object  : AccountContactRelationTrigger
//  Company : Keste @ IDC
//  Author  : Vasavi Poranki
//  Purpose : AccountContactRelation trigger functionality
// ===========================================================================
trigger AccountContactRelationTrigger on AccountContactRelation(after insert, after delete) {
    //Dynamic Code Execution
    if (DynamicCodeExecution.allowExecution('AccountContactRelationTrigger') && !CommonUtilities.isMigrationUser()) {
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                AccountContactRelationHandler.makeCallout(Trigger.new);
            }
            if (Trigger.isDelete && !AccountMergeRequestCtr.mergeInProcess) {
                AccountContactRelationHandler.makeCallout(Trigger.oldMap.values());
            }
        }
    }
}