({
    //Method to prepare the data to be prefilled and send the same to Create Record component
    doInit : function(component, event, helper) {
        (this).startWaiting(component);
        (this).doCallout(component, 'c.populateValues', {}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result !== null) {
                    window.setTimeout(
                        $A.getCallback(function() {
                            $A.get("e.force:closeQuickAction").fire();
                        }), 1000
                    );
                    
                    var resObj = JSON.parse(result);
                    var createAcountContactEvent = $A.get("e.force:createRecord");
                    createAcountContactEvent.setParams({
                        "entityApiName": "Services__c",
                        "defaultFieldValues": resObj
                    });
                    createAcountContactEvent.fire(); 
                }   
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    }
})