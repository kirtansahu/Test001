({
	doInit : function(component, event, helper) {
		helper.fetchLead(component, true);
	},
    
    handleStatusChange : function(component, event, helper) {
        var index = event.currentTarget.dataset.rowIndex;
        var leadStatus = component.get("v.lstLeadStatus");
        let status = 'completed';
        let selectedLeadStatusValue;
        for(let i=0; i<leadStatus.length;i++){
            if(status == 'current'){status = 'incomplete';}
            if(i == index){
                status = 'current';
                selectedLeadStatusValue = leadStatus[i].value;
            }
            leadStatus[i].status = status;
        }
        var lead = component.get("v.oLead");
        lead.Status = selectedLeadStatusValue;
        component.set("v.oLead", lead);
        component.set("v.lstLeadStatus", leadStatus);
    },
    
    handleMarkCurrentStatus: function(component, event, helper) {
        var leadObj = component.get("v.oLead");
        if(leadObj.Status == 'Rejected'){
            let rejectModel = component.find('rejectModel');
        	$A.util.removeClass(rejectModel, 'slds-hide');
        }else if(leadObj.Status == 'Converted'){
            let convertLeadModel = component.find('convertLeadModel');
        	$A.util.removeClass(convertLeadModel, 'slds-hide');
        }else if(leadObj.Status == 'Completed'){
            let leadCompleteModel = component.find('leadCompleteModel');
        	$A.util.removeClass(leadCompleteModel, 'slds-hide');
        }else{
            helper.updateLead(component);
        }
    },
    
    handleCloseModal : function(component, event, helper) {
        helper.handleCloseModalHelper(component);
    },
    
    handleConvertLeadJS: function(component, event, helper) {
       component.set("v.showSpinner", true);
       helper.fetchLead(component, false);
    },
    
    handleUpdateRejectedLead : function(component, event, helper) {
        var inputCmp = component.find('lead_Rejected_Reason');
        var valueMissing = inputCmp.get('v.validity').valueMissing;
        if(valueMissing){
            inputCmp.showHelpMessageIfInvalid();
        }else{
            component.set("v.showSpinner", true);
            helper.updateLead(component);
        }
    },

    handleUpdateCompletedLead : function(component, event, helper) {
        var inputCmp = component.find('Completed__c');
        var valueMissing = inputCmp.get('v.validity').valueMissing;
        if(valueMissing){
            inputCmp.showHelpMessageIfInvalid();
        }else{
            component.set("v.showSpinner", true);
            helper.updateLead(component);
        }
    },
    
    handleMarkAsComplete : function(component, event, helper) {
        var leadObj = component.get("v.oLead");
        var leadStatus = component.get("v.lstLeadStatus");
        for(let i=0; i<leadStatus.length;i++){
            if(leadStatus[i].value == leadObj.Status && (i+1)<leadStatus.length){
                leadObj.Status = leadStatus[i+1].value;
                break;
            }
        }
        component.set("v.oLead", leadObj);
        if(leadObj.Status == 'Rejected'){
            let cmpTarget = component.find('rejectModel');
        	$A.util.removeClass(cmpTarget, 'slds-hide');
        }else if(leadObj.Status == 'Converted'){
            let cmpTarget = component.find('convertLeadModel');
        	$A.util.removeClass(cmpTarget, 'slds-hide');
        }else if(leadObj.Status == 'Completed'){
            let cmpTarget = component.find('leadCompleteModel');
        	$A.util.removeClass(cmpTarget, 'slds-hide');
        }else{
            helper.updateLead(component);
        }
    },
})