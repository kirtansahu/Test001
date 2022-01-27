({
    validateFieldsAndhideCustomDockFooter: function(component, event, helper) {
    	component.set("v.isDataChanged", true);	  
        helper.validate(component, event, event.getParam('draftValues'), component.get("v.showOppItem"));
    },
    
    cloneOpportunity: function(component, event, helper) {
        // stop the form from submitting since we are going to clone the opportunity 
        // so it will be done in the server side action
        event.preventDefault();
        var fields = event.getParam("fields");
        var layoutSections = component.get("v.layoutSections");
        if(layoutSections != null && layoutSections != '' && layoutSections != undefined){
            for(let i=0;i<layoutSections.length;i++){
                let sectionDetails = layoutSections[i];
                if(sectionDetails != null && sectionDetails != '' && sectionDetails != undefined){
                    for(let j=0;j<sectionDetails.layoutFields.length;j++){
                        var fieldDetials = sectionDetails.layoutFields[j];
                        if(!fieldDetials.editableField && fieldDetials.ApiName == ''){
                            delete fields[fieldDetials.ApiName];
                        }else if(!fieldDetials.editableField){
                            delete fields[fieldDetials.ApiName]; 
                        }
                    }
                }
            } 
        }
        var device = $A.get("$Browser.formFactor");
        if(device != null && device != undefined && (device == 'PHONE' || device == 'TABLET ')){
            var opp = component.get("v.opp");
            fields['AccountId'] = opp.AccountId;
            fields['Primary_Contact__c'] = opp.Primary_Contact__c;
            fields['Pricebook2Id'] = opp.Pricebook2Id;
            fields['CampaignId'] = opp.CampaignId;
            fields['End_Customer_Contact__c'] = opp.End_Customer_Contact__c;
            fields['End_Customer_Account__c'] = opp.End_Customer_Account__c;
            fields['Converted_Lead__c'] = opp.Converted_Lead__c;
        }
        helper.cloneOppAndGetLineItems(component, fields);
    },
    
    handleCloneLineItems: function(component, event, helper){
        helper.cloneOppLineItems(component, event);  
    },
    
    handleCloneOppTeamMembers: function(component, event, helper){
        helper.cloneOppLineItems(component, event);  
    },
    
    handleColumnSorting : function(component, event, helper) {
        // assign the latest attribute with the sorted column fieldName and sorted direction
    	component.set("v.sortedBy", event.getParam("fieldName"));
    	component.set("v.sortedDirection", event.getParam("sortDirection")); 
        helper.sortData(component, event.getParam("fieldName"), event.getParam("sortDirection"));
    },
    
    handleProdLineColumnSorting: function(component, event, helper) {
        component.set("v.sortedProdLineBy", event.getParam("fieldName"));
    	component.set("v.sortedProdLineDirection", event.getParam("sortDirection")); 
        helper.sortProdLineData(component, event.getParam("fieldName"), event.getParam("sortDirection"));
    },
    
    handleOppTeamMemberColumnSorting: function(component, event, helper) {
        component.set("v.sortedOppTeamMemberBy", event.getParam("fieldName"));
    	component.set("v.sortedOppTeamMemberDirection", event.getParam("sortDirection")); 
        helper.sortOppTeamMemberData(component, event.getParam("fieldName"), event.getParam("sortDirection"));
    },
    
    /**
     * Handling opp line item row action i.e. deleting a row
     * */
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'delete':
                helper.deleteRow(component, row);
                break;
        }
    },
    
    handleProdLineRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'delete':
                helper.deleteProdLineRow(component, row);
                break;
        }
    },
    
    handleOppTeamMemberRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'delete':
                helper.deleteOppTeamMemberRow(component, row);
                break;
        }
    },
    
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    navigateToOpp : function( component, event, helper ) {
        helper.navigateToOppRecord(component, component.get("v.clonedOppRecordId"));
    },
    
    init: function(component, event, helper) {
       helper.doInit(component, event);
    },
    
    handleOnload : function(component, event, helper) {
        var opp = component.get("v.opp");
        var inputFields = component.find("fieldId");
        
        if(inputFields != null && inputFields != undefined && inputFields.length > 0){
            for(var i=0;i<inputFields.length;i++){
                let fieldName = inputFields[i].get("v.fieldName");
                inputFields[i].set('v.value', '');
                if(fieldName != null && fieldName != '' && fieldName != undefined){
                    if(fieldName != 'Status__c' 
                       && fieldName != "Confidence__c" 
                       && fieldName != "Reason_Won_Lost__c" 
                       && fieldName != "Rejection_Reason__c"
                       && fieldName != "StageName"
                       && fieldName != "CloseDate"
                       && fieldName != "Name"
                       && fieldName != "Rep_Forecast_Amount__c"
                       && fieldName != "Rep_Estimated_Amount__c"
                       && fieldName != "Amount"
                       && fieldName != "Converted_Lead__c"){
                        let fieldValue = opp[fieldName];
                        if(fieldValue != null && fieldValue != undefined){
                            inputFields[i].set('v.value', fieldValue);
                        }
                    }
                }
            }
        }
        
        var inputFields = component.find("fieldId");
        if(inputFields != null && inputFields != undefined && inputFields.length > 0){
            for(var i=0;i<inputFields.length;i++){
                let fieldName = inputFields[i].get("v.fieldName");
                if(fieldName != null && fieldName != '' && fieldName != undefined){
                    if(fieldName == 'Status__c'){
                        inputFields[i].set('v.value', 'Accepted');
                    }else if(fieldName == 'StageName'){
                        inputFields[i].set('v.value', 'New');
                    }
                }
            }
        }
    }
})