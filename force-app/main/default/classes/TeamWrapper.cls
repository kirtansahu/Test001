// ===========================================================================
//  Object	: TeamWrapper
// 	Company	: Keste @ IDC
//  Author	: Vasavi Poranki
// 	Purpose	: Wrapper Class to hold the list of both AccountTeamMember and OpportunityTeamMember
// ===========================================================================
public class TeamWrapper {
	@AuraEnabled
	public List<OpportunityTeamMember> lstOppTeam;
	@AuraEnabled
	public List<UserTerritory2Association> lstAccTeam;
}