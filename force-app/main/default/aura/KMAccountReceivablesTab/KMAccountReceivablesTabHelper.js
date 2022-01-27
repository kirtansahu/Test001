({
    isSearchable : function(component) {
        var searchInput = component.get('v.searchInput');
        if(searchInput.length > 2 ) {
            return true;
        }
        else {
            return false;
        }
    },

    sortBy: function (component, helper, field)
    {
        var sortAsc = component.get("v.AccsortAsc"),
            sortField = component.get("v.AccselectedTabsoft1"),
            records = component.get("v.listofShipto"),
            fieldPath = field.split(/\./),
            fieldValue = this.fieldValue;
        sortAsc = sortField != field || !sortAsc;
        records.sort(function (a, b) {
            var aValue = fieldValue(a, fieldPath),
                bValue = fieldValue(b, fieldPath),
                t1 = aValue == bValue,
                t2 = (!aValue && bValue) || aValue < bValue;
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        component.set("v.AccsortAsc", sortAsc);
        component.set("v.AccselectedTabsoft1", field);
        component.set("v.listofShipto", records);
    },

    fieldValue: function (object, fieldPath)
    {
        var result = object;
        fieldPath.forEach(function (field) {
            if (result) {
                result = result[field];
            }
        });
        return result;
    },

    sortBy1: function (component, helper, field)
    {
        component.set("v.loaded", true);
        var sortAsc = component.get("v.sortAsc1"),
            sortField = component.get("v.selectedTabsoft1"),
            records = component.get("v.InvoiceLists");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function (a, b) {
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || a[field] < b[field];
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        component.set("v.sortAsc1", sortAsc);
        component.set("v.loaded", false);
        component.set("v.sortField", field);
        component.set("v.InvoiceLists", records);
    },

    sortBy2: function (component, helper, field)
    {
        var sortAsc = component.get("v.sortAsc2"),
            sortField = component.get("v.selectedTabsoft2"),
            records = component.get("v.ARInvoicedetails");
        sortAsc = sortField != field || !sortAsc;
        records.sort(function (a, b) {
            var t1 = a[field] == b[field],
                t2 = (!a[field] && b[field]) || a[field] < b[field];
            return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
        });
        component.set("v.sortAsc2", sortAsc);
        component.set("v.sortField", field);
        component.set("v.ARInvoicedetails", records);
    },

    dateValidation: function (component, dateVal, dateName)
    {
        var toastReference = $A.get("e.force:showToast");
        var oneYearDt = new Date();
        var formatedDt = new Date(dateVal);
        oneYearDt = oneYearDt.setMonth(oneYearDt.getMonth() - 6);
        if (formatedDt < oneYearDt)
        {
            toastReference.setParams({
                type: "Error",
                title: "Error",
                duration: 1000,
                message: $A.get("$Label.c.KM_Records_Availability_Valid_Msg"),
                mode: "dismissible"
            });
            toastReference.fire();
            if (dateName == "fromDate")
            {
                component.set("v.fromDate", "");
            }
            if (dateName == "EndDate")
            {
                component.set("v.toDate", "");
            }
            return;
        }
        if (formatedDt > new Date())
        {
            toastReference.setParams({
                type: "Error",
                title: "Error",
                duration: 1000,
                message: $A.get("$Label.c.KM_Date_Must_Be_Past"),
                mode: "dismissible"
            });
            toastReference.fire();
            if (dateName == "fromDate")
            {
                component.set("v.fromDate", "");
            }
            if (dateName == "EndDate")
            {
                component.set("v.toDate", "");
            }
            return;
        }
    },

    InvoicedateValidation: function (component, dateVal, dateName)
    {
        var toastReference = $A.get("e.force:showToast");
        var oneYearDt = new Date();
        var formatedDt = new Date(dateVal);
        oneYearDt = oneYearDt.setMonth(oneYearDt.getMonth() - 6);
        if (formatedDt < oneYearDt)
        {
            toastReference.setParams({
                type: "Error",
                title: "Error",
                duration: 1000,
                message: $A.get("$Label.c.KM_Records_Availability_Valid_Msg"),
                mode: "dismissible"
            });
            toastReference.fire();
            if (dateName == "fromDate")
            {
                component.set("v.InvoicefromDate", "");
            }
            if (dateName == "EndDate")
            {
                component.set("v.InvoicetoDate", "");
            }
            return;
        }
        if (formatedDt > new Date())
        {
            toastReference.setParams({
                type: "Error",
                title: "Error",
                duration: 1000,
                message: $A.get("$Label.c.KM_Date_Must_Be_Past"),
                mode: "dismissible"
            });
            toastReference.fire();
            if (dateName == "fromDate")
            {
                component.set("v.InvoicefromDate", "");
            }
            if (dateName == "EndDate")
            {
                component.set("v.InvoicetoDate", "");
            }
            return;
        }
    },
    accountSearch: function(component){
        component.set('v.loaded', true);
        var toastReference = $A.get("e.force:showToast");
        var actions=component.get('c.getAccountReceivableDetails');
        actions.setParams({
            accountOffset :0,
            searchtext :component.get('v.searchInput')
        });
        actions.setCallback(this,function(response){
            var state=response.getState();
            component.set('v.loaded', false);
            if(state==='SUCCESS'){
                component.set('v.loaded', false);
                var accountResult=response.getReturnValue();
                if(accountResult.length == 0)
                {
                    var toastReference = $A.get("e.force:showToast");
                    toastReference.setParams({
                        "type" : "Error",
                        "title" : "",
                        "duration": 1000,
                        "message" : $A.get("$Label.c.KM_Query_Error"),
                        "mode" : "dismissible"
                    });
                    toastReference.fire();
                    component.set("v.listofShipto", accountResult);
                    component.set('v.showAccountTable',true);
                }
                else
                {
                    // Set response value in listofShipto attribute on component.
                    component.set("v.showAccountTable", true);
                    component.set("v.listofShipto", accountResult);
                    component.set('v.Accountlength',accountResult.length);
                    //component.set('v.sortField', 'Account_Alpha_Name__c');

                }
            }else if(state=='ERROR'){
                var error=response.getError();

            }

        });
        $A.enqueueAction(actions);
    },
     convertArrayOfObjectsToCSV : function(component,objectRecords){
        // declare variables
        var csvStringResult, counter, keys, columnDivider, lineDivider;
       
        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null || !objectRecords.length) {
            return null;
         }
        // store ,[comma] in columnDivider variabel for sparate CSV values and 
        // for start next line use '\n' [new line] in lineDivider varaible  
        columnDivider = ',';
        lineDivider =  '\n';
         var tempResult=[];
        for(var i=0;i<objectRecords.length;i++){
            var result={};
            result['orderNumber']=objectRecords[i].orderNumber;
            if(objectRecords[i].orderType==null || objectRecords[i].orderType=='undefined'){
                result['orderType']='';
            }else{
                result['orderType']=objectRecords[i].orderType;
            }
             result['invoiceCompany']=objectRecords[i].invoiceCompany;
             result['orderStatus']=objectRecords[i].orderStatus;
             result['openAmount']=objectRecords[i].openAmount.replace('KRW','');
             result['invoicedAmount']=objectRecords[i].invoicedAmount.replace('KRW','');
             result['invoiceType']=objectRecords[i].invoiceType;
             result['invoiceNumber']=objectRecords[i].invoiceNumber;
             result['invoiceDate']=objectRecords[i].invoiceDate;
             result['daysOutstanding']=objectRecords[i].daysOutstanding;
             tempResult.push(result);
         }
 
        // in the keys valirable store fields API Names as a key 
        // this labels use in CSV file header  
        keys = ['orderNumber','orderType','invoiceCompany','orderStatus','openAmount','invoicedAmount','invoiceType','invoiceNumber','invoiceDate','daysOutstanding' ];
        
        csvStringResult = '';
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;
 
        for(var i=0; i < tempResult.length; i++){   
            counter = 0;
           
             for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;  
 
              // add , [comma] after every String value,. [except first]
                  if(counter > 0){ 
                      csvStringResult += columnDivider; 
                   }   
               csvStringResult += '"'+ tempResult[i][skey]+'"'; 
               
               counter++;
 
            } // inner for loop close 
             csvStringResult += lineDivider;
          }// outer main for loop close 
       
       // return the CSV formate String 
        return csvStringResult;        
    },
     convertArrayOfObjectsToCSV1 : function(component,objectRecords){
        // declare variables
        var csvStringResult, counter, keys, columnDivider, lineDivider;
       
        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null || !objectRecords.length) {
            return null;
         }
        // store ,[comma] in columnDivider variabel for sparate CSV values and 
        // for start next line use '\n' [new line] in lineDivider varaible  
        columnDivider = ',';
        lineDivider =  '\n';
         var tempResult=[];
        for(var i=0;i<objectRecords.length;i++){
            var result={};
            result['OrderNum']=objectRecords[i].OrderNum;
            result['ShipToNum']=objectRecords[i].ShipToNum;
            if(objectRecords[i].OrderType==null || objectRecords[i].OrderType=='undefined' || objectRecords[i].OrderType=='' ){
                result['OrderType']='';
            }else{
                result['OrderType']=objectRecords[i].OrderType;
            }
            result['LineNumber']=objectRecords[i].LineNumber;
            result['ProductNum']=objectRecords[i].ProductNum;
            result['ProductName']=objectRecords[i].ProductName;
            result['UnitSize']=objectRecords[i].UnitSize;
            result['Status']=objectRecords[i].Status;
            result['Quantity']=objectRecords[i].Quantity;
            result['CustomerPrice']=objectRecords[i].CustomerPrice.replace('KRW','');
            result['ShipmentDate']=objectRecords[i].ShipmentDate;
            tempResult.push(result);
        }
 
        // in the keys valirable store fields API Names as a key 
        // this labels use in CSV file header  
        keys = ['OrderNum','ShipToNum','OrderType','LineNumber','ProductNum','ProductName','UnitSize','Status','Quantity','CustomerPrice','ShipmentDate' ];
        
        csvStringResult = '';
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;
 
        for(var i=0; i < tempResult.length; i++){   
            counter = 0;
           
             for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;  
 
              // add , [comma] after every String value,. [except first]
                  if(counter > 0){ 
                      csvStringResult += columnDivider; 
                   }   
               csvStringResult += '"'+ tempResult[i][skey]+'"'; 
               
               counter++;
 
            } // inner for loop close 
             csvStringResult += lineDivider;
          }// outer main for loop close 
       
       // return the CSV formate String 
        return csvStringResult;        
    },

});