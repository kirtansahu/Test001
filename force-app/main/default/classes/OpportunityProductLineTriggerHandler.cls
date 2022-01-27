/***************************************************************************************
 * @description: This is used as handler class to sync Opportunity Product Line with Siebel
 * @author: Keste Dev
 * @date: 20 Aug, 2019
 ***************************************************************************************/
public class OpportunityProductLineTriggerHandler {
	public static Id SGNRTId = Schema.SObjectType.Account.RecordTypeInfosByName.get('Site SGN').RecordTypeId;

	/***************************************************************************************
    @description: This method used to pre populate default fields on the record ONLY on creation
    @author: Basant Kumar Verma
    @date: 16 Dec, 2019
    @param: List<Opportunity_Product_Line__c> triggerNew : List of new Version of Product Line
    @return: none
    ***************************************************************************************/
	public static void prePopulateFields(List<Opportunity_Product_Line__c> newList) {
		//Dynamic Code Execution
		if (DynamicCodeExecution.allowExecution('OpportunityProductLineTriggerHandler.prePopulateFields')) {
			Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
			for (Opportunity_Product_Line__c pl : newList) {
				oppMap.put(pl.Opportunity__c, null);
			}

			oppMap = new Map<Id, Opportunity>(
				[SELECT Id, CurrencyISOCode FROM Opportunity WHERE Id IN :oppMap.keySet()]
			);

			for (Opportunity_Product_Line__c pl : newList) {
				if (oppMap.containskey(pl.Opportunity__c)) {
					pl.CurrencyISOCode = oppMap.get(pl.Opportunity__c).CurrencyISOCode;
				}
			}
		}
	}

	/***************************************************************************************
    @description: This method used to sync Opportunity Product Line with Siebel
    @author: Keste Dev
    @date: 20 Aug, 2019
    @param: List<Opportunity_Product_Line__c> triggerNew : List of new Version of Product Line
    @param: Map<Id, Opportunity_Product_Line__c> triggerOldMap : Map of new Version of Product Line
    @return: none
    ***************************************************************************************/
	/*public static void syncOpportunityProductLineWithSiebel(List<Opportunity_Product_Line__c> lstOpportunityProductLine, Map<Id, Opportunity_Product_Line__c> triggerOldMap){
    	//Dynamic Code Execution
	    If(DynamicCodeExecution.allowExecution('OpportunityProductLineTriggerHandler.syncOpportunityProductLineWithSiebel')){
	    	Set<Id> setOpportunityId = new Set<Id>();
	    	for(Opportunity_Product_Line__c oppProductLine : lstOpportunityProductLine){
	    		if(oppProductLine.Opportunity__c != null && (triggerOldMap == null || (triggerOldMap != null 
	    																				&& (oppProductLine.Opportunity__c != triggerOldMap.get(oppProductLine.Id).Opportunity__c
																							|| oppProductLine.Primary__c != triggerOldMap.get(oppProductLine.Id).Primary__c
																							|| oppProductLine.Product_Line__c != triggerOldMap.get(oppProductLine.Id).Product_Line__c)))){
	    			setOpportunityId.add(oppProductLine.Opportunity__c);
	    		}
	    	}
	    	
	    	if(setOpportunityId.size()>0){
                Set<Id> lstOppIdToSync = new Set<Id>();
				
				for(Opportunity opp : [SELECT Id FROM Opportunity WHERE Id IN:setOpportunityId AND Siebel_Row_Id__c != null]){
					lstOppIdToSync.add(opp.Id);						
				}
				
				if(lstOppIdToSync.size()>0){
                    String relatedOperationType = triggerOldMap == null ? 'INSERT' : 'UPDATE';
					IntegrationUtility.SynctoSiebel('OPPORTUNITY', setOpportunityId, 'UPDATE', relatedOperationType, 'OPPORTUNITY_PRODUCT_LINE__C');
				}
	    	}
	    }
    }*/

	/***************************************************************************************
    @description: This method used to delete Opportunity Product Lines from Siebel
    @author: Keste Dev
    @date: 21 Aug, 2019
    @param: List<Opportunity_Product_Line__c> lstOpportunityProductLine : Collection of Opportunity Product Line records
    @return: none
    ***************************************************************************************/
	/*public static void syncDeletedOpportunityProductLineWithSiebel(List<Opportunity_Product_Line__c> lstOpportunityProductLine){
     	//Dynamic Code Execution
	    If(DynamicCodeExecution.allowExecution('OpportunityProductLineTriggerHandler.syncDeletedOpportunityProductLineWithSiebel')){
	    	Map<Id, String> mapProductLineIdWithUniqueId = new Map<Id, String>();
			Map<Id, String> mapProductLineIdWithName = new Map<Id, String>();
        	Map<Id, String> mapOpportunityWithSiebelRowId = new Map<Id, String>();
        	
	    	for(Opportunity_Product_Line__c oppProductLine : lstOpportunityProductLine){
	    		if(oppProductLine.Opportunity__c != null && oppProductLine.Product_Line__c != null){
	    			mapOpportunityWithSiebelRowId.put(oppProductLine.Opportunity__c, null);
	    			mapProductLineIdWithUniqueId.put(oppProductLine.Product_Line__c, null);
					mapProductLineIdWithName.put(oppProductLine.Product_Line__c, null);
	    		}
	    	}
	    	
	    	if(!mapOpportunityWithSiebelRowId.IsEmpty() && !mapProductLineIdWithUniqueId.IsEmpty()){
	    		for(Opportunity opportunity : [SELECT Id, Siebel_Row_Id__c FROM Opportunity 
	    										WHERE Id IN:mapOpportunityWithSiebelRowId.keyset() AND Siebel_Row_Id__c != null]){
					mapOpportunityWithSiebelRowId.put(opportunity.Id, opportunity.Siebel_Row_Id__c);
				}
				
				for(Product_Line__c oProductLine : [SELECT Id, Unique_Id__c, Name FROM Product_Line__c WHERE Id IN:mapProductLineIdWithUniqueId.keyset()]){
					mapProductLineIdWithUniqueId.put(oProductLine.Id, oProductLine.Unique_Id__c);
					mapProductLineIdWithName.put(oProductLine.Id, oProductLine.Name);
				}
				
				List<sObjectRecordWrapper> lstsObjectRecordWrapper = new List<sObjectRecordWrapper>();
				for(Opportunity_Product_Line__c oppProductLine : lstOpportunityProductLine){
					if(mapOpportunityWithSiebelRowId.get(oppProductLine.Opportunity__c) != null 
		    			&& mapProductLineIdWithUniqueId.get(oppProductLine.Product_Line__c) != null){
		    			lstsObjectRecordWrapper.add(new sObjectRecordWrapper(mapOpportunityWithSiebelRowId.get(oppProductLine.Opportunity__c), mapProductLineIdWithUniqueId.get(oppProductLine.Product_Line__c),'OPPORTUNITY_PRODUCT_LINE__C', mapProductLineIdWithName.get(oppProductLine.Product_Line__c)));
		    		}
				}
				if(lstsObjectRecordWrapper.size()>0){
	        		IntegrationUtility.syncDeleteRecordWithSiebel(lstsObjectRecordWrapper, 'OPPORTUNITY_PRODUCT_LINE__C');
	            }
	    	}
	    }
     }*/
}