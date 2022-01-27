({
    search : function(component, event, helper) {
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
    
    isSearchable : function(component) {
        var searchInput = component.get("v.searchInput");
        var searchOption = component.find("filter-select").get('v.value');
        if(
            ((searchOption == 'ShipToAlphaName' || searchOption == 'ShipTo') && searchInput.length > 2)
            ||
            ((searchOption == 'ContactName' || searchOption == 'Email') && searchInput.length > 0)
        ) {
            return true;
        }
        else {
            return false;
        }
    },

    //Sorting Method for the Account List
    sortBy: function(component, helper, field) {
        var sortAsc = component.get("v.AccsortAsc"),
            sortField = component.get("v.AccselectedTabsoft1"),
            records = component.get("v.shipToList"),
            fieldPath = field.split(/\./),
            fieldValue = this.fieldValue;
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a, b) {
            var aValue = fieldValue(a, fieldPath),
                bValue = fieldValue(b, fieldPath),
                t1 = aValue == bValue,
                t2 = (!aValue && bValue) || (aValue < bValue);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        component.set("v.AccsortAsc", sortAsc);
        component.set("v.AccselectedTabsoft1", field);
        component.set("v.shipToList", records);
    },

    sortBycon : function(component,helper,field) {
        var sortAsc = component.get("v.consortCon"),
            sortField = component.get("v.conselectedTabsoft1"),
            records = component.get("v.contactList"),
            fieldPath = field.split(/\./),
            fieldValue = this.fieldValue;
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a,b){
            var aValue = fieldValue(a, fieldPath),
                bValue = fieldValue(b, fieldPath),
                t1 = aValue == bValue,
                t2 = (!aValue && bValue) || (aValue < bValue);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        component.set("v.consortCon", sortAsc);
        component.set("v.conselectedTabsoft1", field);
        component.set("v.contactList", records);
    },

    fieldValue: function(object, fieldPath) {
        var result = object;
        fieldPath.forEach(function(field) {
            if (result) {
                result = result[field];
            }
        });
        return result;
    },
})