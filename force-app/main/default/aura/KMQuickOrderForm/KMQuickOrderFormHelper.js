({
	createQuickOrderForm : function(component) {
		var quickOrderArray = new Array();
		quickOrderArray = [...quickOrderArray,{rowId:"1",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"2",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"3",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"4",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"5",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"6",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"7",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"8",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"9",productNumber:"",quantity:"",lotNumber:""}];
		quickOrderArray = [...quickOrderArray,{rowId:"10",productNumber:"",quantity:"",lotNumber:""}];
		component.set("v.quickOrderData", quickOrderArray);
    },
    loadCartShipToAndOrderType : function(component) {
        component.set("v.showSpinnerStatus", true);
        var toastReference = $A.get("e.force:showToast");
        var action = component.get("c.getOrderDetailObject");
        action.setCallback(this, function(response){
            var state= response.getState();
            component.set("v.showSpinnerStatus", false);
            if(state === 'SUCCESS'){
                var oldOrderDetailObj = response.getReturnValue();
                component.set("v.oldShipToNumber", oldOrderDetailObj.shipToNumber);
                component.set("v.oldOrderType", oldOrderDetailObj.orderType);
            }else if(state === 'INCOMPLETE'){
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_API_Error_Message"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            }else if(state === 'ERROR'){
                //generic error handler
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error message: " + errors[0].message+" ::Error Details: " + errors[0].stackTrace);
                        throw new Error("Error: "+errors[0].message);
                    }
                }else{
                    throw new Error("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    showToast : function(title, message, type, duration) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": duration
        });
        toastEvent.fire();
    },
})