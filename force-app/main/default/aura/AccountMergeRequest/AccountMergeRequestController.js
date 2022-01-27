({
	doInit : function(component, event, helper) {
        helper.checkUserProfile(component);
	},
    
    checkAccounts : function(component, event, helper) {
        helper.checkAccounts(component);
    },
    
    reset: function(component, event, helper){
		component.set("v.survivorUniqueId", null);
        component.set("v.victimUniqueId", null);
        component.set("v.showError", false);
        component.set("v.isAllValid", false);
        component.set("v.isActionAllowed", true);
        component.set("v.errorMessages", null);
        component.set("v.survivorAccount", null);
        component.set("v.victimAccount", null);
        component.set("v.showConfirm", false);
    },
    
    showConfirmModel: function(component, event, helper){
        component.set("v.showConfirm", true);
    },
    
    hideConfirmModel: function(component, event, helper){
        component.set("v.showConfirm", false);
    },
    
    startMerging: function(component, event, helper){
        component.set("v.showConfirm", false);
        if(component.get("v.processAsyncronus")){
        	helper.startMergingAsync(component);
        }else{
            helper.startMerging(component);
        }
    },
    
    showHideError: function(component, event, helper){
        component.set("v.showError", !component.get("v.showError"));
    },
})