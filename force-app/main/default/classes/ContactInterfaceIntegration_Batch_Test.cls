// ===========================================================================
//	Object	: ContactInterfaceIntegration_Batch_Test
//	Company	: Keste @IDC
//	Author	: Jayaram Bevara
//	Purpose	: Test Class to get coverage for ContactInterfaceIntegration_Batch
// ===========================================================================
@isTest
public class ContactInterfaceIntegration_Batch_Test {
	@isTest
	public static void testMethodforBatch() {
		//Create Account
		List<Account> accRecList = TestSetupDataUtil.insertAccountRecords(2);
		//Create Contact
		Contact conObj = new Contact(
			LastName = 'Test',
			FirstName = 'Test',
			AccountId = accRecList[1].Id,
			Email = 'abced@gmail.com'
		);
		insert conObj;
		Test.startTest();
		system.schedule(
			'ContactInterfaceIntegration_Schedulde',
			'0 0 23 * * ?',
			new ContactInterfaceIntegration_Schedulde()
		);
		Test.stopTest();
		ContactProfileHandler obj = new ContactProfileHandler();
	}
}