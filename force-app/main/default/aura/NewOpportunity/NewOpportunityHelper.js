({
    //Method to prepare the data to be prefilled and send the same to Create Record component
    doInit : function(component, event, helper) {
        (this).startWaiting(component);
        (this).doCallout(component, 'c.NewOpportunityPrefill', {} , function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                if(result !== null){
                    if(result == 'NA'){
                        component.set("v.IsNotBP", true);       
                    }else{
                        window.setTimeout(
                            $A.getCallback(function() {
                                $A.get("e.force:closeQuickAction").fire();
                            }), 1000
                        );
                        var createAcountContactEvent = $A.get("e.force:createRecord");
                        var rtnobj = JSON.parse(result);
                        createAcountContactEvent.setParams({
                            "entityApiName": "Opportunity",
                            "defaultFieldValues": rtnobj
                        });
                        createAcountContactEvent.fire(); 
                    }
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    }
})