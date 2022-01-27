({
    //Initial action to get the Order History by sku records
    doInit : function(component, event, helper) {
        helper.showSpinner(component);
        var fromDate = new Date();
        var toDate = new Date();
        var finaldate = new Date();
        var yearDate = new Date();
        //Last 6 month date
        fromDate.setMonth(fromDate.getMonth() - 6);
        yearDate.setMonth(yearDate.getMonth() - 12);

        component.find('orderFromDateInput').set('v.min', helper.getFormattedDate(yearDate));
        component.find('orderFromDateInput').set('v.max', helper.getFormattedDate(finaldate));
        component.find('orderToDateInput').set('v.min', helper.getFormattedDate(yearDate));
        component.find('orderToDateInput').set('v.max', helper.getFormattedDate(finaldate));

        let fromDateFormatted = helper.getFormattedDate(fromDate);
        let toDateFormatted = helper.getFormattedDate(toDate);
        component.set('v.fromDate', fromDateFormatted);
        component.set('v.toDate', toDateFormatted);

        // Controller method to get the order history by sku records
        helper.fetchReorderData(component, helper, fromDateFormatted, toDateFormatted);
        helper.setBackButtonData(component);
    },

    //Apply the Search Method
    applyReOrderFilter: function(component, event, helper) {
        var fromDate = component.get("v.fromDate");
        var toDate = component.get("v.toDate");
        if (fromDate == '' || toDate == '') {
            component.set('v.showWarning', true);
            component.set(
                'v.warningMessage',
                $A.get('$Label.c.KM_Invalid_Order_Date_Range_Warning_Msg')
            );
        }
        else {
            helper.showSpinner(component);
            helper.fetchReorderData(component, helper, fromDate, toDate);
        }
    },

    //Sorting Method to sort Table records
    sorter: function(component, event, helper) {
        //Selected Header Id
        var fieldName = event.currentTarget.id;
        helper.sortBy(component,helper, fieldName);
        component.set("v.selectedTabsoft", fieldName);
    },

    //Filter Action to enable fields as per selection
    showFilterOption:function(cmp, event, helper) {
        //Empty all fields
        var Selectedoptions=cmp.find('reOrderField').get('v.value');
        if(Selectedoptions == 'OrderNum' || Selectedoptions == 'OrderLineNum' || Selectedoptions == 'ProductName'){
            //enable filter box
            cmp.set('v.showFilterBox',true);
            //enable filter box
            cmp.set('v.disableFilterBox', false);
            //enable apply filter button
            cmp.set('v.disableApplyBtn', false);
            //disabled order tye fields
            cmp.set('v.showOrderTypeFltr',false);
            //diable status fields
            cmp.set('v.showStatusFltr',false);
            //diable status fields
            cmp.set('v.showDateFltr',false);
            return;
        }
        if(Selectedoptions=='OrderDate'){
            //Enable Apply button
            cmp.set('v.disableApplyBtn', false);
            //disable filter box
            cmp.set('v.showFilterBox',false);
            //disable order type field
            cmp.set('v.showOrderTypeFltr',false);
            //disable status fields
            cmp.set('v.showStatusFltr',false);
            //disable date fields
            cmp.set('v.showDateFltr',true);
            return;
        }
        if(Selectedoptions=='NextStatus'){
            //enable apply button
            cmp.set('v.disableApplyBtn', false);
            //disable filter box
            cmp.set('v.showFilterBox',false);
            //Hide order type field
            cmp.set('v.showOrderTypeFltr',false);
            //show status field
            cmp.set('v.showStatusFltr',true);
            //hide date field
            cmp.set('v.showDateFltr',false);
            return;
        }
        if(Selectedoptions== 'OrderType'){
            //enable apply button
            cmp.set('v.disableApplyBtn', false);
            //Hide filter box
            cmp.set('v.showFilterBox',false);
            //Show order type field
            cmp.set('v.showOrderTypeFltr',true);
            //Hide status field
            cmp.set('v.showStatusFltr',false);
            //Hode date field
            cmp.set('v.showDateFltr',false);
            return;
        }
        //Clear all fields if no option selected
        cmp.set('v.fromTableDate','');
        cmp.set('v.toTableDate','');
        cmp.set('v.disableFilterBox', true);
        cmp.set('v.disableApplyBtn', true);
        cmp.set('v.showFilterBox',true);
        cmp.set('v.showDateFltr',false);
        cmp.set('v.showStatusFltr',false);
        cmp.set("v.reOrderFilterBox",'');
        cmp.set('v.showOrderTypeFltr',false);
    },

    //Action called whn the filter is applied to the table
    applyFilterToTable:function(cmp,event, helper){
        helper.showSpinner(cmp);
        helper.clearTableMessage(cmp);
        cmp.set('v.disableClearBtn', false);
        var toastReference = $A.get("e.force:showToast");
        var selField = cmp.find('reOrderField').get('v.value');
        var searchKey = cmp.get("v.reOrderFilterBox");
        var allRecords = cmp.get("v.reOrderHistory");
        var tempArray = [];
        var setOrderType = new Set();
        var setOfStatus = new Set();
        //Set of Order Types
        if(selField == 'OrderType'){
            var selectedTypes = cmp.find("OrderTypeId").get("v.selectedOptions");
            for(var j = 0; j < selectedTypes.length ; j++){
                var item=selectedTypes[j];
                setOrderType.add(item.Id.toUpperCase());
            }
        }
        //Set of Status selected
        if(selField == 'NextStatus'){
            var selectedStatus = cmp.find("OrderStatusesId").get("v.selectedOptions");
            for(var j = 0; j < selectedStatus.length ; j++){
                var item=selectedStatus[j];
                setOfStatus.add(item.Id.toUpperCase());
            }
        }
        if (selField == 'OrderType' && setOrderType.has('TC UNBILLED')) {
            var ordHistoryObj = {};
            //Ship To Number
            var shipToNumber = cmp.get("v.ShipToNumber");
            //Controller Method to perform OFM API Action
            var action = cmp.get("c.getOrderHistoryList");
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
                        let ordHisResData = actionData.responseDetail;
                        if(ordHisResData){
                            ordHisResData.forEach(function(eachOrdHisRec){
                                ordHistoryObj[eachOrdHisRec.OrderNumber]= eachOrdHisRec.Status;
                            });
                        }
                        for(var i=0; i < allRecords.length; i++){
                            if (allRecords[i].OrderType == 'TC' && allRecords[i].NextStatus == 'Shipped' 
                                && allRecords[i].T9OrderNum == "0" && ordHistoryObj[allRecords[i].OrderNum] != 'COMPLETED') {
                                tempArray.push(allRecords[i]);
                            }
                            if(allRecords[i].OrderType && setOrderType.has(allRecords[i].OrderType.toUpperCase())){
                                tempArray.push(allRecords[i]);
                            }
                        }
                        if(tempArray.length == 0){
                            cmp.set("v.reOrderHistory", tempArray);
                            helper.setNoRecordFoundMessage(cmp);
                            cmp.set("v.hasT9EligibleOrders", helper.hasT9EligibleOrders(tempArray));
                            helper.deselectT9Orders(cmp, event, helper);
                            helper.hideSpinner(cmp);
                            return;
                        }
                        cmp.set('v.disableApplyBtn', true);
                        cmp.set('v.disableClearBtn', false);
                        cmp.set("v.reOrderHistory", tempArray);
                        cmp.set("v.hasT9EligibleOrders", helper.hasT9EligibleOrders(tempArray));
                        helper.deselectT9Orders(cmp, event, helper);
                        helper.hideSpinner(cmp);
                        
                    }
                }
                else if (state === 'ERROR') {
                    let errors = response.getError();
                    helper.showToast("", errors[0].message, "error", 5000);
                    component.set("v.tableMessage", errors[0].message);
                }
            });
            $A.enqueueAction(action);
        }else{
            //Iteration for the filtered records as per the filter selection
            for(var i=0; i < allRecords.length; i++){
                if(selField == 'OrderNum'){
                    if((allRecords[i].OrderNum && allRecords[i].OrderNum.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                        tempArray.push(allRecords[i]);
                    }
                }
                if(selField == 'OrderLineNum'){
                    if((allRecords[i].OrderLineNum && allRecords[i].OrderLineNum.toUpperCase().indexOf(searchKey.toUpperCase()) != -1)){
                        tempArray.push(allRecords[i]);
                    }
                }
                if(selField == 'ProductName'){
                    if((allRecords[i].ProductName && allRecords[i].ProductName.toUpperCase().indexOf(searchKey.toUpperCase()) != -1) || (allRecords[i].ProductNo && allRecords[i].ProductNo.indexOf(searchKey) != -1)){
                        tempArray.push(allRecords[i]);
                    }
                }
                if(selField == 'NextStatus'){
                    if(setOfStatus.has(allRecords[i].NextStatus.toUpperCase()))
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
                if(selField == 'OrderDate'){
                    if(cmp.get('v.fromTableDate')=='' || cmp.get('v.toTableDate')==''){
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 5000,
                            "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        helper.hideSpinner(cmp);
                    }else{
                        if(allRecords[i].OrderDate != '')
                            var frmDt = cmp.get("v.fromTableDate");
                        var toDt = cmp.get("v.toTableDate") != null?cmp.get("v.toTableDate"):new Date();
                        var orDate = new Date(allRecords[i].OrderDate);
                        if(new Date(orDate) > new Date(frmDt) && new Date(orDate) < new Date(toDt)){
                            tempArray.push(allRecords[i]);
                        }  }
                }
                if(selField == 'OrderType'){
                    // if (setOrderType.has('TC UNBILLED')) {
                    //     if (allRecords[i].OrderType == 'TC' && allRecords[i].NextStatus == 'Shipped'
                    //         && allRecords[i].T9OrderNum == "0"
                    //     ) {
                    //         tempArray.push(allRecords[i]);
                    //     }
                    // }
                    if(allRecords[i].OrderType && setOrderType.has(allRecords[i].OrderType.toUpperCase())){
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            if(tempArray.length == 0){
                cmp.set("v.reOrderHistory", tempArray);
                helper.setNoRecordFoundMessage(cmp);
                cmp.set("v.hasT9EligibleOrders", helper.hasT9EligibleOrders(tempArray));
                helper.deselectT9Orders(cmp, event, helper);
                helper.hideSpinner(cmp);
                return;
            }
            cmp.set('v.disableApplyBtn', true);
            cmp.set('v.disableClearBtn', false);
            cmp.set("v.reOrderHistory", tempArray);
            cmp.set("v.hasT9EligibleOrders", helper.hasT9EligibleOrders(tempArray));
            helper.deselectT9Orders(cmp, event, helper);
            helper.hideSpinner(cmp);
        }
        
    },

    //Date validation for the field if selected year is one year past
    checkDateValidation: function(cmp,event, helper){
        var fromdate =cmp.find('fromField').get('v.value');
        var enddate =cmp.find('EndField').get('v.value');
        var toastReference = $A.get("e.force:showToast");
        if(fromdate!='' && enddate!=''){
            if(fromdate>enddate){
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 1000,
                    "message" :$A.get("$Label.c.KM_FromDate_Lessthan_Todate"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
                cmp.find('fromField').set('v.value','');
                cmp.find('EndField').set('v.value');
            }
            else{
                if(fromdate != null) {
                    helper.dateValidations(cmp,fromdate,'fromDate', helper);
                }
                if(enddate != null) {
                    helper.dateValidations(cmp,enddate, 'EndDate', helper);
                }
            }
        }
    },    
    checkAllT9 : function(component, event, helper) {
        if (component.get('v.roSelectedRecords').length > 0 && event.getSource().get("v.checked")) {
            component.set('v.showWarning', true);
            component.set('v.warningMessage', $A.get('$Label.c.KM_RO_Checkbox_Uncheck_Warning'));
            var orders = component.find("t9Checkbox");
            orders.forEach(function(order) {
                order.set('v.checked', false);
            });
            component.find("t9CheckAllInput").set("v.checked", false);
        }
        else {
            let currentValue = event.getSource().get("v.checked");
            let t9SelectedRecords = component.get("v.t9SelectedRecords");
            let currentReorderHistory = component.get("v.reOrderHistory");
            if (currentValue) {
                // Clear t9SelectedRecords
                t9SelectedRecords = [];
                // Filter currentReorderHistory and add the values again
                for (let i = 0; i < currentReorderHistory.length; i++) {
                    let order = currentReorderHistory[i];
                    if (helper.isT9Eligible(order)) {
                        t9SelectedRecords.push(currentReorderHistory[i]);
                    }
                }
                helper.calculateTotalAmountSum(component, t9SelectedRecords);
            }
            else {
                // Clear t9SelectedRecords
                t9SelectedRecords = [];
                let totalAmount = 0;
                component.set('v.totalAmount', totalAmount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","));
            }
            // Set t9Checkbox to currentValue
            component.find("t9Checkbox").forEach(checkbox => {
                if (!checkbox.get("v.disabled")) {
                    checkbox.set("v.checked", currentValue);
                }
            });
            component.set("v.t9SelectedRecords", t9SelectedRecords);
        }
    },

    //Action to clear all fields and assign default list
    clearReOrderBox: function(component, event, helper) {
        helper.showSpinner(component);
        var initArray = [];
        //disabled apply button
        component.set('v.disableApplyBtn', true);
        //disable clear button
        component.set('v.disableClearBtn', true);
        //clear filter type field
        //component.find('reOrderField').set('v.value','');
        component.set("v.filterType", 'Filter By');
        //Clear filter box
        component.set("v.reOrderFilterBox",'');
        //Show filter box
        component.set('v.showFilterBox',true);
        //diabled filter box
        component.set('v.disableFilterBox', true);
        //Assign Original list
        var reOrders = component.get('v.allReOrderHistory');
        component.set("v.reOrderHistory", reOrders);
        component.set("v.hasT9EligibleOrders", helper.hasT9EligibleOrders(reOrders));
        //Clear date fields
        if (component.find('fromField') != undefined && component.find('EndField') != undefined) {
            component.set('v.fromTableDate','');
            component.set('v.toTableDate','');
        }
        //Hide date fiels
        component.set('v.showDateFltr',false);
        //Hide status field
        component.set('v.showStatusFltr',false);
        //Hide Order Type field
        component.set('v.showOrderTypeFltr',false);
        component.set('v.selectedOptions', initArray);
        component.set('v.selectedLabel', '');
        component.find("t9CheckAllInput").set("v.checked", false);
        component.find("t9Checkbox").forEach(checkbox => {
            if (!checkbox.get("v.disabled")) {
                checkbox.set("v.checked", false);
            }
        });
        component.set("v.t9SelectedRecords", []);
        helper.clearTableMessage(component);
        helper.hideSpinner(component);
    },

    //Action for Excel export
    downloadcsv:function(component, event, helper) {
        // get the Records [contact] list from 'ListOfContact' attribute
        var stockData = component.get("v.reOrderHistory");

        // call the helper function which "return" the CSV data as a String
        var csv = helper.convertArrayOfObjectsToCSV(component,stockData);
         if (csv == null) {return;}

        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####
        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self'; //
        hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv]
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click(); // using click() js function to download csv file
    },

    dochnagesondates :function(component, event, helper) {
        component.set('v.toDate', '');

        var selectedFromDate=new Date(component.get('v.fromDate'));
        selectedFromDate.setHours(0,0,0,0);

        var minDateValue = new Date(component.find('orderFromDateInput').get('v.min'));
        minDateValue.setHours(0,0,0,0);

        var maxDateValue = new Date(component.find('orderFromDateInput').get('v.max'));
        maxDateValue.setHours(0,0,0,0);

        // Validate date and clear if invalid
        if (selectedFromDate < minDateValue || selectedFromDate > maxDateValue) {
            component.set('v.fromDate', '');
            component.set('v.disableToDateField', true);
        }

        let selectedFromDateNew=new Date(component.get('v.fromDate'));
        if(selectedFromDateNew instanceof Date && !isNaN(selectedFromDateNew)) {
            component.set('v.disableToDateField', false);
            component.find('orderToDateInput').set('v.min', helper.getFormattedDate(selectedFromDateNew));
            var fromDates = new Date();
            fromDates.setMonth(fromDates.getMonth() - 6);

            if (selectedFromDateNew < fromDates) {
                selectedFromDateNew.setMonth(selectedFromDateNew.getMonth() + 6);
                component.find('orderToDateInput').set('v.max', helper.getFormattedDate(selectedFromDateNew));
                component.set('v.toDate', helper.getFormattedDate(selectedFromDateNew));
            }
            else {
                component.find('orderToDateInput').set('v.max', helper.getFormattedDate(new Date()));
                component.set('v.toDate', helper.getFormattedDate(new Date()));
            }
        }
        else {
            var oneYearDate=new Date();
            oneYearDate.setMonth(oneYearDate.getMonth() - 12);
            component.find('orderToDateInput').set('v.min', helper.getFormattedDate(oneYearDate));
            component.find('orderToDateInput').set('v.max', helper.getFormattedDate(new Date()));
        }
    },

    toDateFieldChanged: function (component, event, helper) {
        var selectedDate = component.get('v.toDate');
        var minDateValue = new Date(component.find('orderToDateInput').get('v.min'));
        var maxDateValue = new Date(component.find('orderToDateInput').get('v.max'));

        if (selectedDate != '' && selectedDate != null) {
            var toDate = new Date(selectedDate);
            toDate.setHours(0,0,0,0);
            if (toDate < minDateValue || toDate > maxDateValue) {
                component.set('v.toDate', '');
            }
        }
    },
    sendEmailWithSelectedRecords : function(component, event, helper) {
        let emailSelectedRecords = new Array();
        emailSelectedRecords = component.get('v.emailSelectedRecords');
        var shipToNum = component.get('v.ShipToNumber');
        var toastReference = $A.get("e.force:showToast");
        helper.showSpinner(component);
        var action = component.get("c.sendEmailWithSelectedOrders");
        action.setParams({selectedOrders : emailSelectedRecords,shipToNumber:shipToNum});
        action.setCallback(this, function(response){
            var state= response.getState();
            helper.hideSpinner(component);
            if(state === 'SUCCESS'){
                component.set('v.emailSelectedRecords',new Array());
                // Set emailCheckboxs to false
                component.find("emailCheckbox").forEach(checkbox => {
                    if(checkbox.get("v.checked")){
                        checkbox.set("v.checked", false);
                    }
                });
                component.find("emailCheckAllInput").set("v.checked", false);
                toastReference.setParams({
                    "type" : "Success",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_Email_Success_Msg"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            }else if(state === 'INCOMPLETE'){
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_API_Error_Message"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            }else if(state === 'ERROR'){
                //generic error handler
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error message: " + errors[0].message+" ::Error Details: " + errors[0].stackTrace);
                        throw new Error("Error: "+errors[0].message);
                    }
                }else{
                    throw new Error("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    checkAllEmail : function(component, event, helper) {
        let currentValue = event.getSource().get("v.checked");
        let emailSelectedRecords = new Array();
        emailSelectedRecords = component.get('v.emailSelectedRecords');
        let currentReorderHistory = component.get("v.reOrderHistory");
        if (currentValue) {
            // Clear emailSelectedRecords
            emailSelectedRecords = new Array();
            // Filter currentReorderHistory and add the values again
            for (let i = 0; i < currentReorderHistory.length; i++) {
                emailSelectedRecords.push(currentReorderHistory[i]);
            }
        }
        else {
            // Clear emailSelectedRecords
            emailSelectedRecords = new Array();
        }
        // Set emailCheckbox to currentValue
        component.find("emailCheckbox").forEach(checkbox => {
            checkbox.set("v.checked", currentValue);
        });
        component.set("v.emailSelectedRecords", emailSelectedRecords);
    },
    emailCheckboxSelectDeselect : function(component, event, helper) {
        var emailSelected = event.getSource().get("v.value");
        var emailSelectedRecords = new Array();
        emailSelectedRecords = component.get('v.emailSelectedRecords');
        if (event.getSource().get("v.checked")) {
            emailSelectedRecords.push(emailSelected);
        }
        else {
            let removeIndex = emailSelectedRecords.map(function(emailRec) {
                return emailRec.ProductNo;
            }).indexOf(emailSelected.ProductNo);
            emailSelectedRecords.splice(removeIndex, 1);
        }
        component.set('v.emailSelectedRecords', emailSelectedRecords);
    },
    roCheckboxSelectDeselect: function(component, event, helper) {
        if (component.get('v.t9SelectedRecords').length > 0 && event.getSource().get("v.checked")) {
            component.set('v.showWarning', true);
            component.set('v.warningMessage', $A.get('$Label.c.KM_T9_Checkbox_Uncheck_Warning'));
            var orders = component.find("roCheckbox");
            orders.forEach(function(order) {
                order.set('v.checked', false);
            });
        }
        else {
            var roSelected = event.getSource().get("v.value");
            var roSelectedRecords = [];
            roSelectedRecords = component.get('v.roSelectedRecords');
            if (event.getSource().get("v.checked")) {
                roSelectedRecords.push(roSelected);
            }
            else {
                let removeIndex = roSelectedRecords.map(function(ro) {
                    return ro.ProductNo;
                }).indexOf(roSelected.ProductNo);
                roSelectedRecords.splice(removeIndex, 1);
            }
            component.set('v.roSelectedRecords', roSelectedRecords);
        }
    },

    t9CheckboxSelectDeselect: function(component, event, helper) {
        if (component.get('v.roSelectedRecords').length > 0 && event.getSource().get("v.checked")) {
            component.set('v.showWarning', true);
            component.set('v.warningMessage', $A.get('$Label.c.KM_RO_Checkbox_Uncheck_Warning'));
            var orders = component.find("t9Checkbox");
            orders.forEach(function(order) {
                order.set('v.checked', false);
            });
        }
        else {
            var t9Selected = event.getSource().get("v.value");
            var t9SelectedRecords = [];
            var totalAmount = 0;
            if(component.get('v.totalAmount')) {
                totalAmount = parseFloat(component.get('v.totalAmount').replace(/,/g, ''));
            }
            t9SelectedRecords = component.get('v.t9SelectedRecords');
            if (event.getSource().get("v.checked")) {
                t9SelectedRecords.push(t9Selected);
                totalAmount += parseFloat(t9Selected.Amount.replace(/,/g, ''));
            }
            else {
                let removeIndex = t9SelectedRecords.map(function(ro) {
                    return ro.ProductNo;
                }).indexOf(t9Selected.ProductNo);
                t9SelectedRecords.splice(removeIndex, 1);
                totalAmount -= parseFloat(t9Selected.Amount.replace(/,/g, ''));
            }
            component.set('v.t9SelectedRecords', t9SelectedRecords);
            component.set('v.totalAmount', totalAmount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","));
        }
    },

    openReorderPATable: function(component, event, helper) {
        helper.getCartDetails(component, event, helper, 'SO');
    },

    closeWarningModal: function(component, event, helper) {
        component.set('v.showWarning', false);
    },

    createT9Order: function(component, event, helper) {
        helper.getCartDetails(component, event, helper, 'T9');
    },
    
    backToOrders: function(component, event, helper) {
        component.set('v.showPAScreen', false);
        component.set('v.showOrderHistoryBySKUInfo', true);
        var initArray = [];
        component.set('v.roSelectedRecords', initArray);
        component.set('v.t9SelectedRecords', initArray);
    },

    handleDifferentShipToT9Message : function(component, event, helper) {
        component.set("v.showDifferentShipToT9Message", false);
    },

})