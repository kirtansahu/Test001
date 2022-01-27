({
    doInit : function(component, event, helper) {
        var toastReference = $A.get("e.force:showToast");
        component.set('v.loaded',true);
        //calling the KM Base Component with pass parameters
        helper.callServer(component,'c.getArExtention',
            {
                invoiceCompany :component.get('v.Incompany'),
                invoiceNumber :component.get('v.InvoiceNo'),
                invoicetype : component.get('v.InType')
            },
            function(response){
                let auraResponse = response;
                let resultValues = auraResponse.dataList;
                if (auraResponse.isSuccess) {
                    component.set('v.loaded',false);
                    if (resultValues.length==0 || resultValues==null) {
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 1000,
                            "message" : $A.get("$Label.c.KM_No_Records_found"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        return;
                    }
                    else{
                        //Set the response in listofArextentions attribute component
                        component.set('v.listofArextentions',resultValues);
                    }
                }
                else {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 1000,
                        "message" : resultValues,
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    return;
                }
            }
        )
    }
})