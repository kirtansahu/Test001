@isTest
public class CustomLookupController_Test {
	@isTest
	public static void unitTest() {
		//Insert Account Records
		List<Account> accList = TestSetupDataUtil.insertAccountRecords(1);
		List<String> subLabelFields = new List<String>{ 'Industry', 'Phone' };
		//(String objectName, String filterField, List<String> subLabelFields, String searchString, String value, String criteria)
		Test.startTest();
		CustomLookupController.fetchRecords('Account', 'Name', subLabelFields, 'Test', accList[0].Id, '');
		//To Cover Exception scenarios
		try {
			CustomLookupController.fetchRecords('Account', 'Name', subLabelFields, 'Test', '', 'Test');
		} catch (Exception ex) {
		}
		Test.stopTest();
	}
}