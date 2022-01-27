// ===========================================================================
//  Object	: ViewLegacyCPQQuoteController
// 	Company	: Keste @IDC
//  Author	: Abinash Panigrahi
// 	Purpose	: Apex Controller Class to Redirect CPQ Site for Standard Quote record and Legacy record to redirect Salsforce Standard view.
//  This Class should be running in without sharing mode, CPQ is expecting Siebel_Quote_Number__c, Siebel_Quote_ID__c
// 	& Siebel_Quote_Type__c to be updated on opportunity
// ===========================================================================
public without sharing class ViewLegacyCPQQuoteController {
    public BigMachines__Quote__c stdCntrlr {get; set;}
    public Id quoteId {get; set;}

    //Standard Constructor
    public ViewLegacyCPQQuoteController(ApexPages.StandardController sc){
        quoteId = null;
        if(sc != null && sc.getId() != null){
        	quoteId = sc.getId();
        }
    }

    // Method Name: updateOpportunity
    // Author: Abinash panigrahi
    // Description: Initialisation Method to perform task onLoad of Page
    // Return: PageReference - Redirect to CPQ Edit Quote page
    public PageReference onLoad(){
        PageReference pg = null;

        if(String.isNotBlank(quoteId)){
            //Fetch Current Legacy quote record data
            BigMachines__Quote__c obj = null;
            for(BigMachines__Quote__c ob : [SELECT Id, Salesforce_Quote_Header__c, Name, RecordTypeId,Sub_Type__c ,BigMachines__Opportunity__c,BigMachines__Status__c, Sub_Status__c, Siebel_Quote_Number__c,CurrencyIsoCode, BigMachines_Quote_Type__c, Price_List__c, BigMachines__Account__c FROM BigMachines__Quote__c WHERE Id =:quoteId]){
                obj = ob;
            }

            //Null Check
            if(obj != null){
                //Current Loggedin User
                Id currentUser = UserInfo.getUserId();

                //Fetch Oracle User record exist or not for Current Loggedin User
                BigMachines__Oracle_User__c oracleUser = null;

                for(BigMachines__Oracle_User__c objNew : [SELECT Id,BigMachines__Allow_Quote_Creation__c,BigMachines__Provisioned__c FROM BigMachines__Oracle_User__c WHERE BigMachines__Salesforce_User__c =: currentUser LIMIT 1]){
                    oracleUser = objNew;
                }

                //If CPQ access doesnot exist
                if(oracleUser == null || (oracleUser != null && oracleUser.BigMachines__Allow_Quote_Creation__c == FALSE && oracleUser.BigMachines__Provisioned__c == FALSE)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.QUOTE_LICENSE_MESSAGE));
                }else{
                    //Check Quote RecordType
                    if(obj.RecordTypeId == Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Standard').getRecordTypeId()){
                        //Redirect to CPQ Edit Quote Page
                        pg = Page.BigMachines__QuoteEdit;
                    }else if(obj.RecordTypeId == Schema.SObjectType.BigMachines__Quote__c.getRecordTypeInfosByName().get('Existing').getRecordTypeId()){

                        //Fetch Related Opportunity
                        if(obj.BigMachines__Opportunity__c != null && obj.BigMachines__Status__c == 'Expired') {
                            Opportunity opp = [SELECT Id, Siebel_Quote_Number__c,Siebel_Quote_ID__c,Siebel_Quote_Type__c FROM Opportunity WHERE Id =: obj.BigMachines__Opportunity__c];
                            opp.Siebel_Quote_Number__c = obj.Name;
                            opp.Siebel_Quote_ID__c = obj.Id;
                            opp.Siebel_Quote_Type__c = obj.BigMachines_Quote_Type__c+'$*$'+obj.Sub_Type__c+'$*$'+obj.BigMachines__Status__c+'$*$'+obj.Sub_Status__c+'$*$'+obj.CurrencyIsoCode+'$*$'+obj.Price_List__c;

                            //Update Opportunity
                            //Exception Handling
                            try{
                                update opp;
                            }catch(Exception ex){
                                //Create Apex Log
                                ExceptionHandlerController.createException('ViewLegacyCPQQuoteController', 'onLoad', 'Apex Controller', 'Update Opportunity', ex.getMessage(), System.today());
                            }
                        }

                        //Redirect to CPQ New Quote Page
                        pg = Page.BigMachines__QuoteCreate;
                    }
                    //Pass required parameters
                    pg.getParameters().put('Id',obj.Id);
                    //Force Redirect
                    pg.setRedirect(true);
                }
            }else{
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.QUOTE_ERROR_MESSAGE));
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.QUOTE_ERROR_MESSAGE));
        }
        return pg;
    }

    // Method Name: back
    // Author: Abinash panigrahi
    // Description: Return to Opportunity record
    // Return: PageReference - Redirect to Parent Opportunity
    public PageReference back(){
        PageReference pg;
        if(String.isNotBlank(quoteId)){
            BigMachines__Quote__c obj = [SELECT Id,BigMachines__Opportunity__c FROM BigMachines__Quote__c WHERE Id =:quoteId LIMIT 1];
            if(obj.BigMachines__Opportunity__c != null){
                pg = new PageReference('/'+obj.BigMachines__Opportunity__c);
                return pg;
            }
        }
        return new PageReference('/lightning/page/home');
    }
}