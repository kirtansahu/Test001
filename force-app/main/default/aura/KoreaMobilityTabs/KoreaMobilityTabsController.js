({
    handleActive: function(component, event, helper) {
        
        helper.getCartData(component);
        helper.loadTabs(component, event);
    },
    setBackButtonData : function(component, event, helper) {
        var backBtnData = event.getParam("backButtonData");
        component.set("v.backButtonData", backBtnData);
    },
    changetoPreviousTab: function(component, event, helper) {
        component.set("v.backOperation", true);
        try {
            var backBtnData = component.get("v.backButtonData");
            if(typeof backBtnData != 'undefined' && backBtnData != null){
                var tab = component.find(backBtnData.tabAuraId);
                component.set("v.selectedTabId", tab.get('v.id'));
                let componentName = 'c:' + tab.get('v.id');
                helper.injectComponent(componentName, tab, component);
            }
        } catch (error) {
            if(error){
                console.log('Error message>> '+error.message+' <<Error Trace>> '+error.stackTrace);
            }
        }
        component.set("v.backOperation", false);
    },
    selectedItemsCount : function (component, event, helper) {
        try{
            var existedProducts = component.get("v.selectedProducts");
            var newProducts = event.getParam("orderedProducts");
            var newOrdDetails = event.getParam("orderDetails");
            var replaceProducts = event.getParam("replaceProducts");
            if(replaceProducts){
                existedProducts = newProducts;
            }else{
                existedProducts = [...existedProducts,...newProducts];
            }
            component.set("v.selectedProducts",existedProducts);
            component.set("v.orderDetails",newOrdDetails);
            component.set("v.selectedProductCount",existedProducts.length);
            var orderDetailObj = {};
            if(existedProducts.length > 0){
                orderDetailObj = newOrdDetails;
            }
            helper.saveCartData(component,JSON.stringify(existedProducts),JSON.stringify(orderDetailObj));
        }catch(e){
            console.log(e);
        }
    }
})