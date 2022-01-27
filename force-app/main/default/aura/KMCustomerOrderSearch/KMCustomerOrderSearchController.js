({
    handleFilterChange: function(component, event, helper) {
        component.set('v.searchInput', '');
        component.set('v.enableSearch', true);
        var options = component.find('filter-select').get('v.value');
        component.set('v.selectedOption', options);
    },

    handleSearchInputChange: function(component, event, helper) {
        component.set("v.enableSearch", !helper.isSearchable(component));
    },

    handleSearchInputKeyPress : function(component, event, helper) {
        if (event.which == 13 && helper.isSearchable(component)) {
            helper.search(component, event, helper);
        }
    },

    doSearch: function(component, event, helper) {
        helper.search(component, event, helper);
    },
    doCustomerOrderSearch : function(component, event, helper) {
        component.set("v.enableSearch", !helper.isSearchable(component));
    },

    //Action to sort Account List
    sortByAccounts: function(component, event, helper) {
        var fieldName = event.currentTarget.id;
        helper.sortBy(component, helper, fieldName);
        component.set("v.AccselectedTabsoft1", fieldName);
        var a = component.get("v.AccsortAsc");
    },

    //Action to sort Contact List
    sortByContacts:function(component, event, helper) {
        var fieldName = event.currentTarget.id;
        helper.sortBycon(component, helper, fieldName);
        component.set("v.conselectedTabsoft1", fieldName);
        var a = component.get("v.consortCon");
    },

    tableRowClicked: function(component, event, helper) {
        var rowClickEvent = component.getEvent("KMTableRowClickEvent");
        var showContactTable = component.get('v.showContactTable');
        rowClickEvent.setParams({
            "recordId" : event.currentTarget.dataset.id,
            "type" : showContactTable ? event.currentTarget.dataset.type : '',
            "tableName" : showContactTable ? 'contactTable' : 'shipToTable'
        });
        rowClickEvent.fire();
    },

    viewMoreAccountRecords: function(component, event, helper) {
        var selectedOption = component.get('v.selectedOption');
        var result = component.get('v.shipToList');
        var action = component.get('c.getShipToRecords');
        action.setParams({
            selectOption : selectedOption,
            accountOffset : result.length,
            searchInput : component.get('v.searchInput')
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === 'SUCCESS'){
                var accResult=response.getReturnValue();
                if(
                    (accResult.length == 0)
                    ||
                    (accResult.length < $A.get('$Label.c.KM_Record_Limits'))
                ) {
                    component.set('v.accountLength', accResult.length);
                    for(var i = 0; i < accResult.length; i++ ) {
                        result = [...result,accResult[i]];
                    }
                    component.set('v.shipToList', result);
                }
                else {
                    for (var i = 0; i < accResult.length; i++) {
                        result = [...result,accResult[i]];
                    }
                    component.set('v.shipToList', result);
                    component.set('v.accountLength', result.length);
                    helper.sortBy(component, helper, 'Account_Alpha_Name__c');
                }
            }
        });
        $A.enqueueAction(action);
    },

    viewMoreContactRecords : function(component, event, helper){
        var selectedOption = component.get('v.selectedOption');
        var result=component.get('v.contactList');
        var searchInputVal = component.get('v.searchInput');
        var moreRecords=component.get('c.getContactRecords');
        moreRecords.setParams({
            selectOption :selectedOption,
            contactOffset :result.length,
            searchInput : searchInputVal
        });
        moreRecords.setCallback(this,function(response){
            var state=response.getState();
            if(state==='SUCCESS'){
                var conResult=response.getReturnValue();
                if(conResult.length==0 || conResult.length < $A.get('$Label.c.KM_Record_Limits')){
                    component.set('v.conLength',conResult.length);
                }else{
                    for(var i=0;i<conResult.length;i++){
                        result=[...result,conResult[i]];
                    }
                    component.set('v.contactList',result);
                    component.set('v.conLength', result.length);
                }
            }
        });
        $A.enqueueAction(moreRecords);
    },
})