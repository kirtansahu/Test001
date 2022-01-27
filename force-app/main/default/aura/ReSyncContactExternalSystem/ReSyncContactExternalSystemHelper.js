({
    doInit : function(component, event) {
        var recordId = component.get("v.recordId");
        (this).doCallout(component, 'c.doCallouts', {'objContactId': recordId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                if (response.getReturnValue() === 'SUCCESS') {
                    (this).doShowToast(component, "Retry Sent!", $A.get("$Label.c.RESYNC_CONTACTINTERFACE"), "success");
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    (this).doShowToast(component, "Retry Failed!", $A.get("$Label.c.RESYNC_CONTACTINTERFACE_ERROR"), "error");
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
        });
    }
})