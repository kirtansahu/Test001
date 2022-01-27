({
	doInit : function(component, event, helper) {
		helper.getCurrentUserTeamMemeberDetails(component, event);
	},
    handledeleteOppTeamMember : function(component, event, helper) {
		helper.deleteOppTeamMember(component, event);
	},
    closeQuickAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})