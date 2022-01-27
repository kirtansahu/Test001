({
    //Sorting method for Contact history data
    sortConHisTable:function(component, field){
        component.set('v.showSpinner', true);
        //Getting filter field value
        var conField = component.find("conField").get('v.value');
        //Getting filter box value
        var contFilterBox = component.get("v.contFilterBox");
        //Sort Order
        var sortConHisAsc = component.get("v.sortConHisAsc");
        //Sort field
        var sortConHisField = component.get("v.sortConHisField");
        sortConHisAsc = sortConHisField != field || !sortConHisAsc;
        var accountId = component.get('v.accDetail');
        //Controlller method for Contact sorting
        var getAccountDetail = component.get("c.getAccountDetail");
        getAccountDetail.setParams({
            "accountId": accountId.Id,
            "fieldName": sortConHisField,
            "isAsc": sortConHisAsc,
            "filterField": conField,
            "searchKey": contFilterBox
        });
        getAccountDetail.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){
                //Setting the Parameters to show table
                var tempConList = new Array();
                var responseData = response.getReturnValue();
                tempConList = this.convertToContacts(responseData.contactData);
                component.set("v.contactHistory", tempConList);
                component.set('v.showSpinner', false);
            }
        });
        component.set("v.sortConHisAsc", sortConHisAsc);
        component.set("v.sortConHisField", field);
        $A.enqueueAction(getAccountDetail);
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
            return t1 ? 0: (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
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

    //Sort the contact Records
    sortByContacts: function(component,helper,field) {
        component.set('v.loaded',true);
        var sortAsc = component.get("v.AccsortAsc"),
            sortField = component.get("v.AccselectedTabsoft"),
            records = component.get("v.contactHistory");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1? 0: (sortAsc?-1:1)*(t2?1:-1);
        });
        //set values in ProductTab attribute on component.
        component.set("v.AccsortAsc", sortAsc);
        component.set('v.loaded',false);
        component.set("v.sortField", field);
        component.set("v.contactHistory", records);
    },

    convertToContacts : function(contactDataFromAccount) {
        let contacts = [];
        for (let i = 0; i < contactDataFromAccount.length; i++) {
            contacts.push(contactDataFromAccount.Contact);
        }
        return contacts;
    },
})