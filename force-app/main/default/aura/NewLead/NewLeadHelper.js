({
    doInit: function (component, event){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.getLeadObject', {'recordId':component.get("v.recordId")}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                component.set("v.leadOb", result);
                this.getFieldsAndSection(component, event);
            } else if (component.isValid() && state === 'ERROR') {
                (this).stopWaiting(component);
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }else{
                (this).stopWaiting(component);
            }
        });
    },
    
    getFieldsAndSection: function (component, event){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.fetchPageLayoutFieldsAndSection', {'leadOb':component.get("v.leadOb")}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                component.set("v.layoutSections", result);
                console.log(JSON.stringify(result));
                
                var requiredFields = {};
                for(var i=0; i<result.length; i++){
                    var sectionOb = result[i];
                    for(var j=0; j<sectionOb.layoutFields.length; j++){
                        var fld = sectionOb.layoutFields[j];
                        if(fld.required){
                            requiredFields[fld.ApiName] = true;
                        }
                    }
                }
                component.set("v.requiredFields", requiredFields);
                component.set("v.showLeadForm", true);
            } else if (component.isValid() && state === 'ERROR') {
                (this).stopWaiting(component);
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }else{
                (this).stopWaiting(component);
            }
        });
    },
    
    doSubmit: function (component, event, sLeadObject){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.doCreateNewLead', {'leadObject':sLeadObject}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                (this).doShowToast(component, 'Success', 'New Lead Created Successfully.', 'success');
                if(component.get("v.recordId")){
                    $A.get("e.force:closeQuickAction").fire();
                    (this).handleModelClose(component, result);
                }else{
                    if(component.get("v.isInConsole")){
                        (this).handleConsoleClose(component, result, (this));
                    }else if(component.get("v.isModel")){
                        (this).handleModelClose(component, result);
                    }else{
                        (this).navigateToRecord(component, result);
                    }
                }
            } else if (component.isValid() && state === 'ERROR') {
                (this).stopWaiting(component);
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }else{
                (this).stopWaiting(component);
            }
        });
    },
    
    handleConsoleClose: function(component, createdRecordId, helper){
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            if(createdRecordId && createdRecordId != null){
                helper.consoleOpenTab(component, {
                    recordId: createdRecordId, 
                    focus: true
                }, function(response) {
                    workspaceAPI.focusTab({tabId : response});
                    workspaceAPI.closeTab({tabId: focusedTabId});
                });
            }else{
                helper.doNavigateToObjectHome(component, 'Lead');
                workspaceAPI.closeTab({tabId: focusedTabId});
            }
        }).catch(function(error) {
            helper.doShowToast(component, 'Error', error, 'error');
        });
    },
    
    handleModelClose: function(component, createdRecordId){
        if(createdRecordId && createdRecordId != null){
        	(this).navigateToRecord(component, createdRecordId);
        }else{
            (this).doNavigateToObjectHome(component, 'Lead');
        }
        (this).doCloseModel(component);
    }
})