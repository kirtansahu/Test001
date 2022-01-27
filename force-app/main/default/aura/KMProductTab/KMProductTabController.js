({
    doInit : function(component, event, helper) {
        var psearchInput = component.get("v.searchInput");
        helper.setBackButtonData(component,psearchInput);
        // var orderButton = component.get("v.orderButton");
        // if(orderButton){
        //     var accRec = component.get("v.accountRec");
        //     var conRec = component.get("v.contactRec");
        //     var backBtnData = {};
        //     backBtnData['tabAuraId'] = "customerOrdersId";
        //     backBtnData['selectedOption'] = component.get("v.selectedOption");
        //     backBtnData['searchInput'] = component.get("v.cusSearchInput");
        //     backBtnData['accountData'] = accRec;
        //     backBtnData['contactData'] = conRec;
        //     backBtnData['productSearchInput'] = component.get("v.searchInput");
        //     backBtnData['formType'] = "pricingAndAvailabilityForm";
        //     var backToButtonAppEvent = $A.get("e.c:KMSendBackToButtonData");
        //     if(backToButtonAppEvent){
        //         backToButtonAppEvent.setParams({
        //             "backButtonData": backBtnData
        //         });
        //         backToButtonAppEvent.fire();
        //     }else{
        //         console.log("Event not Supported");
        //     }
        // }
        
    },
    //Enable And Disables the search Button
    serachButton : function(component, event, helper) {
        component.find('SearchButton').set('v.disabled', !helper.isSearchable(component));
    },

    handleSearchInputKeyPress : function(component,event,helper) {
        if (event.which == 13 && helper.isSearchable(component)) {
            helper.searchProduct(component,helper);
        }
    },

    //Get List of Product records from controller.
    searchProducts : function(component,event,helper){
        helper.searchProduct(component,helper);
    },
    doProductSearch : function(component,event,helper){
        component.find('SearchButton').set('v.disabled', !helper.isSearchable(component));
        helper.searchProduct(component,helper);
    },

    //Get More Product records from controller,When user click Load More button
    viewMoreRecords :function(component, event, helper) {
        component.set('v.loaded',true);
        var result=component.get('v.listofproducts');
        var moreRecords=[];
        var recordResults=component.get('v.allRecords');
        var limits=$A.get("$Label.c.KM_Record_Limits");
        if(recordResults.length-result.length > limits ){
            for(var i=0;i<result.length + parseInt(limits); i++){
                moreRecords.push(recordResults[i]);
            }
            component.set('v.listofproducts',moreRecords);
            component.set('v.Productlength',component.get('v.listofproducts').length);
            component.set('v.loaded',false);
        }
        else{
            for(var i=0;i<result.length+recordResults.length-result.length;i++){
                moreRecords.push(recordResults[i]);
            }
            component.set('v.loaded',false);
            component.set('v.listofproducts',moreRecords);
            component.set('v.Productlength',recordResults.length-component.get('v.listofproducts').length);
        }
    },

    // Product Records Sorting
    sortBy: function(component, event, helper) {
        var fieldName = event.currentTarget.id;
        // call the helper function with pass sortField Name
        helper.sortByProducts(component,helper, fieldName);
        component.set("v.selectedTabsoft", fieldName);
        var a=component.get("v.sortAsc");
    },

    //Get availability Data from OFM for particular Product
    submit:function(component, event, helper) {
        component.set('v.loaded',true);
        var productId=event.currentTarget.dataset.id;
        var actions=component.get('c.getAvailabiltyInfo');
        var toastReference = $A.get("e.force:showToast");
        actions.setParams({
            productNumber :productId,
            shipNumber :component.get('v.shipToNumber')
        });
        actions.setCallback(this,function(response){
            var state=response.getState();
            component.set('v.loaded',false);
            if(state==='SUCCESS'){
                var returnValue = response.getReturnValue();
                if (!returnValue.isSuccess) {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 1000,
                        "message" : returnValue.data,
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    return;
                }
                var result=returnValue.data;
                if(result==null || result.length==0){
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 1000,
                        "message" : $A.get("$Label.c.KM_Product_Error"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    return;
                }else{
                    //If controller returns zero,we are showing No records Message
                    if(JSON.stringify(result)=='{}'){
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 1000,
                            "message" : $A.get("$Label.c.KM_Product_Error"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        return;
                    }else{
                        var priceResult=component.get('v.listofproducts');
                        priceResult.forEach(function(eachproduct){
                            if(eachproduct.SKU==productId){
                                if(result.AVAILABILITYDATE =='undefined' || result.AVAILABILITYDATE=='' || result.AVAILABILITYDATE==null){
                                    eachproduct['AVAILABILITYDATE']='Not Available';
                                }else{
                                    var yearFormat=new Date(result.AVAILABILITYDATE);
                                    var finalDateFormat=yearFormat.getFullYear() + "/" + (yearFormat.getMonth() + 1) + "/" + yearFormat.getDate();
                                    eachproduct['AVAILABILITYDATE']=finalDateFormat;
                                }
                                //set  values in ProductTab attribute on component.
                                eachproduct['AVAILABLEQUANTITY']=result.AVAILABLEQUANTITY;
                                eachproduct['BRANCHPLANT']=result.BRANCHPLANT;
                                eachproduct['enableButton']=false;
                                eachproduct['customerPrice']=result.UNITPRICE;
                                eachproduct['koreanCurrencyCode']=result.CURRENCYCODE;
                            }
                        });
                        component.set('v.listofproducts',priceResult);
                    } }
            }else if(state==='ERROR'){
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 5000,
                            "message" : errors[0].message,
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        console.log("Error message: " + errors[0].message+" ::Error Details: " + errors[0].stackTrace);
                        throw new Error("Error: "+errors[0].message);
                    }
                }else{
                    throw new Error("Unknown Error");
                }
            }
        });
        $A.enqueueAction(actions);
    },

    //Place Orders,When User click add To Order Button.
    addToOrders:function(component, event, helper) {
        var productId=event.getSource().get('v.name');
        var accRec = component.get("v.accountRec");
        var conRec = component.get("v.contactRec");
        var shipToNum;
        var billToNum;
        var ordDetailObj = {};
        if(conRec != null){
            ordDetailObj['contactName'] = conRec.Name;
            ordDetailObj['phoneNumber'] = conRec.Phone;
            ordDetailObj['emailAddress'] = conRec.Email;
            ordDetailObj['crmRowId'] = conRec.Contact_External_Id__c;
        }
        if(accRec != null){
            shipToNum=accRec.ERP_Account_Id__c;
            billToNum=accRec.Primary_Bill_To__r.ERP_Account_Id__c;
            component.set('v.newShipToNumber',shipToNum);
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
            ordDetailObj['billToCountry'] =accRec.Primary_Bill_To__r.Country__c;
        }
        ordDetailObj['orderType'] = component.get('v.orderTypes')['SO'];
        component.set("v.orderDetails",ordDetailObj);
        var action = component.get("c.getOrderDetailObject");
        //action.setParams({shipToNumber : shipToNum , billToNumber : billToNum});
        action.setCallback(this, function(response){
            var state= response.getState();
            if(state === 'SUCCESS'){
                var oldOrderDetailObj = response.getReturnValue();
                component.set("v.oldShipToNumber", oldOrderDetailObj.shipToNumber);
                component.set("v.oldShipToName", oldOrderDetailObj.shipToAlphaName);
                component.set("v.oldOrderType", oldOrderDetailObj.orderType);

                var productData=component.get('v.listofproducts');
                var addProducts=[];
                for(var i=0;i<productData.length;i++){
                    if(productData[i].SKU==productId){
                        var addedOrders={};
                        addedOrders['productName']=productData[i].SKUdesc1;
                        addedOrders['productNumber']=productData[i].SKU;
                        addedOrders['unitSize']=productData[i].SKUdesc2;
                        addedOrders['currencyCode']=productData[i].currencycode;
                        addedOrders['unitPrice']=productData[i].customerPrice;
                        // if AvailableQuantity equal to  zero,set default One to AvailableQuantity
                        if(productData[i].AVAILABLEQUANTITY==0){
                            addedOrders['quantity']=1;
                        }else if(productData[i].AVAILABLEQUANTITY>0){
                            addedOrders['quantity']=1;
                        }
                        addedOrders['selected']=false;
                        addProducts.push(addedOrders);
                    }
                }
                component.set('v.quickOrderData',addProducts);
                //Check old ShipTo And New ShipTo Numbers
                if(component.get('v.oldShipToNumber')==null || component.get('v.oldShipToNumber') == component.get('v.newShipToNumber')){
                    if(component.get('v.oldOrderType')=='T9'){
                        component.set('v.showOrderTypePopup',true);
                        component.set('v.showShipToPopup',false);
                    }else{
                        component.set("v.showShipToPopup",false);
                        var additemsAppEvent = $A.get("e.c:KMAddSelectedItemsToCart");
                        if(additemsAppEvent){
                            additemsAppEvent.setParams({
                                "orderedProducts": component.get('v.quickOrderData'),
                                "orderDetails": ordDetailObj,
                                "replaceProducts": false
                            });
                            additemsAppEvent.fire();
                        }
                        var toastReference = $A.get("e.force:showToast");
                        toastReference.setParams({
                            "type" : "Success",
                            "title" : "",
                            "duration": 5000,
                            "message" :$A.get("$Label.c.KM_QO_Items_added_Msg"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();}

                }else{
                    if(component.get('v.oldShipToNumber') != component.get('v.newShipToNumber')){
                        component.set("v.showShipToPopup",true);
                    }
                }
            }else if(state === 'ERROR'){
                //generic error handler
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        throw new Error("Error: "+errors[0].message);
                    }
                }else{
                    throw new Error("Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    reorderProduct: function(component, event, helper) {
        var productIndex = event.getSource().get('v.name');
        var accRec = component.get("v.accountRec");
        var shipToNum;
        var billToNum;
        var ordDetailObj = {};
        var savedOrderDetails = component.get('v.savedOrderDetails');

        if (savedOrderDetails != null && savedOrderDetails.hasOwnProperty('shipToNumber')) {
            component.set('v.oldShipToNumber', savedOrderDetails.shipToNumber);
            component.set('v.oldShipToName', savedOrderDetails.shipToAlphaName);
        }

        if(accRec != null){
            shipToNum=accRec.ERP_Account_Id__c;
            billToNum=accRec.Primary_Bill_To__r.ERP_Account_Id__c;
            component.set('v.newShipToNumber',shipToNum);
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
            ordDetailObj['billToCountry'] =accRec.Primary_Bill_To__r.Country__c;
        }
        ordDetailObj['orderType'] = component.get('v.orderTypes')['SO'];
        component.set("v.orderDetails", ordDetailObj);
        var productData = component.get('v.listofproducts');

        var addProducts=[];
        var addedOrders={};
        addedOrders['productName'] = productData[productIndex].ProductName;
        addedOrders['productNumber'] = productData[productIndex].ProductNo;
        addedOrders['unitSize'] = productData[productIndex].UnitSize;
        addedOrders['currencyCode'] = productData[productIndex].CurrencyCode;
        addedOrders['unitPrice'] = helper.sanitizePriceValue(productData[productIndex].CustomerPrice);
        // if AvailableQuantity equal to  zero,set default One to AvailableQuantity
        if(productData[productIndex].Quantity == 0){
            addedOrders['quantity'] = 1;
        }else{
            addedOrders['quantity'] = productData[productIndex].Quantity;
        }
        addedOrders['selected'] = false;
        addProducts.push(addedOrders);
        component.set('v.quickOrderData', addProducts);

        if(
            savedOrderDetails == null ||
            Object.keys(savedOrderDetails).length === 0 ||
            Object.keys(savedOrderDetails).length === 1
        ) {
            helper.addSelectedItemsToCart(component, event, helper);
        }
        else if (savedOrderDetails != null && Object.keys(savedOrderDetails).length > 0) {
            if (savedOrderDetails.shipToNumber == component.get('v.newShipToNumber')) {
                if (savedOrderDetails.orderType == component.get('v.orderTypes')['SO']) {
                    helper.addSelectedItemsToCart(component, event, helper);
                }
                else {
                    component.set('v.showOrderTypePopup', true);
                }
            }
            else if(
                savedOrderDetails.shipToNumber != null
                && savedOrderDetails.shipToNumber != component.get('v.newShipToNumber')
            ){
                component.set("v.showShipToPopup",true);
            }
        }
    },
})