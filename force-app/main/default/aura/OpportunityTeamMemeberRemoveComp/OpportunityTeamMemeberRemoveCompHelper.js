({
	getCurrentUserTeamMemeberDetails : function(component, event) {
        var recordId = component.get("v.recordId");
        (this).startWaiting(component);
        (this).doCallout(component, 'c.fetchCurrentUserTeamMember', {'recordId': recordId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.oOpportunityTeamMember", result);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
    
    deleteOppTeamMember : function(component, event){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.deleteOpportunityTeamMember', {'oppTeamMemberId': component.get("v.oOpportunityTeamMember.Id")}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
				(this).doShowToast(component, "Success", $A.get("$Label.c.OTM_Removed_Opportunity_Member"), "success");
                (this).navigateToRecord(component, component.get("v.recordId"));
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors); 
            }
            (this).stopWaiting(component);
        });
    },
})