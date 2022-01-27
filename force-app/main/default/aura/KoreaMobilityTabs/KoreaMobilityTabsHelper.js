({
    loadTabs : function (component, event) {
        var tab = event.getSource();
        let componentName = 'c:' + tab.get('v.id');
        if(componentName != 'c:KMOrdersTab'){
            // component.set("v.backButtonData", null);
            // component.set("v.backOpration", false);
        }
        this.injectComponent(componentName, tab, component);
    },

    //Helper Method to add content with component to tab
    injectComponent: function (name, target, component) {
        let params = {};
        if(name == 'c:KMOrdersTab'){
            var backBtnData = component.get("v.backButtonData");
            var backOperation = false;
            if(typeof backBtnData != 'undefined' && backBtnData != null){
                backOperation = true;
            }
            params = {
                "selectedProducts": component.get("v.selectedProducts"),
                "orderDetails": component.get("v.orderDetails"),
                "estimatedTotal": component.get("v.estimatedTotal"),
                "backButtonData": component.get("v.backButtonData"),
                "enableBackButton" : backOperation
            };
        }else if(name == 'c:KMCustomerOrderTab'){
            var backButton =  component.get("v.backOperation");
            if(!backButton){
                component.set("v.backButtonData",null);
            }
            if(backButton){
                var backBtnData = component.get("v.backButtonData");
                var conData = typeof backBtnData.contactData != 'undefined' && backBtnData.contactData != null ? backBtnData.contactData : null;
                var prodSearchInput = typeof backBtnData.productSearchInput != 'undefined' && backBtnData.productSearchInput != null ? backBtnData.productSearchInput: '';
                params = {
                    "backOperation" : backButton,
                    "formType":backBtnData.formType,
                    "selectedOption":backBtnData.selectedOption,
                    "searchInput":backBtnData.searchInput,
                    "accDetail" : backBtnData.accountData,
                    "selectedContact" : conData,
                    "productSearchInput": prodSearchInput
                };
            }
            
        }else{
            var backButton =  component.get("v.backOperation");
            if(!backButton){
                component.set("v.backButtonData",null);
            }
        }
        $A.createComponent(
            name,
            params,
            function (contentComponent, status, error) {
                if (status === "SUCCESS") {
                    let selectedProducts = component.get("v.selectedProducts");
                    if (selectedProducts) {
                        component.set("v.selectedProductCount", selectedProducts.length);
                    }
                    target.set('v.body', contentComponent);
                } else {
                    throw new Error(error);
                }
            }
        );
    },

    saveCartData : function(component,productData,orderDetails){
        var action = component.get("c.saveCartData");
        //console.log('--productData: ', productData);
        action.setParams({productData:productData,orderDetails:orderDetails});
        action.setCallback(this, function(response){
            var state= response.getState();
            if(state === 'SUCCESS'){
                var success = response.getReturnValue();
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

    getCartData : function(component){
        var action = component.get("c.getCartData");
        action.setCallback(this, function(response){
            var state= response.getState();
            if(state === 'SUCCESS'){
                var savedProducts = response.getReturnValue().productList != null ?
                response.getReturnValue().productList : new Array();
                var savedOrderDetails = response.getReturnValue().orderDetails != null ?
                response.getReturnValue().orderDetails : {};

                component.set("v.selectedProducts",savedProducts);
                component.set("v.orderDetails",savedOrderDetails);
                component.set("v.selectedProductCount", savedProducts.length);

                var totalAmount = 0;
                if(savedProducts.length > 0){
                    savedProducts.forEach(function(eachProduct){
                        if(typeof eachProduct.unitPrice != 'undefined' && eachProduct.unitPrice != '' && eachProduct.unitPrice != null){
                            totalAmount = totalAmount + (Number(eachProduct.unitPrice) * Number(eachProduct.quantity));
                        }
                    });
                }
                component.set("v.estimatedTotal",totalAmount);
                //setting total amount into order details
                var ordDetailObj1 =  component.get("v.orderDetails");
                var totalAmt =  JSON.stringify(totalAmount);
                ordDetailObj1['estimatedTotal'] = totalAmt;
                component.set("v.orderDetails",ordDetailObj1);
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
})