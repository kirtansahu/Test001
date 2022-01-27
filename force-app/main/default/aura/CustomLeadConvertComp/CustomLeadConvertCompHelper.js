({
    fetchLeadDetails : function(component, event) {
        var recordId = component.get("v.recordId");
        component.set("v.errorMessage", null);
        (this).startWaiting(component);
        (this).doCallout(component, 'c.fetchLeadRecordDetails', {'recordId': recordId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.oLead", result);
                if(result.IsConverted){
                    (this).doShowToast(component, "Error!", $A.get("$Label.c.CLC_LeadAlreadyConverted"), 'error');
                }else if($A.util.isEmpty(result.Account__c) || $A.util.isUndefinedOrNull(result.Account__c)){
                    (this).doShowToast(component, "Error!", $A.get("$Label.c.CLC_AccountRequiredMsg"), 'error');
                }else if($A.util.isEmpty(result.Contact__c) || $A.util.isUndefinedOrNull(result.Contact__c)){
                    (this).doShowToast(component, "Error!", $A.get("$Label.c.CLC_ContactRequiredMsg"), 'error');
                }else{
                    component.set("v.isValid", true);
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                var isSFApp = component.get("v.isSFApp");
                if(isSFApp){
                    var errors = response.getError();
                    var errorMessage = errors[0].message;
                    component.set("v.errorMessage", errorMessage);
                }else{
                    (this).handleErrors(component, errors);
                }
            }
            (this).stopWaiting(component);
        });
    },

    handleConvertLead : function(component, event){
        var oLead = component.get("v.oLead");
        component.set("v.errorMessage", null);
        (this).startWaiting(component);
        (this).doCallout(component, 'c.convertLeadIntoOpportunity', {'oLead': oLead}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                (this).doShowToast(component, "Success", $A.get("$Label.c.CLC_LeadConvertedSuccess"), "success");
                (this).navigateToRecord(component, result);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                var isSFApp = component.get("v.isSFApp");
                if(isSFApp){
                    var errors = response.getError();
                    var errorMessage = errors[0].message;
                    component.set("v.errorMessage", errorMessage);
                }else{
                    (this).handleErrors(component, errors);
                }
            }
            (this).stopWaiting(component);
        });
    },
})