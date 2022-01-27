({
    closeShipToValidModel : function(component, event, helper) {
        component.set("v.showShipToPopup",false);
    },

    addProdsWithNewShipTo : function(component, event, helper) {
        //send data through addSelectedItemsToCart application event
        var productData = component.get("v.orderedProducts");
        var ordDetailObj = component.get("v.orderDetails");
        var additemsAppEvent = $A.get("e.c:KMAddSelectedItemsToCart");
        if(additemsAppEvent){
            additemsAppEvent.setParams({
                "orderedProducts": productData,
                "orderDetails": ordDetailObj,
                "replaceProducts": true
            });
            additemsAppEvent.fire();
        }else{
            console.log("Event not Supported");
        }
        component.set("v.savedOrderDetails", ordDetailObj);
        component.set("v.showShipToPopup",false);
        component.set("v.showOrderTypePopup", false);
        var toastReference = $A.get("e.force:showToast");
        toastReference.setParams({
            "type" : "Success",
            "title" : "",
            "duration": 5000,
            "message" :$A.get("$Label.c.KM_QO_Items_added_Msg"),
            "mode" : "dismissible"
        });
        toastReference.fire();
        //refresh the order form by using  refreshOrderForm event
        var refreshOrderFormEvt = component.getEvent("refreshOrderForm");
        if(refreshOrderFormEvt){
            refreshOrderFormEvt.fire();
        }else{
            console.log("Event not Supported");
        }
    },

    closeOrderTypePopup: function(component, event, helper) {
        component.set("v.showOrderTypePopup", false);
    }
})