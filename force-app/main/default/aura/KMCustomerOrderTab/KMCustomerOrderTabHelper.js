({
    //Helper Method to Sort contact table
    sortConTable: function(component, field) {
        component.set('v.showSpinner', true);
        //Sort Order
        var sortConAsc = component.get("v.sortConAsc");
        //Sorting field
        var sortConField = component.get("v.sortConField");
        //Filter Option
        var searchOption = component.find("selectOption").get('v.value');
        //Input box value
        var userInput = component.get("v.userInput");
        sortConAsc = sortConField != field || !sortConAsc;
        //Controller action to perform sorting
        var action = component.get("c.getContactList");
        //Setting parameters for controller actions
        action.setParams({
            "selectOption":searchOption,
            "userInput":userInput,
            "sortField":sortConField,
            "isAsc":sortConAsc
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                component.set("v.contactList", response.getReturnValue());
                component.set('v.showSpinner', false);
            }
        });
        component.set("v.sortConAsc", sortConAsc);
        component.set("v.sortConField", field);
        $A.enqueueAction(action);
    },
    loadAccountContactDetails : function(component, accountId) {
        component.set('v.showSpinner', true);
        component.set('v.showContactDetail',true);
        component.set('v.showCOSearch',false);
        var sortField = component.get("v.sortConHisField");
        var sortOrder = component.get("v.sortConHisAsc");
        if (accountId.length > 0) {
            var getAccountDetail = component.get("c.getAccountDetail");
            getAccountDetail.setParams({
                "accountId" : accountId,
                "fieldName" : sortField,
                "isAsc" : sortOrder,
                "filterField" : "",
                "searchKey" : ""
            });
            getAccountDetail.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS"){
                    var responseObj = response.getReturnValue();
                    component.set('v.accDetail',responseObj.accountData);
                    component.set('v.shipToNumbers',responseObj.accountData.ERP_Account_Id__c);
                    var tempConList = new Array();
                    var contactData = responseObj.contactData;
                    if(contactData && contactData.length > 0){
                        contactData.forEach(function(eachRec){
                            var conDataRec = eachRec.Contact;
                            tempConList = [...tempConList,conDataRec];
                        });
                    }
                    component.set("v.contactHistory",tempConList);
                    component.set("v.allContactHistory",tempConList);
                    component.set("v.showCOSearch",false);
                    component.set("v.showContactDetail",true);
                    component.set('v.showSpinner', false);
                    component.set('v.tabValue', 'contactHistoryTabId');
                }
            });
        }
        $A.enqueueAction(getAccountDetail);
    },

    //Action to Account Detail Page
    openAccountDetails:function(component, accountId) {
        component.set('v.showSpinner', true);
        //var accountId = event.getParam('recordId');
        var sortField = component.get("v.sortConHisField");
        var sortOrder = component.get("v.sortConHisAsc");
        if (accountId.length > 0) {
            var getAccountDetail = component.get("c.getAccountDetail");
            getAccountDetail.setParams({
                "accountId" : accountId,
                "fieldName" : sortField,
                "isAsc" : sortOrder,
                "filterField" : "",
                "searchKey" : ""
            });
            getAccountDetail.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS"){
                    var responseObj = response.getReturnValue();
                    component.set('v.accDetail',responseObj.accountData);
                    component.set('v.showSpinner', true);
                    //component.set('v.accDetail',response.getReturnValue());
                    component.set('v.shipToNumbers',responseObj.accountData.ERP_Account_Id__c);
                    var tempConList = new Array();
                    var contactData = responseObj.contactData;
                    if(contactData && contactData.length > 0){
                        contactData.forEach(function(eachRec){
                            var conDataRec = eachRec.Contact;
                            tempConList = [...tempConList,conDataRec];
                        });
                    }
                    component.set("v.contactHistory",tempConList);
                    component.set("v.allContactHistory",tempConList);
                    component.set("v.showCOSearch",false);
                    component.set("v.showContactDetail",true);
                    component.set('v.showSpinner', false);
                    component.set('v.tabValue', 'contactHistoryTabId');
                    component.find('conApplyBtn').set('v.disabled',true);
                    component.find('conClearBtn').set('v.disabled',true);
                    component.set("v.contFilterBox", "");
                    component.find("conField").set('v.value','');
                    component.find('contFilterBoxId').set('v.disabled',true);
                }
            });
        }
        $A.enqueueAction(getAccountDetail);
    },

    //Open action for Product availabilty Model
    openPAModel: function(cmp, conRecId,typeofData) {
        // for Display Model,set the "isOpen" attribute to "true"
        var stNumber;
        cmp.set("v.showPAModel", true);
        var contactDtList = new Array();
        if(typeofData == "conHistoryResults"){
            contactDtList = cmp.get("v.contactHistory");
        }else if(typeofData == "conSearchResults"){
            contactDtList = cmp.get("v.contactList");
        }
        if(conRecId != null && conRecId != ''){
            let selectedContact;
            let selectedAccount;
            for (let i = 0; i < contactDtList.length; i++) {
                let currentContact = this.getContact(contactDtList[i]);
                if (currentContact.Id == conRecId) {
                    selectedContact = currentContact;
                    selectedAccount = contactDtList[i].Account;
                    break;
                }
            }
            if(typeofData == "conSearchResults"){
                stNumber = selectedAccount.ERP_Account_Id__c;
                cmp.set("v.accDetail", selectedAccount);
            }else if(typeofData == "conHistoryResults"){
                var accDetail = cmp.get("v.accDetail");
                stNumber = accDetail.ERP_Account_Id__c;
            }
            cmp.set("v.selectedContact", selectedContact);
        }
        cmp.set('v.shipToNumbers',stNumber);
    },

    getContact : function(contactObject) {
        let contact = contactObject;
        if (contactObject.hasOwnProperty('Contact')) {
            contact = contactObject.Contact;
        }
        return contact;
    },

    showToast : function(title, message, type, duration) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": duration
        });
        toastEvent.fire();
    },
    doCustomerOrdersearch : function(component, event, helper) {
        //var searchOption = component.find('filter-select').get('v.value');
        var searchOption = component.get('v.selectedOption');
        if(searchOption == 'ShipToAlphaName' || searchOption == 'ShipTo') {
            component.set('v.showCustomerOrderTable', true);
            component.set('v.showContactTable', false);
            component.set('v.showSpinner', true);

            var actions = component.get('c.getShipToRecords');
            actions.setParams({
                selectOption: searchOption,
                accountOffset: 0,
                searchInput: component.get('v.searchInput')
            });
            actions.setCallback(this,function(response){
                var state = response.getState();
                component.set('v.showSpinner',false);
                if(state === 'SUCCESS'){
                    var accList = response.getReturnValue();
                    component.set('v.shipToList', accList);
                    component.set('v.accountLength', accList.length);
                }
            });
            $A.enqueueAction(actions);
        }
        else {
            if(searchOption == 'ContactName' || searchOption == 'Email') {
                component.set('v.showContactTable', true);
                component.set('v.showSpinner', true);
                component.set('v.showCustomerOrderTable',false);
                var contactRecords=component.get('c.getContactRecords');
                contactRecords.setParams({
                    selectOption: searchOption,
                    contactOffset: 0,
                    searchInput: component.get('v.searchInput')
                });
                contactRecords.setCallback(this,function(response){
                    var state = response.getState();
                    if(state === 'SUCCESS'){
                        component.set('v.showSpinner', false);
                        var conResult = response.getReturnValue();
                        component.set('v.contactList', conResult);
                        component.set('v.conLength', conResult.length);
                        helper.sortBy(component, helper, 'Account_Alpha_Name__c');
                    }
                });
                $A.enqueueAction(contactRecords);
            }
        }
    },
    injectComponent: function (name, target,component) {
        var acc = component.get("v.accDetail");
        let params = {};
        params = {
            "accountRecord": acc,
            "ShipToNumber": acc.ERP_Account_Id__c,
            "selectedOption": component.get("v.selectedOption"),
            "searchInput": component.get("v.searchInput")
        };
        $A.createComponent(
            name,
            params,
            function (contentComponent, status, error) {
                if (status === "SUCCESS") {
                    target.set('v.body', contentComponent);
                } else {
                    throw new Error(error);
                }
            }
        );
    },
    setBackButtonData : function(component){
        var accRec = component.get("v.accDetail");
        var backBtnData = {};
        backBtnData['tabAuraId'] = "customerOrdersId";
        backBtnData['selectedOption'] = component.get("v.selectedOption");
        backBtnData['searchInput'] = component.get("v.searchInput");
        backBtnData['accountData'] = accRec;
        backBtnData['formType'] = "shipToContactForm";
        var backToButtonAppEvent = $A.get("e.c:KMSendBackToButtonData");
        if(backToButtonAppEvent){
            backToButtonAppEvent.setParams({
                "backButtonData": backBtnData
            });
            backToButtonAppEvent.fire();
        }else{
            console.log("Event not Supported");
        }
    },
})