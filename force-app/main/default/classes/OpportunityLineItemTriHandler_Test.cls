// ===========================================================================
//  Object: OpportunityLineItemTriHandler_Test
// Company: Keste @IDC
//  Author: Rambabu Gadde
// Purpose: Test class for validating the methods from OpportunityLineItemTriggerHandler.
// ===========================================================================
@istest
public class OpportunityLineItemTriHandler_Test {
	@istest
	public static void unitTest() {
		User u = [
			SELECT Id, Name, Profile.Name, Organization__c, Profile.Id
			FROM User
			WHERE Id = :userinfo.getUserId()
		];
		UserRole r = new UserRole(Name = 'my Role');
		insert r;
		Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Account Manager'];
		System.runAs(u) {
			/* User u1 = new User(LastName = 'Testsample3', Email = 'test'+'sampler'+'@test.com', Username = 'Test_testsample'+'@test.com', Alias = 'test1'
                               ,ProfileId=p.Id,
                               UserRoleId=r.id,Organization__c='Asian Organization',TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');
            insert u1;*/
			Test.startTest();
			//Crete Custom Setting records
			Organization_Group_Division__c obj = new Organization_Group_Division__c();
			obj.Group_Division__c = 'LSG';
			obj.Name = 'Asian Organization';
			insert obj;
			Id pricebookId = Test.getStandardPricebookId();

			Pricebook2 oPricebook = new Pricebook2();
			oPricebook.Name = 'test';
			oPricebook.Currency_Code__c = 'USD';
			oPricebook.IsActive = true;
			insert oPricebook;

			Product2 prod = new Product2(
				Name = 'Product X',
				ProductCode = 'PX_S',
				Group_Division__c = '	LSG',
				Unique_Id__c = '123',
				isActive = true
			);
			insert prod;
            
             Product2 prod2 = new Product2(
                Name = 'Product Y',
                ProductCode = 'PY_S',
                Group_Division__c='	LSG1',
                Unique_Id__c='132',
                isActive = true);
            insert prod2;

			//Insert PricebookEntry record
			PricebookEntry pbEntry = new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = prod.Id,
				UnitPrice = 100.00,
				IsActive = true
			);
			insert pbEntry;
			PricebookEntry pbEntry1 = new PricebookEntry(
				Pricebook2Id = oPricebook.Id,
				Product2Id = prod.Id,
				UnitPrice = 100.00,
				IsActive = true
			);
			insert pbEntry1;
            
             PricebookEntry pbEntry2 = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prod2.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pbEntry2;
            PricebookEntry pbEntry3 = new PricebookEntry(
                Pricebook2Id = oPricebook.Id,
                Product2Id = prod2.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pbEntry3;
            

			//Insert Account record
			Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
			Account a = new Account();
			a.Name = 'Test Account';
			a.RecordTypeId = RecordTypeId;
			a.Unique_Id__c = '4567';
			insert a;
			//insert Contact Records
			Contact c = new Contact();
			c.LastName = 'TestContact';
			c.FirstName = 'TestContactName';
			c.AccountId = a.Id;
			c.Email = 'abcd@gmail.com';
			insert c;
			//insert product record
			Opportunity oplist = new Opportunity(
				Name = 'test',
				Accountid = a.id,
				CloseDate = System.today(),
				Siebel_Row_Id__c = '123',
				Primary_Contact__c = c.id,
				StageName = 'New',
				Confidence__c = '70%',
				Reason_Won_Lost__c = 'Won/Lost - Price'
			);
			insert oplist;
			//insert opportunityLineItem
			OpportunityLineItem oli = new OpportunityLineItem(
				OpportunityId = oplist.Id,
				Quantity = 5,
				Product2Id = prod.Id,
				PricebookEntryId = pbEntry1.Id,
				TotalPrice = 5 * pbEntry.UnitPrice
			);
			insert oli;
             OpportunityLineItem oli2 = new OpportunityLineItem(
                OpportunityId = oplist.Id,
                Quantity = 2,
                Product2Id=prod2.Id,
                PricebookEntryId = pbEntry3.Id,
                TotalPrice = 2 * pbEntry.UnitPrice   
            );
            insert oli2;
			//Assert Statements
			System.assert(oli.OpportunityId == oplist.Id);
			System.assert(oli.Product2Id == prod.Id);
			System.assertNotEquals(oplist.Id, null);
			System.assertNotEquals(c.id, null);
			List<OpportunityLineItem> opItems = [
				SELECT Id, Name, OpportunityId, Product2Id, Quantity
				FROM OpportunityLineItem
			];
			opItems[0].Quantity = 4;
			update opItems;
			Map<Id, OpportunityLineItem> mapResult = new Map<Id, OpportunityLineItem>();
			for (OpportunityLineItem op : opItems) {
				mapResult.put(op.id, op);
			}
			delete opItems;
			//OpportunityLineItemTriggerHandler.syncDeletedOpportunityLineItemWithSiebel(new List<OpportunityLineItem>{oli});
			//OpportunityLineItemTriggerHandler.syncOpportunityLineItemWithSiebel(opItems,mapResult);
			OpportunityLineItemTriggerHandler.productUserDivisionCheck(new List<OpportunityLineItem>{ oli });
			OpportunityLineItemTriggerHandler.getUserGroups('Asian Organization');
			OpportunityLineItemTriggerHandler.getGroupDivision('Asian Organization');
			OpportunityLineItemTriggerHandler.checkValidUser(p.Name);
			Test.stopTest();
		}

	}
}