// ===========================================================================
//  Object	: CreateLegacyCPQQuoteController_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for CreateLegacyCPQQuoteController.
// ===========================================================================
@istest
public class CreateLegacyCPQQuoteController_Test {
	@istest
	public static void unitTest() {
		//create Account Record
		Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Site SGN')
			.getRecordTypeId();
		Account a = new Account(name = 'test', recordtypeid = RecordTypeIdContact);
		a.Parent_Unique_Id__c = math.random() + '12345';
		a.Unique_Id__c = 'SAP_SHIPTO_2387324';
		a.Primary_Bill_To_Unique_Id__c = math.random() + '43215';
		a.ERP_Account_Id__c = '99876564';
		a.Child_Unique_Id__c = math.random() + '21232';
		insert a;
		//Assert Statement
		System.assertNotEquals(a.id, null);
		//Insert Contact Record
		Contact c = new Contact(
			FirstName = 'TestContact',
			LastName = 'Sample',
			AccountId = a.Id,
			Email = 'test@gmail.com'
		);
		insert c;
		//Assert Statement
		System.assertnotEquals(c.Id, null);
		//create Opportunity Record
		Opportunity oplist = new Opportunity();
		oplist.Name = 'test';
		oplist.AccountId = a.id;
		oplist.StageName = 'new';
		oplist.CurrencyIsoCode = 'USD';
		oplist.CloseDate = System.today();
		oplist.Demo_Onsite__c = false;
		oplist.Siebel_Row_Id__c = 'test';
		oplist.Primary_Contact__c = c.id;
		insert oplist;
		//Assert Statements
		System.assertNotEquals(oplist.id, null);
		System.assert(oplist.Primary_Contact__c == c.id);
		System.assertEquals(oplist.AccountId, a.id);
		apexpages.currentpage().getparameters().put('id', oplist.id);
		Apexpages.StandardController sc = new Apexpages.StandardController(oplist);
		CreateLegacyCPQQuoteController cpc = new CreateLegacyCPQQuoteController(sc);
		cpc.stdCntrlr = oplist;
		cpc.onLoad();
		cpc.back();
		apexpages.currentpage().getparameters().put('id', null);
		Apexpages.StandardController sc1 = new Apexpages.StandardController(new Opportunity());
		CreateLegacyCPQQuoteController cpc1 = new CreateLegacyCPQQuoteController(sc1);
		cpc1.stdCntrlr = null;
		cpc1.onLoad();
	}

	@istest
	public static void unitTest_1() {
		//create Account Record
		Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName()
			.get('Site SGN')
			.getRecordTypeId();
		Account a = new Account(name = 'test', recordtypeid = RecordTypeIdContact);
		a.Parent_Unique_Id__c = math.random() + '12345';
		a.Unique_Id__c = 'SAP_SHIPTO_2387324';
		a.Primary_Bill_To_Unique_Id__c = math.random() + '43215';
		a.ERP_Account_Id__c = '99876564';
		a.Child_Unique_Id__c = math.random() + '21232';
		insert a;
		//Insert Contact Record
		Contact c = new Contact(
			FirstName = 'TestContact',
			LastName = 'Sample',
			AccountId = a.Id,
			Email = 'test@gmail.com'
		);
		insert c;
		//Assert Statement
		System.assertnotEquals(c.Id, null);
		//Assert Statement
		System.assertNotEquals(a.id, null);
		apexpages.currentpage().getparameters().put('id', c.Id);
		Apexpages.StandardController sc = new Apexpages.StandardController(new Opportunity());
		CreateLegacyCPQQuoteController cpc = new CreateLegacyCPQQuoteController(sc);
		cpc.stdCntrlr = null;
		cpc.onLoad();
		cpc.back();
	}
}