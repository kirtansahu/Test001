({
    addWorkDays : function (startDate, days) {
        var isAddingDays = (days > 0);
        var isDaysToAddMoreThanWeek = (days > 5 || days < -5);
        if (isNaN(days)) {
            console.log("Value provided for \"days\" was not a number");
            return
        }
        if (!(startDate instanceof Date)) {
            console.log("Value provided for \"startDate\" was not a Date object");
            return
        }
        var dow = startDate.getDay();
        var daysToAdd = parseInt(days);
        if ((dow === 0 && isAddingDays) || (dow === 6 && !isAddingDays)) {
            daysToAdd = daysToAdd + (1 * (isAddingDays ? 1 : -1));
        } else if ((dow === 6 && isAddingDays) || (dow === 0 && !isAddingDays)) {
            daysToAdd = daysToAdd + (2 * (isAddingDays ? 1 : -1));
        }
        if (isDaysToAddMoreThanWeek) {
            daysToAdd = daysToAdd + (2 * (Math.floor(days / 5)));
            if (days % 5 != 0)
                daysToAdd = daysToAdd + (2 * (isAddingDays ?  -1 : 1));
        }
        startDate.setDate(startDate.getDate() + daysToAdd);
        var newDate = $A.localizationService.formatDate(startDate, "YYYY-MM-DD");
        return newDate;
    },

    setMinMaxDatesToReqDelDate : function(component,helper) {
        //setting request delivery date validation
        var today = new Date();
        var anotherDt  = today.setDate(today.getDate() + parseInt(2));
        var fromDate = $A.localizationService.formatDate(anotherDt, "YYYY-MM-DD");
        var toDate  = helper.addWorkDays(today,20);
        component.set("v.minReqDate",fromDate);
        component.set("v.maxReqDate",toDate);
    },

    getDayName: function(curdate) {
        var weekdays = $A.get("$Locale.nameOfWeekdays");
        var dayName = weekdays[curdate.getDay()].fullName;
        return dayName;
    },

    checkFieldsValidation : function(component){
        let isAllValid = component.find('custom_Valid_field').reduce(function(isValidSoFar, inputCmp){
            //display the error messages
            inputCmp.reportValidity();
            //check if the validity condition are met or not.
            return isValidSoFar && inputCmp.checkValidity();
        },true);
        return isAllValid;
    },
    callDiscountNetPriceAPI : function(component,helper,quote){
        if(quote != '' && quote != null){
            var toastReference = $A.get("e.force:showToast");
            component.set("v.showSpinnerStatus", true);
            var allProducts = component.get("v.selectedProducts");
            var orderDetailObj = component.get("v.orderDetails");
            var action = component.get("c.getQuoteDiscountNetPrice");
            action.setParams({quoteNumber : quote ,orderDetails :orderDetailObj, cartProductsData :allProducts});
            action.setCallback(this, function(response){
                var state= response.getState();
                component.set("v.showSpinnerStatus", false);
                if(state === 'SUCCESS'){
                    var respDetail = response.getReturnValue();
                    if(respDetail.success == true){                        
                        var netPriceDataObj = {};
                        if(respDetail.priceOrderList.length > 0){
                            respDetail.priceOrderList.forEach(function(eachsku){
                                netPriceDataObj[eachsku.SKUNUMBER] = eachsku.NETPRICE;
                            });
                        }
                        if(allProducts.length > 0){
                            allProducts.forEach(function(eachProduct){
                                var netPrice =  netPriceDataObj[eachProduct.productNumber];
                                eachProduct['netPrice'] = netPrice;
                                // if(Number(eachProduct.unitPrice) != Number(netPrice)){
                                //     eachProduct['netPrice'] = netPrice;
                                // }else{
                                //     eachProduct['netPrice'] = null;
                                // }
                            });
                        }
                        component.set("v.selectedProducts",allProducts);
                        helper.calculateOrderTotal(component,helper);
                        helper.saveDataIntoCart(component);
                    }else{
                        var msgStr = typeof respDetail.message != 'undefined' && respDetail.message != null ? respDetail.message :' ';
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 1000,
                            "message" : msgStr,
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                    }
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
        }else{
            var allProducts = component.get("v.selectedProducts");
            if(allProducts.length > 0){
                allProducts.forEach(function(eachProduct){
                    eachProduct['netPrice'] = null;
                });
            }
            component.set("v.selectedProducts",allProducts);
            helper.calculateOrderTotal(component,helper);
            helper.saveDataIntoCart(component);
        }
    },
    calculateOrderTotal : function(component,helper){
        var allProducts = component.get("v.selectedProducts");
        var totalAmount = 0;
        if(allProducts.length > 0){
            allProducts.forEach(function(eachProduct){
                if(typeof eachProduct.netPrice != 'undefined' && eachProduct.netPrice != '' && eachProduct.netPrice != null){
                    totalAmount = totalAmount + (Number(eachProduct.netPrice) * Number(eachProduct.quantity));
                }else{
                    if(typeof eachProduct.unitPrice != 'undefined' && eachProduct.unitPrice != '' && eachProduct.unitPrice != null){
                        totalAmount = totalAmount + (Number(eachProduct.unitPrice) * Number(eachProduct.quantity));
                    }
                }
            });
        }
        component.set("v.estimatedTotal",totalAmount);
        //setting total amount into order details
        var totalAmt =  JSON.stringify(totalAmount);
        helper.setOrderDetailObjectVal(component,'estimatedTotal',totalAmt);
    },
    validateProductPrice : function(component){
        var isNotValid = false;
        var allProducts = component.get("v.selectedProducts");
        if(allProducts.length > 0){
            allProducts.forEach(function(eachProduct){
                if(typeof eachProduct.unitPrice == 'undefined' || eachProduct.unitPrice == null || eachProduct.unitPrice == ''){
                    isNotValid = true;
                    return isNotValid;
                }
            });
        }
        return isNotValid;
    },
    setOrderDetailObjectVal : function(component,attrName,attrValue){
        var orderDetailObj = component.get("v.orderDetails");
        orderDetailObj[attrName] = attrValue;
        component.set("v.orderDetails",orderDetailObj);
    },

    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB
    uploadFiletoAttachments: function(component, fileInput) {
        component.set("v.inProgress",true);
        component.set("v.disableAttach",true);
        // get the first file using array
        var file = fileInput;
        var self = this;
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function
        if (file.size > self.MAX_FILE_SIZE) {
            var toastReference = $A.get("e.force:showToast");
            toastReference.setParams({
                "type" : "Error",
                "title" : "",
                "duration": 7000,
                "message" : 'File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes. \n Selected file "'+ file.name+'" size: ' + file.size,
                "mode" : "dismissible"
            });
            toastReference.fire();
            component.set("v.inProgress",false);
            component.set("v.disableAttach",false);
            return;
        }
        // create a FileReader object
        var objFileReader = new FileReader();
        // set onload function of FileReader object
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(dataStart);
            // call the uploadProcess method
            self.uploadProcess(component, file, fileContents);
        });

        objFileReader.readAsDataURL(file);
    },

    uploadProcess: function(component, file, fileContents) {
        var toastReference = $A.get("e.force:showToast");
        var attachId = '';
        // call the apex method 'SaveFile'
        var action = component.get("c.saveAttachedFile");
        action.setParams({
            fileName: file.name,
            base64Data: encodeURIComponent(fileContents),
            contentType: file.type,
            fileId: attachId
        });
        // set call back
        action.setCallback(this, function(response) {
            // store the response / Attachment Id
            attachId = response.getReturnValue();
            component.set("v.inProgress",false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var fileName = response.getReturnValue();
                var splitedArry =  fileName.split('#');
                var uploadedFileName = component.get("v.uploadedFileName");
                if(uploadedFileName != null && uploadedFileName != ''){
                    uploadedFileName = uploadedFileName + '\n ' + splitedArry[1];
                }else{
                    uploadedFileName = splitedArry[1];
                }
                component.set("v.uploadedFileName",uploadedFileName);
                toastReference.setParams({
                    "type" : "Success",
                    "title" : "",
                    "duration": 5000,
                    "message" :"File has been uploaded successfully",
                    "mode" : "dismissible"
                });
                toastReference.fire();
                // handel the response errors
            } else if (state === "INCOMPLETE") {
                component.set("v.disableAttach",false);
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                component.set("v.disableAttach",false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    removeAttachemts : function(component,isMsgShow){
        component.set("v.selectedFileName",'');
        component.set("v.inProgress",true);
        var toastReference = $A.get("e.force:showToast");
        // call the apex method 'remove files'
        var action = component.get("c.removeAttachedFiles");
        // set call back
        action.setCallback(this, function(response) {
            // store the response / Attachment Id
            var success = response.getReturnValue();
            component.set("v.inProgress",false);
            var state = response.getState();
            if (state === "SUCCESS") {
                if(success){
                    component.set("v.uploadedFileName",'');
                    component.set("v.disableAttach",false);
                    if(isMsgShow){
                        toastReference.setParams({
                            "type" : "Success",
                            "title" : "",
                            "duration": 5000,
                            "message" : $A.get("$Label.c.KM_AttachRemoveSuccMsg"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                    }
                    // handel the response errors
                }else{
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" : $A.get("$Label.c.KM_AttachDelErrMsg"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
            } else if (state === "INCOMPLETE") {
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_API_Error_Message"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    saveDataIntoCart : function(component){
        var orderDetailObj = component.get("v.orderDetails");
        var productsList = component.get("v.selectedProducts");
        //save cart through addSelectedItemsToCart application event
        var additemsAppEvent = $A.get("e.c:KMAddSelectedItemsToCart");
        if(additemsAppEvent){
            additemsAppEvent.setParams({
                "orderedProducts": productsList,
                "orderDetails": orderDetailObj,
                "replaceProducts": true
            });
            additemsAppEvent.fire();
        }else{
            console.log("Event not Supported");
        }
    },

    showExistedFiles : function(component){
        var toastReference = $A.get("e.force:showToast");
        // call the apex method 'remove files'
        var action = component.get("c.getUploadedAttachments");
        // set call back
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var uploadedFileName = response.getReturnValue();
                component.set("v.uploadedFileName",uploadedFileName);
                if(uploadedFileName != ''){
                    component.set("v.disableAttach",true);
                }
            } else if (state === "INCOMPLETE") {
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_API_Error_Message"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                      console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    loadBillToInfoAndOldShipToNum : function(component,shipToNum,billToNum) {
        // calling API service
        shipToNum = typeof shipToNum != "undefined" && shipToNum != null ? shipToNum : '';
        billToNum = typeof billToNum != "undefined" && billToNum != null ? billToNum : '';
        var toastReference = $A.get("e.force:showToast");
        component.set("v.showSpinnerStatus", true);
        var action = component.get("c.getBillToContactAndServiceStopCode");
        action.setParams({shipToNumber : shipToNum , billToNumber : billToNum});
        action.setCallback(this, function(response){
            var state= response.getState();
            component.set("v.showSpinnerStatus", false);
            if(state === 'SUCCESS'){
                // component.set("v.oldShipToNumber", response.getReturnValue().cartShipToNumber);
                // component.set("v.oldOrderType", response.getReturnValue().cartOrderType);
                var returnValue = response.getReturnValue();
                console.log('--returnValue: ', returnValue);
                if (!returnValue.isSuccess) {
                    return;
                }
                var responseData = returnValue.data;
                var serviceStopCodeRes = typeof responseData.serviceStopCode != 'undefined' && responseData.serviceStopCode.responseDetail != null ?
                responseData.serviceStopCode.responseDetail : new Array();
                var billToContactNameEmail = typeof responseData.billToContactNameEmail != 'undefined' && responseData.billToContactNameEmail.responseDetail != null ?
                responseData.billToContactNameEmail.responseDetail : new Array();
                var ordDetailObj =  component.get("v.orderDetails");
                if(serviceStopCodeRes.length > 0){
                    ordDetailObj['defaultStopCode'] = serviceStopCodeRes[0].STOPCODE;
                    ordDetailObj['defaultServiceCode'] = serviceStopCodeRes[0].SERVICECODE;
                    //Updated the stopcode srevice code labels
                    var serviceCodeObj = component.get("v.serviceCodes");
                    var stopCodeObj = component.get("v.stopCodes");
                    var ordDetailObj =  component.get("v.orderDetails");
                    var serviceCodeLabel = typeof serviceCodeObj[ordDetailObj.defaultServiceCode] != 'undefined'
                    && serviceCodeObj[ordDetailObj.defaultServiceCode] != null ?
                    serviceCodeObj[ordDetailObj.defaultServiceCode]: ordDetailObj.defaultServiceCode;
                    var stopCodeLabel = typeof stopCodeObj[ordDetailObj.defaultStopCode] != 'undefined'
                    && stopCodeObj[ordDetailObj.defaultStopCode] != null ?
                    stopCodeObj[ordDetailObj.defaultStopCode]: ordDetailObj.defaultStopCode;
                    ordDetailObj['defaultServiceCodeLabel'] = serviceCodeLabel;
                    ordDetailObj['defaultStopCodeLabel'] = stopCodeLabel;
                }
                if(billToContactNameEmail.length > 0){
                    ordDetailObj['defaultBillToContactName'] = billToContactNameEmail[0].WWMLNM;
                    ordDetailObj['defaultBillToContactEmail'] = billToContactNameEmail[0].EAEMAL;
                }
                component.set("v.orderDetails",ordDetailObj);
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

    submitOrderForm : function(component,statusName){
        var toastReference = $A.get("e.force:showToast");
        component.set("v.showSpinnerStatus", true);
        // call the apex method for submit order
        var action = component.get("c.confirmOrder");
        // set call back
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinnerStatus", false);
            if (state === "SUCCESS") {
                component.set("v.statusName",statusName);
                //clear cart through addSelectedItemsToCart application event
                var productData = new Array();
                var ordDetailObj = {};
                var additemsAppEvent = $A.get("e.c:KMAddSelectedItemsToCart");
                if(additemsAppEvent){
                    additemsAppEvent.setParams({
                        "orderedProducts": productData,
                        "orderDetails": ordDetailObj,
                        "replaceProducts": true
                    });
                    additemsAppEvent.fire();
                }
                else{
                    console.log("Event not Supported");
                }
            } else if (state === "INCOMPLETE") {
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" : $A.get("$Label.c.KM_ErrorSubmitOrderForm"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 5000,
                            "message" : "Error message: " + errors[0].message,
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        console.log("Error message: " + errors[0].message+" ::Error Details: " + errors[0].stackTrace);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },

    getUserDetails: function(component, event, helper) {
        var action = component.get('c.getUserDetails');
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            if (state === 'SUCCESS') {
                if(result != null && result != undefined) {
                    var orderDetailObj = component.get('v.orderDetails');
                    orderDetailObj['poOrRefNumber'] = result.PO_Ref_Number__c;
                    orderDetailObj['orderFromState'] = result.Order_Form_State__c
                    component.set("v.orderDetails", orderDetailObj);
                }
            }
        });
        $A.enqueueAction(action);
    }
})