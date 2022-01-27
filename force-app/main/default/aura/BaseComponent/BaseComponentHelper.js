({
    //METHOD TO SHOW SPINNER
    startWaiting: function(component) {
        component.set("v.isWaiting", true);
    },
    
    //METHOD TO HIDE SPINNER
    stopWaiting: function(component) {
        component.set("v.isWaiting", false);
    },
    
    //METHOD TO CALL SERVER SIDE LOGIC
    doCallout: function(component, methodName, params, callBackFunc) {
        doCallout(component, methodName, params, callBackFunc, false, false);
    },
    
    //METHOD TO CALL SERVER SIDE LOGIC
    doCallout: function(component, methodName, params, callBackFunc, isSetStorable, isSetBackground) {
        var action = component.get(methodName);
        if(!$A.util.isEmpty(params) && !$A.util.isUndefinedOrNull(params)){
            action.setParams(params);
        }
        action.setCallback(this, callBackFunc);
        if (isSetStorable) action.setStorable();
        if (isSetBackground) action.setBackground();
        $A.enqueueAction(action);
    },
    
    //METHOD TO NAVIGATE ON RECORD PAGE
    navigateToRecord: function(component, recordId) {
        var navEvt = $A.get("e.force:navigateToSObject");
        if(navEvt != undefined){
            navEvt.setParams({
                "recordId": recordId
            });
            this.startWaiting(component);
            navEvt.fire();
        }else{
            this.myLog('Calssic Action ');
            window.location.href = '/'+recordId;
        }
    },
    
    //METHOD TO SHOW ERROR MESSAGE AS TOAST
    handleErrors: function(component, errors) {
        var eCount;
        for(eCount in errors){
            var error = errors[eCount];
            if (error.pageErrors != undefined) {
                var i;
                for (i in error.pageErrors) {
                    this.doShowToast(component, error.pageErrors[i].statusCode, error.pageErrors[i].message, 'warning');
                }
            } else {
                var i;
                var msgArray = (error.message).split('|');
                for (i in msgArray) {
                    this.doShowToast(component, 'Error', msgArray[i], 'error');
                }   
            }
            
            if (error.fieldErrors != undefined) {
                var fieldErrors = error.fieldErrors;
                var fld;
                for (fld in fieldErrors) {
                    if (fieldErrors.hasOwnProperty(fld)) { 
                        var fldErrors = fieldErrors[fld];
                        var i;
                        for (i in fldErrors) {
                            this.doShowToast(component, fldErrors[i].statusCode, fldErrors[i].message+' ['+fld+']', 'error');
                        }
                    }
                }
            } else {
                var i;
                var msgArray = (error.message).split('|');
                for (i in msgArray) {
                    this.doShowToast(component, 'Error', msgArray[i], 'error');
                }   
            }
        }
    },
    
    //METHOD TO GET ALL URL PARAMS
    getAllUrlParams: function(url) {
        var queryString = url ? url.split('?')[1] : window.location.search.slice(1);
        var obj = {};
        if (queryString) {
            queryString = queryString.split('#')[0];
            var arr = queryString.split('&');
            for (var i = 0; i < arr.length; i++) {
                var a = arr[i].split('=');
                var paramNum = undefined;
                var paramName = a[0].replace(/\[\d*\]/, function(v) {
                    paramNum = v.slice(1, -1);
                    return '';
                });
                var paramValue = typeof(a[1]) === 'undefined' ? true : a[1];
                if (obj[paramName]) {
                    if (typeof obj[paramName] === 'string') {
                        obj[paramName] = [obj[paramName]];
                    }
                    if (typeof paramNum === 'undefined') {
                        obj[paramName].push(paramValue);
                    } else {
                        obj[paramName][paramNum] = paramValue;
                    }
                } else {
                    obj[paramName] = paramValue;
                }
            }
        }
        return obj;
    },
    
    //METHOD TO SHOW TOAST MESSAGES
    doShowToast: function(component, title, message, type) {
        this.doShowToast(component, title, message, type, 'dismissible');
    },
    
    doShowToast: function(component, title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent != undefined){
            toastEvent.setParams({
                mode: mode,
                title: title,
                message: message,
                type: type
            });
            toastEvent.fire();
        }else{
            component.set("v.classic_showToast", true);
            component.set("v.classic_toastType", type);
            component.set("v.classic_toastMessage", message);
        }
    },
    
    //METHOD TO CLOSE OVERLAY LIBRARY MODEL
    doCloseModel: function(component){
        component.find("overlayLib").notifyClose();
    },
    
    //METHOD TO PRINT CONSOLE LOGS
    myLog: function(customMessage){
        console.log(customMessage);
    },
    
    //METHOD TO REFERSH CURRENT PAGE
    doRefresh: function(){
       var refreshEvt = $A.get('e.force:refreshView');
        if(refreshEvt != undefined){
            refreshEvt.fire();  
        }else{
            window.location.href = window.location.href;
        }
    },
    
    //METHOD TO SHOW NEW MODEL
    doNewModel: function(component, modelName, attributes){
        this.doNewModel(component, modelName, attributes, true, "lightning-lookup-modal");
    },
    
    doNewModel: function(component, modelName, attributes, showModelCloseButton, modelClass){
        var modalBody;
        $A.createComponent(
            modelName,attributes,
            function(content, status) {
                if (status === "SUCCESS") {
                    modalBody = content;
                    component.find('overlayLib').showCustomModal({
                        body: modalBody,
                        showCloseButton: showModelCloseButton,
                        cssClass: modelClass,
                    }).then(function (overlay) {
                         //$A.get('e.force:closeQuickAction').fire();
                    });
                }
            }
        );
    },
    
    //METHOD TO NAVIGATE TO HOME PAGE
    doNavigateToObjectHome : function (component, sObjectAPIName) {
        var homeEvent = $A.get("e.force:navigateToObjectHome");
        if(homeEvent != undefined){
            homeEvent.setParams({
                "scope": sObjectAPIName
            });
            homeEvent.fire();
        }else{
            this.doShowToast(component, 'Error', 'Can\'t navigate to object home in classic', 'error');
        }
    },
    
    //METHOD TO SHOW MESSAGE USING NOTIFICATION LIBRARY
    doShowNotif : function(component, variant, message, header, callBackFunc) {
        var ntifLib = component.find('notifLib');
        if(ntifLib != undefined){
            ntifLib.showNotice({
                "variant": variant,
                "message": message,
                "header": header,
                closeCallback: callBackFunc
            });
        }else{
            this.doShowToast(component, header, message, variant);
        }
    },
    
    //METHOD TO NAVIGATE ON URL
    doNavigateToCommunityHome : function () {
        var urlEvent = $A.get("e.force:navigateToURL");
        if(urlEvent != undefined){
            urlEvent.setParams({
                "url": "/s"
            });
            urlEvent.fire();
        }else{
            window.location.href  = '/s';
        }
    },
    
    //METHOD TO CLOSE ALL TOAST
    closeAllToasts : function(component){
        component.set("v.classic_showToast", false);
        component.set("v.classic_toastType", 'error');
        component.set("v.classic_toastMessage", 'something went wrong!!');
    },
    
    //METHOD TO CREATE SOBJECT RECORD
    createRecord : function(component, event, sObjectName, result){
        var createObjectRecord = $A.get("e.force:createRecord");
        createObjectRecord.setParams({
            "entityApiName": sObjectName,
            "defaultFieldValues": result
        });
        createObjectRecord.fire();
    },
    
    closeFocusedTab : function(component) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        }).catch(function(error) {
            this.doShowToast(component, 'Error', error, 'error');
        });
    },
    
    //METHOD TO OPEN RECORD TAB IN CONSOLE
    consoleOpenTab: function(component, attributes, callBackFunc) {
    	var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab(attributes).then(callBackFunc).catch(function(error) {
            (this).doShowToast(component, 'Error', error, 'error');
        });
    },
    
})