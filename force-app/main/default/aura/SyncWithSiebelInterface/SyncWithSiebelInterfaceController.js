({
    //Method to perform Primary Account check on load
    init : function(component, event, helper) {
        //Create Action
        var action = component.get("c.checkPrimaryAccount");
        //Pass Parameters to Apex Method
        action.setParams({
            "recordId": component.get("v.recordId")
        });
        //Add Callback behaviour when for when response is received
        action.setCallback(this, function(response) {
            //Fetch Response
            if(response.getState() === "SUCCESS") {
                //IsValid attribute values depend on Response result
                //alert(response.getReturnValue());
                component.set("v.isValid",response.getReturnValue());
                //Error Toast Message
                if(response.getReturnValue() != "TRUE"){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Error!",
                        message: $A.get("$Label.c.SYNCWITHSIEBELINTERFACE_ERRORMESSAGE"),
                        type: "error"
                    });
                    //Fire Toast/Notification message
                    toastEvent.fire();
                    //Close Modal Component    
                    $A.get("e.force:closeQuickAction").fire(); 
                }
            }
        });
        //Send action off to be executed
        $A.enqueueAction(action);
    },
    
    //Method to trigger Contact Integration logic 
    siebelSync : function(component, event, helper) {

        //Primary Account Check
        if(component.get("v.isValid") == "TRUE"){
            //Fetch Current RecordId
            var recordIds = component.get("v.recordId");
            //Show Spinner Component
            //(this).startWaiting(component);
            component.set("v.Spinner", true);
            //Create Action
            var action = component.get("c.siebelSyncIntegration");
            //Pass Parameters to Apex Method
            action.setParams({
                "recordId": recordIds
            });
            //Add Callback behaviour when for when response is received
            action.setCallback(this, function(response) {
                //Fetch Response
                var state = response.getState();
                if(state === "SUCCESS") {
                    //Pops-up Toast Message, if Success Response received
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Success!",
                        message: $A.get("$Label.c.SYNCWITHSIEBELINTERFACE_SUCCESSMESSAGE"),
                        type: "success"
                    });
                    //Fire Toast/Notification message
                    toastEvent.fire();
                }
                else {
                    //Error Handling -- Display Error Message
                    var errors = response.getError();
                    //(this).handleErrors(component, errors);
                    helper.handleErrors(component, errors);
                }
            //Close Modal Component    
            $A.get("e.force:closeQuickAction").fire(); 
            //Hide Spinner Component after Completed execution
            component.set("v.Spinner", false); 
            });
            //Send action off to be executed
            $A.enqueueAction(action);
        }

    },

    //Method to hide Modal Component
    closeQuickAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})