({
    changeOrderStatusPath : function(component, event, helper) {
        var isChangeStatus = false;
        var newStatusName = event.currentTarget.dataset.statusname;
        var oldStatusName = component.get("v.statusName");
        if(oldStatusName == 'review'){
            if(newStatusName == 'cart'|| newStatusName == 'shippingPayment'){
                isChangeStatus = true;
            }
        }else if(oldStatusName == 'shippingPayment'){
            if(newStatusName == 'cart'){
                isChangeStatus = true;
            }
        }
        if(isChangeStatus){
            var chngStatusEvent = component.getEvent("changeStatus");
            chngStatusEvent.setParams({
                "statusName": newStatusName
            });
            chngStatusEvent.fire();
        }
    },
})