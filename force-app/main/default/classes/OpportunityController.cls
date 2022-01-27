// ===========================================================================
//  Class Name 	: OpportunityController
// 	Company  	: Keste @ IDC
//  Author		: Vasavi P
// 	Purpose		: Controller Class for Lightning Component: CreateNewOpportunity
// ===========================================================================
public with sharing class OpportunityController {
	//Method to return List of Opportunities with default name and stage
	@AuraEnabled
	public static List<Opportunity> populateValues() {
		List<Opportunity> OppLst = new List<Opportunity>();
		Opportunity NewOpp = new Opportunity();
		NewOpp.Name = 'Test Opp';
		NewOpp.StageName = 'New';
		OppLst.add(NewOpp);
		return OppLst;
	}
}