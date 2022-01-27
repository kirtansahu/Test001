({
    doInit : function(component, event, helper) {
        //get promotionOptions
        var promotionOptions = new Array();
        promotionOptions = [...promotionOptions,{value: 'quote',label: $A.get("$Label.c.KM_QuoteLabel")}];
        promotionOptions = [...promotionOptions,{value: 'promotionCode',label: $A.get("$Label.c.KM_PromoCodeLabel")}];
        component.set("v.promotionOptions", promotionOptions);
        var shipToNumber = component.get("v.shipToNumber");
        component.set("v.showSpinnerStatus", true);
        // calling Server side controller for getting Quotes
        var action = component.get("c.getQuoteRecords");
        action.setParams({shipToNumber : shipToNumber});
        action.setCallback(this, function(response){
            var state= response.getState();
            if(state === 'SUCCESS'){
                var quoteOptions = new Array();
                quoteOptions = [...quoteOptions,{label: '-Select-',value: ''}];
                var quoteList = response.getReturnValue();
                if(quoteList){
                    quoteList.forEach(function(eachQuote){
                        var quoteVal = eachQuote.BigMachines_Quote_Type__c + eachQuote.Name;
                        quoteOptions = [...quoteOptions,{label: quoteVal,value: quoteVal}];
                    });
                }
                component.set("v.quoteOptions", quoteOptions);
                component.set("v.showSpinnerStatus", false);
            }else if(state === 'ERROR'){
                component.set("v.showSpinnerStatus", false);
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
    reviewOrdersData: function(component, event, helper) {
        var statusName = event.getSource().get("v.name");
        helper.setOrderSummaryData(component,statusName,false);
    },
    // resetPromoCodes : function(component, event, helper) {
    //     var promoType = component.get("v.promotionType");
    //     if(promoType == 'quote'){
    //         component.set("v.promotionCode",'');
    //     }else if(promoType == 'promotionCode'){
    //         component.set("v.quote",'');
    //     }
    //     var statusName = component.get("v.statusName");
    //     helper.setOrderSummaryData(component,statusName,false);
    // },
    saveQuoteAndPromoCodes : function(component, event, helper) {
        var statusName = component.get("v.statusName");
        helper.setOrderSummaryData(component,statusName,true);
    },
    setPromotionTypeValue : function (component, event, helper) {
        var promoType = event.currentTarget.value;
        component.set("v.promotionType",promoType);
        if(promoType == 'quote'){
            component.set("v.promotionCode",'');
        }else if(promoType == 'promotionCode'){
            component.set("v.quote",'');
        }
        var statusName = component.get("v.statusName");
        helper.setOrderSummaryData(component,statusName,true);
    },
})