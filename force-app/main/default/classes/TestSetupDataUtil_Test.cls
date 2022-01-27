@isTest
public class TestSetupDataUtil_Test {
	@isTest
	public static void unitTest() {
		Test.startTest();
		List<Account> lstAccount = TestSetupDataUtil.insertAccountRecords(1);
		TestSetupDataUtil.insertContactRecordswithAcc(1, lstAccount);
		TestSetupDataUtil.insertAccountTeamRecords(lstAccount);
		TestSetupDataUtil.insertPriceBookRecords(1);
		TestSetupDataUtil.insertProfileRecords(1);
		TestSetupDataUtil.insertAccountHierarchy();
		TestSetupDataUtil.insertTerritoryRules();
		TestSetupDataUtil.insertTerritoryHierarchy();
		try {
			TestSetupDataUtil.insertContactRecordswithAccount(1, lstAccount);
		} catch (Exception ex) {
		}
		try {
			TestSetupDataUtil.insertContactRecords(1);
		} catch (Exception ex) {
		}
		Test.stopTest();
	}

	@isTest
	public static void unitTestV2() {
		try {
			TestSetupDataUtil.insertUsers(1);
		} catch (Exception ex) {
		}
	}

	@isTest
	public static void unitTestV3() {
		try {
			TestSetupDataUtil.insertUserWithProfileName('System Administrator');
		} catch (Exception ex) {
		}
	}
}