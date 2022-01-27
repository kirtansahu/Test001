({
	fetchLead : function(component, isOnLoad) {
		(this).startWaiting(component);
        (this).doCallout(component, 'c.fetchLeadRecord', {"leadId": component.get("v.recordId")} , function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.oLead", result);
                if(isOnLoad){
                    (this).fetchLeadStatus(component);
                }else{
                    (this).handleConvertLead(component);
                } 
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
                (this).stopWaiting(component);
            }else{
                (this).stopWaiting(component);
            }
        });
	},
    
    fetchLeadDependency : function(component, ObjName, ctrlFieldApiName, depFieldApiName, ctrlFieldValue) {
		(this).startWaiting(component);
        (this).doCallout(component, 
                         'c.fetchDependentPickListValue',
                         {"objTypeName": ObjName, "contrfieldApiName": ctrlFieldApiName, "depfieldApiName":depFieldApiName, "contrFldValue":ctrlFieldValue} , 
                         function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                if(ctrlFieldValue === 'Rejected'){
                    component.set("v.RejectReasonOptions", result);
                }else if(ctrlFieldValue === 'Completed'){
                    component.set("v.CompletedOptions", result);
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
	},
    
    fetchLeadStatus : function(component) {
		(this).startWaiting(component);
        (this).doCallout(component, 'c.fetchLeadStatusValues', null , function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                var currentStatus = component.get("v.oLead.Status");
                component.set("v.currentLeadStatus", currentStatus);
                let status = 'completed';
                for(let i=0; i<result.length;i++){
                    if(status == 'current'){status = 'incomplete';}
                    if(result[i].value == currentStatus){status = 'current';}
                    result[i].status = status;
                }
                component.set("v.lstLeadStatus", result);
                (this).fetchLeadDependency(component, 'Lead', 'Status', 'Lead_Rejection_Reason__c', 'Rejected');
                (this).fetchLeadDependency(component, 'Lead', 'Status', 'Completed__C', 'Completed');
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }else{
                (this).stopWaiting(component);
            }
        });
	},
    
    handleCloseModalHelper : function(component) {
        var cmpTarget = component.find('rejectModel');
        if(!$A.util.hasClass(cmpTarget, "slds-hide")){
            $A.util.addClass(cmpTarget, 'slds-hide');
        }
        var convertLeadModelTarget = component.find('convertLeadModel');
        if(!$A.util.hasClass(convertLeadModelTarget, "slds-hide")){
            $A.util.addClass(convertLeadModelTarget, 'slds-hide');
        }
        var leadCompleteModelTarget = component.find('leadCompleteModel');
        if(!$A.util.hasClass(leadCompleteModelTarget, "slds-hide")){
            $A.util.addClass(leadCompleteModelTarget, 'slds-hide');
        }
    },
    
    updateLead: function(component){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.updateLeadRecord', {"leadObj": component.get("v.oLead")} , function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.oLead", result);
                component.set("v.showSpinner", false);
                (this).doShowToast(component, "Success", "Status changed successfully.", 'success');
                (this).handleCloseModalHelper(component);
                (this).doRefresh();
            } else if (component.isValid() && state === 'ERROR') {
                (this).stopWaiting(component);
                (this).doRefresh();
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
    
    handleConvertLead: function(component){
        (this).startWaiting(component);
        var leadObj = component.get("v.oLead");
        if(leadObj.IsConverted){
            (this).doShowToast(component, "Error!", $A.get("$Label.c.CLC_LeadAlreadyConverted"), 'error');
            (this).stopWaiting(component);
            component.set("v.showSpinner", false);
        }else if($A.util.isEmpty(leadObj.Account__c) || $A.util.isUndefinedOrNull(leadObj.Account__c)){
            (this).doShowToast(component, "Error!", $A.get("$Label.c.CLC_AccountRequiredMsg"), 'error');
            (this).stopWaiting(component);
            component.set("v.showSpinner", false);
        }else if($A.util.isEmpty(leadObj.Contact__c) || $A.util.isUndefinedOrNull(leadObj.Contact__c)){
            (this).doShowToast(component, "Error!", $A.get("$Label.c.CLC_ContactRequiredMsg"), 'error');
            (this).stopWaiting(component);
            component.set("v.showSpinner", false);
        }else{
            (this).doCallout(component, 'c.convertLeadIntoOpportunity', {"oLead": leadObj} , function(response) {
                let state = response.getState();
                if (component.isValid() && state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    component.set("v.showSpinner", false);
                    (this).doShowToast(component, "Success", $A.get("$Label.c.CLC_LeadConvertedSuccess"), "success");
                    (this).navigateToRecord(component, result);
                } else if (component.isValid() && state === 'ERROR') {
                    var errors = response.getError();
                    (this).handleErrors(component, errors);
                    component.set("v.showSpinner", false);
                    (this).stopWaiting(component);
                }else{
                    component.set("v.showSpinner", false);
                    (this).stopWaiting(component);
                }
            });
        }
    }
})