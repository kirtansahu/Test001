({
    doInit : function(component, event, helper) {
        var isSFApp = component.get("v.isSFApp");
        if(isSFApp){
            helper.doNewModel(component, "c:NewLead", {"isModel": true, "isInConsole": false, "isSFApp_newLead": true}, false, "lightning-lookup-modal");
        }else{
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(response) {
                component.set("v.isInConsole",response);
                var isInConsole = component.get("v.isInConsole");
                if(!isInConsole){
                    helper.doNewModel(component, "c:NewLead", {"isModel": true, "isInConsole": isInConsole}, false, "lightning-lookup-modal");
                }
            }).catch(function(error) {
                helper.doShowToast(component, 'Error', error, 'error');
            });
        }
	},
    
    onRender : function(component, event, helper) {
       component.set("v.isInitDone", true);
	},
})