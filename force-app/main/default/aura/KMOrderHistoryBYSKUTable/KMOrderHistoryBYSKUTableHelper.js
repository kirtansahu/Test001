({
    fetchReorderData : function(component, helper, fromDate, toDate) {
        var action = component.get("c.getReorderList");
        action.setParams({
            "shipToNum": component.get("v.ShipToNumber"),
            "fromDate": $A.localizationService.formatDate(fromDate, "ddMMyyyy"),
            "toDate": $A.localizationService.formatDate(toDate, "ddMMyyyy")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            let filteredOrders = [];
            let allOrders = [];
            if(state === 'SUCCESS') {
                let auraResponse = response.getReturnValue();
                let actionData = auraResponse.data;
                if (auraResponse.isSuccess) {
                    if (actionData.responseDetail == undefined || actionData.responseDetail.length == 0) {
                        let message = $A.get("$Label.c.KM_No_Records_found");
                        helper.showToast("", message, "info", 2000);
                        component.set("v.tableMessage", message);
                    }
                    else {
                        filteredOrders = actionData.responseDetail;
                        allOrders = actionData.responseDetail;
                        helper.clearTableMessage(component);
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
            component.set("v.reOrderHistory", filteredOrders);
            component.set("v.allReOrderHistory", filteredOrders);
            component.set("v.hasT9EligibleOrders", helper.hasT9EligibleOrders(filteredOrders));
            helper.hideSpinner(component);
            helper.deselectT9Orders(component, event, helper);
        });
        $A.enqueueAction(action);
    },
    setNoRecordFoundMessage : function(component) {
        component.set("v.tableMessage", $A.get("$Label.c.KM_No_Records_found"));
    },

    clearTableMessage : function(component) {
        component.set("v.tableMessage", '');
    },

    //Sorting action for the Records
    sortBy: function(component,helper,field) {
        var sortAsc = component.get("v.sortAsc"),
            sortField = component.get("v.sortField"),
            records = component.get("v.reOrderHistory");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1 ? 0 : (sortAsc ? -1 : 1 ) * ( t2 ? 1 : -1);
        });
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", field);
        component.set("v.reOrderHistory", records);
    },

    //Date validations for the year back selection for the date
    dateValidations:function(cmp, dateVal, dateName, helper){
        var oneYearDt = new Date();
        var formatedDt = new Date(dateVal);
        oneYearDt = oneYearDt.setMonth( oneYearDt.getMonth() - 6);
        if(formatedDt < oneYearDt){
            helper.showToast("", $A.get("$Label.c.KM_Records_Availability_Valid_Msg"), "error", 1000);
            if(dateName == 'fromDate')
                cmp.set('v.fromTableDate', '');
            if(dateName == 'EndDate')
                cmp.set('v.toTableDate', '');
            return;
        }
        if(formatedDt > new Date()){
            helper.showToast("", $A.get("$Label.c.KM_Date_Must_Be_Past"), "error", 1000);
            if(dateName == 'fromDate') {
                cmp.set('v.fromTableDate', '');
            }
            if(dateName == 'EndDate') {
                cmp.set('v.toTableDate', '');
            }
            return;
        }
    },

    showSpinner:function(component) {
        var spinner = component.find("spinnerId");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner:function(component) {
        var spinner = component.find("spinnerId");
        $A.util.addClass(spinner, "slds-hide");
    },

    convertArrayOfObjectsToCSV : function(component, objectRecords){
        var csvStringResult, counter, keys, columnDivider, lineDivider;

        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null || !objectRecords.length) {
            return null;
        }
        // store ,[comma] in columnDivider variabel for sparate CSV values and
        // for start next line use '\n' [new line] in lineDivider varaible
        columnDivider = ',';
        lineDivider =  '\n';
         var temp=[];
        for(var i=0;i<objectRecords.length;i++){
            var result={};
            result['OrderDate'] = objectRecords[i].OrderDate;
            result['OrderNumer'] = objectRecords[i].OrderNum;
            result['UnitSize'] = objectRecords[i].UnitSize;
            result['OrderType'] = objectRecords[i].OrderType;
            result['OrderLineNumber'] = objectRecords[i].OrderLineNum;
            result['ProductName'] = objectRecords[i].ProductName;
            result['ProductNumber'] = objectRecords[i].ProductNo;
            result['UnitSize'] = objectRecords[i].UnitSize.replace('#','');
            result['Quantity'] = objectRecords[i].Quantity;
            result['CustomerPrice'] = objectRecords[i].CustomerPrice;
            result['Amount'] = objectRecords[i].Amount;
            result['NextStatus'] = objectRecords[i].NextStatus;
            temp.push(result);
        }

        // in the keys valirable store fields API Names as a key
        // this labels use in CSV file header
        keys = ['OrderDate','OrderNumer','OrderType','OrderLineNumber','ProductName','ProductNumber','UnitSize','Quantity','CustomerPrice','Amount','NextStatus'];
        //keys=['UnitSize'];
        csvStringResult = '';
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;

        for(var i=0; i < temp.length; i++){
            counter = 0;

            for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;
                // add , [comma] after every String value,. [except first]
                if(counter > 0) {
                    csvStringResult += columnDivider;
                }
               csvStringResult += '"'+ temp[i][skey]+'"';
               counter++;

            }
            csvStringResult += lineDivider;
        }
        // return the CSV formate String
        return csvStringResult;
    },

    createT9Order: function(component, event, helper) {
        var savedOrderDetails = component.get('v.savedOrderDetails');
        helper.setOrderDetails(component);

        if(
            savedOrderDetails == null ||
            Object.keys(savedOrderDetails).length === 0 ||
            Object.keys(savedOrderDetails).length === 1
        ) {
            helper.setOrderProducts(component, helper, false);
            helper.addSelectedItemsToCart(component, event, helper, false);
        }
        else if (savedOrderDetails != null && Object.keys(savedOrderDetails).length > 0) {
            let currentShipTo = component.get('v.newShipToNumber');
            let existingShipTo;
            if (savedOrderDetails.hasOwnProperty('shipToNumber')) {
                existingShipTo = savedOrderDetails.shipToNumber;
            }
            // Different ShipTo
            if (existingShipTo != null && existingShipTo != currentShipTo) {
                if (savedOrderDetails.orderType == 'T9') {
                    component.set("v.showDifferentShipToT9Message", true);
                    return;
                }
                else {
                    component.set('v.oldShipToNumber', existingShipTo);
                    component.set('v.oldShipToName', savedOrderDetails.shipToAlphaName);
                    helper.setOrderProducts(component, helper, false);
                    component.set("v.showShipToPopup", true);
                }
            }
            // Same ShipTo
            else if (existingShipTo == currentShipTo) {
                if (savedOrderDetails.orderType == 'T9') {
                    helper.setOrderProducts(component, helper, true);
                    helper.addSelectedItemsToCart(component, event, helper, true);
                }
                else {
                    helper.setOrderProducts(component, helper, false);
                    component.set('v.showOrderTypePopup', true);
                }
            }
        }
    },

    setOrderDetails : function(component) {
        var accRec = component.get("v.accountRecord");
        var ordDetailObj = {};
        if(accRec != null) {
            component.set('v.newShipToNumber', accRec.ERP_Account_Id__c);
            ordDetailObj['accountId'] = accRec.Id;
            ordDetailObj['shipToNumber'] = accRec.ERP_Account_Id__c;
            ordDetailObj['shipToAlphaName'] = accRec.Account_Alpha_Name__c;
            ordDetailObj['shipToName'] = accRec.Name;
            ordDetailObj['shipToAddressLine1'] = accRec.Address_1__c;
            ordDetailObj['shipToAddressLine2'] = accRec.Address_2__c;
            ordDetailObj['shipToAddressLine3'] = accRec.Address_3__c;
            ordDetailObj['shipToCity'] = accRec.City_f__c;
            ordDetailObj['shipToState'] = accRec.State_f__c;
            ordDetailObj['shipToPostalCode'] = accRec.Zip_Postal_Code_f__c;
            ordDetailObj['shipToCountry'] = accRec.Country__c;
            ordDetailObj['billToNumber'] = accRec.Primary_Bill_To__r.ERP_Account_Id__c;
            ordDetailObj['billToName'] = accRec.Primary_Bill_To__r.Name;
            ordDetailObj['billToAddressLine1'] = accRec.Primary_Bill_To__r.Address_1__c;
            ordDetailObj['billToAddressLine2'] = accRec.Primary_Bill_To__r.Address_2__c;
            ordDetailObj['billToAddressLine3'] = accRec.Primary_Bill_To__r.Address_3__c;
            ordDetailObj['billToCity'] = accRec.Primary_Bill_To__r.City_f__c;
            ordDetailObj['billToState'] = accRec.Primary_Bill_To__r.State_f__c;
            ordDetailObj['billToPostalCode'] = accRec.Primary_Bill_To__r.Zip_Postal_Code_f__c;
            ordDetailObj['billToCountry'] = accRec.Primary_Bill_To__r.Country__c;
        }
        ordDetailObj['orderType'] = 'T9';
        component.set("v.orderDetails", ordDetailObj);
    },

    setOrderProducts : function(component, helper, doFilter) {
        var productData = component.get('v.t9SelectedRecords');
        var t9Products = [];
        let existingProducts = [];
        if (doFilter) {
            existingProducts = helper.getExistingProducts(component);
        }
        for (var i = 0; i < productData.length; i++) {
            if (!existingProducts.includes(this.getOHBySKUCombination(productData[i]))) {
                t9Products.push(
                    {
                        'productName': productData[i].ProductName,
                        'productNumber': productData[i].ProductNo,
                        'unitSize': productData[i].UnitSize,
                        'currencyCode': productData[i].CurrencyCode,
                        'unitPrice': helper.sanitizePriceValue(productData[i].CustomerPrice),
                        'quantity': productData[i].Quantity,
                        'selected': false,
                        'origLineOrderLineNo' : productData[i].OrderLineNum,
                        'origLineOrderNo' : productData[i].OrderNum,
                        'origLineOrderType' : productData[i].OrderType
                    }
                );
            }
        }
        component.set('v.quickOrderData', t9Products);
    },

    getExistingProducts : function(component) {
        let existingProductsFull = component.get("v.savedProducts");
        return existingProductsFull.map(
            productData => this.getOHBySKUCombinationForExisting(productData)
        );
    },

    getOHBySKUCombination : function(productData) {
        return (productData.ProductNo
            + '#'
            + productData.OrderNum
            + '#'
            + productData.OrderLineNum
        );
    },

    getOHBySKUCombinationForExisting : function(productData) {
        return (productData.productNumber
            + '#'
            + productData.origLineOrderNo
            + '#'
            + productData.origLineOrderLineNo
        );
    },

    addSelectedItemsToCart : function(component, event, helper, wasFiltered) {
        component.set("v.showShipToPopup", false);
        var additemsAppEvent = $A.get("e.c:KMAddSelectedItemsToCart");
        if(additemsAppEvent){
            additemsAppEvent.setParams({
                "orderedProducts": component.get('v.quickOrderData'),
                "orderDetails": component.get('v.orderDetails'),
                "replaceProducts": false
            });
            additemsAppEvent.fire();
        }
        helper.showToast(
            "",
            wasFiltered ? $A.get("$Label.c.KM_T9_Products_Added_Message") : $A.get("$Label.c.KM_QO_Items_added_Msg"),
            "Success",
            5000
        );
    },

    getProductDetails: function(component, event, helper) {
        var selectedRecords = [];
        selectedRecords = component.get('v.roSelectedRecords');
        helper.showSpinner(component);
        var productNumbers = [];
        selectedRecords.forEach(function(record){
            productNumbers.push(record.ProductNo)
        });
        var actions=component.get('c.getAvailabiltyInfo');
        actions.setParams({
            productNos : productNumbers,
            shipNumber : component.get('v.ShipToNumber')
        });
        actions.setCallback(this,function(response){
            var state = response.getState();
            if(state === 'SUCCESS') {
                let auraResponse = response.getReturnValue();
                let result = auraResponse.data;
                if (auraResponse.isSuccess) {
                    if (result == null) {
                        helper.showToast("", $A.get("$Label.c.KM_No_Records_found"), "error", 1000);
                        return;
                    }
                    else {
                        //If controller returns zero, we are showing No records Message
                        if (JSON.stringify(result) == '{}') {
                            helper.showToast("", $A.get("$Label.c.KM_Product_Error"), "info", 1000);
                        }
                        else {
                            selectedRecords.forEach(function(record) {
                                var responseInfo = [];
                                responseInfo = result[record.ProductNo];
                                var productDetail = responseInfo[0];
                                if (
                                    productDetail.AVAILABILITYDATE =='undefined'
                                    ||
                                    productDetail.AVAILABILITYDATE == ''
                                    ||
                                    productDetail.AVAILABILITYDATE == null
                                ) {
                                    record['AVAILABILITYDATE'] = 'Not Available';
                                }
                                else {
                                    var yearFormat = new Date(productDetail.AVAILABILITYDATE);
                                    var finalDateFormat = yearFormat.getFullYear() + "/" + (yearFormat.getMonth() + 1) + "/" + yearFormat.getDate();
                                    record['AVAILABILITYDATE'] = finalDateFormat;
                                }
                                //Set values in ProductTab attribute on component.
                                record['AVAILABLEQUANTITY'] = productDetail.AVAILABLEQUANTITY;
                                record['BRANCHPLANT'] = productDetail.BRANCHPLANT;
                                record['enableButton'] = false;
                            });
                            component.set('v.listofproducts', selectedRecords);
                            component.set('v.showOrderHistoryBySKUInfo', false);
                            component.set('v.showPAScreen', true);
                        }
                    }
                }
                else {
                    helper.showToast("", result, "error", 5000);
                }
                helper.hideSpinner(component);
            }
            else if (state === 'ERROR') {
                let errors = response.getError();
                helper.showToast("", errors[0].message, "error", 5000);
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(actions);
    },

    getCartDetails : function(component, event, helper, orderType) {
        var action = component.get("c.getCartData");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set('v.savedOrderDetails', response.getReturnValue().orderDetails);
                component.set('v.savedProducts', response.getReturnValue().productList);
                if (orderType == 'SO') {
                    helper.getProductDetails(component, event, helper);
                }
                else if (orderType== 'T9') {
                    helper.createT9Order(component, event, helper);
                }
            }
            else if(state === 'ERROR'){
                //generic error handler
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        throw new Error("Error: "+errors[0].message);
                    }
                }
                else{
                    throw new Error("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    hasT9EligibleOrders : function(currentReorderHistory) {
        for (let i = 0; i < currentReorderHistory.length; i++) {
            let order = currentReorderHistory[i];
            if (this.isT9Eligible(order)) {
                return true;
            }
        }
        return false;
    },

    isT9Eligible : function(order) {
        return (order.OrderType == 'TC' && order.T9OrderNum == "0" && order.NextStatus == 'Shipped');
    },

    getFormattedDate : function(dateValue) {
        let month = dateValue.getMonth() + 1;
        let date = dateValue.getDate();
        return dateValue.getFullYear()
            + "-"
            + (month < 10 ? '0' + month : month)
            + "-"
            + (date < 10 ? '0' + date : date);
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

    sanitizePriceValue : function(priceValue) {
        if (priceValue != null && priceValue != undefined) {
            priceValue = priceValue.replace(/,/g, '');
        }
        return priceValue;
    },

    calculateTotalAmountSum : function(component, t9SelectedRecords) {
        var total = 0;
        t9SelectedRecords.forEach(function(selectedRecord) {
            total += parseFloat(selectedRecord.Amount.replace(/,/g, ''));
        });
        component.set('v.totalAmount', total.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","));
    },

    deselectT9Orders: function(component, event, helper) {
        var orders = component.find("t9Checkbox");
        if(orders) {
            orders.forEach(function(order) {
                order.set('v.checked', false);
            });
            component.find("t9CheckAllInput").set("v.checked", false);
        }
        var t9SelectedRecords = [];
        let totalAmount = 0;
        component.set('v.totalAmount', totalAmount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","));
        component.set("v.t9SelectedRecords", t9SelectedRecords);
    },

    setBackButtonData : function(component){
        var accRec = component.get("v.accountRecord");
        var backBtnData = {};
        backBtnData['tabAuraId'] = "customerOrdersId";
        backBtnData['selectedOption'] = component.get("v.selectedOption");
        backBtnData['searchInput'] = component.get("v.searchInput");
        backBtnData['accountData'] = accRec;
        //backBtnData['contactData'] = conRec;
        backBtnData['formType'] = "orderHistoryBySKUForm";
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