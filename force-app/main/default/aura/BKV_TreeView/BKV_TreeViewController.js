({
	doInit : function(component, event, helper) {
        helper.startWaiting(component);
        helper.doCallout(component, "c.buildTreeHirarchy", {}, function(response) {
            let state = response.getState();
            helper.myLog('=============== state '+state);
            if (state === "SUCCESS") {
                helper.myLog('=============== RESPONSE '+JSON.stringify(response.getReturnValue()));
                component.set('v.treeH' , response.getReturnValue());
            } else if (state === "ERROR") {
                helper.handleErrors(component, response.getError());
            }
            helper.stopWaiting(component);
        });
	}
})