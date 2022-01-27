// ===========================================================================
//  Object	:	PhoneFormatUtility_Test
// 	Company	:	Keste @IDC
//  Author	:	Basant Kumar Verma
// 	Purpose	:	Unit Test Class for PhoneFormatUtility
// ===========================================================================
@isTest
private class PhoneFormatUtility_Test {
	//PRIAVTE ATTRIBUTE TO STORE THE COUNTRY NAME USED IN TEST CLASS
	private static final String TEST_COUNTRY = 'TEST_COUNTRY';

	//TEST SETUP METHOD TO CREATE A NEW RECORD IN CUSTOM SETTING FOR TEST CLASS
	@testSetup
	public static void testSetupMethod() {
		Phone_Number_Format_Data_Standards__c st = new Phone_Number_Format_Data_Standards__c();
		st.Name = TEST_COUNTRY;
		st.Country_Code__c = 11;
		st.isActive__c = true;
		st.Phone_Format__c = '(000) 000-0000';
		insert st;
		//Assert Statement
		System.assertNotEquals(st.Id, null);
	}

	@isTest
	public static void testPhoneFormatting() {
		//LIST OF ALL VALID PHONE NUMBERS
		List<String> validPhones = new List<String>();
		validPhones.add('1234567890');
		validPhones.add('+111234567890');
		validPhones.add('+111234567890x11');
		validPhones.add(' + 1 1 1 2 3 4 5 6 7 8 9 0 x 1 1 ');
		validPhones.add(' + 1			 1 1 2 3 4		 5 6 7 8 9 0		 x		 1 1	 ');

		//LIST OF ALL IN-VALID PHONE NUMBERS
		List<String> inValidPhones = new List<String>();
		inValidPhones.add('234567890');
		inValidPhones.add('01234567890');
		inValidPhones.add('+11123456789');
		inValidPhones.add('+1112345678900');
		inValidPhones.add('+11234567890x11');
		inValidPhones.add('+211234567890x11');
		inValidPhones.add(' + 1 1 1 2 3 4 5 6 7 8 9 0 1 1 ');
		inValidPhones.add(' 1			 1 1 2 3 4		 5 6 7 8 9 0		 x		 1 1	 ');

		//TO COVER THE INVALID_INPUTS
		PhoneFormatUtility wr = new PhoneFormatUtility('Phone_Format__c', null, null);
		System.assertEquals(wr.isSuccess, false);

		//TO COVER THE COUNTRY_FORMAT_MISSING
		wr = new PhoneFormatUtility('Phone_Format__c', '11', TEST_COUNTRY + '11');
		System.assertEquals(wr.isSuccess, false);

		//TO CHECK ALL VALID PHONES
		for (String phoneStr : validPhones) {
			wr = new PhoneFormatUtility('Phone_Format__c', phoneStr, TEST_COUNTRY);
			System.assertEquals(wr.isSuccess, true);
		}

		//TO CHECK ALL IN-VALID PHONES
		for (String phoneStr : inValidPhones) {
			wr = new PhoneFormatUtility('Phone_Format__c', phoneStr, TEST_COUNTRY);
			System.assertEquals(wr.isSuccess, false);
		}
	}
}