({
	doInit: function (component,event, helper) {
        helper.doInit(component,event, helper);
    },
    
    back: function(component,event, helper){
       $A.get("e.force:closeQuickAction").fire();
    }
})