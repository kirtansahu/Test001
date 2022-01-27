// ===========================================================================
//  Object	: CommonUtilities_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for CommonUtilities.
// ===========================================================================
@istest
public class CommonUtilities_Test {
	@istest
	public static void unitTest() {
		CommonUtilities c = new CommonUtilities();
		CommonUtilities.debug('Test');
		Boolean b = CommonUtilities.isIntegrationOrMigrationUser();
		System.assertEquals(b, false);
		boolean b1 = CommonUtilities.isIntegrationUser();
		System.assertEquals(b1, false);
		boolean b2 = CommonUtilities.isMigrationUser();
		System.assertEquals(b2, false);
		CommonUtilities.isGoodToExecuteBatch('Apex Class');
		CommonUtilities.isAllRecordsFailedInRecentExecution('update pricebookEntry');
		List<AsyncApexJob> jobInfo = [SELECT Status, NumberOfErrors FROM AsyncApexJob];
		//Assert Statement
		System.assertNotEquals(jobInfo.size(), null);
		CommonUtilities.prepareQuery('Account', new Set<String>{ 'Name', 'Rating' }, true);
		CommonUtilities.prepareQuery('Account', new Set<String>{ 'Name', 'Rating' }, false);
		CommonUtilities.debug(new Contact());
		CommonUtilities.isSystemAdminUser();
		CommonUtilities.countMatches('test', 'test');
		CommonUtilities.stringReplaceAll('test@#');
		CommonUtilities.isCPQIntegrationUser();
	}
}