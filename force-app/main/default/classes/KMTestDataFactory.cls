// ===========================================================================
//  Object  : KMTestDataFactory
//  Author  : Ajinkya Hingne
//  Purpose : To create test data.
// ===========================================================================
@isTest
public with sharing class KMTestDataFactory {
	public static List<Account> insertAccountHierarchy() {
		Account gsgn = new Account(
			Name = 'Global SGN Test Account',
			RecordTypeId = getRecordTypeId(Label.ACCOUNT_RECORD_GLOBAL_SGN),
			Unique_Id__c = '1001'
		);
		insert gsgn;

		Account nsgn = new Account(
			Name = 'National SGN Test',
			ParentId = gsgn.Id,
			RecordTypeId = getRecordTypeId(Label.ACCOUNT_RECORD_NATIONAL_SGN),
			Parent_Unique_Id__c = '1001',
			Unique_Id__c = '1002'
		);
		insert nsgn;

		Account sgn = new Account(
			Name = 'Site SGN Test',
			ParentId = nsgn.Id,
			RecordTypeId = getRecordTypeId(Label.ACCOUNT_RECORD_SITE_SGN),
			Parent_Unique_Id__c = '1002',
			Unique_Id__c = '1003'
		);
		insert sgn;

		Account shipto = new Account(
			Name = 'Ship To Test',
			ParentId = sgn.Id,
			RecordTypeId = getRecordTypeId(Label.ACCOUNT_RECORD_SHIPTO),
			Child_Unique_Id__c = '1005',
			Primary_Bill_To_Unique_Id__c = '1006',
			Parent_Unique_Id__c = '1003',
			Unique_Id__c = '1004',
			Price_Book__c = insertPriceBookRecords(1)[0].Id
		);
		insert shipto;

		//Add BillTo Account RecordType
		Account billto = new Account(
			Name = 'Bill To Test',
			RecordTypeId = getRecordTypeId(Label.ACCOUNT_RECORD_BILLTO),
			Unique_Id__c = '1005'
		);
		insert billto;

		Account billto1 = new Account(
			Name = 'Bill To Test',
			RecordTypeId = getRecordTypeId(Label.ACCOUNT_RECORD_BILLTO),
			Unique_Id__c = '1006'
		);
		insert billto1;

		List<Account> accList = new List<Account>();
		accList.add(gsgn);
		accList.add(nsgn);
		accList.add(sgn);
		accList.add(shipto);
		accList.add(billto);

		return accList;
	}

	public static List<Account> createAndInsertShipToAccounts(Integer count) {
		List<Account> accounts = new List<Account>();
		Account shipTo;

		Id priceBookRecordId = insertPriceBookRecords(1)[0].Id;

		for (Integer i = 0; i < count; i++) {
			shipTo = new Account();
			shipTo.Name = 'Test' + i;
			shipTo.ERP_Account_Id__c = 'TestingERP' + i;
			shipTo.Account_Alpha_Name__c = 'TestAlpha' + i;
			shipTo.Address_1__c = 'Test Address 1';
			shipTo.Address_2__c = 'Test Address 2';
			shipTo.Unique_Id__c = 'Test Unique' + i;
			shipTo.recordtypeid = getRecordTypeId(Label.ACCOUNT_RECORD_SHIPTO);
			shipTo.Price_Book__c = priceBookRecordId;
			accounts.add(shipTo);
		}

		insert accounts;
		return accounts;
	}

	public static void createOFMOAuthSettings() {
		KM_OFM_OAuth_Settings__c ofmApiSettings = new KM_OFM_OAuth_Settings__c();
		ofmApiSettings.OAuth_Access_Token_URL__c = 'https://tmo-sysint-api-auth.auth.us-east-1.amazoncognito.com/oauth2/token';
		ofmApiSettings.Client_ID__c = 'a81774kvfvprha6imlactcuap';
		ofmApiSettings.Client_Secret__c = '1g9ieoibv55pv7l92g7kdkdigr3m4es4dv6thbt7h07nv7eok9fl';
		ofmApiSettings.TimeOut__c = Integer.valueOf('60000');
		insert ofmApiSettings;
	}

	public static void createOFMOAuthConfig(String tokenType) {
		KM_OFM_OAuth_Config__c oAuthConfig = new KM_OFM_OAuth_Config__c();

		if (tokenType == 'Bearer') {
			oAuthConfig.Access_Token__c =
				'eyJraWQiOiJ3Z2xmVklWeHN5dE91R20rck56NWhvN1NWT2tUWlBxTH' +
				'VsVDNTZDkreUg4PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJhODE3NzRrdmZ2cHJoYTZpbWxhY3RjdW' +
				'FwIiwidG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvbnByb21wdC1hcGlcL2NyZWF0ZSBvbnByb2' +
				'1wdC1hcGlcL2RlbGV0ZSBvbnByb21wdC1hcGlcL3JlYWQiLCJhdXRoX3RpbWUiOjE1OTQxMzM2ODgsIm' +
				'lzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC' +
				'0xX0o5cnNFQnRtUSIsImV4cCI6MTU5NDEzNzI4OCwiaWF0IjoxNTk0MTMzNjg4LCJ2ZXJzaW9uIjoyLC' +
				'JqdGkiOiI3ZDQ1NDhhYS1iYTU3LTRkOTYtYmE1ZC1jNmMxZTk2OWUwZTMiLCJjbGllbnRfaWQiOiJhOD' +
				'E3NzRrdmZ2cHJoYTZpbWxhY3RjdWFwIn0.U-alMVC3Mnk5jQ6HoedSZoBf2MStVb1u9zthGIlUSAz7ar' +
				'dGiVguucSrEbyrwwCOGTWUdcROwQFlP4Q_kwD2BifDS4GPdBm4T1NuwP-tpZWqOYBjp2_qm9fG3umkBM' +
				'ZSP53dRvwgv6HQyuwuo_5oR-Yk2eLIHOuoahbcv5QNi6ged4QfD30QKrAjRRDLcCcdC9gh3ovYz_jDjS' +
				'KE685l4EzWTQUmVHydW59Qo3sDB3bZb8JvGGiBA6iQmEIiXqQQvQlnSl5tdgnyE9uggY0JlkO94CHXcg' +
				'NfI32wEorzXW_loYhrRSERG1ilwpespOPVyqnYGafOK8_7iNzXScicrA';
			oAuthConfig.Token_Type__c = 'Bearer';
		} else if (tokenType == 'OAuth API') {
			oAuthConfig.Access_Token__c =
				'eyJraWQiOiJ3Z2xmVklWeHN5dE91R20rck56NWhvN1NWT2tUWlBxTHVs' +
				'VDNTZDkreUg4PSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJhODE3NzRrdmZ2cHJoYTZpbWxhY3RjdWFwIiwi' +
				'dG9rZW5fdXNlIjoiYWNjZXNzIiwic2NvcGUiOiJvbnByb21wdC1hcGlcL2NyZWF0ZSBvbnByb21wdC1hcGlc' +
				'L2RlbGV0ZSBvbnByb21wdC1hcGlcL3JlYWQiLCJhdXRoX3RpbWUiOjE1OTYwOTcxNTUsImlzcyI6Imh0dHBz' +
				'OlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX0o5cnNFQnRtUSIs' +
				'ImV4cCI6MTU5NjEwMDc1NSwiaWF0IjoxNTk2MDk3MTU1LCJ2ZXJzaW9uIjoyLCJqdGkiOiJkYzAyZTRhMi1i' +
				'MDgzLTQwNGYtODBkOC00MDA1OGZiOTJhNzciLCJjbGllbnRfaWQiOiJhODE3NzRrdmZ2cHJoYTZpbWxhY3Rj' +
				'dWFwIn0.HXsppcn7yyeazl3UonJsJkD7GxKGlzDNovQkiA6ADlAdJH8qrcjGgti7NIKO-Ijk5wrnlYg0Wf6C' +
				'bL5i-QMco2BoPvj5UnhrvaWQKP9mC7AJUigHEe7fXX1OBkX0aLsafkRnLVxRWgPdcWh7zyCeHH8rOxh0lDR5' +
				'eryH8XjI4CoGU8IBkEkte6F0GRIYuu4KTkDu4AftqlR1EUPxjw954SbXub_3zay8B2h1_KFLVx8BkEvQtI1J' +
				'JuVP1OEedkWRey_pDGjZjiAN-h5h3SVjLGw3PkwmYO2aHSUNU16kC8vaepqInfd-tS1JuOr0dkvfT4Zn_Qb2' +
				'pLrkKxO5kY2oKg';
			oAuthConfig.Token_Type__c = 'OAuth API';
		}
		oAuthConfig.Expiry_Start_Datetime__c = System.now();
		oAuthConfig.Expiry_End_Datetime__c = System.now().addSeconds(Integer.valueOf(3600));

		insert oAuthConfig;
	}

	private static List<PriceBook2> insertPriceBookRecords(Integer count) {
		List<PriceBook2> pbList = new List<PriceBook2>();
		for (Integer i = 0; i < count; i++) {
			PriceBook2 priceBook = new PriceBook2(
				Name = Label.KM_ShipTo_PriceList,
				isActive = true,
				Currency_Code__c = 'USD'
			);
			pbList.add(priceBook);
		}
		insert pbList;
		return pbList;
	}

	private static Id getRecordTypeId(String recordTypeName) {
		return Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
	}
}