({
	doInit: function(component, event, helper) {
        helper.doInit(component, event);
    },
    
    handleOnload : function(component, event, helper) {
        var leadOb = component.get("v.leadOb");
        var inputFields = component.find("fieldId");
        var requiredFields = component.get("v.requiredFields");
        if(inputFields != null && inputFields != undefined && inputFields.length > 0){
            for(var i=0;i<inputFields.length;i++){
                let fieldName = inputFields[i].get("v.fieldName");
                if(fieldName != null && fieldName != '' && fieldName != undefined){
                    if(fieldName == 'Account__c' || fieldName == "Contact__c" 
                       || fieldName =="FirstName" || fieldName =="LastName"
                       || fieldName =="Company" || fieldName =="RecordTypeId"){
                        let fieldValue = leadOb[fieldName];
                        if(fieldValue != null && fieldValue != undefined){
                            inputFields[i].set('v.value', fieldValue);
                        }
                    }
                    
                    if(requiredFields[fieldName]){
                        inputFields[i].set('v.required', true);
                    }
                }
            }
        }
        
        
        helper.stopWaiting(component);
    },
    
    createLead: function(component, event, helper) {
        helper.startWaiting(component);
        event.preventDefault();
        var leadOb = component.get("v.leadOb");
        var fields = event.getParam('fields');
        for (var fld in fields) {
            if (fld != undefined && fld != '' && fields.hasOwnProperty(fld)) {           
                leadOb[fld] = fields[fld];
            }
        }
        component.set("v.leadOb", leadOb);
        if(leadOb.Account__c != null && leadOb.Account__c != '' && leadOb.Contact__c != null && leadOb.Contact__c != ''){
            helper.doSubmit(component, event, leadOb);
        }else{
            helper.doShowToast(component, 'Error', 'Required Fields Missing [Account, Contact]', 'error');  
        }
    },
    
    /*handleSuccess: function(component, event, helper) {
        event.preventDefault();
        var updatedRecord = JSON.parse(JSON.stringify(event.getParams()));
        helper.doShowToast(component, 'Success', 'New Lead Created Successfully.', 'success');        
    },
    
    handleError: function(component, event, helper) {
        helper.stopWaiting(component);
        var errorOb = JSON.parse(JSON.stringify(event.getParams()));
        console.log(JSON.stringify(event.getParams()));
        
        if(errorOb){
            if(errorOb.output){
                if(errorOb.output.errors && errorOb.output.errors.length > 0){
                    for(var i=0; i<errorOb.output.errors.length; i++){
                        var errOb = errorOb.output.errors[i];
                        helper.doShowToast(component, errOb.errorCode, errOb.message, 'error');
                    }
                }
            }
            
            if(errorOb.error && errorOb.error.body){
                if(errorOb.error.body.errorCode){
                    helper.doShowToast(component, errorOb.error.body.errorCode, errorOb.error.body.message, 'error');
                }else if(errorOb.error.body.output && errorOb.error.body.output.errors && errorOb.error.body.output.errors.length > 0){
                    for(var j=0; i<errorOb.error.body.output.errors.length; j++){
                        var errOb = errorOb.error.body.output.errors[j];
                        helper.doShowToast(component, errOb.errorCode, errOb.message, 'error');
                    }
                }
            }
        }
    },*/
    
    handleCancel : function(component, event, helper) {
        event.preventDefault();
        var recordId = component.get("v.recordId");
        if(recordId){
        	$A.get("e.force:closeQuickAction").fire();
        }else{
            if(component.get("v.isInConsole")){
                helper.handleConsoleClose(component, null, helper);
            }else if(component.get("v.isModel")){
                helper.handleModelClose(component, null);
            }else {
                helper.doNavigateToObjectHome(component, 'Lead');
            }
        }
    },
})