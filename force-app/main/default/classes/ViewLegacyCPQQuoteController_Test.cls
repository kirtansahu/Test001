// ===========================================================================
//  Object	: ViewLegacyCPQQuoteController_Test
// 	Company	: Keste @ IDC
//  Author	: Rambabu Gadde
// 	Purpose	: Unit Test Class for ViewLegacyCPQQuoteController.
// ===========================================================================
@istest
public class ViewLegacyCPQQuoteController_Test {
    @istest
    public static void unitTest(){//create Account Record
        Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
        Account a=new Account(name='test',recordtypeid=RecordTypeIdContact);
        a.Parent_Unique_Id__c=math.random()+'12345';
        a.Unique_Id__c='SAP_SHIPTO_2387324';
        a.Primary_Bill_To_Unique_Id__c=math.random()+'43215';
        a.ERP_Account_Id__c='99876564';
        a.Child_Unique_Id__c=math.random()+'21232';
        insert a;
        //Assert Statement
        System.assertNotEquals(a.Id, null);
        List<Account> accList=TestSetupDataUtil.insertAccountRecords(10);
        //Insert Contact Record
        List<Contact> conList=   TestSetupDataUtil.insertContactRecordswithAcc(3,accList);
        //create Opportunity Record
        Opportunity oplist=new Opportunity();
        oplist.Name='test';
        oplist.AccountId=a.id;
        oplist.StageName='new';
        oplist.CurrencyIsoCode='USD';
        oplist.CloseDate=System.today();
        oplist.Demo_Onsite__c=False;
        oplist.Siebel_Row_Id__c='test';
        oplist.Pending_SLA_Due_Date__c = System.today();
        oplist.Primary_Contact__c=conList[0].id;
        oplist.Quote_Revenue__c = 100;
        insert oplist;
        //Assert Statements
        System.assert(oplist.AccountId==a.Id);
        System.assertNotEquals(oplist.Id, null);
        System.assertEquals(conList.size(), 3);
        System.assertEquals(oplist.Primary_Contact__c,conList[0].id);
        //create Oracle CPQ Cloud Site record
        BigMachines__Configuration_Record__c bcr=new BigMachines__Configuration_Record__c();
        bcr.BigMachines__bm_site__c='01';
        bcr.BigMachines__Connected_App_Name__c='Oracle_CPQ_Cloud';
        bcr.BigMachines__process_id__c='011';
        bcr.BigMachines__action_id_copy__c='022';
        bcr.BigMachines__action_id_open__c='033';
        bcr.BigMachines__document_id__c='004';
        bcr.BigMachines__version_id__c='005';
        bcr.BigMachines__process__c='sample';
        bcr.BigMachines__Primary_Commerce_Process__c=true;
        bcr.BigMachines__Is_Active__c=true;
        insert bcr;
        //Create Oracle User
        BigMachines__Oracle_User__c ou = new BigMachines__Oracle_User__c();
        ou.BigMachines__Allow_Quote_Creation__c = TRUE;
        ou.BigMachines__Provisioned__c = TRUE;
        ou.BigMachines__Salesforce_User__c = UserInfo.getUserId();
        ou.BigMachines__User_Groups__c = 'SalesAgent';
        ou.BigMachines__Oracle_CPQ_Cloud_Site__c = bcr.Id;
        insert ou;
        //Assert Statement
        System.assertNotEquals(bcr.Id, null);
        System.assertEquals(bcr.BigMachines__Is_Active__c, true);
        Id RecordTypeIdQuote = Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        Id RecordTypeIdQuote2 = Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Existing').getRecordTypeId();
        //create Quote/Sample/iReserve record
        BigMachines__Quote__c bmq=new BigMachines__Quote__c();
        bmq.BigMachines__Opportunity__c=opList.id;
        bmq.recordtypeid=RecordTypeIdQuote;
        bmq.Siebel_Quote_Number__c='sample';
        bmq.BigMachines_Quote_Type__c='p';
        bmq.BigMachines__Site__c=bcr.id;
        bmq.Quote_Revenue__c = 100;
        bmq.BigMachines__Status__c = 'Expired';
        insert bmq;
        //Assert Statement
        System.assertNotEquals(bmq.id, null);
        System.assert(bmq.BigMachines__Site__c==bcr.Id);
        apexpages.currentpage().getparameters().put('id' , bmq.id);
        Apexpages.StandardController sc = new Apexpages.StandardController(bmq);
        ViewLegacyCPQQuoteController cpc=new ViewLegacyCPQQuoteController(sc);
        CloneLegacyCPQQuoteController cc = new CloneLegacyCPQQuoteController(sc);
        cc.stdCntrlr = bmq;
        cc.onLoad();
        cpc.stdCntrlr=bmq;
        cpc.onLoad();
        Apexpages.StandardController sc2 = new Apexpages.StandardController(oplist);
        CreateLegacyCPQQuoteController cpc2=new CreateLegacyCPQQuoteController(sc2);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Opportunity>{oplist});
        NewLegacyCPQQuoteController newController=new NewLegacyCPQQuoteController(stdSetController);
        cpc2.stdCntrlr=oplist;
        cpc2.onLoad();
        cpc2.back();
        newController.oppId=oplist.id;
        newController.onLoad();
        newController.back();
        Apexpages.currentpage().getparameters().put('retURL' , bmq.id);
        Apexpages.StandardController SCX = new Apexpages.StandardController(bmq);
        SyncSiebelQuoteController SSQController = new SyncSiebelQuoteController(SCX);
        SSQController.stdCntrlr=bmq;
        SSQController.onLoad();

        bmq.recordtypeid=RecordTypeIdQuote2;
        update bmq;
        sc = new Apexpages.StandardController(bmq);
        cpc=new ViewLegacyCPQQuoteController(sc);
        cpc.stdCntrlr=bmq;
        cpc.onLoad();

        ou.BigMachines__Allow_Quote_Creation__c = FALSE;
        ou.BigMachines__Provisioned__c = FALSE;
        update ou;
        cpc.onLoad();
        cpc.back();
        cpc2.onLoad();
        cpc2.back();
        newController.onLoad();
        newController.back();
    }

    @istest
    public static void unitTest_1(){
        Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
        Account a=new Account(name='test',recordtypeid=RecordTypeIdContact);
        a.Parent_Unique_Id__c=math.random()+'12345';
        a.Unique_Id__c='SAP_SHIPTO_2387324';
        a.Primary_Bill_To_Unique_Id__c=math.random()+'43215';
        a.ERP_Account_Id__c='99876564';
        a.Child_Unique_Id__c=math.random()+'21232';
        insert a;
        List<Account> accList=TestSetupDataUtil.insertAccountRecords(10);
        //Insert Contact Record
        List<Contact> conList=   TestSetupDataUtil.insertContactRecordswithAcc(3,accList);
        //Assert Statements
        System.assertEquals(conList.Size(), 3);
        System.assertNotEquals(a.id, null);
        //create Opportunity Record
        Opportunity oplist=new Opportunity();
        oplist.Name='test';
        oplist.AccountId=a.id;
        oplist.StageName='new';
        oplist.Pending_SLA_Due_Date__c = System.today();
        oplist.CurrencyIsoCode='USD';
        oplist.CloseDate=System.today();
        oplist.Demo_Onsite__c=False;
        oplist.Siebel_Row_Id__c='test';
        oplist.Primary_Contact__c=conList[0].id;
        oplist.Quote_Revenue__c = 100;
        insert oplist;
        //create Oracle CPQ Cloud Site record
        BigMachines__Configuration_Record__c bcr=new BigMachines__Configuration_Record__c();
        bcr.BigMachines__bm_site__c='01';
        bcr.BigMachines__Connected_App_Name__c='Oracle_CPQ_Cloud';
        bcr.BigMachines__process_id__c='011';
        bcr.BigMachines__action_id_copy__c='022';
        bcr.BigMachines__action_id_open__c='033';
        bcr.BigMachines__document_id__c='004';
        bcr.BigMachines__version_id__c='005';
        bcr.BigMachines__process__c='sample';
        bcr.BigMachines__Primary_Commerce_Process__c=true;
        bcr.BigMachines__Is_Active__c=true;
        insert bcr;
        System.assertNotEquals(bcr.Id, null);
        Id RecordTypeIdQuote = Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Existing').getRecordTypeId();
        //create Quote/Sample/iReserve record
        BigMachines__Quote__c bmq=new BigMachines__Quote__c();
        bmq.BigMachines__Opportunity__c=opList.id;
        bmq.recordtypeid=RecordTypeIdQuote;
        bmq.Siebel_Quote_Number__c='sample';
        bmq.BigMachines_Quote_Type__c='p';
        bmq.BigMachines__Site__c=bcr.id;
        bmq.Quote_Revenue__c = 100;
        bmq.BigMachines__Status__c = 'Expired';
        insert bmq;
        //Assert Statements
        System.assertEquals(bmq.BigMachines__Opportunity__c, opList.id);
        System.assertNotEquals(bmq.Id, null);
        apexpages.currentpage().getparameters().put('id' , bmq.id);
        Apexpages.StandardController sc = new Apexpages.StandardController(bmq);
        ViewLegacyCPQQuoteController cpc=new ViewLegacyCPQQuoteController(sc);
        cpc.stdCntrlr=bmq;
        cpc.onLoad();
        apexpages.currentpage().getparameters().put('id' , null);
        Apexpages.StandardController sc1 = new Apexpages.StandardController(new BigMachines__Quote__c());
        ViewLegacyCPQQuoteController cpc1=new ViewLegacyCPQQuoteController(sc1);
        cpc1.stdCntrlr=bmq;
        cpc1.onLoad();
    }

    @istest
    public static void unitTest_111(){
        Id RecordTypeIdContact = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Site SGN').getRecordTypeId();
        Account a=new Account(name='test',recordtypeid=RecordTypeIdContact);
        a.Parent_Unique_Id__c=math.random()+'12345';
        a.Unique_Id__c='SAP_SHIPTO_2387324';
        a.Primary_Bill_To_Unique_Id__c=math.random()+'43215';
        a.ERP_Account_Id__c='99876564';
        a.Child_Unique_Id__c=math.random()+'21232';
        insert a;
        List<Account> accList=TestSetupDataUtil.insertAccountRecords(10);
        //Insert Contact Record
        List<Contact> conList=   TestSetupDataUtil.insertContactRecordswithAcc(3,accList);
        //Assert Statements
        System.assertEquals(conList.Size(), 3);
        System.assertNotEquals(a.id, null);

        //create Oracle CPQ Cloud Site record
        BigMachines__Configuration_Record__c bcr=new BigMachines__Configuration_Record__c();
        bcr.BigMachines__bm_site__c='01';
        bcr.BigMachines__Connected_App_Name__c='Oracle_CPQ_Cloud';
        bcr.BigMachines__process_id__c='011';
        bcr.BigMachines__action_id_copy__c='022';
        bcr.BigMachines__action_id_open__c='033';
        bcr.BigMachines__document_id__c='004';
        bcr.BigMachines__version_id__c='005';
        bcr.BigMachines__process__c='sample';
        bcr.BigMachines__Primary_Commerce_Process__c=true;
        bcr.BigMachines__Is_Active__c=true;
        insert bcr;
        System.assertNotEquals(bcr.Id, null);
        Id RecordTypeIdQuote = Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Existing').getRecordTypeId();
        //create Quote/Sample/iReserve record
        BigMachines__Quote__c bmq=new BigMachines__Quote__c();
        bmq.BigMachines__Account__c=a.id;
        bmq.recordtypeid=RecordTypeIdQuote;
        bmq.Siebel_Quote_Number__c='sample';
        bmq.BigMachines_Quote_Type__c='p';
        bmq.BigMachines__Site__c=bcr.id;
        bmq.Quote_Revenue__c = 100;
        bmq.BigMachines__Status__c = 'Expired';
        bmq.BigMachines_Quote_Type__c = 'E';
        insert bmq;
        //Assert Statements
        System.assertNotEquals(bmq.Id, null);
        apexpages.currentpage().getparameters().put('id' , bmq.id);
        Apexpages.StandardController sc = new Apexpages.StandardController(bmq);
        ViewLegacyCPQQuoteController cpc=new ViewLegacyCPQQuoteController(sc);
        cpc.stdCntrlr=bmq;
        cpc.onLoad();
    }

    @istest
    public static void unitTest_2(){
        //create Oracle CPQ Cloud Site record
        BigMachines__Configuration_Record__c bcr=new BigMachines__Configuration_Record__c();
        bcr.BigMachines__bm_site__c='01';
        bcr.BigMachines__Connected_App_Name__c='Oracle_CPQ_Cloud';
        bcr.BigMachines__process_id__c='011';
        bcr.BigMachines__action_id_copy__c='022';
        bcr.BigMachines__action_id_open__c='033';
        bcr.BigMachines__document_id__c='004';
        bcr.BigMachines__version_id__c='005';
        bcr.BigMachines__process__c='sample';
        bcr.BigMachines__Primary_Commerce_Process__c=true;
        bcr.BigMachines__Is_Active__c=true;
        insert bcr;
        //Assert Statements
        System.assertNotEquals(bcr.Id, null);
        System.assertEquals(bcr.BigMachines__Is_Active__c, true);

        apexpages.currentpage().getparameters().put('id' , bcr.Id);
        Apexpages.StandardController sc1 = new Apexpages.StandardController(new BigMachines__Quote__c());
        ViewLegacyCPQQuoteController cpc1=new ViewLegacyCPQQuoteController(sc1);
        cpc1.onLoad();
    }

    @istest
    public static void errorConditions(){//create Account Record
        CloneLegacyCPQQuoteController cc = new CloneLegacyCPQQuoteController(null);
        PageReference pg = cc.onLoad();
        system.assertEquals(pg, null);
        system.assert(ApexPages.getMessages().size() > 0);
        system.assertEquals(ApexPages.getMessages().get(0).getSummary(), Label.QUOTE_ERROR_MESSAGE);

        cc.quoteId = UserInfo.getUserId();
        cc.onLoad();
        system.assertEquals(pg, null);
        system.assert(ApexPages.getMessages().size() > 0);
        system.assertEquals(ApexPages.getMessages().get(0).getSummary(), Label.QUOTE_ERROR_MESSAGE);

        BigMachines__Configuration_Record__c bcr=new BigMachines__Configuration_Record__c();
        bcr.BigMachines__bm_site__c='01';
        bcr.BigMachines__Connected_App_Name__c='Oracle_CPQ_Cloud';
        bcr.BigMachines__process_id__c='011';
        bcr.BigMachines__action_id_copy__c='022';
        bcr.BigMachines__action_id_open__c='033';
        bcr.BigMachines__document_id__c='004';
        bcr.BigMachines__version_id__c='005';
        bcr.BigMachines__process__c='sample';
        bcr.BigMachines__Primary_Commerce_Process__c=true;
        bcr.BigMachines__Is_Active__c=true;
        insert bcr;
        //Assert Statement
        System.assertNotEquals(bcr.Id, null);
        System.assertEquals(bcr.BigMachines__Is_Active__c, true);

        Id RecordTypeIdQuote = Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        //create Quote/Sample/iReserve record
        BigMachines__Quote__c bmq=new BigMachines__Quote__c();
        bmq.recordtypeid=RecordTypeIdQuote;
        bmq.Siebel_Quote_Number__c='sample';
        bmq.BigMachines_Quote_Type__c='p';
        bmq.BigMachines__Status__c = 'Expired';
        bmq.BigMachines__Site__c=bcr.id;
        insert bmq;

        cc.quoteId = bmq.Id;
        cc.onLoad();
        system.assertEquals(pg, null);
        system.assert(ApexPages.getMessages().size() > 0);
        system.assertEquals(ApexPages.getMessages().get(0).getSummary(), Label.QUOTE_ERROR_MESSAGE);
    }
}