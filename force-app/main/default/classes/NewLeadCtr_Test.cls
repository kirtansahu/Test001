// ===========================================================================
//  Class Name 	: NewLeadCtr_Test
// 	Company  	: Keste @IDC
// 	Author      : Basant Kumar Verma
// 	Purpose		: This apex class is worked as test class for NewLeadCtr
// ===========================================================================
@isTest
public class NewLeadCtr_Test {
	@istest
	public static void myUnitTest() {
		String jsonBody = '{"editLayoutSections":[{"columns":2,"heading":"Lead Information","layoutRows":[{"layoutItems":[{"editable":false,"label":"First Name","layoutComponents":[{"details":{"name":"FirstName"},"displayLines":1,"tabOrder":1,"type":"Field","value":"FistName"}],"placeholder":false,"required":false}],"numItems":2}],"rows":6,"useCollapsibleSection":false,"useHeading":false}]}';
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(200, jsonBody));

		Account acc = new Account(
			Name = 'Test Account',
			Account_Status__c = 'ACTIVE',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId()
		);
		acc.Unique_Id__c = 'testing1234';
		insert acc;
		Contact con = new Contact(
			lastname = 'test',
			firstname = 'testName',
			AccountId = acc.Id,
			Email = 'abcd@GMAIL.COM'
		);
		insert con;

		Lead lOb = NewLeadCtr.getLeadObject(con.Id);
		System.assertEquals(lOb.Account__c, acc.Id);
		System.assertEquals(lOb.Contact__c, con.Id);
		System.assertEquals(lOb.FirstName, con.FirstName);
		System.assertEquals(lOb.LastName, con.LastName);
		System.assertEquals(lOb.Company, acc.Name);

		Id describeRecordTypeId = PageLayoutDescriberHelper.getDefaultRecordType(lOb);
		System.assert(describeRecordTypeId != null);
		System.assertEquals(describeRecordTypeId, lOb.RecordTypeId);

		try {
			List<LayoutSection> lstLayoutSection = NewLeadCtr.fetchPageLayoutFieldsAndSection(lOb);
			System.assert(false, 'Uncommited Work Pending Exception Expected');
		} catch (Exception e) {
			System.assert(true, 'Uncommited Work Pending Exception Expected');
		}

		lOb.Lead_Rejection_Reason__c = null;
		lOb.Opportunity_Name__c = 'Test';
		NewLeadCtr.doCreateNewLead(lOb);
	}

	@istest
	public static void myUnitTest2() {
		String jsonBody = '{"editLayoutSections":[{"columns":2,"heading":"Lead Information","layoutRows":[{"layoutItems":[{"editable":false,"label":"First Name","layoutComponents":[{"details":{"name":"FirstName"},"displayLines":1,"tabOrder":1,"type":"Field","value":"FistName"}],"placeholder":false,"required":false}],"numItems":2}],"rows":6,"useCollapsibleSection":false,"useHeading":false}]}';
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(200, jsonBody));

		Lead lOb = NewLeadCtr.getLeadObject(null);
		System.assertEquals(lOb.Account__c, null);
		System.assertEquals(lOb.Contact__c, null);
		System.assertEquals(lOb.LastName, Label.Default_Lead_Company_and_Last_Name);
		System.assertEquals(lOb.Company, Label.Default_Lead_Company_and_Last_Name);

		List<LayoutSection> lstLayoutSection = NewLeadCtr.fetchPageLayoutFieldsAndSection(lOb);
		System.assert(lstLayoutSection != null);

		lOb.Lead_Rejection_Reason__c = null;
		lOb.Opportunity_Name__c = 'Test';
		NewLeadCtr.doCreateNewLead(lOb);
	}
}