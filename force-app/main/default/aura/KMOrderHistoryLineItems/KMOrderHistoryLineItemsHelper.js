({
    invoiceDateValidation: function(component, dateVal, dateName) {
        var toastReference = $A.get("e.force:showToast");
        var oneYearDt = new Date();
        var formatedDt = new Date(dateVal);
        oneYearDt = oneYearDt.setMonth(oneYearDt.getMonth() - 6);
        if (formatedDt < oneYearDt){
            toastReference.setParams({
                "type" : "Error",
                "title" : "",
                "duration": 1000,
                "message" : $A.get("$Label.c.KM_Records_Availability_Valid_Msg"),
                "mode" : "dismissible"
            });
            toastReference.fire();
            if (dateName == 'fromDate') {
                component.set('v.linefromDate', '');
            }
            if (dateName == 'EndDate') {
                component.set('v.linetoDate', '');
            }
        }
        else if (formatedDt > new Date()) {
            toastReference.setParams({
                "type" : "Error",
                "title" : "",
                "duration": 1000,
                "message" :  $A.get("$Label.c.KM_Date_Must_Be_Past"),
                "mode" : "dismissible"
            });
            toastReference.fire();
            if (dateName == 'fromDate') {
                component.set('v.linefromDate', '');
            }
            if (dateName == 'EndDate') {
                component.set('v.linetoDate', '');
            }
        }
    },

    //Sort Method for Line Items
    sortLineItems: function(component,helper,field) {
        var sortAsc = component.get("v.sortLineAsc"),
            sortField = component.get("v.sortLineField"),
            records = component.get("v.lineItems");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        //Set Sorting Order
        component.set("v.sortLineAsc", sortAsc);
        //Set Sort Field
        component.set("v.sortLineField", field);
        //Set Record values
        component.set("v.lineItems", records);
    },

})