// ===========================================================================
//	Class Name	: ViewAccountTeamOnOpportunity
//	Company		: Keste @IDC
//	Author		: Abinash Panigrahi
//	Purpose		: Apex Controller for ViewAccountTeamOnOpportunity.cmp - Lightning Component, which is used in 'View/Add Account Team' action on Opportunity.
//          	This class will implement the following functionalities :
//           	- Add the Opportunity Team Members from related Account Team
//           	- Delete the Opportunity Team Members
// ===========================================================================
public class ViewAccountTeamOnOpportunity {
	// Method Name: viewAccountTeamData
	// Description: AuraEnabled Method to fetch the Account and Opportunity Team members from provided Opportunity record Id
	// Parameter 1: String objOppId - Opportunity record Id for which team members need to be fetched
	// Return: TeamWrapper - Wrapper Class Containing list of both Account and Opportunity team members
	@AuraEnabled
	public static TeamWrapper viewAccountTeamData(String objOppId) {
		TeamWrapper objTeamWrapper = new TeamWrapper();
		Opportunity objOpp = new Opportunity();
		List<UserTerritory2Association> lstAccTeam = new List<UserTerritory2Association>();
		Map<String, OpportunityTeamMember> mpOTM = new Map<String, OpportunityTeamMember>();

		if (objOppId != null) {
			for (Opportunity opp : [
				SELECT
					Id,
					Name,
					AccountId,
					Account.RecordType.DeveloperName,
					(
						SELECT Id, Name, UserId, TeamMemberRole, User.Name, IsPrimary__c, Position__c
						FROM OpportunityTeamMembers
					)
				FROM Opportunity
				WHERE Id = :objOppId
			]) {
				objOpp = opp;
			}

			if (objOpp.OpportunityTeamMembers != null) {
				for (OpportunityTeamMember objOTM : objOpp.OpportunityTeamMembers) {
					String uniqueId = objOTM.UserId;
					mpOTM.put(uniqueId, objOTM);
				}
				objTeamWrapper.lstOppTeam = objOpp.OpportunityTeamMembers;
			}
		}

		// Prepare Account list
		Set<Id> sgnIds = new Set<Id>();

		// Extra Condition check Added to segregate logic for Non-NSGN accounts
		if (objOpp.Account.RecordType.DeveloperName != 'NSGN') {
			sgnIds.add(objOpp.AccountId);
		} else {
			// Get all child SGN Record Ids
			for (Account objAcc : [SELECT Id FROM Account WHERE ParentId = :objOpp.AccountId]) {
				sgnIds.add(objAcc.Id);
			}
		}

		// Get all Territory assosiated with Child SGNs
		Set<Id> terrIds = new Set<Id>();
		for (ObjectTerritory2Association objTerr : [
			SELECT Id, ObjectId, Territory2Id, SobjectType
			FROM ObjectTerritory2Association
			WHERE ObjectId IN :sgnIds
		]) {
			terrIds.add(objTerr.Territory2Id);
		}

		// Fetch User related to Territory
		for (UserTerritory2Association objUser : [
			SELECT Id, UserId, User.Name, Territory2Id, Territory2.Name, IsActive, RoleInTerritory2
			FROM UserTerritory2Association
			WHERE Territory2Id IN :terrIds
		]) {
			lstAccTeam.add(objUser);
		}

		// Add to Response Wrapper
		objTeamWrapper.lstAccTeam = lstAccTeam;
		return objTeamWrapper;
	}

	// Method Name: updateOpportunityTeam
	// Description: AuraEnabled Method to update Opportunity team member
	// Parameter 1: List<AccountTeamMember> lstAddAccTeam - List of Account Team Members to be Created as Opportunity Team members
	// Parameter 2: List<OpportunityTeamMember> lstRemoveOppTeam - List of Opportunity Team Members to be removed
	// Parameter 3: String objOppId - Opportunity record Id
	// Return: String - Returning Status/Error message
	@AuraEnabled
	public static String updateOpportunityTeam(
		List<UserTerritory2Association> lstAddAccTeam,
		List<OpportunityTeamMember> lstRemoveOppTeam,
		String objOppId
	) {
		try {
			if (lstAddAccTeam != null && lstAddAccTeam.size() > 0) {
				list<OpportunityTeamMember> lstOppTeam = new List<OpportunityTeamMember>();
				for (UserTerritory2Association objAccTeam : lstAddAccTeam) {
					OpportunityTeamMember objOTM = new OpportunityTeamMember();
					objOTM.OpportunityId = objOppId;
					objOTM.UserId = objAccTeam.UserId;
					objOTM.TeamMemberRole = 'Account Manager';
					objOTM.OpportunityAccessLevel = 'Edit';
					objOTM.Position__c = objAccTeam.Territory2.Name;
					lstOppTeam.add(objOTM);
				}
				if (lstOppTeam != null && lstOppTeam.Size() > 0) {
					insert lstOppTeam;
				}
			}

			if (lstRemoveOppTeam != null && lstRemoveOppTeam.size() > 0) {
				List<OpportunityTeamMember> lstOppTeam = new List<OpportunityTeamMember>();
				for (OpportunityTeamMember objOppTeam : lstRemoveOppTeam) {
					if (!objOppTeam.isPrimary__c)
						lstOppTeam.add(objOppTeam);
				}

				delete lstOppTeam;
			}
			return 'Opportunity Team Updated Successfully';
		} catch (Exception ex) {
			ExceptionHandlerController.createException(
				'ViewAccountTeam',
				'View Account Team on Opportunity',
				'Quick Action Logic',
				'Update Opportunity Team',
				ex.getMessage(),
				System.today()
			);
			return ex.getMessage();
		}
	}

	// Method Name: defineAccess
	// Description: AuraEnabled Method to fetch Current user access level to perform add/delete Opportunity Team Member
	// Parameter 1: String objOppId - Opportunity record Id
	// Return: accesslevel - Boolean value to determine current user Edit accessslevel on OTM records
	@AuraEnabled
	public static Boolean defineAccess(String objOppId) {
		//Instance to store Edit Accesslevel info of Current loggedin user
		Boolean accesslevel = false;

		//Current Loogedin User
		Id currentUser = UserInfo.getUserId();

		//Fetch Primary Opportunity Team Member record
		Id primaryOppTeam = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId = :objOppId LIMIT 1].Id;

		//NULL Check
		if (primaryOppTeam != null && currentUser != null) {
			//Fetch the User Record Access related info
			//Primary Opportunity Team Member record & Current User
			UserRecordAccess obj = [
				SELECT HasAllAccess, RecordId
				FROM UserRecordAccess
				WHERE RecordId = :primaryOppTeam AND UserId = :currentUser
				LIMIT 1
			];
			accesslevel = obj.HasAllAccess;
		}

		return accesslevel;
	}
}