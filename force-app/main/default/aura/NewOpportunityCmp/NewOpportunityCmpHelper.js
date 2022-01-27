({
    //Method to prepare the data to be prefilled and send the same to Create Record component
    doInit : function(component, event) {
        (this).startWaiting(component);
        var recordId = component.get("v.recordId");
        (this).doCallout(component, 'c.NewOppPrefill', {'conId': recordId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                $A.get("e.force:closeQuickAction").fire();
               	(this).createRecord(component, event, "Opportunity", JSON.parse(result));
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
})