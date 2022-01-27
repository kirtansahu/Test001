({
    //Enable & Disable the Search Button
    handleSearchInputChange : function(component, event, helper) {
        component.find('searchButton').set('v.disabled', !helper.isSearchable(component));
    },

    handleSearchInputKeyPress : function(component,event,helper){
        if (event.which == 13 && helper.isSearchable(component)) {
           helper.accountSearch(component);
        }
    },

    // Get List of Accounts from Apex controller.
    doSearch : function(component, event, helper) {
        helper.accountSearch(component);
    },

    sortByST : function(component, event, helper)
    {
        var fieldName = event.currentTarget.id;
        // call the helper function with pass fieldName
        helper.sortBy(component,helper, fieldName);
        component.set("v.AccselectedTabsoft1", fieldName);
        var a=component.get("v.AccsortAsc");
    },

    viewMoreRecords:function(component, event, helper)
    {
        component.set('v.loaded',true);
        var result=component.get('v.listofShipto');
        helper.callServer
        (
            component,
            'c.getAccountReceivableDetails',
            {
                // AccountLimit: component.get('v.AccountLimit'),
                accountOffset :result.length,
                searchtext :component.get('v.searchInput')
            },
            function(response)
            {
                component.set('v.loaded',false);
                if(response.length==0 || response.length < $A.get('$Label.c.KM_Record_Limits'))
                {
                    component.set('v.Accountlength',response.length);
                    for(var i=0;i<response.length;i++){
                        result=[...result,response[i]];
                    }
                    component.set('v.listofShipto',result);
                }
                else
                {
                    for(var i=0;i<response.length;i++){
                        result=[...result,response[i]];
                    }
                    component.set('v.listofShipto',result);
                    component.set('v.Accountlength',result.length);
                }
            }
        )
    },

    //Get OFM data from Apex controller
    openAccountDetails : function(component, event, helper) {
        component.set('v.loaded', true);
        var ShipToNumber = event.currentTarget.dataset.id;
        component.set("v.ArPage2", true);
        component.set("v.showAccountTable", false);
        component.set("v.showSearch", false);
        component.set("v.ARInvoicedetailsPage", false);
        // call the helper function with pass method Name,Ship to Number
        helper.callServer
        (
            component,
            'c.getparticularAccount',
            {
                accountId : ShipToNumber
            },
            function(response)
            {
                //set response value in Account attribute on component.
                component.set('v.Account', response);
                component.set('v.loaded', false);
            }
        );
        // Call to get Account Receivables
        var getResponse = component.get("c.getOFMResponse");
        getResponse.setParams({"shipTo":ShipToNumber});
        getResponse.setCallback(this, function(response) {
            console.log('response state: ', JSON.stringify(response.getState()));
            console.log('response value: ', JSON.stringify(response.getReturnValue()));
            var state = response.getState();
            var toastReference = $A.get("e.force:showToast");
            if(state === 'SUCCESS') {
                let auraResponse = response.getReturnValue();
                let arResult = auraResponse.data;
                if (auraResponse.isSuccess) {
                    component.find('Selects').set('v.value','');
                    component.set('v.Selectedvalue',true);
                    component.set('v.SearchBoxInputs','');
                    component.set('v.InvoiceListSearchBox',true);
                    component.set('v.SelectedOrderType',false);
                    component.set('v.Selecteddate',false);
                    if(arResult==null  || JSON.stringify(arResult)=='{"responseHeader":{}}' || arResult.length=='undefined' ) {
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 1000,
                            "message" :  $A.get("$Label.c.KM_No_Records_found"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        component.set('v.InvoiceLists', arResult);
                        return;
                    }
                    else {
                        //set response value in ARDetails attribute on component.
                        component.set('v.ARDetails', arResult.responseARHeader);
                        var fromDate = new Date();
                        var result=[];
                        var tt = fromDate.setDate(fromDate.getDate() -180);
                        //var previousYrDt = fromDate.getFullYear() + "/" + (fromDate.getMonth() + 1) + "/" + fromDate.getDate();
                        for(var i=0; i< arResult.responseARDetail.length; i++) {
                            //if(response.getReturnValue().responseARDetail[i].invoiceDate>previousYrDt)
                            result.push(arResult.responseARDetail[i]);
                        }
                        component.set('v.InvoiceLists', result);
                        component.set('v.unfilterdata', result);
                        component.find('Selects').set('v.value','Filter By');
                    }
                }
                else {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" : arResult,
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    throw new Error("Error: "+ arResult);
                }
            }
            else if(state==='ERROR'){
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
        $A.enqueueAction(getResponse);
    },

    SelectOptions:function(component, event, helper)
    {
        //get the value of select option
        var Selectedvalue= component.find('Selects').get('v.value');
        component.set('v.option',Selectedvalue);
        if(Selectedvalue==='Order#' ||  Selectedvalue==='Invoice Number')
        {
            component.find('ApplyButton').set('v.disabled',false);
            //Set the values to component Attributes
            component.set('v.Selectedvalue',true);
            component.set('v.InvoiceListSearchBox',false);
            component.set('v.SelectedOrderType',false);
            component.set('v.Selecteddate',false);
            component.set('v.SearchBoxInputs','');
            component.set('v.fromDate','');
            component.set('v.toDate','');
            component.find('ApplyButton').set('v.disabled',false);
        }
        if(Selectedvalue=='Filter By')
        {
            component.set('v.Selectedvalue',true);
            component.set('v.SelectedOrderType',false);
            component.set('v.Selecteddate',false);
            component.set('v.InvoiceListSearchBox',true);
            component.set('v.SearchBoxInputs','');
            component.set('v.fromDate','');
            component.set('v.toDate','');
            component.find('ApplyButton').set('v.disabled',true);
            component.find('Clearbutton').set('v.disabled',true);
        }
        if(Selectedvalue =='Order Type')
        {
            component.find('ApplyButton').set('v.disabled',false);
            component.set('v.Selectedvalue',false);
            component.set('v.SelectedOrderType',true);
            component.set('v.InvoiceListSearchBox',false);
            component.set('v.Selecteddate',false);
        }
        if(Selectedvalue ==='Invoice Date')
        {
            component.set('v.Selectedvalue',false);
            component.set('v.SelectedOrderType',false);
            component.set('v.Selecteddate',true);
            component.find('ApplyButton').set('v.disabled',false)
        }
    },

    sortBy1: function(component, event, helper)
    {
        var fieldName = event.currentTarget.id;
        // call the helper function with pass sortField Name
        helper.sortBy1(component, helper, fieldName);
        component.set("v.selectedTabsoft1", fieldName);
    },

    doApply:function(component, event, helper)
    {
        //get the value of select option
        var selField= component.find('Selects').get('v.value');
        component.find('Clearbutton').set('v.disabled',false);
        var allRecords = component.get("v.InvoiceLists");
        var toastReference = $A.get("e.force:showToast")
        var tempArray = [];
        var setOrderType = new Set();
        if(selField == 'Order Type')
        {
            var selectedTypes = component.find("OrderTypeforOH").get("v.selectedOptions");
            for(var j = 0; j < selectedTypes.length ; j++)
            {
                var item=selectedTypes[j];
                setOrderType.add(item.Id.toUpperCase());
            }
        }
        for(var i=0; i < allRecords.length; i++)
        {
            if(selField== 'Order Type')
            {
                if(allRecords[i].orderType)
                {
                    if(setOrderType.has(allRecords[i].orderType.toUpperCase())){
                        tempArray.push(allRecords[i]);
                        component.set('v.loaded',false);
                    }
                }
            }
            if(selField =='Invoice Number')
            {
                var searchKey1=component.get('v.SearchBoxInputs');
                if(allRecords[i].invoiceNumber)
                {
                    if((allRecords[i].invoiceNumber && (allRecords[i].invoiceNumber+'').indexOf(searchKey1) > -1))
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            if(selField =='Order#')
            {
                var searchKey=component.get('v.SearchBoxInputs');
                if(allRecords[i].orderNumber)
                {
                    if((allRecords[i].orderNumber && (allRecords[i].orderNumber+'').indexOf(searchKey) != -1))
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            if(selField == 'Invoice Date')
            {
                if(component.get("v.fromDate")=='' || component.get("v.toDate")=='')
                {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                }
                else
                {
                    if(allRecords[i].invoiceDate != '')
                        var frmDt = component.get("v.fromDate");
                    var toDt = component.get("v.toDate") != null?component.get("v.toDate"):new Date();
                    var orDate = new Date(allRecords[i].invoiceDate);
                    if(new Date(orDate) > new Date(frmDt) && new Date(orDate) < new Date(toDt))
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
        }
        var toastReference = $A.get("e.force:showToast");
        if(tempArray.length==0)
        {
            // toastReference.setParams({
            //     "type" : "Error",
            //     "title" : "",
            //     "duration": 1000,
            //     "message" : $A.get("$Label.c.KM_No_Records_found"),
            //     "mode" : "dismissible"
            // });
            // toastReference.fire();
            component.set("v.InvoiceLists",tempArray);
            component.set('v.loaded',false);
            return;
        }
        else
        {
            //set response value in InvoiceLists attribute on component.
            component.set('v.loaded',false);
            component.set("v.InvoiceLists",tempArray);
        }
    },

    doclear:function(component, event, helper)
    {
        //component.set('v.loaded',true);
        //get the value of select option
        var SelectedOptions= component.find('Selects').get('v.value');
        if(SelectedOptions==='Order#' || SelectedOptions==='Invoice Number'|| SelectedOptions==='Invoice Date'|| SelectedOptions==='Order Type')
        {
            //set the values to component attributes
            component.set('v.Selectedvalue',true);
            component.find('Selects').set('v.value','Filter By');
            component.find('ApplyButton').set('v.disabled',true);
            component.find('Clearbutton').set('v.disabled',true);
            component.set("v.InvoiceLists",component.get('v.unfilterdata'));
            component.set('v.SelectedOrderType',false);
            component.set('v.loaded',false);
            component.set('v.InvoiceListSearchBox',true);
            component.set('v.SelectedOrderType',false);
            component.set('v.Selecteddate',false);
            component.set('v.SearchBoxInputs','');
            component.set('v.fromDate','');
            component.set('v.toDate','');
        }
        component.set("v.InvoiceLists",component.get('v.unfilterdata'));
    },

    checkDateValue:function(component, event, helper)
    {
        //Get the Selected dates
        var fromdate =component.find('fromDateField').get('v.value');
        var enddate =component.find('EndDateField').get('v.value');
        var toastReference = $A.get("e.force:showToast");
        if(fromdate!='' && enddate!='')
        {
            if(fromdate>enddate)
            {
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 1000,
                    "message" :$A.get("$Label.c.KM_FromDate_Lessthan_Todate"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
                component.find('fromDateField').set('v.value','');
                component.find('EndDateField').set('v.value','');
            }
            else
            {
                if(fromdate != null)
                    // call the helper function with pass fromdate
                    helper.dateValidation(component,fromdate,'fromDate');
                if(enddate != null)
                    // call the helper function with pass Enddate
                    helper.dateValidation(component,enddate, 'EndDate');
            }
        }
    },

    //Get All Invoice details from Apex controller
    OpenInvoicedetails:function(component, event, helper)
    {
        component.set('v.loaded',true);
        component.set("v.showSearch",false);
        component.set("v.showAccountTable",false);
        component.set("v.ArPage2",false);
        component.set("v.ARInvoicedetailsPage",true);
        var OrderNum=event.currentTarget.dataset.ordernumbers;
        var OrderTypes=event.currentTarget.dataset.types;
        var ordercompany=event.currentTarget.dataset.comapny;
        var invoiceNo=event.currentTarget.dataset.invoicenumber;
        var orderPoNo=event.currentTarget.dataset.opnumber;
        var orderdate=event.currentTarget.dataset.orderdate;
        component.set("v.InvoiceNumbers",invoiceNo);
        component.set("v.Orderno",OrderNum);
        component.set("v.Ordertypes",OrderTypes);
        component.set("v.customerPo",orderPoNo);
        component.set("v.orderdate",orderdate);
        component.set('v.listInvoiceType',event.currentTarget.dataset.invoicevalue)
        var toastReference = $A.get("e.force:showToast");
        var actionItems=component.get('c.getInvoicedetails');
        actionItems.setParams({
            'orderNumber' :OrderNum,
            'orderType' :OrderTypes,
            'orderCompany':ordercompany
        });
        actionItems.setCallback(this,function(response){
            var state=response.getState();
            component.set('v.loaded',false);
            component.set('v.ARInvoicedetails',[]);
            component.set('v.unfilterInvoices',[]);
            if(state==='SUCCESS'){
                let auraResponse = response.getReturnValue();
                let invoiceResult = auraResponse.dataList;
                if (auraResponse.isSuccess) {
                    if(invoiceResult.length==0 || invoiceResult.length==null){
                        toastReference.setParams({
                            "type" : "Error",
                            "title" : "",
                            "duration": 1000,
                            "message" : $A.get("$Label.c.KM_No_Records_found"),
                            "mode" : "dismissible"
                        });
                        toastReference.fire();
                        component.set('v.ARInvoicedetails',invoiceResult);
                    }
                    else{
                        component.set('v.ARInvoicedetails',invoiceResult);
                        component.set('v.unfilterInvoices',invoiceResult);
                    }
                }
                else {
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" : auraResponse.data,
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    throw new Error("Error: "+invoiceResult);
                }
            }
            else if(state==='ERROR'){
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
        $A.enqueueAction(actionItems);
    },

    //Get the Selected Options from Filter
    InvoiceSelectOptions :function(component, event, helper)
    {
        //Get the Selected options
        var InvoiceOptions=component.find('InvoiceSelects').get('v.value');
        if(InvoiceOptions=='Filter By')
        {
            component.find('InvoiceApplybutton').set('v.disabled',true);
            component.find('Invoiceclearbutton').set('v.disabled',true);
            component.set('v.InvoiceTexts',true);
            component.set('v.InvoiceInputSearchBox','');
            component.set('v.Invoiceinoutdisabled',true);
            component.set('v.InvoicefromDate','');
            component.set('v.InvoicetoDate','');
            component.set('v.invoiceorderTypes',false);
            component.set('v.invoiceShipmentdates',false);
        }
        if(InvoiceOptions== 'Order#'|| InvoiceOptions=='Ship-To#'|| InvoiceOptions=='Product Name' || InvoiceOptions=='Product#')
        {
            component.find('InvoiceApplybutton').set('v.disabled',false);
            component.set('v.InvoiceTexts',true);
            component.set('v.Invoiceinoutdisabled',false);
            component.set('v.InvoiceInputSearchBox','');
            component.set('v.InvoicefromDate','');
            component.set('v.InvoicetoDate','');
            component.set('v.invoiceorderTypes',false);
            component.set('v.invoiceShipmentdates',false);
        }
        if(InvoiceOptions=='Shipment Date')
        {
            component.set('v.InvoiceTexts',false);
            component.set('v.invoiceorderTypes',false);
            component.set('v.invoiceShipmentdates',true);
            component.find('InvoiceApplybutton').set('v.disabled',false);
        }
        if(InvoiceOptions =='Order Type')
        {
            component.find('InvoiceApplybutton').set('v.disabled',false);
            component.set('v.InvoiceTexts',false);
            component.set('v.invoiceorderTypes',true);
            component.set('v.invoiceShipmentdates',false);
        }
    },

    sortBy2 : function(component, event, helper)
    {
        var fieldName = event.currentTarget.id;
        helper.sortBy2(component,helper, fieldName);
        component.set("v.selectedTabsoft2", fieldName);
        var a=component.get("v.sortAsc2");
    },

    doInvoiceApply:function(component, event, helper)
    {
        //var searchKey=component.find('FilterInput').get('v.value');
        component.set('v.loaded',true);
        var toastReference = $A.get("e.force:showToast");
        //Get the Selected options
        var selField= component.find('InvoiceSelects').get('v.value');
        component.find('Invoiceclearbutton').set('v.disabled',false);
        var allRecords = component.get("v.ARInvoicedetails");
        var tempArray = [];
        var setOrderType = new Set();
        if(selField == 'Order Type')
        {
            var selectedTypes = component.find("OrderTypeforOH1").get("v.selectedOptions");
            for(var j = 0; j < selectedTypes.length ; j++)
            {
                var item=selectedTypes[j];
                setOrderType.add(item.Id.toUpperCase());
            }
        }
        for(var i=0; i < allRecords.length; i++)
        {
            if(selField== 'Order Type')
            {
                if(allRecords[i].OrderType)
                {
                    if(setOrderType.has(allRecords[i].OrderType.toUpperCase()))
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
            if(selField =='Order#')
            {
                var searchKey=component.get('v.InvoiceInputSearchBox');
                if((allRecords[i].OrderNum && (allRecords[i].OrderNum+'').indexOf(searchKey) != -1))
                {
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField =='Ship-To#')
            {
                var searchKey1=component.get('v.InvoiceInputSearchBox');
                if((allRecords[i].ShipToNum && (allRecords[i].ShipToNum+'').indexOf(searchKey1) != -1) )
                {
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField =='Product Name')
            {
                var searchKey1=component.get('v.InvoiceInputSearchBox');
                if((allRecords[i].ProductName && allRecords[i].ProductName.toUpperCase().indexOf(searchKey1) != -1))
                {
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField =='Product#')
            {
                var searchKey1=component.get('v.InvoiceInputSearchBox');
                if((allRecords[i].ProductNum && allRecords[i].ProductNum.toUpperCase().indexOf(searchKey1) != -1))
                {
                    tempArray.push(allRecords[i]);
                }
            }
            if(selField=='Shipment Date')
            {
                if(component.get('v.InvoicefromDate')=='' || component.get('v.InvoicetoDate')=='')
                {
                    component.set('v.loaded',false);
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 5000,
                        "message" :$A.get("$Label.c.KM_FromDate_ToDate"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    component.set('v.loaded',false);
                }
                else
                {
                    if(allRecords[i].ShipmentDate != '')
                        var frmDt = component.get("v.InvoicefromDate");
                    var toDt = component.get("v.InvoicetoDate") != null?component.get("v.InvoicetoDate"):new Date();
                    var orDate = new Date(allRecords[i].ShipmentDate);
                    if(new Date(orDate) > new Date(frmDt) && new Date(orDate) < new Date(toDt))
                    {
                        tempArray.push(allRecords[i]);
                    }
                }
            }
        }
        var toastReference = $A.get("e.force:showToast");
        if(tempArray.length==0)
        {
            component.set("v.ARInvoicedetails", tempArray);
            component.set('v.loaded',false);
            // toastReference.setParams({
            //     "type" : "Error",
            //     "title" : "",
            //     "duration": 1000,
            //     "message" : $A.get("$Label.c.KM_No_Records_found"),
            //     "mode" : "dismissible"
            // });
            // toastReference.fire();
            return;
        }
        else
        {
            //Set response in ARInvoicedetails attribute on Component
            component.set('v.loaded',false);
            component.set("v.ARInvoicedetails", tempArray);
        }
    },

    //Clear the Filter
    doInvoiceclear:function(component,event,helper)
    {
        component.set('v.loaded',true);
        var InvoiceOptions= component.find('InvoiceSelects').get('v.value');
        // component.set('v.loaded',false);
        if(InvoiceOptions== 'Shipment Date' || InvoiceOptions =='Order Type'|| InvoiceOptions =='Ship-To#' || InvoiceOptions=='Order#' || InvoiceOptions=='Product Name' || InvoiceOptions=='Product#')
        {
            component.set('v.InvoiceTexts',true);
            component.find('InvoiceSelects').set('v.value','Filter By');
            component.set('v.Invoiceinoutdisabled',true);
            component.set('v.loaded',false);
            component.set('v.InvoiceInputSearchBox','');
            component.set("v.ARInvoicedetails",component.get('v.unfilterInvoices'));
            component.find('InvoiceApplybutton').set('v.disabled',true);
            component.find('Invoiceclearbutton').set('v.disabled',true);
            component.set('v.invoiceorderTypes',false);
            component.set('v.invoiceShipmentdates',false);
            component.set('v.InvoicefromDate','');
            component.set('v.InvoicetoDate','');
        }
        //Set response in ARInvoicedetails attribute component
        component.set("v.ARInvoicedetails",component.get('v.unfilterInvoices'));
        component.set('v.loaded',false);
    },

    Invoicedatevalidation :function(component,event,helper){
        //Get the Selected Dates
        var fromdate =component.find('InfromDateField').get('v.value');
        var enddate =component.find('INEndDateField').get('v.value');
        var toastReference = $A.get("e.force:showToast");
        if(fromdate !='' && enddate!='')
        {
            if(fromdate>enddate)
            {
                toastReference.setParams({
                    "type" : "Error",
                    "title" : "",
                    "duration": 1000,
                    "message" : $A.get("$Label.c.KM_FromDate_Lessthan_Todate"),
                    "mode" : "dismissible"
                });
                toastReference.fire();
                component.find('InfromDateField').set('v.value','');
                component.find('INEndDateField').set('v.value','');
            }
            else
            {
                if(fromdate != null)
                    //call helper function with pass fromDate
                    helper.InvoicedateValidation(component,fromdate,'fromDate');
                if(enddate != null)
                    //call helper function with pass Enddate
                    helper.InvoicedateValidation(component,enddate, 'EndDate');
            }
        }
    },

    ArExtentiondetails :function(component,event,helper){
        // Get Selected record data
        component.set('v.loaded',true);
        var ARrecord=event.getSource().get('v.name');
        //callin the modalpopup component.
        $A.createComponent
        (
            "c:KMAccountReceivableModalPopUp",
            {
                "InType": ARrecord.invoiceType,
                "Incompany": ARrecord.invoiceCompany,
                "InvoiceNo": ARrecord.invoiceNumber
            },
            function(content, status) {
                if (status === "SUCCESS") {
                    component.set('v.loaded',false);
                    component.find('overlayLib').showCustomModal({
                        header:  $A.get("$Label.c.KM_Account_Receivables"),
                        body: content,
                        showCloseButton: true,
                        cssClass: "mymodal"
                    });
                }else if(state==='ERROR'){
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
            }
        );
    },

    backToPage:function(component,event,helper){
        component.set('v.ArPage2', false);
        component.set('v.showAccountTable', true);
        component.set('v.showSearch', true);
        component.find('searchButton').set('v.disabled', false);
        component.set('v.InvoiceLists',new Array());
    },

    backToAccountHeaderPage:function(component,event,helper){
        component.set('v.ARInvoicedetailsPage',false);
        component.set('v.ArPage2',true);
        var options=component.get('v.option');
        if(options=='Order#' || options== 'Order Type' || options =='Invoice Number' || options=='Invoice Date')
        {
            component.find('Selects').set('v.value',options);
            component.find('ApplyButton').set('v.disabled',false);
            component.find('Clearbutton').set('v.disabled',false);
            component.set('v.option','Filter By');
        }
        if(options== 'Filter By'|| options=='undefined')
        {
            component.find('Selects').set('v.value',options);
            component.find('ApplyButton').set('v.disabled',true);
            component.find('Clearbutton').set('v.disabled',true);
        }

    },

    downloadCsv : function(component,event,helper){

        // get the Records [Invoice] list from 'ListOfContact' attribute
        var stockData = component.get("v.InvoiceLists");

        // call the helper function which "return" the CSV data as a String
        var csv = helper.convertArrayOfObjectsToCSV(component,stockData);
        if (csv == null){return;}

        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####
        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self'; //
        hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv]
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click(); // using click() js function to download csv file
    },

    downloadCsv1 : function(component,event,helper){
        // get the Records [Invoice] list from 'ListOfContact' attribute
        var stockData = component.get("v.ARInvoicedetails");
        // call the helper function which "return" the CSV data as a String
        var csv = helper.convertArrayOfObjectsToCSV1(component,stockData);
        if (csv == null){return;}

        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####
        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self'; //
        hiddenElement.download = 'ExportData.csv';  // CSV file Name* you can change it.[only name not .csv]
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click(); // using click() js function to download csv file

    }

})