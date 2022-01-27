({
    //Action to enable different field as per the selection in filter field drop down
    showLineFilterOption : function (component, event, helper) {
        component.set("v.showSpinner", true);
        // Emptying fields initially
        component.set("v.lineFilterBox", '');
        component.set('v.linefromDate', '');
        component.set('v.linetoDate', '');
        var selectedOption = component.find('lineFilterField').get('v.value');
        if (selectedOption == 'ProductName' || selectedOption == 'ProductNum') {
            //Show filer box
            component.set("v.showLineFilterBox", true);
            //enable filter box
            component.set('v.disableLineFilterBox', false);
            //Enable Apply button
            component.find('applyLineFltr').set('v.disabled', false);
            //Hiding Date fields
            component.set("v.showLineDateFilter", false);
            //Hide Status field
            component.set("v.showLineStatus", false);
            component.set("v.showSpinner", false);
        }
        else if (selectedOption == 'Status') {
            //Show Status field
            component.set("v.showLineStatus", true);
            //Hide Filter box
            component.set("v.showLineFilterBox", false);
            //Hide Date fields
            component.set("v.showLineDateFilter", false);
            //Enable Apply button
            component.find('applyLineFltr').set('v.disabled', false);
            component.set("v.showSpinner", false);
        }
        else if(
            selectedOption == 'ShipmentDate'
            ||
            selectedOption == 'UserRequestedDate'
            ||
            selectedOption == 'AvailabilityDate'
        ) {
            //Hide status field
            component.set("v.showLineStatus", false);
            //Hide filter box
            component.set("v.showLineFilterBox", false);
            //Show date fields
            component.set("v.showLineDateFilter", true);
            //Enable Apply button
            component.find('applyLineFltr').set('v.disabled', false);
            //Show Date Fields
            component.set("v.showLineDateFilter", true);
            component.set("v.showSpinner", false);
        }
        else {
            //If No Condition is satisified Disabling all options
            component.find('applyLineFltr').set('v.disabled', true);
            component.set("v.showLineFilterBox", true);
            component.set("v.showLineStatus", false);
            component.set("v.showLineDateFilter", false);
            component.set('v.disableLineFilterBox',true);
            component.set("v.showSpinner", false);
        }
    },

    dateValidation: function(component, event, helper){
        var fromdate =component.find('LinefromDateField').get('v.value');
        var enddate =component.find('LineEndDateField').get('v.value');
        var toastReference = $A.get("e.force:showToast");
        if (fromdate !='' && enddate!=''){
            if (fromdate>enddate){
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 1000,
                    "message" : $A.get("$Label.c.KM_FromDate_Lessthan_Todate"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
                component.find('LinefromDateField').set('v.value','');
                component.find('LineEndDateField').set('v.value','');
            }
            else {
                if (fromdate != null)
                    //call helper function with pass fromDate
                    helper.invoiceDateValidation(component, fromdate, 'fromDate');
                if (enddate != null)
                    //call helper function with pass Enddate
                    helper.invoiceDateValidation(component, enddate, 'EndDate');
            }
        }
    },

    //Action to Filter Line Items data
    applyLineFilter: function(cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        cmp.set('v.disableLineClearBtn', false);
        var toastReference = $A.get("e.force:showToast");
        var searchString = cmp.get("v.lineFilterBox");
        var selLineField = cmp.find('lineFilterField').get('v.value');
        var allRecords = cmp.get("v.lineItems");
        var tempArray = [];
        var setOfLineStatus = new Set();
        //If loop to take the all selected statuses
        if (selLineField == 'Status') {
            var selectedStatus = cmp.find("LineStatusesId").get("v.selectedOptions");
            for (var j = 0; j < selectedStatus.length ; j++) {
                var item=selectedStatus[j];
                setOfLineStatus.add(item.Id.toUpperCase());
            }
        }
        //Iteration to take all the records and filter with corresponding field values
        for (var i=0; i < allRecords.length; i++) {
            //If loop Product name is selected
            if (selLineField == 'ProductName') {
                if (
                    (allRecords[i].ProductName)
                    &&
                    (allRecords[i].ProductName.toUpperCase().indexOf(searchString.toUpperCase()) != -1)
                ) {
                    tempArray.push(allRecords[i]);
                }
            }
            //If loop for Product number selected
            if (selLineField == 'ProductNum') {
                if(
                    (allRecords[i].ProductNum)
                    &&
                    (allRecords[i].ProductNum.toUpperCase().indexOf(searchString.toUpperCase()) != -1)
                ) {
                    tempArray.push(allRecords[i]);
                }
            }
            //if loop for the status selection
            if (selLineField == 'Status') {
                if (setOfLineStatus.has(allRecords[i].Status.toUpperCase())) {
                    tempArray.push(allRecords[i]);
                }
            }
            //if shipment date is selected
            if (selLineField == 'ShipmentDate') {
                if (cmp.get('v.linetoDate') == '' || cmp.get('v.linetoDate') == '') {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
                else {
                    if (allRecords[i].ShipmentDate != '') {
                        var frmDt = cmp.get("v.linefromDate");
                    }
                    var toDt = cmp.get("v.linetoDate") != null ? cmp.get("v.linetoDate") : new Date();
                    var shipDate = new Date(allRecords[i].ShipmentDate);
                    if (new Date(shipDate) > new Date(frmDt) && new Date(shipDate) < new Date(toDt)){
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            //if Requested date is selected
            if (selLineField == 'UserRequestedDate') {
                if (cmp.get('v.linetoDate') == '' || cmp.get('v.linetoDate') == '') {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
                else{
                    if (allRecords[i].UserRequestedDate != '') {
                        var frmDt = cmp.get("v.linefromDate");
                    }
                    var toDt = cmp.get("v.linetoDate") != null ? cmp.get("v.linetoDate") : new Date();
                    var reqDate = new Date(allRecords[i].UserRequestedDate);
                    if (new Date(reqDate) > new Date(frmDt) && new Date(reqDate) < new Date(toDt)) {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            //If available date is selected
            if (selLineField == 'AvailabilityDate') {
                if (cmp.get('v.linetoDate') == '' || cmp.get('v.linetoDate') == '') {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
                else {
                    if (allRecords[i].AvailabilityDate != '') {
                        var frmDt = cmp.get("v.linefromDate");
                    }
                    var toDt = cmp.get("v.linetoDate") != null ? cmp.get("v.linetoDate") : new Date();
                    var availDate = new Date(allRecords[i].AvailabilityDate);
                    if (new Date(availDate) > new Date(frmDt) && new Date(availDate) < new Date(toDt)){
                        tempArray.push(allRecords[i]);
                    }
                }
            }
        }
        cmp.set("v.lineItems", tempArray);
        cmp.set("v.showSpinner", false);
    },

    //Action that called if the Clear button clicked
    clearLineBox: function(component, event, helper) {
        //Clearing all the Filter boxes data and assigning original list
        component.set("v.lineFilterBox", '');
        component.set('v.linefromDate', '');
        component.set('v.linetoDate', '');
        component.find('applyLineFltr').set('v.disabled',true);
        component.find('clearLineFltr').set('v.disabled',true);
        component.find("lineFilterField").set('v.value','');
        var allLines = component.get("v.allLineItems");
        component.set('v.lineItems',allLines);
        component.set('v.showLineStatus', false);
        component.set('v.disableLineApplyBtn', false);
        component.set('v.showLineDateFilter',false);
        component.set("v.showLineFilterBox", true);
        component.set('v.disableLineFilterBox',true);
    },

    //Action for Sorting Line Items
    sortLineItems: function(component, event, helper) {
        component.set("v.showSpinner", true);
        //Get the Id of the header clicked
        var fieldName = event.currentTarget.id;
        helper.sortLineItems(component,helper, fieldName);
        component.set("v.sortLineField", fieldName);
        var a = component.get("v.sortLineAsc");
        component.set("v.showSpinner", false);
    },

    navigateToAccountDetails: function(component, event, helper) {
        var navigateToAccountDetailsEvent = component.getEvent("KMNavigateToAccountDetailsEvent");
        navigateToAccountDetailsEvent.fire();
    }

})