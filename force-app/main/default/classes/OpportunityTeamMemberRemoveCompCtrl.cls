/***************************************************************************************
 * @description: This is used as controller for Opportunity Team Member Remove lightning
 * component which is used to remove current user from Opportunity Team Member
 * @author: Adarsh Sharma
 * @copyright: Kesete Dev
 * @date: 23 March, 2020
 ***************************************************************************************/
public without sharing class OpportunityTeamMemberRemoveCompCtrl {
	/***************************************************************************************
    @description: This method used to fetch current users Opportunity Team Member
    @author: Adarsh Sharma
	@copyright: Keste Dev
    @date: 23 March, 2020
    @param: String recordId : current record Id
    @return: OpportunityTeamMember : fetch current user's Opportunity Team Member
    ***************************************************************************************/
	@AuraEnabled
	public static OpportunityTeamMember fetchCurrentUserTeamMember(String recordId) {
		OpportunityTeamMember oOpportuntiyTeamMember = null;
		for (OpportunityTeamMember otm : [
			SELECT Id, OpportunityId, UserId, isPrimary__c
			FROM OpportunityTeamMember
			WHERE OpportunityId = :recordId AND UserId = :UserInfo.getUserId()
			LIMIT 1
		]) {
			oOpportuntiyTeamMember = otm;
		}
		return oOpportuntiyTeamMember;
	}

	/***************************************************************************************
    @description: This method used to delete current users Opportunity Team Member
    @author: Adarsh Sharma
	@copyright: Keste Dev
    @date: 23 March, 2020
    @param: String oppTeamMemberId : current Opportunity Team Member record Id
    @return: none
    ***************************************************************************************/
	@AuraEnabled
	public static void deleteOpportunityTeamMember(Id oppTeamMemberId) {
		try {
			delete new OpportunityTeamMember(Id = oppTeamMemberId);
		} catch (DMLException dmlex) {
			throw new AuraException(dmlex.getDmlMessage(0));
		} catch (Exception ex) {
			throw new AuraException(ex.getMessage());
		}
	}
}