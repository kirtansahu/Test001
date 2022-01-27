({
    setNoRecordFoundMessage : function(component) {
        component.set("v.tableMessage", $A.get("$Label.c.KM_No_Records_found"));
    },

    clearTableMessage : function(component) {
        component.set("v.tableMessage", '');
    },

    //Sorting Method for the Order History Table
    sortBy: function(component,helper,field) {
        var sortAsc = component.get("v.sortAsc"),
            sortField = component.get("v.sortField"),
            records = component.get("v.orderHistory");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1? 0: (sortAsc?-1:1)*(t2?1:-1);
        });
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", field);
        component.set("v.orderHistory", records);
    },

   //Action to calculate the total of the Order records
    calculateTotal: function(cmp){
        var orders = cmp.get('v.orderHistory');
        var totalamount = 0;
        for(var i = 0; i<orders.length; i++){
            totalamount +=Number(orders[i].Total);
        }
       return totalamount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    },

    //Date validation to show  Error to select one year records
    dateValidation: function(cmp, dateVal, dateName){
        var toastReference = $A.get("e.force:showToast");
        var oneYearDt = new Date();
        var formatedDt = new Date(dateVal);
        oneYearDt = oneYearDt.setMonth( oneYearDt.getMonth() - 6);
        if(formatedDt < oneYearDt){
            toastReference.setParams({
                "type" : "Error",
                "title" : "",
                "duration": 1000,
                "message" :  $A.get("$Label.c.KM_Records_Availability_Valid_Msg"),
                "mode" : "dismissible"
            });
            toastReference.fire();
            if(dateName == 'fromDate') {
                cmp.set('v.fromDate', '');
            }
            if(dateName == 'EndDate') {
                cmp.set('v.toDate', '');
            }
            return;
        }
        if(formatedDt > new Date()){
            toastReference.setParams({
                "type" : "Error",
                "title" : "",
                "duration": 1000,
                "message" : $A.get("$Label.c.KM_Date_Must_Be_Past"),
                "mode" : "dismissible"
            });
            toastReference.fire();
            if(dateName == 'fromDate') {
                cmp.set('v.fromDate', '');
            }
            if(dateName == 'EndDate') {
                cmp.set('v.toDate', '');
            }
            return;
        }
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
    }
})