({
    doInit: function (component,event, helper) {
        helper.doInit(component,event);
    },
    back: function(component,event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})