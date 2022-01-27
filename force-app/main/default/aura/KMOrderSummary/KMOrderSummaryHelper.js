({
    setOrderSummaryData : function (component,statusName,changeQuote) {
        var promotionType = component.get("v.promotionType");
        var quote = component.get("v.quote");
        var promotionCode = component.get("v.promotionCode");
        var ordStatusEvent = component.getEvent("setOrderStatus");
        ordStatusEvent.setParams({
            "statusName": statusName,
            "promotionType":promotionType,
            "quote": quote,
            "promotionCode": promotionCode,
            "changeQuote":changeQuote
        });
        ordStatusEvent.fire();
    },
})