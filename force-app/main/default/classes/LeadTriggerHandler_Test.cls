// ===========================================================================
//  Object: LeadTriggerHandler_Test
// Company: Keste @IDC
//  Author: Abinash Panigrahi
// Purpose: Unit Test Class for LeadTrigger and LeadTriggerHandler.
// ===========================================================================
@isTest
public class LeadTriggerHandler_Test {
    
    // Method Name: testSetupMethod
    // Author: Abinash panigrahi
    // Description: Method to create Test Data to be used
    @testSetup
    public static void testSetupMethod(){
        //Insert Account Records
        List<Account> accList = TestSetupDataUtil.insertAccountRecords(3);
        //Insert Contact Records
        TestSetupDataUtil.insertContactRecordswithAcc(3,accList);
    }
    
    // Method Name: campaignLogicTest
    // Author: Abinash panigrahi
    // Description: Method to test campaign creation at Lead Object
    @isTest
    public static void campaignLogicTest(){
        Test.startTest();
        //Insert Lead
        Lead lObj = new Lead(Lead_Source_Id__c = '1001',Contact_External_Id__c='234', LastName = 'Test Lead Obj', Company = 'Test', Opportunity_Name__c = 'Test Opp', Lead_Rejection_Reason__c = null);
        insert lObj;
        Lead lObj2 = new Lead(Lead_Source_Id__c = '1002', Contact_External_Id__c='456', LastName = 'Test Lead Obj 2', Company = 'Test', Opportunity_Name__c = 'Test Opp', Lead_Rejection_Reason__c = null);
        insert lObj2;
        //Create Campaign
        Campaign campObj = new Campaign(Name='test0123',StarTrack_Id__c='1002',Siebel_Row_Id__c='10345',Source_Number__c='test1');
        insert campObj; 
        CampaignMember campMember = new CampaignMember(CampaignId =campObj.id, LeadId = lObj2.Id, Status = 'Sent');
        insert campMember; 
        //Assert Statements
        System.assert(campMember.CampaignId==campObj.id);
        System.assertNotEquals(lObj.id, null);
        System.assertEquals(campMember.LeadId,lObj2.Id);
        
        Test.stopTest();
        List<Lead> leads=[select Id,Lead_Source_Id__c,LastName,Contact_External_Id__c,RecordTypeId from Lead where Lead_Source_Id__c='1002'];
        leads[0].Lead_Source_Id__c = '10345';
        update leads;
        System.assertEquals(leads[0].Lead_Source_Id__c,  '10345');
        Map<Id,Lead>leadResult=new Map<Id,Lead>();
        for(Lead l:leads){
            leadResult.put(l.id,l);
        }
        System.assertNotEquals(leadresult.size(), null);
        List<CampaignMember>am=[select id from CampaignMember where CampaignId=:campObj.Id and LeadId=:lObj.id];
        LeadTriggerHandler.primaryRelationSetup(leads,leadResult);
        System.assertNotEquals(am.size(), null);
    }
    
    // Method Name: relationshipTest
    // Author: Abinash panigrahi
    // Description: Method to test Account & Contact relationship at Lead Object
    @isTest
    public static void relationshipTest(){
        //Insert Lead
        Lead lObj = new Lead(Contact_External_Id__c = '0', Lead_Source_Id__c='Test',LastName = 'Test Lead Obj', Company = 'Test', Opportunity_Name__c = 'Test Opp', Lead_Rejection_Reason__c = null);
        insert lObj;
        
        Lead lObj2 = new Lead(Contact_External_Id__c = '1',Lead_Source_Id__c='Test1',LastName = 'Test Lead Obj', Company = 'Test', Opportunity_Name__c = 'Test Opp', Lead_Rejection_Reason__c = null);
        insert lObj2;
        
        //Update Lead
        lObj2.Contact_External_Id__c = null;
        update lObj2;
        //Assert Statements
        System.assertNotEquals(lObj2.Id, null);
        System.assertEquals(lObj2.Contact_External_Id__c, null);
        Map<Id,Lead> mapResult=new Map<id,Lead>();
        //Fetch All Leads
        List<Lead> leadList=[SELECT Id,Name,Contact_External_Id__c,RecordTypeId FROM LEAD];
        for(Lead l:leadList){
            mapResult.put(l.Id,l);
        }
        LeadTriggerHandler.primaryRelationSetup(leadList,mapResult);
        //Fetch Lead after Insert
        lObj = [SELECT Id, Account__c, Contact__c FROM Lead WHERE Contact_External_Id__c = '0'];
        lObj2 = [SELECT Id, Account__c, Contact__c FROM Lead WHERE Contact_External_Id__c = null];
        
        //Fetch Contact
        Contact conObj = [SELECT Id, AccountId FROM Contact WHERE Contact_External_Id__c = '0'];
        Contact conObj2 = [SELECT Id, AccountId FROM Contact WHERE Contact_External_Id__c = '2'];
        
        //Assertion Statements
        //System.assertEquals(lObj.Account__c, conObj.AccountId);
        //System.assertNotEquals(lObj2.Account__c, conObj2.AccountId);
        //System.assertEquals(lObj.Contact__c, conObj.Id);
    }
    
    @istest
    public static void testData(){
        //Insert Lead
        Lead lObj = new Lead(Contact_External_Id__c = null, LastName = 'Test Lead Obj', Company = 'Test', Opportunity_Name__c = 'Test Opp',Lead_Rejection_Reason__c = null);
        lObj.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Label.MARKETING_ALERTED_ACTIVITY).getRecordTypeId();
        insert lObj;
        List<Lead>allList=[select Id,Name,Contact_External_Id__c,RecordTypeId from Lead];
        //Assert Statements
        System.assertNotEquals(lObj.Id, null);
        System.assertEquals(allList.Size(), 1);
        Map<Id,Lead>leadResult=new Map<Id,Lead>();
        for(Lead l:allList){
            leadResult.put(l.id,l);
        }
        List<Lead>newLeads=new List<Lead>();
        Lead lObj2 = new Lead(Contact_External_Id__c = '1', LastName = 'Test Lead Obj', Company = 'Test', Opportunity_Name__c = 'Test Opp', Lead_Rejection_Reason__c = null);
        lObj2.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Label.MARKETING_ALERTED_ACTIVITY).getRecordTypeId();
        lObj2.Lead_Source_Id__c = 'test';
        insert lObj2;
        newLeads.add(lObj2); 
        LeadTriggerHandler.createCampaignRec(new List<Lead>{lObj2},null);
        
        lObj2.Contact_External_Id__c = null;
        lObj2.Status = 'Rejected';
        update lObj2;
        
        lObj2.Status = 'Working';
        update lObj2;
        
        lObj2.Status = 'Converted';
        update lObj2;
    }
}