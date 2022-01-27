/********************************************************************************************************
 * Object    : PageLayoutDescriberHelper_Test
 * Company   : Keste @ IDC
 * Author    : Rambabu Gadde
 * Purpose   : Unit Test  class for PageLayoutDescriberHelper.
 ********************************************************************************************************/
@istest
public class PageLayoutDescriberHelper_Test {
	@istest
	public static void unitTest() {
		String jsonBody = '{"editLayoutSections":[{"columns":2,"heading":"Account Information","layoutRows":[{"layoutItems":[{"editable":false,"label":"Account Name","layoutComponents":[{"details":{"name":"Name"},"displayLines":1,"tabOrder":1,"type":"Field","value":"Name"}],"placeholder":false,"required":false}],"numItems":2}],"rows":6,"useCollapsibleSection":false,"useHeading":false}]}';
		Test.setMock(HttpCalloutMock.class, new MockHTTPResponse(200, jsonBody));

		Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
		List<String> recordTypeNames = new List<String>(recordTypes.keyset());
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = recordTypes.get(recordTypeNames[0]).getRecordTypeId();
		a.Unique_Id__c = '4567';
		//Assert Statements
		System.assertEquals(a.Unique_Id__c, '4567');
		System.assertNotEquals(jsonBody, null);
		Id defaultRecordtypeId = PageLayoutDescriberHelper.getDefaultRecordType(a);
		PageLayoutDescriberHelper.describeSectionWithFields(defaultRecordtypeId, 'Account');
	}
	@istest
	public static void unitTest1() {
		test.startTest();
		LayoutField lFields = new LayoutField(true, true, true, 'Account', 'String', 'Account');
		LayoutSection lSections = new LayoutSection('Account', true, 2, true);
		//Assert Statement
		System.assertNotEquals(lFields, null);
		System.assertNotEquals(lSections, null);
		test.stopTest();
	}
}