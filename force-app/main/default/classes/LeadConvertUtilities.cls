/********************************************************************************************************
 * Object	: LeadConvertUtilities
 * Company	: Keste @ IDC
 * Author	: Adarsh Sharma
 * Purpose	: Utility class for the Custom Lead Path and Custom Lead Convert Lightning Component
 ********************************************************************************************************/
public class LeadConvertUtilities {
	/***************************************************************************************
    @description: This method used to fetch current lead record details
    @author: Keste Dev
    @date: 08 July, 2019
    @param: Id recordId : current record Id
    @return: Lead : fetch current sObject
    ***************************************************************************************/
	public static Lead fetchLeadRecordDetails(Id recordId) {
		Lead oLead = new Lead();
		if (DynamicCodeExecution.allowExecution('LeadConvertUtilities.fetchLeadRecordDetails')) {
			for (Lead lead : [
				SELECT
					Id,
					IsConverted,
					Account__c,
					Contact__c,
					Comment__c,
					Opportunity_Name__c,
					Current_Weekly_Capacity_Primary__c,
					RecordType.Name,
					Product_Grouping_Global__c,
					Status,
					Current_Instrument_Model_Primary__c,
					Other_notes__c,
					Current_Instrument_Model_Secondary__c,
					Current_Rgts_Cons_Product_Primary__c,
					Current_Rgts_Cons_Product_Secondary__c,
					Current_Weekly_Capacity_Secondary__c,
					Potential_selling_strategy__c,
					Primary_supplier_Inst__c,
					Primary_Supplier_Rgts_Cons__c,
					Primary_supplier_pain_pt_Inst__c,
					Primary_supplier_pain_pt_Rgts_Cons__c,
					Secondary_supplier_Inst__c,
					Secondary_supplier_Rgts_Cons__c,
					Secondary_supplier_pain_pt_Inst__c,
					Secondary_supplier_pain_pt_Rgts_Cons__c,
					Target_Weekly_Capacity_Primary__c,
					Target_Weekly_Capacity_Secondary__c,
					What_type_of_Contract_Primary__c,
					What_type_of_contract_Secondary__c,
					Other_Primary_Supplier_Inst__c,
					Other_Primary_Supplier_Rgts_Cons__c,
					Other_Secondary_Supplier_Inst__c,
					Other_Secondary_Supplier_Rgts_Cons__c
				FROM Lead
				WHERE Id = :recordId
			]) {
				oLead = lead;
			}
		}
		return oLead;
	}

	/***************************************************************************************
    @description: This method used to convert lead into opportunity
    @author: Keste Dev
    @date: 08 July, 2019
    @param: Lead oLead : current lead sobject
    @return: Id : converted opportunity id
    ***************************************************************************************/
	public static Id convertLead(Lead oLead) {
		Savepoint sp = Database.SetSavepoint();
		Id oppId;
		Database.LeadConvertResult oLeadConvertResult;
		try {
			if (DynamicCodeExecution.allowExecution('LeadConvertUtilities.convertLeadIntoOpportunity')) {
				OpportunityTriggerHandler.isFromLeadConversion = true;
				String convertStatusLabel = fetchLeadStatus();
				oLeadConvertResult = Database.convertLead(createLeadConvert(convertStatusLabel, oLead));
				if (oLeadConvertResult.isSuccess()) {
					oppId = oLeadConvertResult.getOpportunityId();
					if (oppId != null) {
						updateOpportunity(oppId, oLead);
					}
				}
			}
		} catch (exception ex) {
			Database.rollback(sp);
			throw new AuraHandledException(ex.getMessage());
		}

		if (oLeadConvertResult != null && !oLeadConvertResult.isSuccess()) {
			Database.Error[] lstErrors = oLeadConvertResult.getErrors();
			if (lstErrors != null && lstErrors.size() > 0) {
				Database.rollback(sp);
				throw new AuraHandledException(lstErrors[0].getMessage());
			}
		}
		return oppId;
	}

	/***************************************************************************************
    @description: This method used to fetch convert lead status label
    @author: Keste Dev
    @date: 08 July, 2019
    @param: none
    @return: String : converted lead status masterlabel
    ***************************************************************************************/
	public static String fetchLeadStatus() {
		String convertStatusLabel;
		if (DynamicCodeExecution.allowExecution('LeadConvertUtilities.fetchLeadStatus')) {
			for (LeadStatus convertStatus : [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1]) {
				convertStatusLabel = convertStatus.ApiName;
			}
		}
		return convertStatusLabel;
	}

	/***************************************************************************************
    @description: This method used to create lead convert
    @author: Keste Dev
    @date: 08 July, 2019
    @param: String convertStatusLabel : converted lead status master label
	@param: Lead oLead : current lead sObject record
    @return: Database.LeadConvert : current lead convert object
    ***************************************************************************************/
	public static Database.LeadConvert createLeadConvert(String convertStatusLabel, Lead oLead) {
		Database.LeadConvert oLeadConvert = new Database.LeadConvert();
		if (DynamicCodeExecution.allowExecution('LeadConvertUtilities.createLeadConvert')) {
			oLeadConvert.setLeadId(oLead.id);
			oLeadConvert.setAccountId(oLead.Account__c);
			oLeadConvert.setContactId(oLead.Contact__c);
			oLeadConvert.setConvertedStatus(convertStatusLabel);
		}
		return oLeadConvert;
	}

	/***************************************************************************************
    @description: This method used to update contact on newly converted opportunity
    @author: Keste Dev
    @date: 10 July, 2019
    @param: Id oppId : converted opportunity id
	@param: Lead oLead : current lead sObject record
    @return: none
    ***************************************************************************************/
	public static void updateOpportunity(Id oppId, Lead oLead) {
		if (DynamicCodeExecution.allowExecution('LeadConvertUtilities.updateOpportunity')) {
			Map<string, string> mapLeadOppFieldMapping = new Map<string, string>();
			for (ConvertLeadtoOpportunityFieldMapping__mdt leadOppField : [
				SELECT Lead_Field_API__c, Opportunity_Field_API__c
				FROM ConvertLeadtoOpportunityFieldMapping__mdt
			]) {
				if (
					String.IsNotBlank(leadOppField.Lead_Field_API__c) &&
					String.IsNotBlank(leadOppField.Opportunity_Field_API__c)
				) {
					mapLeadOppFieldMapping.put(leadOppField.Lead_Field_API__c, leadOppField.Opportunity_Field_API__c);
				}
			}
			if (mapLeadOppFieldMapping.size() > 0) {
				Opportunity opp = new Opportunity(Id = oppId);
				for (String leadField : mapLeadOppFieldMapping.KeySet()) {
					opp.put(mapLeadOppFieldMapping.get(leadField), oLead.get(leadField));
				}
				if (oLead.RecordType.Name == System.Label.SalesCreatedLeadRecordTypeName) {
					//Added Close Date = Today +45 --Lead Pass
					opp.CloseDate = System.today().addDays(45);
					opp.Description = '';
					if (oLead.Comment__c != null) {
						opp.Description += 'Lead Comment: ' + '\n';
						opp.Description += oLead.Comment__c + '\n\n';
					}
					if (oLead.Product_Grouping_Global__c != null) {
						opp.Description += 'Product Selected: ' + '\n';
						opp.Description += oLead.Product_Grouping_Global__c;
					}
				}
				update opp;
			}
		}
	}
}