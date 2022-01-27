({
    //Method to get the Order History Data
    doInit : function(component, event, helper) {
        component.set("v.showSpinnerStatus", true);
        //Ship To Number
        var shipToNumber = component.get("v.shipToNumber");
        //Controller Method to perform OFM API Action
        var action = component.get("c.getOrderHistoryList");
        var toastReference = $A.get("e.force:showToast");
        action.setParams({
            "shipToNumber": shipToNumber,
            "siebelRowID": ''
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                let auraResponse = response.getReturnValue();
                let actionData = auraResponse.data;
                if (auraResponse.isSuccess) {
                    if (actionData.responseDetail == undefined || actionData.responseDetail.length == 0) {
                        let message = $A.get("$Label.c.KM_No_Records_found");
                        helper.showToast("", message, "info", 2000);
                        component.set("v.tableMessage", message);
                    }
                    else {
                        var fromDate = new Date();
                        // var tt = fromDate.setDate(fromDate.getDate() - 300);
                        var previousYrDt = fromDate.getFullYear() + "/" + (fromDate.getMonth() + 1) + "/" + fromDate.getDate();
                        var result=[];
                        for(var i=0; i < actionData.responseDetail.length; i++) {
                            if(actionData.responseDetail[i].OrderDate < previousYrDt) {
                                result.push(actionData.responseDetail[i]);
                            }
                        }
                        if (result.length > 0) {
                            component.set("v.orderHistory", result);
                            component.set("v.allOrderHistory", result);
                            //Total calculation
                            var totalAmount = helper.calculateTotal(component);
                            component.set("v.totalAmount", totalAmount);
                            helper.clearTableMessage(component);
                        }
                        else {
                            let message = $A.get("$Label.c.KM_No_Records_found");
                            helper.showToast("", message, "info", 2000);
                            component.set("v.tableMessage", message);
                        }
                    }
                }
                else {
                    helper.showToast("", actionData, "error", 5000);
                    component.set("v.tableMessage", actionData);
                }
            }
            else if (state === 'ERROR') {
                let errors = response.getError();
                helper.showToast("", errors[0].message, "error", 5000);
                component.set("v.tableMessage", errors[0].message);
            }
            component.set('v.showSpinnerStatus', false);
        });
        $A.enqueueAction(action);
    },

    //Sort method for the Order History
    sorter: function(component, event, helper) {
        component.set("v.showSpinnerStatus", true);
        var fieldName = event.currentTarget.id;
        //Helper Method for sorting
        helper.sortBy(component, helper, fieldName);
        //Set Sort field
        component.set("v.selectedTabsoft", fieldName);
        component.set("v.showSpinnerStatus", false);
    },

    //Date validations for one year
    checkDateValue: function(cmp,event, helper){
        var fromdate =cmp.find('fromDateField').get('v.value');
        var enddate =cmp.find('EndDateField').get('v.value');
        var toastReference = $A.get("e.force:showToast");
        if(fromdate != '' && enddate != '') {
            if(fromdate > enddate) {
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 1000,
                    "message" :$A.get("$Label.c.KM_FromDate_Lessthan_Todate"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
                cmp.find('fromDateField').set('v.value', '');
                cmp.find('EndDateField').set('v.value', '');
            }
            else {
                if(fromdate != null) {
                    helper.dateValidation(cmp, fromdate, 'fromDate');
                }
                if(enddate != null) {
                    helper.dateValidation(cmp, enddate, 'EndDate');
                }
            }
        }
    },

    //Action which will enable Line item section in Customer Order Component
    openLineItems: function(component, event, helper) {
        //Get Order Record index
        var index = event.currentTarget.dataset.record;
        //Get the Order record details
        var selectedOrder = component.get("v.orderHistory")[index];
        //Call component event for enabling line item section
        var orderHeaderEvent = component.getEvent("cmpEvent");
        //Set Order record details
        orderHeaderEvent.setParams({"orderDetail": selectedOrder});
        orderHeaderEvent.fire();
    },

    //Action to show filter Options
    showFilterOption:function (cmp, event, helper) {
        var selField = cmp.find('filterField').get('v.value');
        if(selField =='ContactName' || selField =='OrderNumber' || selField =='PONumber' || selField =='HoldCode' || selField =='OrderMode'){
            //enable filter box section
            cmp.set("v.showFilterBox", true);
            //Enable filter box
            cmp.set('v.disableOrderFilterBox',false);
            //enable apply button
            cmp.find('orApplyBtn').set("v.disabled",false);
            //disable order type field
            cmp.set("v.showOrderType", false);
            //diable status field
            cmp.set("v.showStatusList", false);
            //diable date field
            cmp.set("v.showDateFilter", false);
        }
        else if(selField == 'OrderType'){
            //enable order type field
            cmp.set("v.showOrderType", true);
            //diable statuc field
            cmp.set("v.showStatusList", false);
            //disabled date fiel
            cmp.set("v.showDateFilter", false);
            //disable filter box
            cmp.set("v.showFilterBox", false);
            //enable apply button
            cmp.find('orApplyBtn').set('v.disabled',false);
        }
            else if(selField == 'Status'){
                //enable status field
                cmp.set("v.showStatusList", true);
                //diabled order type field
                cmp.set("v.showOrderType", false);
                //disable filter box
                cmp.set("v.showFilterBox", false);
                //disable date field
                cmp.set("v.showDateFilter", false);
                //enable apply button
                cmp.find('orApplyBtn').set('v.disabled',false);
            }
                else if(selField == 'OrderDate'){
                    //enable date fields
                    cmp.set("v.showDateFilter", true);
                    //diable status field
                    cmp.set("v.showStatusList", false);
                    //disable order type
                    cmp.set("v.showOrderType", false);
                    //disable filter box
                    cmp.set("v.showFilterBox", false);
                    //enable apply button
                    cmp.find('orApplyBtn').set('v.disabled',false);
                }
                    else {
                        //Set all fields to blank if filter by option is selected
                        cmp.set("v.showDateFilter", false);
                        cmp.set("v.showStatusList", false);
                        cmp.set("v.showOrderType", false);
                        cmp.set("v.showFilterBox", true);
                        cmp.find('orApplyBtn').set('v.disabled',true);
                        cmp.set('v.disableOrderFilterBox',true);
                        cmp.set("v.OrderFilterBox", '');
                        cmp.set("v.fromDate", '');
                        cmp.set("v.toDate", '');
                    }
    },

    //Filter action for SHIPTO CONTACT crelated list
    applyOrderFilter:function (cmp, event, helper) {
        cmp.set("v.showSpinnerStatus", true);
        helper.clearTableMessage(cmp);
        //enable clear button
        cmp.find('orClearBtn').set('v.disabled',false);
        var toastReference = $A.get("e.force:showToast");
        //search box value
        var searchKey = cmp.get("v.OrderFilterBox");
        //filter field value
        var selField = cmp.find('filterField').get('v.value');
        //All records
        var allRecords = cmp.get("v.orderHistory");
        var tempArray = [];
        var setOrderType = new Set();
        var setOfStatus = new Set();

        //All selected order type values from drop down
        if(selField == 'OrderType'){
            var selectedTypes = cmp.find("OrderTypeforOH").get("v.selectedOptions");
            for(var j = 0; j < selectedTypes.length ; j++){
                var item=selectedTypes[j];
                setOrderType.add(item.Id.toUpperCase());
            }
        }
        //All selected status values from drop down
        if(selField == 'Status'){
            var selectedStatus = cmp.find("OrderStatusesId").get("v.selectedOptions");
            for(var j = 0; j < selectedStatus.length ; j++){
                var item=selectedStatus[j];
                setOfStatus.add(item.Id.toUpperCase());
            }
        }
        //iteration to filter the records based on selected filter options
        for(var i=0; i < allRecords.length; i++){
            if(selField == 'ContactName'){

                if((allRecords[i].ContactName && allRecords[i].ContactName.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField == 'OrderNumber'){
                if((allRecords[i].OrderNumber && allRecords[i].OrderNumber.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField == 'PONumber'){
                if((allRecords[i].PONumber && allRecords[i].PONumber.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField == 'Status'){
                if(setOfStatus.has(allRecords[i].Status.toUpperCase())){
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField == 'HoldCode'){
                if((allRecords[i].HoldCode && allRecords[i].HoldCode.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField == 'OrderMode'){
                if((allRecords[i].OrderMode && allRecords[i].OrderMode.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField == 'OrderDate'){
                if(cmp.get('v.fromDate')=='' || cmp.get('v.toDate')==''){
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    cmp.set("v.showSpinnerStatus", false);
                }else{
                    if(allRecords[i].OrderDate != '')
                        var frmDt = cmp.get("v.fromDate");
                    var toDt = cmp.get("v.toDate") != ''?cmp.get("v.toDate"):new Date();
                    var orDate = new Date(allRecords[i].OrderDate);
                    if(new Date(orDate) > new Date(frmDt) && new Date(orDate) < new Date(toDt)){
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            if(selField == 'OrderType'){
                if(allRecords[i].OrderType && setOrderType.has(allRecords[i].OrderType.toUpperCase())){
                    tempArray.push(allRecords[i]);
                }
            }
        }
        if(tempArray.length == 0){
            cmp.set("v.orderHistory", tempArray);
            cmp.set("v.totalAmount", 0);
            //cmp.find('orApplyBtn').set('v.disabled', true);
            // toastReference.setParams({
            //     "type" : "Error",
            //     "title" : "",
            //     "duration": 1000,
            //     "message" : $A.get("$Label.c.KM_No_Records_found"),
            //     "mode" : "dismissible"
            // });
            //toastReference.fire();
            helper.setNoRecordFoundMessage(cmp);
            cmp.set("v.showSpinnerStatus", false);
            return;
        }
        cmp.set("v.orderHistory", tempArray);
        var totalAmount = helper.calculateTotal(cmp);
        cmp.set("v.totalAmount", totalAmount);
        cmp.set("v.showSpinnerStatus", false);
    },

    //Action to clear the filtered records and assign the original record list
    clearFilterBox: function(component, event, helper) {
        //Empty Order filterbox
        component.set('v.OrderFilterBox', '');
        component.set('v.showFilterBox', true);
        //diabled filter box
        component.set('v.disableOrderFilterBox', true);
        //Clear filter field
        component.find("filterField").set('v.value', '');
        component.set("v.showOrderType", false);
        component.set("v.showStatusList", false);
        //Order list assignment
        var orders = component.get('v.allOrderHistory');
        component.set("v.orderHistory", orders);
        //disable apply button
        component.find('orApplyBtn').set('v.disabled', true);
        //diabled clear button
        component.find('orClearBtn').set('v.disabled', true);
        //Clear date fields
        component.set('v.fromDate', '');
        component.set('v.toDate', '');
        //Calculate Total
        var amt = helper.calculateTotal(component);
        //Assign amount
        component.set("v.totalAmount", amt);
        //Show filter box section
        //component.set("v.showFilterBox", true);
        //Disable date fields
        component.set("v.showDateFilter", false);
        helper.clearTableMessage(component);
    },
})