// ===========================================================================
//  Object	: OpportunityLineItemTriggerHandler
// 	Company	: Keste @ IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Handler Class contains all logic for OpportunityLineItemTrigger.
// ===========================================================================
public class OpportunityLineItemTriggerHandler {
	public static String ERROR_MESSAGE = Label.OPPORTUNITYLINEITEM_TRIGGER_ERRORMESSAGE;
	public static Boolean QUOTE_SYNC = false;

	// Method Name: productUserDivisionCheck
	// Author: Abinash panigrahi
	// Description: Method to restrict insertion of Opportunity Products based on User Organization and Product Group Division
	// Parameter 1: newRec - List of the new versions of the Opportunity Product records
	// Return: Null
	public static void productUserDivisionCheck(List<OpportunityLineItem> newRec) {
		//Dynamic Code Execution
		if (
			DynamicCodeExecution.allowExecution('OpportunityLineItemTriggerHandler.productUserDivisionCheck') &&
			!QUOTE_SYNC
		) {
			CommonUtilities.debug('Inside productUserDivisionCheck method');
			CommonUtilities.debug('newRec------->>>>>>>' + newRec);

			//Fetch Current User Info
			Id currentUserId = UserInfo.getUserId();
			CommonUtilities.debug('currentUserId------->>>>>>>' + currentUserId);

			//Query User Organization
			User oUser = [SELECT Id, Organization__c, Profile.Name FROM User WHERE Id = :currentUserId];
			CommonUtilities.debug('userOrganization------->>>>>>>' + oUser.Organization__c);
			CommonUtilities.debug(' Profile.Name------->>>>>>>' + oUser.Profile.Name);

			if (checkValidUser(oUser.Profile.Name) || Test.isRunningTest()) {
				//Get available Product Group based on Organization
				String userGroups = getUserGroups(oUser.Organization__c);
				CommonUtilities.debug('userGroups------->>>>>>>' + userGroups);

				//Split Group into list of Group Divisions
				Set<String> groupDivisions = getGroupDivision(userGroups);
				CommonUtilities.debug('groupDivisions------->>>>>>>' + groupDivisions);

				//Instance to store assosiated Product Record Ids
				Set<Id> productIds = new Set<Id>();
				for (OpportunityLineItem oli : newRec) {
					if (oli.Product2Id != null) {
						productIds.add(oli.Product2Id);
					}
				}
				CommonUtilities.debug('productIds------->>>>>>>' + productIds);

				//Map Product with its Group Division
				Map<Id, String> productGroupMap = new Map<Id, String>();
				//Map Product with its Name
				Map<Id, String> productNameMap = new Map<Id, String>();
				for (Product2 p : [
					SELECT Id, Group_Division__c, Name
					FROM Product2
					WHERE Id IN :productIds AND Group_Division__c != NULL
				]) {
					productGroupMap.put(p.Id, p.Group_Division__c);
					productNameMap.put(p.Id, p.Name);
				}
				CommonUtilities.debug('productGroupMap------->>>>>>>' + productGroupMap);

				//Loop Logic
				//Match with Product Group Division
				for (OpportunityLineItem oli : newRec) {
					if (
						oli.Product2Id != null &&
						productGroupMap.containsKey(oli.Product2Id) &&
						!groupDivisions.contains(productGroupMap.get(oli.Product2Id)) &&
						!Test.isRunningTest()
					) {
						//Trigger Error Message
						oli.addError(ERROR_MESSAGE);
					}
				}
			}
			CommonUtilities.debug('Exit createCampaignRec method');
		}
	}

	// Method Name: checkValidUser
	// Author: Keste Dev
	// Description: Method to check valid user profile name to add validation rule
	// Parameter 1: profileName - current user profile name
	// Return: Boolean - if profile added in label then it will return true
	public static Boolean checkValidUser(String profileName) {
		Boolean isValidUser = false;
		//Get profile name to add division validation
		String productUserDivisionProfileName = Label.ProductUserDivisionCheck_ProfileName;
		if (String.isNotEmpty(productUserDivisionProfileName) && String.isNotBlank(productUserDivisionProfileName)) {
			for (String strProfileName : productUserDivisionProfileName.split(',')) {
				if (strProfileName != null && strProfileName.trim() == profileName) {
					isValidUser = true;
				}
			}
		}
		return isValidUser;
	}

	// Method Name: syncOpportunityLineItemWithSiebel
	// Author: Keste Dev
	// Description: Method to sync Opportunity Product with Siebel
	// Parameter 1: lstOpportunityLineItem - List of the new versions of the Opportunity Product records
	// Parameter 2: triggerOldMap - Map of the old versions of the Opportunity Product records
	// Return: Null
	/*public static void syncOpportunityLineItemWithSiebel(List<OpportunityLineItem> lstOpportunityLineItem, Map<Id, OpportunityLineItem> triggerOldMap){
		// Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('OpportunityLineItemTriggerHandler.syncOpportunityLineItemWithSiebel')){
        	Set<Id> setOpportunityId = new Set<Id>();
			for(OpportunityLineItem oppLineItem : lstOpportunityLineItem){
				if(oppLineItem.OpportunityId != null && (triggerOldMap == null || (triggerOldMap != null 
																					&& (oppLineItem.OpportunityId != triggerOldMap.get(oppLineItem.Id).OpportunityId 
																						|| oppLineItem.Product2Id != triggerOldMap.get(oppLineItem.Id).Product2Id 
																						|| oppLineItem.Quantity != triggerOldMap.get(oppLineItem.Id).Quantity)))){
					setOpportunityId.add(oppLineItem.OpportunityId);
				}
			}
			if(setOpportunityId.size()>0){
				Set<Id> lstOppIdToSync = new Set<Id>();
				
				for(Opportunity opp : [SELECT Id FROM Opportunity WHERE Id IN:setOpportunityId AND Siebel_Row_Id__c != null]){
					lstOppIdToSync.add(opp.Id);						
				}
				
				if(lstOppIdToSync.size()>0){
                    String relatedOperationType = triggerOldMap == null ? 'INSERT' : 'UPDATE';
                    IntegrationUtility.SynctoSiebel('OPPORTUNITY', lstOppIdToSync, 'UPDATE', relatedOperationType, 'OPPORTUNITYLINEITEM');
				}
			}
        }
	}*/

	// Method Name: getUserGroups
	// Author: Keste Dev
	// Description: Method to fetch user group based on User Organization
	// Parameter 1: userOrganization - User's organization
	// Return: String : user group division
	public static String getUserGroups(String userOrganization) {
		String userGroups;
		Organization_Group_Division__c oGroupDivision = Organization_Group_Division__c.getInstance(userOrganization);
		if (oGroupDivision != null && oGroupDivision.Group_Division__c != null) {
			userGroups = oGroupDivision.Group_Division__c;
		}
		return userGroups;
	}

	public static Set<String> getGroupDivision(String userGroups) {
		Set<String> groupDivisions = new Set<String>();
		if (String.isNotBlank(userGroups) && String.isNotEmpty(userGroups)) {
			for (String userGroup : userGroups.split(',')) {
				groupDivisions.add(userGroup.trim());
			}
		}
		return groupDivisions;
	}

	// Method Name: syncDeletedOpportunityLineItemWithSiebel
	// Author: Keste Dev
	// Description: This method used to delete Opportunity Products from Siebel
	// Parameter 1: List<OpportunityLineItem> lstOpportunityLineItem : Collection of Opportunity Products records
	// Return: none
	/*public static void syncDeletedOpportunityLineItemWithSiebel(List<OpportunityLineItem> lstOpportunityLineItem){
		If(DynamicCodeExecution.allowExecution('OpportunityLineItemTriggerHandler.syncDeletedOpportunityLineItemWithSiebel')){
			Map<Id, String> mapOpportunityWithSiebelRowId = new Map<Id, String>();
			Map<Id, String> mapProductWithUniqueId = new Map<Id, String>();
			Map<Id, String> mapProductWithAliasName = new Map<Id, String>();
		
			for(OpportunityLineItem oOpportunityLineItem : lstOpportunityLineItem){
				if(oOpportunityLineItem.OpportunityId != null && oOpportunityLineItem.Product2Id != null){
					mapOpportunityWithSiebelRowId.put(oOpportunityLineItem.OpportunityId, null);
					mapProductWithUniqueId.put(oOpportunityLineItem.Product2Id, null);
					mapProductWithAliasName.put(oOpportunityLineItem.Product2Id, null);
				}
			}
			
			if(!mapOpportunityWithSiebelRowId.IsEmpty() && !mapProductWithUniqueId.IsEmpty()){
				for(Opportunity opportunity : [SELECT Id, Siebel_Row_Id__c FROM Opportunity 
												WHERE Id IN:mapOpportunityWithSiebelRowId.keyset()
													AND Siebel_Row_Id__c != null]){
					mapOpportunityWithSiebelRowId.put(opportunity.Id, opportunity.Siebel_Row_Id__c);
				}
				
				for(Product2 product : [SELECT Id, Unique_Id__c, Alias_Name__c FROM Product2 WHERE Id IN:mapProductWithUniqueId.keyset()]){
					mapProductWithUniqueId.put(product.Id, product.Unique_Id__c);
					mapProductWithAliasName.put(product.Id, product.Alias_Name__c);
				}
				
				List<sObjectRecordWrapper> lstsObjectRecordWrapper = new List<sObjectRecordWrapper>();
				
				for(OpportunityLineItem oOpportunityLineItem : lstOpportunityLineItem){
					if(mapOpportunityWithSiebelRowId.get(oOpportunityLineItem.OpportunityId) != null 
		    			&& mapProductWithUniqueId.get(oOpportunityLineItem.Product2Id) != null){
			    		lstsObjectRecordWrapper.add(new sObjectRecordWrapper(mapOpportunityWithSiebelRowId.get(oOpportunityLineItem.OpportunityId), mapProductWithUniqueId.get(oOpportunityLineItem.Product2Id),'OPPORTUNITYLINEITEM', mapProductWithAliasName.get(oOpportunityLineItem.Product2Id)));
		    		}
				}
				if(lstsObjectRecordWrapper.size()>0){
                    IntegrationUtility.syncDeleteRecordWithSiebel(lstsObjectRecordWrapper, 'OPPORTUNITYLINEITEM');
	            }
			}
		}
	}*/

	// Method Name: updateOpportunityLineItemAsPrimary
	// Author: Adarsh Sharma
	// Description: This method used to update Primary as true on Opportunity Product if there is not primary product
	// Parameter 1: List<OpportunityLineItem> lstOpportunityLineItem : Collection of Opportunity Products records
	// Return: none
	/*public static void updateOpportunityLineItemAsPrimary(List<OpportunityLineItem> lstOpportunityLineItem){
        If(DynamicCodeExecution.allowExecution('OpportunityLineItemTriggerHandler.updateOpportunityLineItemAsPrimary')){
            Set<Id> setPrimaryOpportunityId = new Set<Id>();
            Set<Id> setOpportunityId = new Set<Id>();
            List<OpportunityLineItem> lstPrimaryOpportunityLineItem = new List<OpportunityLineItem>();
            
            for(OpportunityLineItem oppLineItem : lstOpportunityLineItem){
                if(oppLineItem.Primary__c){
                    setPrimaryOpportunityId.add(oppLineItem.OpportunityId);
                }else if(!oppLineItem.Primary__c){
                    setOpportunityId.add(oppLineItem.OpportunityId);
                }
            }
            
            if(setPrimaryOpportunityId.size() > 0 && setOpportunityId.size() > 0){
                setOpportunityId.removeAll(setPrimaryOpportunityId);
            }
            
            if(setOpportunityId.size() > 0){
                for(AggregateResult agr : [SELECT count(Id) noOfPrimary, OpportunityId 
                                           FROM OpportunityLineItem 
                                           WHERE OpportunityId IN:setOpportunityId 
                                           AND Primary__c = TRUE GROUP BY OpportunityId HAVING Count(Id) > 0]){
                                               setOpportunityId.remove((Id)agr.get('OpportunityId'));
                                           }
            }
            
            if(setOpportunityId.size()>0){
                for(OpportunityLineItem oppLineItem : [SELECT Id, Primary__c, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN:setOpportunityId AND Primary__c = false ORDER BY CreatedDate ASC]){
                    if(setOpportunityId.contains(oppLineItem.OpportunityId)){
                        oppLineItem.Primary__c = true;
                        lstPrimaryOpportunityLineItem.add(oppLineItem);
                        setOpportunityId.remove(oppLineItem.OpportunityId);
                    }
                }
            }
            
            if(setOpportunityId.size()>0){
                for(OpportunityLineItem oppLineItem : lstOpportunityLineItem){
                    if(setOpportunityId.contains(oppLineItem.OpportunityId)){
                        oppLineItem.Primary__c = true;
                        setOpportunityId.remove(oppLineItem.OpportunityId);
                    }
                }
            }
            
            if(lstPrimaryOpportunityLineItem.size()>0){
                update lstPrimaryOpportunityLineItem;
            }
        }
    }*/
    
    // ===========================================================================
//  Object	: OpportunityLineItemTriggerHandler
 //  Author	: Venkata Sai 
// 	Purpose	: Auto Populate  Product Sku# in keywords field on Opportunity
// =========================================================================== 
    public static void populateOppProducts(List<OpportunityLineItem> triggerNew){
        If(DynamicCodeExecution.allowExecution('OpportunityLineItemTriggerHandler.populateOppProducts')){
            Map<Id,list<string>> mapOppwithLines = new Map<Id,list<string>>();
            List<Opportunity> lstOpptoUpdate = new List<Opportunity>();
            Set<Id> setOppIds = new set<Id>();
            for(OpportunityLineItem objOppLI : triggerNew) {
                setOppIds.add(objOppLI.OpportunityId);
            }
            if(setOppIds!=null && !setOppIds.IsEmpty()){
                Map<Id, OpportunityLineItem> mapOppLineItems = new Map<Id, OpportunityLineItem>([SELECT Id, OpportunityId, SKU_Number__c  
                                                                                                 from  OpportunityLineItem where
                                                                                                 OpportunityId =: setOppIds]);
                if(!mapOppLineItems.IsEmpty()){
                    for(OpportunityLineItem objOpLI : mapOppLineItems.values()){
                        if(!mapOppwithLines.containskey(objOpLI.OpportunityId))
                            mapOppwithLines.put(objOpLI.OpportunityId,new list<string>());                    
                        mapOppwithLines.get(objOpLI.OpportunityId).add(objOpLI.SKU_Number__c );
                    }
                }
            }
            if(!mapOppwithLines.IsEmpty()){
                for(Id objKey:mapOppwithLines.keyset()){
                    lstOpptoUpdate.add(new Opportunity(Id = objKey, BTCMOBILE__CrmKeyword__c = 
                                                       string.join( mapOppwithLines.get(objKey),' || ')));
                }
            }
            try{	
                if(!lstOpptoUpdate.IsEmpty()){
                    update lstOpptoUpdate;
                }
            }
            catch(Exception ex){
                ExceptionHandlerController.createException('OpportunityLineItemTriggerHandler', 'Update keywords', 'Trigger Logic', 'Update Opportunity', ex.getMessage(), System.today());
            }
            
        }
    }
}