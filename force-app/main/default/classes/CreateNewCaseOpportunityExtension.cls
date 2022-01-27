// ===========================================================================
//  Object  : CreateNewCaseOpportunityExtension
//  Company : Keste @ IDC
//  Author  : Adarsh Sharma
//  Purpose : Handler Class contains all logic for Create New Opprtunity and
//  associate to case.
// ===========================================================================
public class CreateNewCaseOpportunityExtension {
	public Case oCase { get; set; }
	public Opportunity opp { get; set; }
	public List<LayoutSection> layoutSections { get; set; }

	public CreateNewCaseOpportunityExtension(ApexPages.StandardController stdCon) {
		try {
			oCase = (Case) stdCon.getRecord();

			Id AccountSiteSGNRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(Label.ACCOUNT_RECORD_SITE_SGN)
				.getRecordTypeId();
			Id AccountProspectRecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
				.get(Label.ACCOUNT_RECORD_PROSPECT)
				.getRecordTypeId();

			for (Case c : [
				SELECT Id, Opportunity__c, AccountId, Account.RecordTypeId, Account.Account_Status__c, ContactId
				FROM Case
				WHERE Id = :oCase.Id
			]) {
				oCase = c;
			}
			if (oCase.Opportunity__c != null) {
				ApexPages.addMessage(
					new ApexPages.Message(ApexPages.Severity.ERROR, Label.CNCO_OpportunityAlreadyExistMsg)
				);
			} else if (
				oCase.Account.Account_Status__c != 'Active' ||
				(oCase.Account.RecordTypeId != AccountSiteSGNRecordTypeId &&
				oCase.Account.RecordTypeId != AccountProspectRecordtypeId)
			) {
				ApexPages.addMessage(
					new ApexPages.Message(ApexPages.Severity.ERROR, Label.Opportunity_Account_Required_Message)
				);
			} else {
				opp = new Opportunity();
				opp.AccountId = oCase.AccountId;
				opp.Primary_Contact__c = oCase.ContactId;
				opp.StageName = 'New';
				opp.Status__c = 'Pending';

				//Added Current User Profile Check Condition
				//Default Opportunity Source accordingly
				Id profileId = userinfo.getProfileId();
				String profileName = [SELECT Id, Name FROM Profile WHERE Id = :profileId].Name;
				if (profileName == 'Tech Support') {
					opp.Opportunity_Source__c = 'TS Created';
				} else if (profileName == 'FAS') {
					opp.Opportunity_Source__c = 'FAS Created';
				}

				Id describeRecordTypeId = PageLayoutDescriberHelper.getDefaultRecordType(new Opportunity());
				layoutSections = PageLayoutDescriberHelper.describeSectionWithFields(
					describeRecordTypeId,
					'Opportunity'
				);
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
	}

	// Method Name: createNewOpportunity
	// Author: Adarsh Sharma
	// Description: Method to use create new opportunity and update case with opportunity Id
	// Return: redirect to case record page
	public PageReference createNewOpportunity() {
		PageReference oPage = null;
		try {
			insert opp;

			oCase.Opportunity__c = opp.Id;
			update oCase;

			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.CNCO_OpportunityCreatedMsg));

			oPage = new PageReference('/' + opp.Id);
		} catch (DmlException dmlex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dmlex.getDMLMessage(0)));
			oPage = null;
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			oPage = null;
		}
		return oPage;
	}
}