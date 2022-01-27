({
    doInit : function(component, event, helper) {
        helper.createQuickOrderForm(component);
        var accRec = component.get("v.accountRec");
        var conRec = component.get("v.contactRec");
        var ordDetailObj = {};
        var shipToNum;
        var billToNum;
        if(typeof conRec != 'undefined' && conRec != null){
            ordDetailObj['contactName'] = conRec.Name;
            ordDetailObj['phoneNumber'] = conRec.Phone;
            ordDetailObj['emailAddress'] = conRec.Email;
            ordDetailObj['crmRowId'] = conRec.Contact_External_Id__c;
        }
        if(typeof accRec != 'undefined' && accRec != null){
            shipToNum = accRec.ERP_Account_Id__c;
            component.set("v.newShipToNumber", shipToNum);
            component.set("v.oldShipToNumber", null);
            component.set("v.oldShipToName", accRec.Name);

            ordDetailObj['accountId'] = accRec.Id;
            ordDetailObj['shipToNumber'] = shipToNum;
            ordDetailObj['shipToAlphaName'] = accRec.Account_Alpha_Name__c;
            ordDetailObj['shipToName'] = accRec.Name;
            ordDetailObj['shipToAddressLine1'] = accRec.Address_1__c;
            ordDetailObj['shipToAddressLine2'] = accRec.Address_2__c;
            ordDetailObj['shipToAddressLine3'] = accRec.Address_3__c;
            ordDetailObj['shipToCity'] = accRec.City_f__c;
            ordDetailObj['shipToState'] = accRec.State_f__c;
            ordDetailObj['shipToPostalCode'] = accRec.Zip_Postal_Code_f__c;
            ordDetailObj['shipToCountry'] = accRec.Country__c;
            if(typeof accRec.Primary_Bill_To__r != 'undefined' && accRec.Primary_Bill_To__r != null){
                billToNum = accRec.Primary_Bill_To__r.ERP_Account_Id__c;
                ordDetailObj['billToNumber'] = billToNum;
                ordDetailObj['billToName'] = accRec.Primary_Bill_To__r.Name;
                ordDetailObj['billToAddressLine1'] = accRec.Primary_Bill_To__r.Address_1__c;
                ordDetailObj['billToAddressLine2'] = accRec.Primary_Bill_To__r.Address_2__c;
                ordDetailObj['billToAddressLine3'] = accRec.Primary_Bill_To__r.Address_3__c;
                ordDetailObj['billToCity'] = accRec.Primary_Bill_To__r.City_f__c;
                ordDetailObj['billToState'] = accRec.Primary_Bill_To__r.State_f__c;
                ordDetailObj['billToPostalCode'] = accRec.Primary_Bill_To__r.Zip_Postal_Code_f__c;
                ordDetailObj['billToCountry'] =accRec.Primary_Bill_To__r.Country__c;
            }
        }
        ordDetailObj['orderType'] = 'SO';
        component.set("v.orderDetails",ordDetailObj);
        helper.loadCartShipToAndOrderType(component);

        var backBtnData = {};
        backBtnData['tabAuraId'] = "customerOrdersId";
        backBtnData['selectedOption'] = component.get("v.selectedOption");
        backBtnData['searchInput'] = component.get("v.searchInput");
        backBtnData['accountData'] = accRec;
        backBtnData['contactData'] = conRec;
        backBtnData['formType'] = "quickOrderForm";
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
    refreshOrderForm : function(component, event, helper) {
        helper.createQuickOrderForm(component);
        helper.loadCartShipToAndOrderType(component);
    },
    removeStyles: function(component, event, helper) {
        $A.util.removeClass(event.currentTarget, 'error-input-data' );
        $A.util.removeClass(event.currentTarget, 'success-input-data' );
    },
    addToOrderForm : function(component, event, helper) {
        component.set("v.showSpinnerStatus", true);
        var quickOrderArray = new Array();
        quickOrderArray = component.get("v.quickOrderData");
        var quantityNotFound = false;
        var productData = new Array();
        var productsExisted = false;
        //check Quick order Quantity validation
        quickOrderArray.forEach(function(eachQCProd){
            if( eachQCProd.productNumber != null && eachQCProd.productNumber != ''){
                eachQCProd.productNumber = eachQCProd.productNumber.toUpperCase()
                productsExisted = true;
                if(eachQCProd.quantity == null || eachQCProd.quantity == ''){
                    quantityNotFound = true;
                }else{
                    productData = [...productData,{productNumber:eachQCProd.productNumber,quantity:eachQCProd.quantity,lotNumber:eachQCProd.lotNumber}];
                }
            }
        });
        if(productsExisted){
            if(quantityNotFound == false){
                try {
                    // calling API service
                    var newShipToNum1 = component.get("v.newShipToNumber");
                    var action = component.get("c.getProductInfoForQuickOrder");
                    action.setParams({quickOrderList :quickOrderArray,shipToNumber:newShipToNum1});
                    action.setCallback(this, function(response){
                        var state = response.getState();
                        if(state === 'SUCCESS'){
                            let returnValue = response.getReturnValue();
                            if (!returnValue.isSuccess) {
                                component.set("v.showSpinnerStatus", false);
                                helper.showToast("", returnValue.data, "Error", 5000);
                                return;
                            }
                            if(returnValue.data == null){
                                component.set("v.showSpinnerStatus", false);
                                helper.showToast("", $A.get("$Label.c.KM_API_Error_Message"), "Error",5000);
                            }
                            var ofmProducts = returnValue.data.responseDetail != null ?
                            returnValue.data.responseDetail : new Array();

                            var qOProducts = component.find("productInputId");
                            //Description: Fix for Price Validation in case unitPrice is missing for a product
                            //Modified By: Hardik Mehta
                            //Modified Date: 06-08-2020
                            var productWithoutUnitPrice = false;
                            if(productData){
                                productData.forEach(function(eachProd){
                                    ofmProducts.forEach(function(eachofmProd){
                                        if(eachProd.productNumber == eachofmProd.productNumber){
                                            eachProd['productName'] = eachofmProd.productDescription;
                                            eachProd['unitSize'] = eachofmProd.unitSize;
                                            if(eachofmProd.unitPrice){
                                                eachProd['unitPrice'] = eachofmProd.unitPrice;
                                            }else{
                                                productWithoutUnitPrice = true;
                                            }
                                            eachProd['currencyCode'] = eachofmProd.currencyCode;
                                            eachProd['selected'] = false;
                                        }
                                    });
                                });
                            }
                            if(productWithoutUnitPrice){
                                helper.showToast("", $A.get("$Label.c.KM_ProductPriceValidMsg"), "Error",5000);
                                component.set("v.showSpinnerStatus", false);
                                return false;
                            }

                            var isError = false;
                            qOProducts.forEach(function(eachQCProd){
                                var prodNum = eachQCProd.get("v.value");
                                if( prodNum != null && prodNum != ''){
                                    var prodFound = false;
                                    ofmProducts.forEach(function(eachProd){
                                        if(prodNum == eachProd.productNumber){
                                            prodFound = true;
                                        }
                                    });

                                    if(prodFound){
                                        $A.util.removeClass(eachQCProd, 'error-input-data' );
                                        $A.util.addClass(eachQCProd, 'success-input-data' );
                                    }else{
                                        isError = true;
                                        $A.util.removeClass(eachQCProd, 'success-input-data' );
                                        $A.util.addClass(eachQCProd, 'error-input-data' );
                                    }

                                }
                            });
                            if(isError == false){
                                component.set("v.orderedProducts",productData);
                                // check shipToNumber validation
                                var oldShipToNum = component.get("v.oldShipToNumber");
                                var newShipToNum = component.get("v.newShipToNumber");
                                if(oldShipToNum != null && oldShipToNum != ''){
                                    if(newShipToNum != oldShipToNum){
                                        component.set("v.showOrderTypePopup",false);
                                        component.set("v.showShipToPopup",true);
                                        component.set("v.showSpinnerStatus", false);
                                        return;
                                    }
                                }
                                //check orderType validation
                                var oldOrderType = component.get("v.oldOrderType");
                                if(oldOrderType == 'T9'){
                                    component.set("v.showShipToPopup",false);
                                    component.set("v.showOrderTypePopup",true);
                                    component.set("v.showSpinnerStatus", false);
                                    return;
                                }
                                //send data through addSelectedItemsToCart application event
                                var ordDetailObj = component.get("v.orderDetails");
                                var additemsAppEvent = $A.get("e.c:KMAddSelectedItemsToCart");
                                if(additemsAppEvent){
                                    additemsAppEvent.setParams({
                                        "orderedProducts": productData,
                                        "orderDetails": ordDetailObj,
                                        "replaceProducts": false
                                    });
                                    additemsAppEvent.fire();
                                }else{
                                    console.log("Event not Supported");
                                }
                                component.set("v.showSpinnerStatus", false);
                                helper.showToast("", $A.get("$Label.c.KM_QO_Items_added_Msg"), "Success",5000);
                                helper.createQuickOrderForm(component);
                            }else{
                                component.set("v.showSpinnerStatus", false);
                                helper.showToast("", $A.get("$Label.c.KM_QO_Prod_Avialable_Valid_Msg"), "Error",5000);
                            }
                        }else if(state === 'INCOMPLETE'){
                            component.set("v.showSpinnerStatus", false);
                            helper.showToast("", $A.get("$Label.c.KM_API_Error_Message"), "Error",5000);
                        }else if(state === 'ERROR'){
                            component.set("v.showSpinnerStatus", false);
                            //generic error handler
                            var errors = response.getError();
                            if(errors){
                                if(errors[0] && errors[0].message){
                                    helper.showToast("", errors[0].message, "Error",5000);
                                    console.log("Error message: " + errors[0].message+" ::Error Details: " + errors[0].stackTrace);
                                    throw new Error("Error: "+errors[0].message);
                                }
                            }else{
                                throw new Error("Unknown Error");
                            }
                        }
                    });
                    $A.enqueueAction(action);
                } catch (error) {
                    component.set("v.showSpinnerStatus", false);
                    console.log('Error: '+error);
                }

            }else{
                component.set("v.showSpinnerStatus", false);
                helper.showToast("", $A.get("$Label.c.KM_QO_Quantity_Validation_Msg"), "Error",5000);
                var qOProducts = component.find("productInputId");
                qOProducts.forEach(function(eachQCProd){
                    var prodNum = eachQCProd.get("v.value");
                    if( prodNum != null && prodNum != ''){
                        var qtyNotFound = false;
                        quickOrderArray.forEach(function(eachProd){
                            if(eachProd.productNumber != null && eachProd.productNumber != ''){
                                if(prodNum == eachProd.productNumber){
                                    if(eachProd.quantity == null || eachProd.quantity == ''){
                                        qtyNotFound = true;
                                    }
                                }
                            }
                        });
                        if(qtyNotFound){
                            $A.util.removeClass(eachQCProd, 'success-input-data' );
                            $A.util.addClass(eachQCProd, 'error-input-data' );
                        }
                    }
                });
            }
        }else{
            component.set("v.showSpinnerStatus", false);
            helper.showToast("", $A.get("$Label.c.KM_API_Error_Message"), "Error",5000);
        }
    }
})