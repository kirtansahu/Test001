// ===========================================================================
//  Class Name 	: NewOpportunityCls
// 	Company  	: Keste @ IDC
//  Author		: Vasavi P
// 	Purpose		: This apex class is used as Controller for NewOpportunitycmp - Lightning Component,
// 					which is used in 'New Opportunity' action at Contact level. This class will prefill
// 					the Contact and Account values under Opportunity Screen
// 	Test Class	: NewOpportunityCls_Test.cls
// ===========================================================================
public class NewOpportunityCls {
	// Method Name: NewOppPrefill
	// Author: Vasavi P
	// Description: Method to build an opportunity record prefilled with primary contact and account informations
	// Parameter 1: Id conId - Contact id to be used as primary Contact
	// Return: String: serialized JSON of Opportunity Record
	@AuraEnabled
	public static String NewOppPrefill(Id conId) {
		return createNewOpportunity(conId);
	}

	// Method Name: createNewOpportunity
	// Author: Vasavi P
	// Description: Method to build an opportunity record prefilled with primary contact and account informations
	// Parameter 1: Id conId - Contact id to be used as primary Contact
	// Return: String: serialized JSON of Opportunity Record
	public static String createNewOpportunity(Id contactRecordId) {
		Contact oContact = fetchContactRecord(contactRecordId);
		return serialize(createOpportuntiy(oContact));
	}

	// Method Name: fetchContactRecord
	// Author: Vasavi P
	// Description: Method to fetch the contact record from its record Id
	// Parameter 1: Id recordId - Contact id to be fetched
	// Return: Contact: fetched contact record
	public static Contact fetchContactRecord(Id recordId) {
		Contact oContact = new Contact();
		for (Contact con : [SELECT Id, AccountId FROM Contact WHERE Id = :recordId]) {
			oContact = con;
		}
		return oContact;
	}

	// Method Name: createOpportuntiy
	// Author: Vasavi P
	// Description: Method to build an opportunity record prefilled with primary contact and account informations
	// Parameter 1: Contact oContact - Contact object to be used to prefill the details
	// Return: Opportunity: Opportunity record with prefilled details
	public static Opportunity createOpportuntiy(Contact oContact) {
		Opportunity opp = new Opportunity();
		opp.StageName = 'New';
		opp.Primary_Contact__c = oContact.Id;
		if (oContact.AccountId != null) {
			opp.AccountId = oContact.AccountId;
		}
		return opp;
	}

	// Method Name: serialize
	// Author: Vasavi P
	// Description: Method to build serialized Opportunity JSON with predefined fields only.
	// Parameter 1: Opportunity opp - Opportunity record to be serialized
	// Return: String: serialized JSON of Opportunity Record
	public static String serialize(Opportunity opp) {
		String json = '';
		json += '{';
		for (Schema.FieldSetMember f : SObjectType.Opportunity.FieldSets.Opportunity_Fieldset.getFields()) {
			if (
				!f.getFieldPath().contains('__r') &&
				opp.get(f.getFieldPath()) != null &&
				opp.get(f.getFieldPath()) != ''
			) {
				json += '\"' + f.getFieldPath() + '\" : \"' + opp.get(f.getFieldPath()) + '\",';
			}
		}
		json = json.substring(0, json.length() - 1);
		json += '}';
		return json;
	}
}