({
    doInit : function (component, event, helper) {
        var paymentmethods = new Array();
        paymentmethods = [...paymentmethods,{value: 'C - Purchase Order', label: $A.get("$Label.c.KM_CPurchaseOrder")}];
        paymentmethods = [...paymentmethods,{value: 'S - Credit Card with Tax Invoice', label: $A.get("$Label.c.KM_SCreditCardwithTaxInvoice")}];
        paymentmethods = [...paymentmethods,{value: '3 - Credit Card without Tax Invoice', label: $A.get("$Label.c.KM_3CreditCardwithoutTaxInvoice")}];
        component.set("v.paymentmethods",paymentmethods);
        //Created Order type options
        var orderTypeObj = {};
        orderTypeObj['SO']= $A.get("$Label.c.KM_SO_StandardOrder");
        orderTypeObj['SU']= $A.get("$Label.c.KM_SU_PrepaidOrderforDeposit");
        orderTypeObj['SE']= $A.get("$Label.c.KM_SE_PrepaidOrder");
        orderTypeObj['TC']= $A.get("$Label.c.KM_TC_DeferredPaymentOrder");
        orderTypeObj['T9']= $A.get("$Label.c.KM_T9_DeferredInvoiceOrder");
        component.set("v.ordertypes",orderTypeObj);
        // created service code object
        var serviceCodeObj  = {};
        serviceCodeObj['K01'] = $A.get("$Label.c.KM_K01Label");
        serviceCodeObj['K02'] = $A.get("$Label.c.KM_K02Label");
        serviceCodeObj['K03'] = $A.get("$Label.c.KM_K03Label");
        serviceCodeObj['K04'] = $A.get("$Label.c.KM_K04Label");
        serviceCodeObj['K05'] = $A.get("$Label.c.KM_K05Label");
        serviceCodeObj['K06'] = $A.get("$Label.c.KM_K06Label");
        serviceCodeObj['K07'] = $A.get("$Label.c.KM_K07Label");
        serviceCodeObj['K08'] = $A.get("$Label.c.KM_K08Label");
        serviceCodeObj['K09'] = $A.get("$Label.c.KM_K09Label");
        serviceCodeObj['KOT'] = $A.get("$Label.c.KM_KOTLabel");
        serviceCodeObj['KRG'] = $A.get("$Label.c.KM_KRGLabel");
        serviceCodeObj['KWE'] = $A.get("$Label.c.KM_KWELabel");
        component.set("v.serviceCodes",serviceCodeObj);
        var serviceCodeList = new Array();
        serviceCodeList = [...serviceCodeList,{value:'',label:'-Select-'}];
        Object.keys(serviceCodeObj).forEach(function(eachCode){
            serviceCodeList = [...serviceCodeList,{value:eachCode,label:serviceCodeObj[eachCode]}];
        });
        component.set("v.newServiceCodeOptions",serviceCodeList);
        // created stop code object
        var stopCodeObj  = {};
        stopCodeObj['KBS'] = $A.get("$Label.c.KM_KBSLabel");
        stopCodeObj['KDJ'] = $A.get("$Label.c.KM_KDJLabel");
        stopCodeObj['KGJ'] = $A.get("$Label.c.KM_KGJLabel");
        stopCodeObj['KJJ'] = $A.get("$Label.c.KM_KJJLabel");
        stopCodeObj['KSE'] = $A.get("$Label.c.KM_KSELabel");
        stopCodeObj['KWE'] = $A.get("$Label.c.KM_KWELabel");
        stopCodeObj['103'] = $A.get("$Label.c.KM_103Label");
        component.set("v.stopCodes",stopCodeObj);
        var stopCodeList = new Array();
        stopCodeList = [...stopCodeList,{value:'',label:'-Select-'}];
        Object.keys(stopCodeObj).forEach(function(eachCode){
            stopCodeList = [...stopCodeList,{value:eachCode,label:stopCodeObj[eachCode]}];
        });
        component.set("v.newStopCodeOptions",stopCodeList);
        var orderDetailObj = component.get("v.orderDetails");
        if(typeof orderDetailObj.shipComplete != 'undefined' && orderDetailObj.shipComplete){
            helper.setMinMaxDatesToReqDelDate(component,helper);
        }
        helper.getUserDetails(component, event, helper);
        helper.calculateOrderTotal(component,helper);
        helper.saveDataIntoCart(component);
    },
    selectAllProducts : function (component, event, helper) {
        var selectAll = event.getSource().get("v.checked");
        selectAll  = selectAll ? false : true;
        var allProducts = component.get("v.selectedProducts");
        if(allProducts){
            allProducts.forEach(function(eachProduct){
                eachProduct['selected'] = selectAll;
            });
            component.set("v.selectedProducts",allProducts);
        }
    },
    removeSelectedProducts : function (component, event, helper) {
        var allProducts = component.get("v.selectedProducts");
        var allProductsTemp = new Array();
        var totalAmount = 0;
        if(allProducts){
            allProducts.forEach(function(eachProduct){
                if(eachProduct.selected != true){
                    allProductsTemp.push(eachProduct);
                    if(typeof eachProduct.unitPrice != 'undefined' && eachProduct.unitPrice != '' && eachProduct.unitPrice != null){
                        totalAmount = totalAmount + (Number(eachProduct.unitPrice) * Number(eachProduct.quantity));
                    }
                }
            });
            component.set("v.selectedProducts",allProductsTemp);
            component.set("v.selectAll",false);
            component.set("v.estimatedTotal",totalAmount);
            var totalAmt = JSON.stringify(totalAmount);
            helper.setOrderDetailObjectVal(component,'estimatedTotal',totalAmt);
            helper.saveDataIntoCart(component);
        }
    },
    setSeletedOrdersStatus : function (component, event, helper) {
        var exitStatus = component.get("v.statusName");
        var toastReference = $A.get("e.force:showToast");
        if(exitStatus == 'shippingPayment'){
            let isAllValid = helper.checkFieldsValidation(component);
            if(isAllValid){
                //Updated the stopcode srevice code labels
                var orderTypeObj = component.get("v.ordertypes");
                var serviceCodeObj = component.get("v.serviceCodes");
                var stopCodeObj = component.get("v.stopCodes");
                var ordDetailObj =  component.get("v.orderDetails");
                ordDetailObj['newServiceCodeLabel'] = serviceCodeObj[ordDetailObj.newServiceCode];
                ordDetailObj['newStopCodeLabel'] = stopCodeObj[ordDetailObj.newStopCode];
                ordDetailObj['orderTypeLabel'] = orderTypeObj[ordDetailObj.orderType];
                component.set("v.orderDetails",ordDetailObj);
                if(ordDetailObj.orderType != null && ordDetailObj.orderType != ''){
                    var newBillConName = ordDetailObj.newBillToContactName;
                    var newBillConEmail = ordDetailObj.newBillToContactEmail;
                    var isErrorVal  = false;
                    if(typeof newBillConName == 'undefined' || newBillConName == null || newBillConName == ''
                    || typeof newBillConEmail == 'undefined' || newBillConEmail == null || newBillConEmail == ''){
                        if(typeof newBillConName != 'undefined' && newBillConName != null && newBillConName != ''){
                            isErrorVal = true;
                            toastReference.setParams({
                                "type" : "Error",
                                "title" : "",
                                "duration": 5000,
                                "message" :$A.get("$Label.c.KM_ContactEmailReqMsg"),
                                "mode" : "dismissible"
                            });
                            toastReference.fire();
                        }
                        if(typeof newBillConEmail != 'undefined' && newBillConEmail != null && newBillConEmail != ''){
                            isErrorVal = true;
                            toastReference.setParams({
                                "type" : "Error",
                                "title" : "",
                                "duration": 5000,
                                "message" :$A.get("$Label.c.KM_ContactNameReqMsg"),
                                "mode" : "dismissible"
                            });
                            toastReference.fire();
                        }
                    }
                    if(isErrorVal == false){
                        helper.saveDataIntoCart(component);
                        component.set("v.statusName",event.getParam("statusName"));
                    }
                }else{
                    $A.util.addClass(component.find('orderTypeFieldId'), 'slds-has-error');
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_Mandatory_Fields_ValidMsg"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
            }else{
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_Mandatory_Fields_ValidMsg"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            }
        }else if(exitStatus == 'cart'){
            var ordDetailObj =  component.get("v.orderDetails");
            let isAllValid = helper.checkFieldsValidation(component);
            if(isAllValid){
                component.set("v.disableOrderTypesWithPP",false);
                if(ordDetailObj.orderType != 'T9'){
                    if(ordDetailObj.shipToAlphaName.startsWith('PP')){
                        helper.setOrderDetailObjectVal(component,'orderType','SE');
                        component.set("v.disableOrderTypesWithPP",true);
                    }
                }
                var promotionType = event.getParam("promotionType");
                var quote = event.getParam("quote");
                var promotionCode = event.getParam("promotionCode");
                promotionType = typeof promotionType != 'undefined' && promotionType != null ? promotionType : '';
                quote = typeof quote != 'undefined' && quote != null ? quote : '';
                promotionCode = typeof promotionCode != 'undefined' && promotionCode != null ? promotionCode : '';
                helper.setOrderDetailObjectVal(component,'promotionType',promotionType);
                helper.setOrderDetailObjectVal(component,'quote',quote);
                helper.setOrderDetailObjectVal(component,'promotionCode',promotionCode);
                helper.saveDataIntoCart(component);
                if(event.getParam("changeQuote")){
                    // call the get netprice/discount api
                    helper.callDiscountNetPriceAPI(component,helper,quote);
                }
                var isNotValidPrice = helper.validateProductPrice(component);
                if(isNotValidPrice == false){
                    var existedStatusName =  component.get("v.statusName");
                    if(existedStatusName != event.getParam("statusName")){
                        helper.loadBillToInfoAndOldShipToNum(component,ordDetailObj.shipToNumber,ordDetailObj.billToNumber);
                    }
                    component.set("v.statusName",event.getParam("statusName"));
                }else{
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" : $A.get("$Label.c.KM_ProductPriceValidMsg"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
                helper.showExistedFiles(component);
            }else{
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 5000,
                    "message" :$A.get("$Label.c.KM_Mandatory_Fields_ValidMsg"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
            }
        }else if(exitStatus == 'review'){
            //Call Submit order form method
            var statusName = event.getParam("statusName");
            helper.submitOrderForm(component,statusName);
        }else{
            component.set("v.statusName",event.getParam("statusName"));
        }
    },
    changeOrderStatus : function (component, event, helper) {
        component.set("v.statusName",event.getParam("statusName"));
    },
    resetRequestDeleveryDate : function (component, event, helper) {
        helper.setOrderDetailObjectVal(component,'requestDeleveryDate',null);
        helper.saveDataIntoCart(component);
    },
    setMinMaxDateValues : function (component, event, helper) {
        var shipComplete = event.getSource().get("v.checked");
        if(shipComplete){
            helper.setMinMaxDatesToReqDelDate(component,helper);
        }else{
            helper.setOrderDetailObjectVal(component,'requestDeleveryDate',null);
        }
        helper.saveDataIntoCart(component);
    },
    setRequestDeleveryDate : function (component, event, helper) {
        var toastReference = $A.get("e.force:showToast");
        var deleveryDate = event.getSource().get("v.value");
        var dayName = helper.getDayName(new Date(deleveryDate));
        if(dayName == $A.get("$Label.c.KM_SaturdayLabel") || dayName == $A.get("$Label.c.KM_SundayLabel")){
            toastReference.setParams({
                "type" : "Error",
                "title" : "",
                "duration": 5000,
                "message" :$A.get("$Label.c.KM_ReqDate_ValidMsg"),
                "mode" : "dismissible"
            });
            toastReference.fire();
            helper.setOrderDetailObjectVal(component,'requestDeleveryDate',null);
        }
        helper.saveDataIntoCart(component);
    },
    setOrderTypeValue : function (component, event, helper) {
        var ordType = event.currentTarget.value;
        helper.setOrderDetailObjectVal(component,'orderType',ordType);
        $A.util.removeClass(component.find('orderTypeFieldId'), 'slds-has-error');
        if(ordType != 'SU'){
            //helper.removeAttachemts(component,false);
            //helper.calculateOrderTotal(component,helper);
        }
        helper.saveDataIntoCart(component);

    },
    calculateEstimatedTotal : function (component, event,helper) {
        helper.calculateOrderTotal(component,helper);
        helper.saveDataIntoCart(component);

    },
    handleFilesChange : function (component, event,helper) {
        var uploadedFiles = event.getSource().get("v.files");
        var selectedFileName = '';
        if(uploadedFiles.length > 0){
            for(let i=0;i<uploadedFiles.length;i++) {
                if(selectedFileName != null && selectedFileName != ''){
                    selectedFileName = selectedFileName + '\n ' + uploadedFiles[i].name;
                }else{
                    selectedFileName = uploadedFiles[i].name;
                }
            }
            component.set("v.selectedFileName",selectedFileName);
        }
    },
    removeAttachments : function (component, event,helper) {
        helper.removeAttachemts(component,true);
    },
    addAttachments : function (component, event,helper) {
        // get the selected files using aura:id [return array of files]
        var fileInput = component.find("fileInputFieldId").get("v.files");
        if(fileInput.length > 0){
            for(var i =0; i < fileInput.length; i++){
                helper.uploadFiletoAttachments(component, fileInput[i]);
            }
        }
    },
    updateCartData : function (component, event, helper) {
        helper.saveDataIntoCart(component);
    },
    saveEstTotalOrderObj : function (component, event, helper) {
        var estVal = event.getSource().get("v.value");
        helper.setOrderDetailObjectVal(component,'estimatedTotal',estVal);
        helper.saveDataIntoCart(component);
    },
    backToPreviousTab : function(component, event, helper) {
        var backBtnData = component.get("v.backButtonData");
        var backOperation = false;
        if(typeof backBtnData != 'undefined' && backBtnData != null){
            backOperation = true;
        }
		var backToPrevTabEvt = component.getEvent("backToPreviousTab");
        if(backToPrevTabEvt){
            backToPrevTabEvt.setParams({
                "backOperation": backOperation
            });
            backToPrevTabEvt.fire();
        }else{
            console.log("Event not Supported");
        }
	},
})