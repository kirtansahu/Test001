({
    checkUserProfile : function(component) {
        (this).startWaiting(component);
        (this).doCallout(component, 'c.checkForValidProfile', {}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                if(!result.isSuccess){
                    component.set("v.errorMessages", [result.statusMessage]);
                    component.set("v.isActionAllowed", false);
                }else{
                    component.set("v.isActionAllowed", true);
                    component.set("v.errorMessages", null);
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleAllErrors(component, errors);
                component.set("v.survivorAccount", null);
                component.set("v.victimAccount", null);
            }
            (this).stopWaiting(component);
        });
    },
    
    checkAccounts : function(component) {
        var survivorUniqueId = component.get("v.survivorUniqueId");
        var victimUniqueId = component.get("v.victimUniqueId");
        (this).doCallout(component, 'c.getAccountDetails', {'survivorUniqueId':survivorUniqueId, 'victimUniqueId':victimUniqueId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                if(result){
                    if(result.survivor.accountFound){
                    	component.set("v.survivorAccount", result.survivor.accountObject);
                    }else{
                        component.set("v.survivorAccount", null);
                    }
                    if(result.victim.accountFound){
                    	component.set("v.victimAccount", result.victim.accountObject);
                    }else{
                        component.set("v.victimAccount", null);
                    }
                    component.set("v.isAllValid", result.isAllValid);
                    
                    if(result.isAllValid){
                    	component.set("v.errorMessages", null);
                        component.set("v.showError", false);
                        var childThreshold = parseInt($A.get("$Label.c.ACCOUNT_MERGE_MAX_ALLOWED_CHILDS"));
                        if(childThreshold <= result.numberOfChildRecords){
                        	component.set("v.processAsyncronus", true);   
                        }else{
                        	component.set("v.processAsyncronus", false);   
                        }
                    }else{
                        component.set("v.errorMessages", result.errorMessages);
                        component.set("v.showError", result.errorMessages.length>0);
                    }
                }else{
                    component.set("v.survivorAccount", null);
                    component.set("v.victimAccount", null);
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleAllErrors(component, errors);
                component.set("v.survivorAccount", null);
                component.set("v.victimAccount", null);
            }
        });
	},
    
    startMerging : function(component) {
        var survivorUniqueId = component.get("v.survivorUniqueId");
        var victimUniqueId = component.get("v.victimUniqueId");
        var survivorAccount = component.get("v.survivorAccount");
        var victimAccount = component.get("v.victimAccount");
        (this).startWaiting(component);
        component.set("v.actionInProcess", true);
        (this).doCallout(component, 'c.processAccountMerging', {'survivorUniqueId':survivorUniqueId, 'victimUniqueId':victimUniqueId}, function(response) {
            let state = response.getState();
            (this).stopWaiting(component);
            component.set("v.actionInProcess", false);
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                if(result.isSuccess){
                    component.set("v.errorMessages", null);
                    component.set("v.isAllValid", false);
                    component.set("v.showError", false);
                    (this).doShowToast(component, 'Success', '"'+victimAccount.Name+'" successfully merged to "'+survivorAccount.Name+'"', 'success', 'sticky');
                }else{
                    component.set("v.errorMessages", [result.statusMessage]);
                    component.set("v.showError", true);
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleAllErrors(component, errors);
            }
        });
    },
    
    startMergingAsync : function(component) {
        var survivorUniqueId = component.get("v.survivorUniqueId");
        var victimUniqueId = component.get("v.victimUniqueId");
        var survivorAccount = component.get("v.survivorAccount");
        var victimAccount = component.get("v.victimAccount");
        (this).startWaiting(component);
        component.set("v.actionInProcess", true);
        (this).doCallout(component, 'c.processAccountMergingAsync', {'survivorUniqueId':survivorUniqueId, 'victimUniqueId':victimUniqueId}, function(response) {
            let state = response.getState();
            (this).stopWaiting(component);
            component.set("v.actionInProcess", false);
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                if(result.isSuccess){
                    component.set("v.errorMessages", null);
                    component.set("v.isAllValid", false);
                    component.set("v.showError", false);
                    (this).doShowToast(component, 'Success', 'Request to merge "'+victimAccount.Name+' ('+victimUniqueId+')" to "'+survivorAccount.Name+' ('+survivorUniqueId+')" is received successfully.', 'warning', 'sticky');
                }else{
                    component.set("v.errorMessages", [result.statusMessage]);
                    component.set("v.showError", true);
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleAllErrors(component, errors);
            }
        });
    },
    
    handleAllErrors: function(component, errors) {
        var errorMessages = [];
        var eCount;
        for(eCount in errors){
            var error = errors[eCount];
            if (error.pageErrors != undefined) {
                var i;
                for (i in error.pageErrors) {
                    errorMessages.push(error.pageErrors[i].statusCode+": "+error.pageErrors[i].message);
                }
            } else {
                var i;
                var msgArray = (error.message).split('|');
                for (i in msgArray) {
                    errorMessages.push("Error: "+msgArray[i]);
                }   
            }
            
            if (error.fieldErrors != undefined) {
                var fieldErrors = error.fieldErrors;
                var fld;
                for (fld in fieldErrors) {
                    if (fieldErrors.hasOwnProperty(fld)) { 
                        var fldErrors = fieldErrors[fld];
                        var i;
                        for (i in fldErrors) {
                            errorMessages.push(fldErrors[i].statusCode+": "+fldErrors[i].message+" ["+fld+"]");
                        }
                    }
                }
            } else {
                var i;
                var msgArray = (error.message).split('|');
                for (i in msgArray) {
                    errorMessages.push("Error: "+msgArray[i]);
                }   
            }
        }
        component.set("v.errorMessages", errorMessages);
        if(errorMessages && errorMessages.length > 0){
           component.set("v.showError", true); 
        }
    },
})