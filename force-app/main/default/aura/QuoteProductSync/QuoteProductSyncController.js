({
    init : function(component, event, helper) {
        helper.startWaiting(component);
        component.set('v.columns', [
            {label: 'SKU #', fieldName: 'linkProduct', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Product_Name__c' }, target: '_blank'}},
            {label: 'SKU Name', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'Product_Alias_Name__c' }, target: '_blank'}}, 
            {label: 'Net Price', fieldName: 'BigMachines__Sales_Price__c', type: 'currency', typeAttributes: { currencyCode: 'USD'}, cellAttributes: { alignment: 'left' }},
            {label: 'Qty', fieldName: 'BigMachines__Quantity__c', type: 'number', cellAttributes: { alignment: 'left' }}
        ]);
        component.set('v.columnsNew', [
            {label: 'SKU #', fieldName: 'linkProduct', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'SKU_Number__c' }, target: '_blank'}},
            {label: 'SKU Name', fieldName: 'linkName', type: 'url', sortable : true, typeAttributes: {label: { fieldName: 'SKU_Name__c' }, target: '_blank'}},
            {label: 'Sales Price', fieldName: 'UnitPrice', type: 'currency', typeAttributes: { currencyCode: 'USD'}, cellAttributes: { alignment: 'left' }},
            {label: 'Total Qty', fieldName: 'Quantity', type: 'number', cellAttributes: { alignment: 'left' }}
        ]);
        helper.doCallout(component, 'c.doInit', { quoteId : component.get("v.recordId") }, function(response) {
            let state = response.getState();
            if(state === "SUCCESS"){ 
                var resultWrapper = response.getReturnValue();
                var quoteProducts = resultWrapper.quoteProducts;
                quoteProducts.forEach(function(record){
                    record.linkName = '/'+record.Id;
                    record.linkProduct = '/'+record.BigMachines__Product__c;
                });
                var oppProducts = resultWrapper.opportunityProducts;
                oppProducts.forEach(function(record){
                    record.linkName = '/'+record.Id;
                    record.linkProduct = '/'+record.Product2Id;
                });
                component.set("v.data", resultWrapper.quoteProducts);
                component.set("v.dataNew", resultWrapper.opportunityProducts);
                component.set("v.loaded", resultWrapper.showData);
                component.set("v.qualified", resultWrapper.showComponent);
                component.set("v.errorMessage", resultWrapper.errorMessage);
                component.set("v.quoteHeader", resultWrapper.quoteHeader);
                component.set("v.oppHeader", resultWrapper.oppHeader);
                component.set("v.quotePricelist", resultWrapper.quotePricelist);
                component.set("v.oppPricelist", resultWrapper.oppPricelist);
                component.set("v.oppRecId", resultWrapper.oppRecId);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                helper.handleErrors(component, errors);
            }
            helper.stopWaiting(component);
        });
    },

    handleSave : function(component, event, helper) {
        helper.doCallout(component, 'c.upsertOpportunityProducts', { quoteProductRecords : component.find('product-table').getSelectedRows(), oppId : component.get("v.oppRecId")}, function(response) {
            var state = response.getState();
            if(state === "SUCCESS"){ 
                var resultStr = response.getReturnValue();
                if(resultStr === 'SUCCESS'){
                    helper.doShowToast(component,"Sync Complete!",$A.get("$Label.c.QUOTE_PRODUCTSYNC_SUCCESSMESSAGE"),"success","success");
                }else{
                    helper.doShowToast(component,"Sync Errored Out!",$A.get("$Label.c.QUOTE_PRODUCTSYNC_ERRORMESSAGE"),"error","error"); 
                }
                helper.doCallout(component, 'c.opportunityProductData', { oppId : component.get("v.oppRecId") }, function(response) {
                    var state = response.getState();
                    if(state === "SUCCESS"){ 
                        var records =response.getReturnValue();
                        records.forEach(function(record){
                            record.linkName = '/'+record.Id;
                            record.linkProduct = '/'+record.Product2Id;
                        });
                        component.set("v.dataNew", response.getReturnValue());
                        component.set("v.selectedRows", []);
                        component.set("v.greyButton", true);
                    } else if (component.isValid() && state === 'ERROR') {
                        var errors = response.getError();
                        helper.handleErrors(component, errors);
                    }
                });
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                helper.handleErrors(component, errors);
            }
        });
    },
    
    handleExit : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleSort : function(component,event,helper){
        var sortBy = event.getParam("fieldName");
        var sortDirection = event.getParam("sortDirection");
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        helper.sortData(component,sortBy,sortDirection);
    },

    enableSyncButton : function(component, event, helper) {
        component.set("v.greyButton", false);
        var selectedRows = event.getParam('selectedRows');
        if(selectedRows && selectedRows.length > 0){
        	component.set("v.greyButton", false);
        }else{
            component.set("v.greyButton", true);
        }
    },
})