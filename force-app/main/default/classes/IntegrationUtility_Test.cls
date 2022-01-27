// ===========================================================================
//  Class Name  :   IntegrationUtility_Test
//  Company     :   Keste @IDC
//  Author      :   Rambabu Gadde
//  Purpose     :   test Class for IntegrationResponse,IntegrationRequestUtilty_V2,IntegrationRequestUtilty,IntegrationUtility
// =============================================================================================================================
@isTest
public class IntegrationUtility_Test {
	public static testMethod void IntegrationRequestUtilityTest() {
		List<Account> accRecs = testSetupDataUtil.insertAccountRecords(10);
		Account acc = [SELECT Id FROM Account LIMIT 1][0];
		Account a = new Account();
		a.Name = 'Test Name';
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
		a.Account_Status__c = 'Active';
		a.ERP_Account_Id__c = 'test';
		a.Unique_Id__c = '123';
		insert a;
		List<Contact> cons = testSetupDataUtil.insertContactRecordswithAcc(3, accRecs);
		//Assert Statements
		System.assertEquals(cons.size(), 3);
		Contact objCon = [
			SELECT
				Id,
				LastName,
				MobilePhone,
				List_of_Target_Systems__c,
				Login_Name__c,
				X7UP_Account_Country__c,
				CreatedDate,
				VNTI_FLAG__c,
				SEND_SURVEY_FLG__c,
				CreatedById,
				Discipline__c,
				LastModifiedDate,
				SEND_FIN_FLG__c,
				SEND_PROMOTES_FLG__c,
				Customer_Brand__c,
				ENTERPRISE_FLAG__c,
				PRIV_FLG__c,
				SEND_NEWS_FLG__c,
				AB_Suppress_Special_Offers__c,
				LastModifiedById,
				OwnerId,
				Salutation,
				Suffix,
				Primary_Ship_To__c,
				Language_Preference__c,
				Primary_Account_Country_Code__c
			FROM Contact
			LIMIT 1
		][0];
		objCon.FirstName = 'testfirstname';
		objCon.AccountId = acc.Id;
		objCon.Suppress_Special_Offers__c = true;
		objCon.Suppress_Technical_Advice__c = true;
		objCon.Suppress_New_Products__c = true;
		objCon.English_Name__c = 'test';
		objCon.DuplicateContactOf__c = 'testduplicate';
		objCon.Member_Flag__c = true;
		objCon.AB_Suppress_Technical_Advice__c = true;
		objCon.SAP_Contact_Number__c = '19088';
		objCon.Suppress_Gifts__c = true;
		objCon.Web_Enabled_Flag__c = true;
		objCon.Profiling_Status__c = 'L prime - Pre-Contact';
		objCon.Academic_Title__c = 'Dr.';
		objCon.Phone_Opt_In__c = true;
		objCon.DoNotCall = true;
		objCon.Gender__c = 'F';
		objCon.OtherPhone = '18966';
		objCon.Active_Status_Flag__c = 'Active';
		objCon.Building__c = 'testbuilding';
		objCon.Department__c = 'testdept';
		objCon.EOne_Flag__c = true;
		objCon.EOne_Id__c = 'testeoneid';
		objCon.PI_First_Name__c = 'testpiname';
		objCon.PI_Last_Name__c = 'testpilastname';
		objCon.AB_Suppress_New_Products__c = true;
		objCon.AB_Suppress_Gifts__c = true;
		objCon.Alias__c = 'testAlias';
		objCon.Lab_Name__c = 'testlab';
		objCon.Room__c = 'testroom';
		objCon.SC_User__c = true;
		objCon.Web_Status__c = 'Registered';
		objCon.Alternate_Email_Address__c = 'test@mail.com';
		objCon.Phone = '12908789034';
		objCon.Email_Opt_In__c = true;
		objCon.Comment__c = 'testcomment';
		objCon.Type__c = 'Lead Source';
		objCon.Email = 'testcon@mail.com';
		objCon.Fax = '12908789034';
		objCon.HomePhone = '12908789034';
		objCon.Title = '12467';
		objCon.Nickname__c = 'testnickname';
		objCon.FacilityType__c = 'Agrigenomics';
		objCon.OrganizationType__c = 'Dealer';
		objCon.Registration_Type__c = 'Automatic';
		objCon.TF_B2B_Flag__c = false;
		objCon.MiddleName__c = 'Test';
		objCon.Contact_External_Id__c = 'TestCon1' + Math.random();
		objCon.Income__c = 123.00;
		objCon.MailingStreet = 'address';
		objCon.MailingCity = 'City';
		objCon.MailingCountryCode = null;
		objCon.MailingCounty__c = 'Address';
		objCon.MailingStateCode = null;
		objCon.MailingPostalCode = '';
		objCon.MailingIncomplete__c = true;
		objCon.MailingBuilding__c = 'Test1';
		objCon.MailingDepartment__c = 'Mailing';
		objCon.MailingDistrict__c = 'Dst';
		objCon.MailingInstitute__c = 'Ins';
		objCon.MailingMailStop__c = 'stop';
		objcon.MailingPOBox__c = '';
		objcon.MailingRoom__c = '';
		update objCon;
		Opportunity op = new Opportunity();
		op.AccountId = a.Id;
		op.Name = 'sampledata1';
		op.AccountId = a.Id;
		op.CloseDate = System.today();
		op.StageName = 'New';
		op.Confidence__c = '25%';
		op.Siebel_Row_Id__c = '89009';
		op.Primary_Contact__c = cons[0].id;
		insert op;
		//Assert Statements
		System.assert(op.AccountId == a.Id);
		System.assertNotEquals(op.Id, null);
		Profile__c objProfile = new Profile__c();
		objProfile.Tier_Description__c = 'test';
		objProfile.Tier_Level__c = 'T1';
		insert objProfile;
		System.assertNotEquals(objProfile.id, null);
		Contact_Profile__c objCP = new Contact_Profile__c();
		objCP.Contact__c = objCon.Id;
		objCP.Profile__c = objProfile.Id;
		objCP.Contact_Profile_External_Id__c = 'TestCP1' + Math.random();
		insert objCP;
		test.startTest();
		String strJSONReq1 = IntegrationRequestUtilty.getDeleteACRelationJSONRequest('', '');
		system.assertNotEquals(objCon, null);
		test.stopTest();
		IntegrationResponse intr = new IntegrationResponse();
		intr.IsLargeResponse = true;
		intr.recordId = '';
		intr.ex = null;
		intr.Errors = new List<Object>();
		intr.IsSuccess = false;
		intr.requestHeader = 'test';
		ExceptionHandlerController.createException('rest', null, null, null, null, null);
		List<Opportunity> opList1 = [
			SELECT
				Id,
				Name,
				Siebel_Row_Id__c,
				Status__c,
				Primary_Revenue_Committed_Flag__c,
				CurrencyIsoCode,
				AccountId,
				Direct_Indirect__c,
				DM_Forecast__c,
				End_Customer_Account__c,
				End_Customer_Contact__c,
				Opportunity_Source__c,
				Rejection_Reason__c,
				Consignment_Flag__c,
				Lost_Order_Detail__c,
				Description,
				Reason_Won_Lost__c,
				Rev_Rec_At_Risk__c,
				Demo_Onsite__c,
				FOB__c,
				StageName,
				Confidence__c,
				Primary_Contact__c,
				OwnerId,
				CloseDate
			FROM Opportunity
		];
		opList1[0].Primary_Contact__c = objCon.id;
		opList1[0].Siebel_Row_Id__c = 'test';
		update opList1[0];
		//Crete Custom Setting records
		Organization_Group_Division__c obj = new Organization_Group_Division__c();
		obj.Group_Division__c = 'LSG';
		obj.Name = 'Asian Organization';
		insert obj;
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
		//Create User
		User u = new User(
			LastName = 'Testsample',
			Email = 'test' + 'sample' + '@test.com',
			Username = 'Test_test' + System.now().getTime() + '@test.com',
			Alias = 'test',
			ProfileId = profileId,
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		insert u;

		u.Organization__c = 'Asian Organization';
		u.User_External_Id__c = 'test';
		update u;
		//Assert Statements
		System.assertEquals(u.User_External_Id__c, 'test');
		System.assertEquals(u.Organization__c, 'Asian Organization');
		System.runAs(u) {
			//create a Product
			Product2 prod = new Product2(
				Name = 'Product X',
				ProductCode = 'PX_S',
				Group_Division__c = ' LSG',
				isActive = true,
				Unique_Id__c = 'test'
			);
			insert prod;
			//Create your pricebook entry
			PricebookEntry pbEntry = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
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

			//Create OpportunityTeamMember
			OpportunityLineItem oli = new OpportunityLineItem(
				OpportunityId = opList1[0].Id,
				Quantity = 5,
				Product2Id = prod.Id,
				PricebookEntryId = customPbEntry.Id,
				TotalPrice = 5 * customPbEntry.UnitPrice
			);
			insert oli;
			//Create the OpportunityTeam Member
			OpportunityTeamMember otm = new OpportunityTeamMember();
			otm.OpportunityId = opList1[0].id;
			otm.UserId = userInfo.getUserId();
			otm.TeamMemberRole = 'Opportunitymanager';
			insert otm;
			List<opportunityTeamMember> teams = new List<OpportunityTeamMember>();
			teams.add(otm);
			//Ftech all Opportunity Records
			List<Opportunity> op1 = [SELECT Id, name FROM Opportunity];
			set<Id> keys = new Set<id>();
			for (Opportunity o : op1) {
				keys.add(o.id);
			}

			List<OpportunityLineItem> opLineItem = new List<OpportunityLineItem>();
			opLineItem.add(oli);
			//create Product Line
			Product_Line__c pl = new Product_Line__c(
				Product_Line__c = 'test12',
				Unique_Id__c = 'test',
				IGOR_Code_Description__c = 'sample1',
				Plan_Code__c = '011',
				Product_Group__c = ''
			);
			insert pl;
			//create Opportunity Product Line
			list<Opportunity_Product_Line__c> opportunityPL = new List<Opportunity_Product_Line__c>();
			Opportunity_Product_Line__c QPL = new Opportunity_Product_Line__c(
				Opportunity__c = opList1[0].Id,
				Primary__c = true,
				Product_Line__c = pl.Id
			);
			insert QPL;
			opportunityPL.add(QPL);
			//Assert Statements
			System.assertEquals(opportunityPL.Size(), 1);
			System.assertEquals(teams.size(), 1);
			System.assertNotEquals(pl.id, null);
			IntegrationRequestUtilty.getContactJSONRequest('INSERT', cons, false);
			IntegrationRequestUtilty.getContactJSONRequest('DELETE', cons, false);
			IntegrationRequestUtilty.getContactJSONRequest(new List<Contact>{ objCon }, false, false);
			IntegrationRequestUtilty.getDeleteCProfileJSONRequest('1234', 'sample', '12345', '');
			IntegrationRequestUtilty.getDeleteOpportunityTeamMembersJSONRequest('123', '12345', '4567');
			IntegrationRequestUtilty.getProductLineJSON(opportunityPL);
		}

	}
}