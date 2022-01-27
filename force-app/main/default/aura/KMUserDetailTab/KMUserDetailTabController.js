({
    doInit : function(component, event, helper) {
        var getUserDetails = component.get('c.getUserDetails');
        getUserDetails.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.userData", response.getReturnValue());
                var userLanguageKey = response.getReturnValue().LanguageLocaleKey;
                component.set("v.selectedLanguageKey", userLanguageKey);
            }
            component.set("v.isLoaded", true);
        });
        $A.enqueueAction(getUserDetails);
    },

    handleSave : function(component, event, helper) {
        component.set("v.showSpinner", true);
        var userInfo = component.get("v.userData");
        var isLanguageChanged = false;
        if (component.get('v.selectedLanguageKey') != userInfo.LanguageLocaleKey) {
            userInfo.LanguageLocaleKey = component.get('v.selectedLanguageKey');
            isLanguageChanged = true;
        }
        var saveUserDetails = component.get('c.saveUserDetails');
        saveUserDetails.setParams({
            userData: userInfo
        });
        saveUserDetails.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var toastReference = $A.get("e.force:showToast");
                toastReference.setParams({
                    "type" : "success",
                    "title" : "",
                    "duration": 5000,
                    "message" : $A.get('$Label.c.KM_User_Details_Update_Success_Msg'),
                    "mode" : "dismissible"
                });
                toastReference.fire();
                // Refresh the page
                if (isLanguageChanged) {
                    component.set("v.showSpinner", true);
                    location.reload();
                }
            }
            else {
                let errors = response.getError();
                console.log('-- errors: '+errors);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(saveUserDetails);
    }
})