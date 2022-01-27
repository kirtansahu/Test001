/***************************************************************************************
 * @description: This is used as controller for custom lead convert lightning componet
 * which is used to convert lead in opportunity
 * @author: Keste Dev
 * @date: 08 July, 2019
 ***************************************************************************************/
public with sharing class CustomLeadConvertCtrl {
	/***************************************************************************************
    @description: This method used to fetch current lead record details
    @author: Keste Dev
    @date: 08 July, 2019
    @param: Id recordId : current record Id
    @return: Lead : fetch current sObject
    ***************************************************************************************/
	@AuraEnabled
	public static Lead fetchLeadRecordDetails(Id recordId) {
		return LeadConvertUtilities.fetchLeadRecordDetails(recordId);
	}

	/***************************************************************************************
    @description: This method used to convert lead into opportunity
    @author: Keste Dev
    @date: 08 July, 2019
    @param: Lead oLead : current lead sobject
    @return: Id : converted opportunity id
    ***************************************************************************************/
	@AuraEnabled
	public static Id convertLeadIntoOpportunity(Lead oLead) {
		return LeadConvertUtilities.convertLead(oLead);
	}
}