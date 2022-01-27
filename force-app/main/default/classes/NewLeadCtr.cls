// ===========================================================================
//  Class Name 	: NewLeadCtr
// 	Company  	: Keste @ IDC
//  Author		: Basant Kumar Verma
// 	Purpose		: This apex class is used as Controller for NewLead - Lightning Component,
// 					which is used in 'New Lead' action at Contact level. This class will prefill
// 					the Recodr Type, Account, Contact, FirstName, LastName and Company values under Lead Screen
// 	Test Class	: NewLeadCtr_Test.cls
// ===========================================================================
public class NewLeadCtr {
	// Method Name: getLeadObject
	// Author: Basant Kumar Verma
	// Description: Method which will return Lead record details
	// Parameter 1: Id recordId -
	// Return: Lead -
	@AuraEnabled
	public static Lead getLeadObject(Id recordId) {
		Lead leadOb = new Lead();
		leadOb.RecordTypeId = PageLayoutDescriberHelper.getDefaultRecordType(leadOb);
		leadOb.Company = Label.Default_Lead_Company_and_Last_Name;
		leadOb.FirstName = Label.Default_Lead_Company_and_Last_Name;
		leadOb.LastName = Label.Default_Lead_Company_and_Last_Name;
		leadOb.Lead_Rejection_Reason__c = null;
		if (String.isNotBlank(recordId)) {
			for (Contact c : [
				SELECT Id, FirstName, LastName, AccountId, Account.Name
				FROM Contact
				WHERE Id = :recordId
			]) {
				leadOb.Account__c = c.AccountId;
				leadOb.Contact__c = c.Id;
				leadOb.FirstName = c.FirstName;
				leadOb.LastName = c.LastName;
				leadOb.Company = c.Account.Name;
			}
		}
		return leadOb;
	}

	// Method Name: fetchPageLayoutFieldsAndSection
	// Author: Basant Kumar Verma
	// Description: Method which will used to get all fields and sections from page layout
	// Parameter 1: Lead leadOb -
	// Return: List<LayoutSection> - Collection of layout section and fields
	@AuraEnabled
	public static List<LayoutSection> fetchPageLayoutFieldsAndSection(Lead leadOb) {
		try {
			List<LayoutSection> lstLayoutSection = new List<LayoutSection>();
			Id describeRecordTypeId = PageLayoutDescriberHelper.getDefaultRecordType(leadOb);
			lstLayoutSection = PageLayoutDescriberHelper.describeSectionWithFields(describeRecordTypeId, 'Lead');
			return lstLayoutSection;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static String doCreateNewLead(Lead leadObject) {
		if (leadObject.Account__c != null) {
			for (Account acc : [SELECT Id, Name FROM Account WHERE Id = :leadObject.Account__c]) {
				leadObject.Company = acc.Name;
			}
		} else {
			leadObject.Company = Label.Default_Lead_Company_and_Last_Name;
		}
		if (leadObject.Contact__c != null) {
			for (Contact con : [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :leadObject.Contact__c]) {
				leadObject.FirstName = con.FirstName;
				leadObject.LastName = con.LastName;
			}
		} else {
			leadObject.FirstName = Label.Default_Lead_Company_and_Last_Name;
			leadObject.LastName = Label.Default_Lead_Company_and_Last_Name;
		}
		insert leadObject;
		return leadObject.Id;
	}
}