({
    isSearchable : function(component) {
        var searchInput =component.get('v.searchInput');
        if(searchInput.length >= 3) {
            return true;
        }
        else {
            return false;
        }
    },

    //Sort the Product Records
    sortByProducts: function(component,helper,field) {
        component.set('v.loaded',true);
        var sortAsc = component.get("v.sortAsc"),
            sortField = component.get("v.selectedTabsoft"),
            records = component.get("v.listofproducts");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function(a,b){
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || (a[field] < b[field]);
            return t1? 0: (sortAsc?-1:1)*(t2?1:-1);
        });
        //set values in ProductTab attribute on component.
        component.set("v.sortAsc", sortAsc);
        component.set('v.loaded',false);
        component.set("v.sortField", field);
        component.set("v.listofproducts", records);
    },

    addSelectedItemsToCart : function(component, event, helper) {
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
        var toastReference = $A.get("e.force:showToast");
        toastReference.setParams({
            "type" : "Success",
            "title" : "",
            "duration": 5000,
            "message" :$A.get("$Label.c.KM_QO_Items_added_Msg"),
            "mode" : "dismissible"
        });
        toastReference.fire();
    },

    sanitizePriceValue : function(priceValue) {
        if (priceValue != null && priceValue != undefined) {
            priceValue = priceValue.replace(/,/g, '');
        }
        return priceValue;
    },
    searchProduct : function(component,helper){
        component.set('v.ProductTable',true);
        var toastReference = $A.get("e.force:showToast");
        var prodSearchInput = component.get('v.searchInput');
        if(typeof prodSearchInput != 'undefined' && prodSearchInput != null && prodSearchInput != ''){
            component.set('v.loaded',true);
            var actions=component.get('c.getOFMProducts');
            actions.setParams({
                "inputSearchValue" : prodSearchInput,
            });
            actions.setCallback(this,function(response){
                var state=response.getState();
                if(state==='SUCCESS'){
                    component.set('v.loaded', false);
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
                    var result = returnValue.dataList;
                    //If result values equal to null or Empty,it's display the toast meaasge.
                    if(result==null || result.length==0){
                        component.set('v.loaded', false);
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 1000,
                            "message" : $A.get("$Label.c.KM_Query_Error"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        component.set('v.listofproducts',result);
                        component.set('v.allRecords',result);
                        component.set('v.Productlength',result.length);
                        return;
                    }else{
                        var productTemp=[];
                        for(var i=0;i<result.length;i++){
                            var productResult={};
                            productResult['enableButton']=true;
                            productResult['customerPrice']='';
                            productResult['koreanCurrencyCode']='';
                            productResult['SNo']=result[i];
                            productResult['SKU']=result[i].SKU;
                            productResult['searchtext']=result[i].searchtext
                            productResult['SKUdesc1']=result[i].SKUdesc1;
                            productResult['SKUdesc2']=result[i].SKUdesc2;
                            productResult['Baseunitprice']=result[i].Baseunitprice;
                            productResult['currencycode']=result[i].currencycode;
                            productTemp.push(productResult);
                        }
                        component.set('v.allRecords',productTemp);
                        var limitedProduct=[];
                        if(productTemp.length > $A.get("$Label.c.KM_Record_Limits")){
                            for(var j=0; j<$A.get("$Label.c.KM_Record_Limits"); j++){
                                limitedProduct.push(productTemp[j]);
                            }
                            component.set('v.listofproducts',limitedProduct);
                            component.set('v.Productlength',limitedProduct.length);
                            helper.sortByProducts(component,helper, 'SKU');
                        }
                        else{
                            component.set('v.listofproducts',productTemp);
                            component.set('v.Productlength',component.get('v.listofproducts').length);
                            helper.sortByProducts(component,helper, 'SKU');
                        }
                    }

                }else if(state === "ERROR"){
                    component.set('v.loaded', false);
                    var errors=response.getError();
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
                            throw new Error("Error: "+errors[0].message);
                        }
                    }else{
                        throw new Error("Unknown Error");
                    }
                }
            });
            $A.enqueueAction(actions);
        }
        helper.setBackButtonData(component,prodSearchInput);
    },
    setBackButtonData : function(component,prodInputSearch){
        prodInputSearch = typeof prodInputSearch != 'undefined' && prodInputSearch != null ? prodInputSearch : '';
        var orderButton = component.get("v.orderButton");
        if(orderButton){
            var accRec = component.get("v.accountRec");
            var conRec = component.get("v.contactRec");
            var backBtnData = {};
            backBtnData['tabAuraId'] = "customerOrdersId";
            backBtnData['selectedOption'] = component.get("v.selectedOption");
            backBtnData['searchInput'] = component.get("v.cusSearchInput");
            backBtnData['accountData'] = accRec;
            backBtnData['contactData'] = conRec;
            backBtnData['productSearchInput'] = prodInputSearch;
            backBtnData['formType'] = "pricingAndAvailabilityForm";
            var backToButtonAppEvent = $A.get("e.c:KMSendBackToButtonData");
            if(backToButtonAppEvent){
                backToButtonAppEvent.setParams({
                    "backButtonData": backBtnData
                });
                backToButtonAppEvent.fire();
            }else{
                console.log("Event not Supported");
            }
        }
    },


})