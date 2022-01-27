@isTest(SeeAllData=true)
public class TestCoverage_CAS {
	static testMethod void ValidateCASContactExtract() {
		try {
			Test.startTest();
			DateTime dt = System.now();
			////create test data////
			//
			//
			//create user
			User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

			System.runAs(thisUser) {
				List<User> userList = new List<User>();

				String dtStr =
					dt.year() +
					'' +
					dt.month() +
					'' +
					dt.day() +
					'' +
					dt.hour() +
					'' +
					dt.minute() +
					'' +
					dt.second() +
					'' +
					dt.millisecond();
				Id profileId = [SELECT Id FROM Profile WHERE Name = 'Account Manager'].Id;
				UserRole r = new UserRole(Name = 'test Role11');
				insert r;
				User usr = new User(
					LastName = 'TestEMEAUser11',
					Email = 'test111@testemea.com',
					Username = 'Test_testemea' + dtStr + '@test.com',
					Alias = 'testemea',
					ProfileId = profileId,
					TimeZoneSidKey = 'America/Los_Angeles',
					EmailEncodingKey = 'UTF-8',
					LanguageLocaleKey = 'en_US',
					LocaleSidKey = 'en_US',
					userRoleId = r.Id,
					Organization__c = 'EMEA'
				);
				userList.add(usr);
				insert userList;
			}
			User SalesUser = [SELECT Id FROM User WHERE LastName = 'TestEMEAUser11'];
			System.runAs(SalesUser) {
				//create the data as a Sales Rep
				////////////////
				/*  List<Organization_Group_Division__c> orgList=new List<Organization_Group_Division__c>(); 
          Organization_Group_Division__c obj = new Organization_Group_Division__c();
            obj.Group_Division__c = 'LSG';
            obj.Name = 'European Organization';
          orgList.add(obj);
            insert orgList;*/

				Id pricebookId = Test.getStandardPricebookId();
				List<Pricebook2> pbList = new List<Pricebook2>();
				Pricebook2 oPricebook = new Pricebook2();
				oPricebook.Name = 'testpb';
				oPricebook.Currency_Code__c = 'USD';
				oPricebook.IsActive = true;
				pbList.add(oPricebook);
				insert pbList;

				//insert products
				List<Product2> prodList = new List<Product2>();
				//product 1
				Product2 prod1 = new Product2(
					Name = 'Product1 X1',
					ProductCode = 'PX_S1',
					Group_Division__c = '	LSG',
					Unique_Id__c = '123',
					isActive = true,
					Product_Line_Label__c = 'QUANTSTUDIO3',
					Platform__c = 'GENETIC SCIENCES',
					Sub_Platform__c = 'PLATFORM',
					Business_Unit_Label__c = 'CORE INSTRUMENT'
				);
				prodList.add(prod1);

				//product 2
				Product2 prod2 = new Product2(
					Name = 'Product2 X2',
					ProductCode = 'PX_S2',
					Group_Division__c = '	LSG',
					Unique_Id__c = '456',
					isActive = true,
					Product_Line_Label__c = 'QUANTSTUDIO3',
					Platform__c = 'GENETIC SCIENCES',
					Sub_Platform__c = 'PLATFORM',
					Business_Unit_Label__c = 'CORE INSTRUMENT'
				);
				prodList.add(prod2);
				//product 3
				Product2 prod3 = new Product2(
					Name = 'Product3 X3',
					ProductCode = 'PX_S3',
					Group_Division__c = '	LSG',
					Unique_Id__c = '789',
					isActive = true,
					Product_Line_Label__c = 'QUANTSTUDIO3',
					Platform__c = 'GENETIC SCIENCES',
					Sub_Platform__c = 'PLATFORM',
					Business_Unit_Label__c = 'CORE INSTRUMENT'
				);
				prodList.add(prod3);

				//product 4
				Product2 prod4 = new Product2(
					Name = 'Product4 X4',
					ProductCode = 'PX_S4',
					Group_Division__c = '	LSG',
					Unique_Id__c = '101112',
					isActive = true,
					Product_Line_Label__c = 'QUANTSTUDIO3',
					Platform__c = 'GENETIC SCIENCES',
					Sub_Platform__c = 'PLATFORM',
					Business_Unit_Label__c = 'CORE INSTRUMENT'
				);
				prodList.add(prod4);

				insert prodList; //insert the products together

				//Insert PricebookEntry records for the products just created

				List<PricebookEntry> pbEntryList = new List<PricebookEntry>();

				//Standard PricebookEntry for product 1
				PricebookEntry stdpbEntry1 = new PricebookEntry(
					Pricebook2Id = pricebookId,
					Product2Id = prodList[0].Id,
					UnitPrice = 100.00,
					IsActive = true
				);
				pbEntryList.add(stdpbEntry1);
				//Custom PricebookEntry for product 1
				PricebookEntry custompbEntry1 = new PricebookEntry(
					Pricebook2Id = pbList[0].Id,
					Product2Id = prodList[0].Id,
					UnitPrice = 100.00,
					IsActive = true
				);
				pbEntryList.add(custompbEntry1);

				//StandarPricebookEntry for product 2
				PricebookEntry stdpbEntry2 = new PricebookEntry(
					Pricebook2Id = pricebookId,
					Product2Id = prodList[1].Id,
					UnitPrice = 200.00,
					IsActive = true
				);
				pbEntryList.add(stdpbEntry2);

				//Custom PricebookEntry for product 2
				PricebookEntry custompbEntry2 = new PricebookEntry(
					Pricebook2Id = pbList[0].Id,
					Product2Id = prodList[1].Id,
					UnitPrice = 200.00,
					IsActive = true
				);
				pbEntryList.add(custompbEntry2);

				//Standard PricebookEntry for product 3
				PricebookEntry stdpbEntry3 = new PricebookEntry(
					Pricebook2Id = pricebookId,
					Product2Id = prodList[2].Id,
					UnitPrice = 300.00,
					IsActive = true
				);
				pbEntryList.add(stdpbEntry3);

				//Custom PricebookEntry for product 3
				PricebookEntry custompbEntry3 = new PricebookEntry(
					Pricebook2Id = pbList[0].Id,
					Product2Id = prodList[2].Id,
					UnitPrice = 400.00,
					IsActive = true
				);
				pbEntryList.add(custompbEntry3);

				insert pbEntryList; //insert all the price book entries together

				//Insert Account record
				Id RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
					.get('Site SGN')
					.getRecordTypeId();
				List<Account> accList = new List<Account>();

				Account a = new Account();
				a.Name = 'Test Account111';
				a.RecordTypeId = RecordTypeId;
				a.Unique_Id__c = '45678';
				accList.add(a);
				insert accList;

				//insert Contact Records
				List<Contact> conList = new List<Contact>();
				Contact c = new Contact();
				c.LastName = 'John';
				c.FirstName = 'DoeN';
				c.AccountId = accList[0].Id;
				c.Phone = '1234567890';
				c.Email = 'abcd111@gmail.com';
				c.Email_Opt_In__c = true;
				c.MailingStreet = '123 main,st';
				c.MailingCity = 'New York';
				//  c.MailingState='NY';
				c.MailingCountry = 'United States';
				c.MailingPostalCode = '12345';
				conList.add(c);
				insert conList;

				//insert Opportunity record
				List<Opportunity> optyList = new List<Opportunity>();
				Opportunity opty = new Opportunity(
					Name = 'testopty111',
					Accountid = accList[0].id,
					CloseDate = System.today(),
					Siebel_Row_Id__c = '123abc',
					Primary_Contact__c = conList[0].id,
					StageName = 'New',
					Confidence__c = '70%',
					Reason_Won_Lost__c = 'Won/Lost - Price'
				);
				optyList.add(opty);
				insert optyList;
				//insert contact oppty role
				//OpportunityContactRole opRole=new OpportunityContactRole(ContactId=c.Id,OpportunityId=oplist.Id,Role='Decision Maker',IsPrimary=true);
				//insert opRole;

				List<OpportunityLineItem> oliList = new List<OpportunityLineItem>(); //prepare list for insertion of Opty products

				//insert opportunityLineItem for 1st product
				OpportunityLineItem oli = new OpportunityLineItem(
					OpportunityId = optyList[0].Id,
					Quantity = 5,
					Product2Id = prodList[0].Id,
					PricebookEntryId = pbEntryList[1].Id,
					TotalPrice = 5 * pbEntryList[1].UnitPrice
				);
				oliList.add(oli);

				//insert Opty Line item record for 2nd product
				OpportunityLineItem oli2 = new OpportunityLineItem(
					OpportunityId = optyList[0].Id,
					Quantity = 2,
					Product2Id = prodList[1].Id,
					PricebookEntryId = pbEntryList[3].Id,
					TotalPrice = 2 * pbEntryList[3].UnitPrice
				);
				oliList.add(oli2);
				insert oliList;

				List<Opportunity> opListupdate = [
					SELECT Id, Name, StageName
					FROM Opportunity
					WHERE ID = :optyList[0].Id
				];
				for (Opportunity opUpdate : opListupdate) {
					opUpdate.StageName = 'Qualified';
					opUpdate.OwnerId = SalesUser.Id;
				}
				update opListupdate;

				optyList.clear(); //clear prev list contents

				//create another Opportunity but without product
				Opportunity opty2 = new Opportunity(
					Name = 'testopty22111 no product',
					Accountid = accList[0].id,
					CloseDate = System.today(),
					Siebel_Row_Id__c = '12344abc',
					Primary_Contact__c = conList[0].id,
					StageName = 'New',
					Confidence__c = '70%',
					Reason_Won_Lost__c = 'Won/Lost - Price'
				);
				optyList.add(opty2);
				insert optyList;

				//create Product Line
				List<Product_Line__c> plineList = new List<Product_Line__c>();
				Product_Line__c pl = new Product_Line__c(
					Product_Line__c = 'test',
					Unique_Id__c = '123',
					IGOR_Code_Description__c = 'sample',
					Plan_Code__c = '01',
					Product_Group__c = 'trec'
				);
				plineList.add(pl);
				insert plineList;
				//create opportunity product line record
				List<Opportunity_Product_Line__c> opllist = new List<Opportunity_Product_Line__c>();
				Opportunity_Product_Line__c opl = new Opportunity_Product_Line__c();
				opl.Opportunity__c = optyList[0].Id;
				opl.CurrencyIsoCode = 'USD';
				opl.Primary__c = true;
				opl.Product_Line__c = plineList[0].id;
				opllist.add(opl);
				insert opllist;

				opListupdate = [SELECT Id, Name, StageName FROM Opportunity WHERE ID = :optyList[0].Id];
				for (Opportunity opUpdate : opListupdate) {
					opUpdate.StageName = 'Qualified';
					opUpdate.OwnerId = SalesUser.Id;
				}
				update opListupdate;

				///insert test Case records
				//get the record type id for case
				Id RecordTypeIdCase = Schema.SObjectType.Case.getRecordTypeInfosByName()
					.get('Tech Support')
					.getRecordTypeId();
				//system.debug('value is '+RecordTypeIdContact);
				List<Case> caseList = new List<Case>();
				Case caserec = new Case(
					Origin = 'Email',
					Accountid = accList[0].id,
					Subject = '123abc',
					Status = 'Open',
					Sub_Status__c = 'Assigned',
					Email_Queue__c = 'TS:HID',
					Area__c = 'Human Identity',
					RecordTypeId = RecordTypeIdCase,
					ContactId = conList[0].id,
					Primary_Product__c = prodList[0].Id
				);
				caseList.add(caserec);
				insert caselist;

				/*  Datetime yesterday = Datetime.now().addDays(-1);
				 Test.setCreatedDate(caselist.Id, yesterday);*/

				List<Case> caseListupdate = [SELECT Id, ClosedDate FROM Case WHERE ID = :caselist[0].Id];
				for (Case caseUpdate : caseListupdate) {
					//caseUpdate.ClosedDate=System.today();
					caseUpdate.Status = 'Closed';
					caseUpdate.Sub_Status__c = 'Resolved';
				}
				update caseListupdate;

				//add a product to the case
				/*   List<Case_Related_Products__c> caseProdList=new List<Case_Related_Products__c>();
            Case_Related_Products__c cpInsert=new Case_Related_Products__c(Case__c=caselist[0].Id,Product__c=prodList[0].Id,Primary__c=true);
             caseProdList.add(cpInsert);
           insert caseProdList;*/
			}
			//runAs
			// system.debug('ID for Case is '+caselist[0].Id);
			//CASCase=Database.Query('Select Id,CaseNumber,Origin,CreatedDate,OwnerId,Owner.Name,AccountId,ContactId,ClosedDate,CreatedBy.Name,Subject from Case where ClosedDate =LAST_N_DAYS:' +lastDays+ ' AND Status= \'Closed\' AND Sub_Status__c=\'Resolved\' AND Area__c IN (\'Human Identity\',\'Rapid HIT\') AND RecordType.Name =\'Tech Support\' AND CaseNumber!=\'\'');

			//end of creation of test data//
			//   Integer MAX_QUERY = Limits.getLimitQueries();
			//	Integer NUM_QUERY = MAX_QUERY - 1;

			//  System.assertEquals(NUM_QUERY, Limits.getQueries());
			//
			//
			////////create the test CAS record for opty with percent
			string casPrimeId;
			List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();

			CAS_Prime__c cp_opty = new CAS_Prime__c();
			dt = System.now();
			cp_opty.Name = 'TEST_CAS_LSG_EMEA' + string.valueOf(dt);
			cp_opty.Survey_ID__c = 'SALE1';
			cp_opty.Division_name__c = 'LSG';
			cp_opty.B_U_Name__c = 'EMEA';
			cp_opty.Functional_Site__c = 'LSG - EMEA';
			cp_opty.Report_run__c = 'Daily';
			cp_opty.Include_Header__c = 'Yes';
			cp_opty.File_Format__c = 'CSV';
			cp_opty.Functional_Country__c = '';
			cp_opty.Language__c = 'English';

			cp_opty.Sample_Size__c = 100;
			cp_opty.Sample_Size_Type__c = 'Percent';
			cp_opty.Survey_Object_Type__c = 'Opportunity';
			casPrimeList.add(cp_opty);
			//  insert casPrimeList;
			////////////////////////////////////////////////////////////////////////////////////////////////
			//////////////////////////create the test CAS record for opty with record count/////////////////

			CAS_Prime__c cp_opty2 = new CAS_Prime__c();
			dt = System.now();
			cp_opty2.Name = 'TEST_CAS_LSG_EMEA2' + string.valueOf(dt);
			cp_opty2.Survey_ID__c = 'SALE1';
			cp_opty2.Division_name__c = 'LSG';
			cp_opty2.B_U_Name__c = 'EMEA';
			cp_opty2.Functional_Site__c = 'LSG - EMEA';
			cp_opty2.Report_run__c = 'Daily';
			cp_opty2.Include_Header__c = 'Yes';
			cp_opty2.File_Format__c = 'CSV';
			cp_opty2.Functional_Country__c = '';
			cp_opty2.Language__c = 'English';

			cp_opty2.Sample_Size__c = 20;
			cp_opty2.Sample_Record_Count__c = 20;
			cp_opty2.Sample_Size_Type__c = 'Record Count';
			cp_opty2.Survey_Object_Type__c = 'Opportunity';
			casPrimeList.add(cp_opty2);
			/////////////////////////////////////////////////////////////////////////////////
			CAS_Prime__c cp_case = new CAS_Prime__c();
			dt = System.now();
			cp_case.Name = 'TEST_CAS_LSG_EMEA_Case' + string.valueOf(dt);
			cp_case.Survey_ID__c = 'TSUP1';
			cp_case.Division_name__c = 'LSG';
			cp_case.B_U_Name__c = 'GSD';
			cp_case.Functional_Site__c = 'LSG - GSD';
			cp_case.Report_run__c = 'Daily';
			cp_case.Include_Header__c = 'Yes';
			cp_case.File_Format__c = 'CSV';
			cp_case.Functional_Country__c = '';
			cp_case.Language__c = 'English';

			cp_case.Sample_Size__c = 100;
			cp_case.Sample_Size_Type__c = 'Percent';
			cp_case.Survey_Object_Type__c = 'Case';
			casPrimeList.add(cp_case);

			insert casPrimeList;

			List<CAS_Prime__c> cpList = [
				SELECT ID, Name
				FROM CAS_Prime__c
				WHERE Active__c = TRUE AND Name LIKE 'TEST_CASE%'
			];
			List<string> cprime = new List<string>();
			CASContactExtract cas = new CASContactExtract();

			for (CAS_Prime__c cp : cpList) {
				casPrimeId = cp.ID;

				cprime.add(casPrimeId);
				cas.GenerateExtract(cprime);
				cprime.clear();
			}

			cpList.clear();
			casPrimeList.clear();

			cas = null;
			//test with sample type= record count

			//  System.assertEquals(NUM_QUERY, Limits.getQueries());
			Test.stopTest();
			//   System.assertEquals(NUM_QUERY, Limits.getQueries());
		} catch (Exception e) {
			//try
			system.debug(
				' ERROR LINE#:' +
				e.getLineNumber() +
				' ERROR CAUSE: ' +
				e.getCause() +
				' ERROR MESSAGE: ' +
				e.getMessage()
			);
		}
	}
	static testMethod void Validate_ScheduleCASDaily() {
		Test.startTest();
		string casPrimeId;
		List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();
		CAS_Prime__c cp = new CAS_Prime__c();
		DateTime dt = System.now();
		cp.Name = 'CASLSG_EMEA' + string.valueOf(dt);
		cp.Survey_ID__c = 'SALE1';
		cp.Division_name__c = 'LSG';
		cp.B_U_Name__c = 'EMEA';
		cp.Functional_Site__c = 'LSG - EMEA';
		cp.Report_run__c = 'Daily';
		cp.Include_Header__c = 'Yes';
		cp.File_Format__c = 'CSV';
		cp.Functional_Country__c = '';
		cp.Language__c = 'English';

		cp.Sample_Size__c = 100;
		cp.Sample_Size_Type__c = 'Percent';
		cp.Survey_Object_Type__c = 'Opportunity';
		casPrimeList.add(cp);
		insert casPrimeList;

		List<CAS_Prime__c> cpList = [SELECT ID, Name FROM CAS_Prime__c WHERE ID = :casPrimeList[0].Id];

		for (CAS_Prime__c c : cpList) {
			casPrimeId = c.ID;
		}

		String Frequency = 'Daily';
		String CASName = 'LSGCASTest1CodeCoverage';
		List<String> CAS_Params = new List<String>();

		CAS_Params.add(Frequency);
		CAS_Params.add(CASPrimeId);
		CAS_Params.add(CASName);

		Schedule_CAS.scheduleThis(CAS_Params);
		Test.stopTest();
	}

	static testMethod void Validate_TFCASTrigger() {
		Test.startTest();
		string casPrimeId;
		List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();
		CAS_Prime__c cp = new CAS_Prime__c();
		DateTime dt = System.now();
		cp.Name = 'CASLSG_EMEA' + string.valueOf(dt);
		cp.Survey_ID__c = 'SALE1';
		cp.Division_name__c = 'LSG';
		cp.B_U_Name__c = 'EMEA';
		cp.Functional_Site__c = 'LSG - EMEA';
		cp.Report_run__c = 'Daily';
		cp.Include_Header__c = 'Yes';
		cp.File_Format__c = 'CSV';
		cp.Functional_Country__c = '';
		cp.Language__c = 'English';

		cp.Sample_Size__c = 100;
		cp.Sample_Size_Type__c = 'Percent';
		cp.Survey_Object_Type__c = 'Opportunity';
		casPrimeList.add(cp);
		insert casPrimeList;

		Test.stopTest();
	}

	static testMethod void Validate_TFCASTriggerException() {
		Test.startTest();
		string casPrimeId;
		List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();
		CAS_Prime__c cp = new CAS_Prime__c();
		DateTime dt = System.now();
		cp.Name = 'CASLSG_EMEA' + string.valueOf(dt);
		cp.Survey_ID__c = 'SALE1';
		cp.Division_name__c = 'LSG';
		cp.B_U_Name__c = 'EMEA';
		cp.Functional_Site__c = 'LSG - EMEA';
		cp.Report_run__c = 'Daily1';
		cp.Include_Header__c = 'Yes';
		cp.File_Format__c = 'CSV';
		cp.Functional_Country__c = '';
		cp.Language__c = 'English';

		cp.Sample_Size__c = 100;
		cp.Sample_Size_Type__c = 'Percent';
		cp.Survey_Object_Type__c = 'Opportunity';
		casPrimeList.add(cp);
		insert casPrimeList;

		Test.stopTest();
	}

	static testMethod void Validate_ScheduleCASException() {
		Test.startTest();

		//String Frequency='Daily';

		String CASPrimeId = 'a2B8E000000Dzkt';
		String CASName = 'Test1Exception';

		List<String> CAS_Params = new List<String>();

		// CAS_Params.add(Frequency);
		CAS_Params.add(CASPrimeId);
		CAS_Params.add(CASName);

		Schedule_CAS.scheduleThis(CAS_Params);
		Test.stopTest();
	}
	static testMethod void Validate_TFCASActiveFlagUpdateTrigger() {
		Test.startTest();
		string casPrimeId;
		List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();
		CAS_Prime__c cp = new CAS_Prime__c();
		DateTime dt = System.now();
		cp.Name = 'CASLSG_EMEA' + string.valueOf(dt);
		cp.Survey_ID__c = 'SALE1';
		cp.Division_name__c = 'LSG';
		cp.B_U_Name__c = 'EMEA';
		cp.Functional_Site__c = 'LSG - EMEA';
		cp.Report_run__c = 'Daily';
		cp.Include_Header__c = 'Yes';
		cp.File_Format__c = 'CSV';
		cp.Functional_Country__c = '';
		cp.Language__c = 'English';

		cp.Sample_Size__c = 100;
		cp.Sample_Size_Type__c = 'Percent';
		cp.Survey_Object_Type__c = 'Opportunity';
		casPrimeList.add(cp);
		insert casPrimeList;

		List<CAS_Prime__c> casPrimeListUpdate = [SELECT ID, Active__c FROM CAS_Prime__c WHERE ID = :casPrimeList[0].Id];
		for (CAS_Prime__c cpupdate : casPrimeListUpdate) {
			cpupdate.Active__c = false;
		}
		update casPrimeListUpdate;
		Test.stopTest();
	}
	static testMethod void Validate_TFCASActiveFlagUpdateTriggerException() {
		Test.startTest();
		string casPrimeId;
		List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();
		CAS_Prime__c cp = new CAS_Prime__c();
		DateTime dt = System.now();
		cp.Name = 'CASLSG_EMEA1' + string.valueOf(dt);
		cp.Survey_ID__c = 'SALE1';
		cp.Division_name__c = 'LSG';
		cp.B_U_Name__c = 'EMEA';
		cp.Functional_Site__c = 'LSG - EMEA';
		cp.Report_run__c = 'Daily1';
		cp.Include_Header__c = 'Yes';
		cp.File_Format__c = 'CSV';
		cp.Functional_Country__c = '';
		cp.Language__c = 'English';

		cp.Sample_Size__c = 100;
		cp.Sample_Size_Type__c = 'Percent';
		cp.Survey_Object_Type__c = 'Opportunity';
		casPrimeList.add(cp);
		insert casPrimeList;

		List<CAS_Prime__c> casPrimeListUpdate = [SELECT ID, Active__c FROM CAS_Prime__c WHERE ID = :casPrimeList[0].Id];
		for (CAS_Prime__c cpupdate : casPrimeListUpdate) {
			cpupdate.Active__c = false;
		}
		update casPrimeListUpdate;
		Test.stopTest();
	}

	static testMethod void Validate_TFCASInActiveFlagUpdateTrigger() {
		Test.startTest();
		string casPrimeId;
		List<CAS_Prime__c> casPrimeList = new List<CAS_Prime__c>();
		CAS_Prime__c cp = new CAS_Prime__c();
		DateTime dt = System.now();
		cp.Name = 'CASLSG_EMEA' + string.valueOf(dt);
		cp.Survey_ID__c = 'SALE1';
		cp.Division_name__c = 'LSG';
		cp.B_U_Name__c = 'EMEA';
		cp.Functional_Site__c = 'LSG - EMEA';
		cp.Report_run__c = 'Daily';
		cp.Include_Header__c = 'Yes';
		cp.File_Format__c = 'CSV';
		cp.Functional_Country__c = '';
		cp.Language__c = 'English';

		cp.Sample_Size__c = 100;
		cp.Sample_Size_Type__c = 'Percent';
		cp.Survey_Object_Type__c = 'Opportunity';
		casPrimeList.add(cp);
		insert casPrimeList;

		List<CAS_Prime__c> casPrimeListUpdate = [SELECT ID, Active__c FROM CAS_Prime__c WHERE ID = :casPrimeList[0].Id];
		for (CAS_Prime__c cpupdate : casPrimeListUpdate) {
			cpupdate.Active__c = false;
		}
		update casPrimeListUpdate;

		for (CAS_Prime__c cpupdate : casPrimeListUpdate) {
			cpupdate.Active__c = true;
		}

		update casPrimeListUpdate;

		Test.stopTest();
	}
}