({
    doInit : function(component, event, helper) {
        helper.fetchLeadDetails(component, event);
    },
    convertLead : function(component, event, helper) {
        helper.handleConvertLead(component, event);
    },
    closeQuickAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
})