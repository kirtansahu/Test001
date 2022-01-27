// ===========================================================================
//  Object	: EventTriggerHandler_Test
// 	Company	: Keste @IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Test class for EventTrigger And EventTriggerHandler
// ===========================================================================
@isTest
public class EventTriggerHandler_Test {
	@isTest
	public static void UpdateOpportunityTest() {
		EventTriggerHandler.OPPORTUNITY_PREFIX = '006';
		TestSetupDataUtil.insertUsers(1);
		List<user> uu = [SELECT id, Name FROM User];
		Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		Account a = new Account();
		a.Name = 'Test Account';
		a.RecordTypeId = RecordTypeId;
		a.CurrencyIsoCode = 'USD';
		a.Unique_Id__c = 'test';
		insert a;
		//Assert Statements
		System.assertNotEquals(a.id, null);
		Id pricebookId = Test.getStandardPricebookId();
		Product2 prod = new Product2(Name = 'Product X', ProductCode = 'Pro-X', isActive = true);
		insert prod;

		//Create your pricebook entry
		PricebookEntry pbEntry = new PricebookEntry(
			Pricebook2Id = pricebookId,
			Product2Id = prod.Id,
			UnitPrice = 100.00,
			IsActive = true
		);
		insert pbEntry;

		Pricebook2 customPB = new Pricebook2(Name = 'Custom Pricebook', isActive = true, Currency_Code__c = 'USD');
		insert customPB;

		PricebookEntry customPbEntry = new PricebookEntry(
			Pricebook2Id = customPB.Id,
			Product2Id = prod.Id,
			UnitPrice = 12000,
			IsActive = true
		);
		insert customPbEntry;

		//insert contact
		Contact c = new Contact(
			LastName = 'TestContact',
			FirstName = 'TestContactName',
			Accountid = a.Id,
			Email = 'abcd@gmail.com'
		);
		insert c;
		Opportunity opp = new Opportunity(
			Name = 'Test Opp',
			CloseDate = System.today(),
			currencyisocode = 'USD',
			StageName = 'New',
			Confidence__c = '100%',
			Accountid = a.id,
			Reason_Won_Lost__c = 'Won/Lost - Price',
			Primary_Contact__c = c.id
		);

		insert opp;
		//Assert Statements
		//System.assertEquals(cons.size(), 2);
		System.assert(opp.Primary_Contact__c == c.id);
		OpportunityLineItem qli = new OpportunityLineItem(
			Opportunityid = Opp.Id,
			pricebookentryid = customPbEntry.id,
			TotalPrice = 100,
			Quantity = 2
		);
		insert qli;
		//EventTriggerHandler.updateOpportunity(Events);
		//create Event
		Event e2 = new Event();
		e2.WhatId = opp.Id;
		e2.Type = 'Demo Request';
		e2.Subject = 'Test Subject';
		e2.DurationInMinutes = 1;
		e2.ActivityDateTime = system.Now();
		insert e2;
		e2.Subject = 'Test';
		update e2;
		delete e2;
		System.assertNotEquals(e2.id, null);
		//create Task
		Task e = new Task();
		e.WhatId = opp.Id;
		e.Type = 'call';
		e.Subject = 'Test Subject';
		insert e;
		Event e3 = new Event();
		e3.WhatId = opp.Id;
		e3.Type = 'Demo Request';
		e3.Subject = 'Test Subject';
		e3.DurationInMinutes = 1;
		e3.ActivityDateTime = system.Now();
		insert e3;
		delete e3;
		//create Task
		Task e1 = new Task();
		e1.WhatId = opp.Id;
		e1.Type = 'call';
		e1.Subject = 'Test Subject';
		insert e1;
		delete e1;

		Case oCase = new Case();
		oCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Tech Support').getRecordTypeId();
		oCase.ContactId = c.Id;
		oCase.AccountId = a.Id;
		oCase.Origin = 'Email';
		oCase.Status = 'Closed';
		oCase.Sub_Status__c = 'Resolved';
		insert oCase;

		Event e4 = new Event();
		e4.WhatId = oCase.Id;
		e4.Type = 'Demo Request';
		e4.Subject = 'Test Subject';
		e4.DurationInMinutes = 1;
		e4.ActivityDateTime = system.Now();
		insert e4;

		try {
			delete e4;
		} catch (Exception ex) {
		}

		EventTriggerHandler.uncheckRequestDemo(new List<Event>{ e2 });
		List<Opportunity> oplist = [
			SELECT
				Id,
				(SELECT id FROM tasks WHERE type = 'demo Request'),
				(SELECT Id FROM Events WHERE type = 'Demo Request')
			FROM Opportunity
		];
	}
}