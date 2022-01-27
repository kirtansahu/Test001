({
    handleLoad : function(component, event, helper) {
        var recordUi = event.getParam("recordUi");
        var status = recordUi.record.fields['Status'].value;
        component.set("v.leadStatus", status);
    },
    handleOnError: function(component, event, helper) {
        component.set("v.leadStatus", "NO_ACCESS");
    }
})