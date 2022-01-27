/********************************************************************************
 * Object   : UserTrigger
 * Company  : Keste @IDC
 * Author   : Abinash Panigrahi
 * Purpose  : Dispatch User trigger functionality.
 ********************************************************************************/
trigger UserTrigger on User(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete,
	after undelete
) {
	if (DynamicCodeExecution.allowExecution('UserTrigger')) {
		if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter) {
			UserTriggerHandler.oracleUserSync(Trigger.new, Trigger.oldMap);
		}

		/************************ ACCOUNT TEAM LOGIC DECOMMISION - TERRITORY MANAGEMENT CHANGES ************************/
		/*if(Trigger.isUpdate && Trigger.isAfter) {
            //Instance to store User recordIds
            Set<Id> userIds = new Set<Id>();
            //Populate values to Instance
            for(User u : Trigger.new){
                if(u.IsActive != Trigger.oldMap.get(u.Id).IsActive 
                   || (u.Retrigger_Account_Team__c && u.Retrigger_Account_Team__c != Trigger.oldMap.get(u.Id).Retrigger_Account_Team__c)){
                    userIds.add(u.Id);
                }
            }
            
            //Call Batch Class
            if(userIds != null && userIds.size() > 0){
                Database.executeBatch(new RetriggerAccountTeam_Batch(userIds));
            }
        }*/
	}
}