// ===========================================================================
//  Object  : LeadTriggerHandler
//  Company : Keste @IDC
//  Author  : Abinash Panigrahi
//  Purpose : Handler Class contains all logic for LeadTrigger.
// ===========================================================================
public class LeadTriggerHandler {

    //Fetch Marketing Alerted Activity RecordType Id
    private final static String MARKETING_ACTIVITY_ID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Label.MARKETING_ALERTED_ACTIVITY).getRecordTypeId();

    //Fetch Sales Created Lead RecordType Id
    private final static String SALES_CREATED_ID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get(Label.SALES_CREATED_LEAD).getRecordTypeId();

    //Lead Status Value
    private final static String LEAD_STATUS_NEW = 'New';
    private final static String LEAD_STATUS_REJECTED = 'Rejected';
    private final static String LEAD_STATUS_CONVERTED = 'Converted';
    private final static String LEAD_STATUS_WORKING = 'Working';

    private final static String USER_RECORDID_PREFIX = '005';

    // Method Name: primaryRelationSetup
    // Author: Abinash panigrahi
    // Description: Method to assosiate Account and Contact lookup relationship based on Contact External Id 
    // Parameter 1: newRec - List of the new versions of the Lead records
    // Parameter 2: oldMap - Map of IDs to the old versions of the Lead records
    // Return: Null
    public static void primaryRelationSetup(List<Lead> newRec, Map<Id,Lead> oldMap){

        //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('LeadTriggerHandler.primaryRelationSetup')){

            CommonUtilities.debug('Inside primaryRelationSetup Method');
            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('oldMap------->>>>>>>'+oldMap);
            
            //Instance to store Contact External Ids
            Set<String> externalIds = new Set<String>();
            for(Lead l : newRec){
                //Filter only Marketing Leads
                if(l.RecordTypeId == MARKETING_ACTIVITY_ID){
                    //Prepare the set of external contact ids
                    if(l.Contact_External_Id__c != NULL && (oldMap == null || l.Contact_External_Id__c != oldMap.get(l.Id).Contact_External_Id__c)){
                        externalIds.add(l.Contact_External_Id__c);
                    }
                    
                    //Populate Account and Conatct with null if the external id is removed
                    if(oldMap != null && l.Contact_External_Id__c == NULL && l.Contact_External_Id__c != oldMap.get(l.Id).Contact_External_Id__c){
                        l.Contact__c = NULL;
                        l.Account__c = NULL;
                    }
                }
            }
            
            //Instance to store the relationship between External Id and Contact and Account SF Record Id
            Map<String, Contact> contactMap = new Map<String, Contact>();
            
            /*****************************************************
             * @comment : Changing to Siebel Row Id reference from existing Contact External Id attribute. 
             * NEW CONTACT INTERFACE CHANGE REQUEST
             ******************************************************/

            //Fetch related Contact records
            for(Contact c : [SELECT Id, AccountId,Salesforce_Contact_Id__c,Account_Name__c, Name, Lead_Source_Id__c FROM Contact WHERE Salesforce_Contact_Id__c IN: externalIds]){
                contactMap.put(c.Salesforce_Contact_Id__c, c);
            }
            
            //Update Lead Record with Primary relation setup
            for(Lead l : newRec){
                //Filter Marketing Leads
                if(l.RecordTypeId == MARKETING_ACTIVITY_ID){
                    //Conditional to check Siebel Contact relation
                    if(l.Contact_External_Id__c != NULL && (oldMap == null || l.Contact_External_Id__c != oldMap.get(l.Id).Contact_External_Id__c)){
                        if(contactMap.containsKey(l.Contact_External_Id__c)){
                            l.Contact__c = contactMap.get(l.Contact_External_Id__c).Id;
                            if(contactMap.get(l.Contact_External_Id__c).AccountId != null){
                                l.Account__c = contactMap.get(l.Contact_External_Id__c).AccountId;
                                l.Lead_Source_Id__c = contactMap.get(l.Contact_External_Id__c).Lead_Source_Id__c;
                                String oppName = contactMap.get(l.Contact_External_Id__c).Account_Name__c +'-'+ contactMap.get(l.Contact_External_Id__c).Name+'-'+l.Lead_Source_Name__c;
                                if(oppName.length()>120){
                                    l.Opportunity_Name__c = oppName.substring(0, 120);
                                }else{
                                    l.Opportunity_Name__c = oppName;
                                }
                            }
                        }
                    }
                }
            } 

            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('Exit primaryRelationSetup Method');
        }
    }
    
    // Method Name: createCampaignRec
    // Author: Abinash panigrahi
    // Description: Method to create Campaign with Campaign Member using Lead Source Id 
    // Parameter 1: newRec - List of the new versions of the Lead records
    // Parameter 2: oldMap - Map of IDs to the old versions of the Lead records
    // Return: Null
    public static void createCampaignRec(List<Lead> newRec, Map<Id,Lead> oldMap){

        //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('LeadTriggerHandler.createCampaignRec')){

            CommonUtilities.debug('Inside createCampaignRec Method');
            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('oldMap------->>>>>>>'+oldMap);

            //Instance to store Unique Lead Source Ids and populate with values
            Map<String, Lead> leadSourceMap = new Map<String, Lead>();
            for(Lead l : newRec){
                if(l.Lead_Source_Id__c != NULL && (oldMap == null || l.Lead_Source_Id__c != oldMap.get(l.Id).Lead_Source_Id__c) && l.RecordTypeId == MARKETING_ACTIVITY_ID){
                    leadSourceMap.put(l.Lead_Source_Id__c, l);
                }
            }
            
            //Instance to map the relationship between Lead Source Id and Campaign RecordId
            Map<String, Campaign> leadSourceCampaignMap = new Map<String, Campaign>();
            for(Campaign cmp : [SELECT Id, StarTrack_Id__c FROM Campaign WHERE Siebel_Row_Id__c IN: leadSourceMap.keySet()]){
                leadSourceCampaignMap.put(cmp.StarTrack_Id__c, cmp);
            }
            
            //Tnstance to store newly Campaign Record
            Map<String, Campaign> toInsertCampaign = new Map<String, Campaign>();
            //Create Campaign Record with StarTrackId populated
            for(String leadSource : leadSourceMap.keySet()){
                if(!leadSourceCampaignMap.containsKey(leadSource)){
                    Campaign cmp = new Campaign(Name = leadSource, StarTrack_Id__c = leadSource);
                    toInsertCampaign.put(leadSource, cmp);
                    leadSourceCampaignMap.put(leadSource, cmp);
                }
            }
            
            //Exception Handling
            //Insert Campaign record
            try{
                if(toInsertCampaign.values().size() > 0){
                    insert toInsertCampaign.values();
                }
            }catch(Exception ex){
                //Create Apex Log
                ExceptionHandlerController.createException('ContactTriggerHandler', 'createCampaignRec', 'Trigger Logic', 'Insert Campaign', ex.getMessage(), System.today());
            }
            
            //Fetch Related Campaign Member records
            //Instance to store the relationship between CampaignId and its related Campaign Member's Lead RecordId
            Map<Id, Set<Id>> campaignMemberMap = new Map<Id, Set<Id>>();
            for(CampaignMember cm : [SELECT Id, LeadId, CampaignId FROM CampaignMember WHERE CampaignId IN: leadSourceCampaignMap.values() AND LeadId IN: leadSourceMap.values()]){
                if(!campaignMemberMap.containsKey(cm.CampaignId)){
                    campaignMemberMap.put(cm.CampaignId, new Set<Id>());
                }
                
                campaignMemberMap.get(cm.CampaignId).add(cm.LeadId);
            }
            
            //Instance to store newly created CampaignMember record
            List<CampaignMember> toInsertCampaignMember = new List<CampaignMember>();
            for(String leadSource : leadSourceMap.keySet()){
                if(leadSourceCampaignMap.containsKey(leadSource)){
                    Id campaignId = leadSourceCampaignMap.get(leadSource).Id;
                    Id leadId = leadSourceMap.get(leadSource).Id;
                    
                    if(campaignMemberMap.containsKey(campaignId) && !campaignMemberMap.get(campaignId).contains(leadId)){
                        toInsertCampaignMember.add(new CampaignMember(LeadId = leadId, CampaignId = campaignId, Status = 'Sent'));
                    }
                }       
            }
            
            //Exception Handling
            //Insert CampaignMember record
            try{
                if(toInsertCampaignMember.size()>0 || Test.isRunningTest()){
                    insert toInsertCampaignMember;
                }
            }catch(Exception ex){
                //Create Apex Log
                ExceptionHandlerController.createException('LeadTriggerHandler', 'createCampaignRec', 'Trigger Logic', 'Insert CampaignMember', ex.getMessage(), System.today());
            }

            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('Exit createCampaignRec Method');
        }
    }

    // Method Name: createdByApexSharingRule
    // Author: Abinash panigrahi
    // Description: Method to extend Record Sharing with CreatedBy User with help of Apex LeadShare
    // Parameter 1: newRec - List of the new versions of the Lead records
    // Parameter 2: oldMap - Map of IDs to the old versions of the Lead records
    // Return: Null
    public static void createdByApexSharingRule(List<Lead> newRec, Map<Id,Lead> oldMap){

        //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('LeadTriggerHandler.createdByApexSharingRule')){

            CommonUtilities.debug('Inside createdByApexSharingRule Method');
            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('oldMap------->>>>>>>'+oldMap);

            //Instance to store LeadShare records
            List<LeadShare> toBeApexShared = new List<LeadShare>();
            
            //Loop Logic
            //To figure out Sales Created Lead records
            for(Lead ld : newRec){
                if(ld.RecordTypeId == SALES_CREATED_ID && ((oldMap == null && ld.CreatedById != ld.OwnerId) || (oldMap != null && oldMap.get(ld.Id).OwnerId != ld.OwnerId && oldMap.get(ld.Id).OwnerId == ld.CreatedById))){
                    toBeApexShared.add(new LeadShare(LeadAccessLevel = Label.LEAD_CREATEDBY_ACCESS, LeadId = ld.Id, UserOrGroupId = ld.CreatedById));
                }
            }

            CommonUtilities.debug('toBeApexShared------->>>>>>>'+toBeApexShared);

            //Insert the sharing record and capture the save result.
            //The false parameter allows for partial processing if multiple records passed into the operation. 
            List<Database.SaveResult> results = Database.insert(toBeApexShared,false);

            for(Database.SaveResult sr : results){
                // Process the save results.
                if(!sr.isSuccess()){
                    //Get first save result error.
                    Database.Error err = sr.getErrors()[0];
                    //Create Apex Log
                    ExceptionHandlerController.createException('LeadTriggerHandler', 'createdByApexSharingRule', 'Trigger Logic', 'Lead Apex Sharing', err.getMessage(), System.today());
                }
            }

            CommonUtilities.debug('Exit createdByApexSharingRule Method');
        }
    }

    // Method Name: campaignHistoryMaintain
    // Author: Abinash panigrahi
    // Description: Method to add Sales Created Leads as Campaign Memebers - Campaign History
    // Parameter 1: newRec - List of the new versions of the Lead records
    // Parameter 2: oldMap - Map of IDs to the old versions of the Lead records
    // Return: Null
    public static void campaignHistoryMaintain(List<Lead> newRec, Map<Id,Lead> oldMap){

        //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('LeadTriggerHandler.campaignHistoryMaintain')){

            CommonUtilities.debug('Inside campaignHistoryMaintain Method');
            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('oldMap------->>>>>>>'+oldMap);

            //Instance to store newly created CampaignMember record
            List<CampaignMember> toInsertCampaignMember = new List<CampaignMember>();

            //Loop Logic
            //Filter out Sales Created Leads by Campaign Value/Change
            for(Lead ld : newRec){
                if(ld.Primary_Campaign__c != null && ld.RecordTypeId == SALES_CREATED_ID && (oldMap == null || (oldMap != null && ld.Primary_Campaign__c != oldMap.get(ld.Id).Primary_Campaign__c))){
                    toInsertCampaignMember.add(new CampaignMember(LeadId = ld.Id, CampaignId = ld.Primary_Campaign__c, Status = 'Sent'));
                }
            }

            //Exception Handling
            //Insert CampaignMember record
            try{
                if(toInsertCampaignMember.size()>0){
                    insert toInsertCampaignMember;
                }
            }catch(Exception ex){
                //Create Apex Log
                ExceptionHandlerController.createException('LeadTriggerHandler', 'campaignHistoryMaintain', 'Trigger Logic', 'Insert CampaignMember', ex.getMessage(), System.today());
            }

            CommonUtilities.debug('Exit campaignHistoryMaintain Method');
        }
    }

    // Method Name: statusChangeCaptureRemainder
    // Author: Abinash panigrahi
    // Description: Method to store Datetime stamp for New Lead Status being assigned to Owner - Will be used further by Schedulde Class to send Remainder Notification
    // Parameter 1: newRec - List of the new versions of the Lead records
    // Parameter 2: oldMap - Map of IDs to the old versions of the Lead records
    // Return: Null
    public static void statusChangeCaptureRemainder(List<Lead> newRec, Map<Id,Lead> oldMap){

        //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('LeadTriggerHandler.statusChangeCaptureRemainder')){

            CommonUtilities.debug('Inside statusChangeCaptureRemainder Method');
            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('oldMap------->>>>>>>'+oldMap);

            for(Lead ld : newRec){
                if(ld.Status == LEAD_STATUS_NEW && String.valueOf(ld.OwnerId).startsWith(USER_RECORDID_PREFIX) && (oldMap == null || (oldMap != null && ld.OwnerId != oldMap.get(ld.Id).OwnerId))){
                    ld.Status_Capture_Change__c = System.today().addDays(Integer.valueOf(Label.LEADPASS_REMAINDERNOTIFICATION));
                }else if(oldMap != null && ld.Status != LEAD_STATUS_NEW && oldMap.get(ld.Id).Status == LEAD_STATUS_NEW){
                    ld.Status_Capture_Change__c = null;
                }
                CommonUtilities.debug('ld.Status_Capture_Change__c------->>>>>>>'+ld.Status_Capture_Change__c);
            }

            CommonUtilities.debug('Exit statusChangeCaptureRemainder Method');
        }
    }

    // Method Name: chatterPostLeadStatusNotification
    // Author: Abinash panigrahi
    // Description: Method to create Chatter Post when Lead Status is changed to Converted / Rejected - Lead Owner and Creator mention
    // Parameter 1: newRec - List of the new versions of the Lead records
    // Parameter 2: oldMap - Map of IDs to the old versions of the Lead records
    // Return: Null
    public static void chatterPostLeadStatusNotification(List<Lead> newRec, Map<Id,Lead> oldMap){

        //Dynamic Code Execution
        If(DynamicCodeExecution.allowExecution('LeadTriggerHandler.chatterPostLeadStatusNotification')){

            CommonUtilities.debug('Inside chatterPostLeadStatusNotification Method');
            CommonUtilities.debug('newRec------->>>>>>>'+newRec);
            CommonUtilities.debug('oldMap------->>>>>>>'+oldMap);

            List<FeedItem> toBePostedItems = new List<FeedItem>();
            for(Lead ld : newRec){
                if(ld.Status != oldMap.get(ld.Id).Status && ( ld.Status == LEAD_STATUS_REJECTED || ld.Status == LEAD_STATUS_CONVERTED || ld.Status == LEAD_STATUS_WORKING)){

                    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                    ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

                    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

                    /*Specify the user id for @mention. You can create multiple ConnectApi.MentionSegmentInput if 
                    there are multiple users.
                    */

                    mentionSegmentInput.id = ld.CreatedById;
                    messageBodyInput.messageSegments.add(mentionSegmentInput);

                    if(ld.Status == LEAD_STATUS_REJECTED){
                        textSegmentInput.text = Label.LEAD_CHATTERPOST_STARTMESSAGE1 + ' '+ ld.Contact_First_Name__c+ ' '+ld.Contact_Last_Name__c+ ' '+Label.LEAD_CHATTERPOST_REJECTEDMESSAGE + ' '+ ld.Lead_Rejection_Reason__c;
                    }else if(ld.Status == LEAD_STATUS_CONVERTED){
                        textSegmentInput.text = Label.LEAD_CHATTERPOST_STARTMESSAGE1 + ' '+ ld.Contact_First_Name__c+ ' '+ld.Contact_Last_Name__c+ ' '+ Label.LEAD_CHATTERPOST_CONVERTEDMESSAGE + ' '+ ld.Opportunity_Name__c;
                    }else if(ld.Status == LEAD_STATUS_WORKING){
                        textSegmentInput.text = Label.LEAD_CHATTERPOST_STARTMESSAGE2 + ' '+ ld.Contact_First_Name__c+ ' '+ld.Contact_Last_Name__c+ ' '+ Label.LEAD_CHATTERPOST_WORKINGMESSAGE;
                    }else{
                        textSegmentInput.text = ' ';
                    }
                    
                    messageBodyInput.messageSegments.add(textSegmentInput);

                    feedItemInput.body = messageBodyInput;
                    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;

                    //SubjectId indicates to which record this feed item will be tagged to. 
                    feedItemInput.subjectId = ld.Id;

                    //Exception Handling
                    //Post Chatter Feeds
                    try{
                        if(!Test.isRunningTest()){
                            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null,feedItemInput);
                        }
                    }catch(Exception ex){
                        //Create Apex Log
                        ExceptionHandlerController.createException('LeadTriggerHandler', 'chatterPostLeadStatusNotification', 'Trigger Logic', 'Chatter Post Notification', ex.getMessage(), System.today());
                    }
                }
            }

            CommonUtilities.debug('Exit chatterPostLeadStatusNotification Method');
        }
    }
}