@isTest
private class gl_CustomContactLookupController_Test {
	static testMethod void search_Test() {
		gl_CustomContactLookupController lookup = new gl_CustomContactLookupController();
		Contact con1 = new Contact(FirstName = 'Andy', LastName = 'Young', Phone = '4444', MobilePhone = '3333');
		insert con1;
		Contact con2 = new Contact(FirstName = 'Pat', LastName = 'Doer', Phone = '1111');
		insert con2;
		Contact con3 = new Contact(FirstName = 'Patty', LastName = 'Ty', Phone = '2222');
		insert con3;
		Contact con4 = new Contact(FirstName = 'Jane', LastName = 'Doer', Email = 'test@gmail.com');
		insert con4;
		lookup.searchString = '[{"AccountId":"00141000009i2ysAAA","Id":"0034100000CVAQMAA5","Name":"Andy Young","FirstName":"Andy","LastName":"Young","MailingStreet":"1301 Hoch Drive","Email":"a_young@dickenson.com","Phone":"4444","MobilePhone":"3333","Account":{"Name":"Dickenson plc","BillingPostalCode":"66045","Id":"00141000009i2ysAAA"}}]';

		PageReference pr = lookup.search();

		System.debug('*** results = ' + lookup.contact_results);
		System.assert(lookup.contact_results.size() != 0);
		lookup.firstName = 'Pat';
		lookup.lastName = 'Ty';
		lookup.email = 'test@gmail.com';
		pr = lookup.search();
		System.debug('*** results = ' + lookup.contact_results);
		System.assert(lookup.contact_results.size() != 0);

		List<Contact> existingContacts = lookup.contact_results;
		Contact con5 = new Contact(FirstName = 'John', LastName = 'Ty', Email = 'test123@gmail.com');
		insert con5;
		lookup.firstName = 'John';
		lookup.lastName = 'Ty';
		lookup.email = 'test123@gmail.com';
		pr = lookup.search();
		//lookup.addUniqueSobjects(existingContacts,lookup.contact_results);
		System.assert(existingContacts.size() != 0);
		lookup.getFormTag();
		lookup.getTextBox();
	}
}