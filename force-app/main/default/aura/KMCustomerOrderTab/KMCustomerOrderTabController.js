({
    doInit : function (component, event, helper) {
        var backOperation = component.get("v.backOperation");
        //console.log('backOpration>> '+backOperation);
        if(backOperation){
            //Call the aura:method in the child component
            var cstSearchResultComp = component.find("customerSearchCompId");
            var customerResult = cstSearchResultComp.loadCustomerOrderSearch();
            helper.doCustomerOrdersearch(component, event, helper);
            var accRec = component.get("v.accDetail");
            helper.loadAccountContactDetails(component, accRec.Id);
            var formType = component.get("v.formType");
            if(formType == 'quickOrderForm'){
                component.set('v.hideCustomerOrder', false);
                component.set('v.showPAModel', false);
                component.set('v.showProductAvailability', false);
                component.set('v.showContactDetail', true);
                component.set('v.showCustomerOrderTable', true);
                component.set('v.showQuickOrderCapture',true);
                component.set('v.showSpinner',false);
                helper.searchResult();
            }else if(formType == 'pricingAndAvailabilityForm'){
                component.set('v.hideCustomerOrder', false);
                component.set('v.showPAModel', false);
                component.set('v.showProductAvailability', true);
                component.set('v.showContactDetail', true);
                component.set('v.showCustomerOrderTable', true);
                component.set('v.showQuickOrderCapture',false);
                component.set('v.showSpinner',false);
                var prodSearchResultComp = component.find("productSearchCompId");
                var productResult = prodSearchResultComp.loadProductsSearch();
                helper.searchResult();
            }else if(formType == 'orderHistoryBySKUForm'){
                component.set('v.hideCustomerOrder', true);
                component.set('v.showPAModel', false);
                component.set('v.showProductAvailability', false);
                component.set('v.showContactDetail', true);
                component.set('v.showCustomerOrderTable', true);
                component.set('v.showQuickOrderCapture',false);
                component.set('v.showSpinner',false);
                //insert KMOrderHistoryBYSKUTable compoent
                var tab = component.find("ordHistorybySKUTabId");
                component.set("v.tabValue","OrderHistorybySKUTabId");
                let componentName = 'c:KMOrderHistoryBYSKUTable';
                helper.injectComponent(componentName, tab,component);
            }else if(formType == 'shipToContactForm'){
                component.set('v.hideCustomerOrder', true);
                component.set('v.showPAModel', false);
                component.set('v.showProductAvailability', false);
                component.set('v.showContactDetail', true);
                component.set('v.showCustomerOrderTable', true);
                component.set('v.showQuickOrderCapture',false);
                component.set('v.showSpinner',false);
                helper.searchResult();
            }
        }
    },
    //Close action for Product availabilty Model
    closePAModel: function (cmp, event, helper) {
        cmp.set('v.showPAModel', '');
    },

    openCaptureOrderModel :function(cmp, event, helper) {
        cmp.set("v.selectedContact", null);
        cmp.set("v.showPAModel", true);
    },

    //Action to open Product availability Search
    openPASearch :function (cmp, event, helper) {
        cmp.set("v.showProductAvailability",true);
    },

    //Handler Action for the Component event which will fire from the OrderHistoryTable Component to show line Items
    handleOrderEvent: function (cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        var orderDetail = event.getParam("orderDetail");
        cmp.set('v.orderHeaderInfo', orderDetail);
        //Controller action to call OFM Service to get Line Items data
        var action = cmp.get("c.getOrderDetailList");
        //Setting data for calling API data
        action.setParams({
            "orderNumber":orderDetail.OrderNumber,
            "orderType":orderDetail.OrderType,
            "orderCompany":orderDetail.OrderCompany
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if(state === 'SUCCESS'){
                let auraResponse = response.getReturnValue();
                let actionData = auraResponse.data;
                if (auraResponse.isSuccess) {
                    if (actionData.responseDetail && actionData.responseDetail.OrderDetails) {
                        var tempArray = [];
                        tempArray = actionData.responseDetail.OrderDetails;
                        cmp.set('v.lineItems', tempArray);
                        cmp.set('v.allLineItems', tempArray);
                    }
                    else {
                        let message = $A.get("$Label.c.KM_No_Records_found");
                        helper.showToast("", message, "info", 2000);
                        cmp.set('v.lineItems', []);
                        cmp.set('v.allLineItems', []);
                    }
                }
                else {
                    helper.showToast("", actionData, "error", 5000);
                    cmp.set('v.lineItems', []);
                    cmp.set('v.allLineItems', []);
                }
            }
            else if (state === 'ERROR') {
                let errors = response.getError();
                helper.showToast("", errors[0].message, "error", 5000);
                cmp.set('v.lineItems', []);
                cmp.set('v.allLineItems', []);
            }
            cmp.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
        cmp.set('v.showLineItemSection', true);
        //Hiding Customer Order Section to show Line Items section
        var customerOrder = cmp.find('customerOrderId');
        $A.util.addClass(customerOrder, 'slds-hide');
    },

    //Action to Navigate to Account Detail Screen from Line Items Page
    navigateToAccountDetails: function(cmp, event, helper) {
        cmp.set('v.showLineItemSection', false);
        var customerOrder = cmp.find('customerOrderId');
        $A.util.removeClass(customerOrder, 'slds-hide');
        cmp.set('v.tabValue', 'OrderHistoryTabId');
        cmp.set('v.lineItems', '');
        return;
    },

    //Method can be used if required for Product availability
    openPASearch:function(component, event, helper) {
        component.set('v.hideCustomerOrder',false);
        component.set('v.showProductAvailability',true);
    },

    //Method for showing Quick Order Button Clicked
    openQuickOrder:function(component, event, helper) {
        component.set('v.hideCustomerOrder',false);
        component.set('v.showQuickOrderCapture',true);
        component.set('v.showProductAvailability',false);
    },

    backToPage: function(component, event, helper) {
        component.set('v.showContactDetail',false);
        component.set('v.showCustomerOrderTable',true);
        component.set('v.showCOSearch',true);
        var backToButtonAppEvent = $A.get("e.c:KMSendBackToButtonData");
        if(backToButtonAppEvent){
            backToButtonAppEvent.setParams({
                "backButtonData": null
            });
            backToButtonAppEvent.fire();
        }else{
            console.log("Event not Supported");
        }
    },

    backToContacts:function(component, event, helper){
        var selectedOption = component.get('v.selectedOption');
        if(selectedOption == 'ContactName' || selectedOption == 'Email' ){
            component.set('v.showProductAvailability', false);
            component.set('v.hideCustomerOrder', true);
            component.set('v.showCustomerOrderTable', false);
            component.set('v.showContactTable', true);
            component.set('v.showPAModel', false);
        }
        if(selectedOption =='ShipToAlphaName' || selectedOption == 'ShipTo' || selectedOption == 'undefined'){
            component.set('v.hideCustomerOrder', true);
            component.set('v.showPAModel', false);
            component.set('v.showProductAvailability', false);
            component.set('v.showContactDetail', true);
            component.set('v.showCustomerOrderTable', true);
        }
        component.set('v.productSearchInput','');
        helper.setBackButtonData(component);
        
    },

    backToQuickContacts :function(component, event, helper){
        var selectedOption = component.get('v.selectedOption');
        if(selectedOption == 'ContactName' || selectedOption=='Email' ){
            component.set('v.showQuickOrderCapture',false);
            component.set('v.hideCustomerOrder',true);
            component.set('v.showCustomerOrderTable',false);
            component.set('v.showContactTable',true);
            component.set('v.showPAModel',false);
        }
        if( selectedOption=='undefined' || selectedOption =='ShipToAlphaName' || selectedOption == 'ShipTo'){
            component.set('v.hideCustomerOrder',true);
            component.set('v.showPAModel',false);
            component.set('v.showQuickOrderCapture',false);
            component.set('v.showProductAvailability',false);
            component.set('v.showContactDetail',true);
            component.set('v.showCustomerOrderTable',true);
        }
        helper.setBackButtonData(component);
    },

    handleTableRowClickEvent: function(component, event, helper) {
        if (event.getParam("tableName") == "contactTable") {
            var recId = event.getParam("recordId");
            var typeofData = event.getParam("type");
            helper.openPAModel(component, recId,typeofData);
        }
        else if (event.getParam("tableName") == "shipToTable") {
            var recId = event.getParam("recordId");
            helper.openAccountDetails(component, recId);
            helper.setBackButtonData(component);
        }
    }
})