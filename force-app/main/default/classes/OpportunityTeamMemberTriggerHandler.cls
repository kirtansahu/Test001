/***************************************************************************************
 * @description: This is used as handler class for OpportunityTeamMemberTrigger which used
 * to update opportunity owner when primary opportunity team member added on opportunity
 * check for duplicate primary opportunity team member
 * Sync Opportunity Team Member with Siebel When record insert or deleted.
 * @author: Keste Dev
 * @date: 19 Aug, 2019
 ***************************************************************************************/
public class OpportunityTeamMemberTriggerHandler {
	public static Boolean isFromAssignmentRuleJob = false;
	private static String READ_ACCESS = 'Read';
	private static String EDIT_ACCESS = 'Edit';
	public static Id SGNRTId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site SGN').RecordTypeId;

	/***************************************************************************************
    @description: This method used to add validation rule for primary record to not allow to delete
    @author: Keste Dev
    @date: 23 Aug, 2019
    @param: List<OpportunityTeamMember> triggerOld : List of old version of Opportunity team Member
    @return: none
    ***************************************************************************************/
	public static void checkAndNotAllowToDeletePrimaryTeamMember(List<OpportunityTeamMember> triggerOld) {
		// Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTeamMemberTriggerHandler.beforeDelete') &&
			!isFromAssignmentRuleJob
		) {
			for (OpportunityTeamMember oOpportunityTeamMember : triggerOld) {
				if (oOpportunityTeamMember.isPrimary__c && !CommonUtilities.isIntegrationOrMigrationUser()) {
					oOpportunityTeamMember.addError(Label.OppTeamMember_PrimaryDeleteMsg);
				}
			}
		}
	}

	/***************************************************************************************
    @description: This method used to check duplicate primary record
    @author: Keste Dev
    @date: 19 Aug, 2019
    @param: List<OpportunityTeamMember> triggerNew : List of new version of Opportunity team Member
 	@param: Map<Id, OpportunityTeamMember> triggerOldMap : Map of old version of Opportunity team Member
    @return: none
    ***************************************************************************************/
	public static void checkDuplicatePrimaryOppTeamMembers(
		List<OpportunityTeamMember> triggerNew,
		Map<Id, OpportunityTeamMember> triggerOldMap
	) {
		Set<Id> setOpportunityId = new Set<Id>();
		// Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution(
				'OpportunityTeamMemberTriggerHandler.checkDuplicatePrimaryOppTeamMembers'
			)
		) {
			for (OpportunityTeamMember oOpportunityTeamMember : triggerNew) {
				if (
					oOpportunityTeamMember.OpportunityId != null &&
					oOpportunityTeamMember.isPrimary__c &&
					(triggerOldMap == null ||
					(triggerOldMap != null &&
					oOpportunityTeamMember.isPrimary__c != triggerOldMap.get(oOpportunityTeamMember.Id).isPrimary__c))
				) {
					setOpportunityId.add(oOpportunityTeamMember.OpportunityId);
				}
			}
			if (setOpportunityId.size() > 0) {
				for (AggregateResult agr : [
					SELECT count(Id) noOfPrimary, OpportunityId
					FROM OpportunityTeamMember
					WHERE OpportunityId IN :setOpportunityId AND isPrimary__c = TRUE
					GROUP BY OpportunityId HAVING Count(Id) > 1
				]) {
					triggerNew.get(0).addError(Label.OppTeamMember_DuplicatePrimary);
				}
			}
		}
	}

	/***************************************************************************************
    @description: This method used to update Opportunity Owner
    @author: Keste Dev
    @date: 19 Aug, 2019
    @param: List<OpportunityTeamMember> triggerNew : List of new version of Opportunity team Member
    @return: none
    ***************************************************************************************/
	public static void updateOpportunityOwner(List<OpportunityTeamMember> triggerNew) {
		// Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('OpportunityTeamMemberTriggerHandler.updateOpportunityOwner')) {
			Map<Id, Id> mapOpportunityOwnerId = new Map<Id, Id>();
			List<Opportunity> lstOpportunity = new List<Opportunity>();

			for (OpportunityTeamMember OTM : triggerNew) {
				if (OTM.OpportunityId != null && OTM.UserId != null && OTM.isPrimary__c) {
					mapOpportunityOwnerId.put(OTM.OpportunityId, OTM.UserId);
				}
			}

			if (!mapOpportunityOwnerId.IsEmpty()) {
				for (Opportunity opp : [
					SELECT Id, OwnerId
					FROM Opportunity
					WHERE Id IN :mapOpportunityOwnerId.keyset()
				]) {
					if (opp.OwnerId != mapOpportunityOwnerId.get(opp.Id)) {
						opp.OwnerId = mapOpportunityOwnerId.get(opp.Id);
						lstOpportunity.add(opp);
					}
				}
			}

			if (lstOpportunity.size() > 0) {
				update lstOpportunity;
			}
		}
	}

	/***************************************************************************************
    @description: This method used to sync Opportunity Team Member with Siebel
    @author: Keste Dev
    @date: 19 Aug, 2019
    @param: List<OpportunityTeamMember> triggerNew : List of new version of Opportunity team Member
    @return: none
    ***************************************************************************************/
	/*public static void syncOpportunityTeamMemberWithSiebel(List<OpportunityTeamMember> lstOpportunityTeamMember){
		// Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('OpportunityTeamMemberTriggerHandler.syncOpportunityTeamMemberWithSiebel')){
			Set<Id> setOpportunityId = new Set<Id>();
			for(OpportunityTeamMember OTM : lstOpportunityTeamMember){
				setOpportunityId.add(OTM.OpportunityId);
			}
            
			if(setOpportunityId.size()>0){

				Set<Id> lstOppIdToSync = new Set<Id>();
				
				for(Opportunity opp : [SELECT Id FROM Opportunity WHERE Id IN:setOpportunityId AND Siebel_Row_Id__c != null]){
					lstOppIdToSync.add(opp.Id);						
				}
				
				if(lstOppIdToSync.size()>0){
					IntegrationUtility.SynctoSiebel('OPPORTUNITY', lstOppIdToSync, 'UPDATE', 'INSERT', 'OPPORTUNITYTEAMMEMBER');
				}
			}	
        }
	}*/

	/***************************************************************************************
    @description: This method used to delete Opportunity Team Member from Siebel
    @author: Keste Dev
    @date: 21 Aug, 2019
    @param: List<OpportunityTeamMember> lstOpportunityTeamMember : Collection of OpportunityTeamMember records
    @return: none
    ***************************************************************************************/
	/*public static void syncDeletedOpportunityTeamMemberWithSiebel(List<OpportunityTeamMember> lstOpportunityTeamMember){
    	//Dynamic Code Execution
	    /*If(DynamicCodeExecution.allowExecution('OpportunityTeamMemberTriggerHandler.syncDeletedOpportunityTeamMemberWithSiebel')){
	    	Map<Id, String> mapOpportunityWithSiebelRowId = new Map<Id, String>();
	    	Map<Id, String> mapUserWithExternalId = new Map<Id, String>();
            Map<Id, String> mapUserWithPositionId = new Map<Id, String>();
	    	
	    	for(OpportunityTeamMember oOpportunityTeamMember : lstOpportunityTeamMember){
	    		if(oOpportunityTeamMember.OpportunityId != null && oOpportunityTeamMember.UserId != null){
	    			mapOpportunityWithSiebelRowId.put(oOpportunityTeamMember.OpportunityId, null);
	    			mapUserWithExternalId.put(oOpportunityTeamMember.UserId, null);
                    mapUserWithPositionId.put(oOpportunityTeamMember.UserId, null);
	    		}
	    	}
	    	
	    	if(!mapOpportunityWithSiebelRowId.IsEmpty() && !mapUserWithExternalId.IsEmpty() && !mapUserWithPositionId.IsEmpty()){
	    		for(Opportunity opportunity : [SELECT Id, Siebel_Row_Id__c 
		    									FROM Opportunity 
		    									WHERE Id IN:mapOpportunityWithSiebelRowId.keyset() 
		    										AND Siebel_Row_Id__c != null 
													AND Account.RecordTypeId =:SGNRTId AND Account.ERP_Account_Id__c != null 
													AND AccountId != null]){
					mapOpportunityWithSiebelRowId.put(opportunity.Id, opportunity.Siebel_Row_Id__c);
				}
				
				for(User oUser : [SELECT Id, User_External_Id__c, Primary_Position__c FROM User 
									WHERE Id IN:mapUserWithExternalId.keyset() AND User_External_Id__c != null AND Primary_Position__c != NULL ]){
					mapUserWithExternalId.put(oUser.Id, oUser.User_External_Id__c);
                    mapUserWithPositionId.put(oUser.Id, oUser.Primary_Position__c);
				}
				
				List<sObjectRecordWrapper> lstsObjectRecordWrapper = new List<sObjectRecordWrapper>();
				for(OpportunityTeamMember oOpportunityTeamMember : lstOpportunityTeamMember){
		    		if(mapOpportunityWithSiebelRowId.get(oOpportunityTeamMember.OpportunityId) != null 
		    			&& mapUserWithExternalId.get(oOpportunityTeamMember.UserId) != null){
			    			String strExtId = oOpportunityTeamMember.OpportunityId+'_'+oOpportunityTeamMember.UserId;
                            lstsObjectRecordWrapper.add(new sObjectRecordWrapper(strExtId, mapUserWithExternalId.get(oOpportunityTeamMember.UserId),'OPPORTUNITYTEAMMEMBER', mapUserWithPositionId.get(oOpportunityTeamMember.UserId)));
		    		}
		    	}

		    	if(lstsObjectRecordWrapper.size()>0){
	        		IntegrationUtility.syncDeleteRecordWithSiebel(lstsObjectRecordWrapper, 'OPPORTUNITYTEAMMEMBER');
	            }
	    	}
	    }
    }*/

	// Method Name: populateUserPrimaryPosition
	// Author: Abinash panigrahi
	// Description: Method to populate Position__c field from User Primary Position value
	// Parameter 1: newRec - List of the new versions of the OpportunityTeamMember records
	// Return: Null

	public static void populateUserPrimaryPosition(List<OpportunityTeamMember> newRec) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityTeamMemberTriggerHandler.populateUserPrimaryPosition') &&
			!isFromAssignmentRuleJob
		) {
			CommonUtilities.debug('Inside populateUserPrimaryPosition Method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Store the relationship between User and Primary Position
			Map<Id, String> userPositionMap = new Map<Id, String>();
			//Store the relationship between User and Primary Position
			//Map<Id,String> userUniqueMap = new Map<Id,String>();
			//Map<Id,String> oppSiebelIdMap = new Map<Id,String>();
			//Loop logic to populate instance
			for (OpportunityTeamMember otm : newRec) {
				if (otm.UserId != null && otm.OpportunityId != null) {
					userPositionMap.put(otm.UserId, null);
					//userUniqueMap.put(otm.UserId,NULL);
					//oppSiebelIdMap.put(otm.OpportunityId,NULL);
				}

				if (CommonUtilities.isMigrationUser() && otm.OpportunityAccessLevel == READ_ACCESS) {
					otm.OpportunityAccessLevel = EDIT_ACCESS;
				}
			}

			//Fetch related User records
			for (User u : [
				SELECT Id, Primary_Position__c, User_External_Id__c
				FROM User
				WHERE Id IN :userPositionMap.keySet()
			]) {
				userPositionMap.put(u.Id, u.Primary_Position__c);
				//userUniqueMap.put(u.Id,u.User_External_Id__c);
			}

			//Fetch related Opportunity records
			//for(Opportunity o : [SELECT Id, Siebel_Row_Id__c FROM Opportunity WHERE Id IN: oppSiebelIdMap.keySet()])
			//oppSiebelIdMap.put(o.Id,o.Siebel_Row_Id__c);

			//Update Opportunity Team records with Position value
			for (OpportunityTeamMember otm : newRec) {
				if (otm.UserId != null && userPositionMap.get(otm.UserId) != null) {
					if (otm.Position__c == null)
						otm.Position__c = userPositionMap.get(otm.UserId);
					//otm.User_Unique_Id__c = userUniqueMap.get(otm.UserId);
				}
				//if(otm.OpportunityId != NULL && oppSiebelIdMap.containsKey(otm.OpportunityId)){
				//otm.Opportunity_Siebel_Id__c = oppSiebelIdMap.get(otm.OpportunityId);
				//}
			}

			CommonUtilities.debug('newRec------->>>>>>>' + newRec);
			CommonUtilities.debug('Exit populateUserPrimaryPosition Method');
		}
	}
}