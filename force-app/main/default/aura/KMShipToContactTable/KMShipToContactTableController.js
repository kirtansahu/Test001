({
    doInit :function(component, event, helper) {
       // component.find('conField').set('v.value','');
        component.set('v.disableApplyButton',true);
        component.set('v.disableClearButton',true);
        component.set('v.contFilterBox','');
        component.set('v.disableShipToContactFilter',true);
        component.set('v.shipToContactFilter','');
    },

    //Action to enable the
    enableFilter:function(component, event, helper) {
        //Set Contact filter box to blank
        component.set("v.contFilterBox",'');
        component.set('v.disableShipToContactFilter', true);
        //Get Contact filter dropdown value
        var conField = component.get('v.shipToContactFilter');
        //Disabling Contact filter box initially
        component.set('v.disableShipToContactFilter', true);
        //Disabling Contact filter box Apply Button
        component.set('v.disableApplyButton', true);
        //Disabling Contact filter box Clear Button
        component.set('v.disableClearButton', true);
        if(conField == 'Name' || conField == 'Email') {
            component.set('v.disableApplyButton', false);
            component.set('v.disableShipToContactFilter', false);
        }
    },

    //Filter action for SHIPTO CONTACT crelated list
    applyConFilter:function (cmp, event, helper) {
        //cmp.set('v.showSpinner', true);
        cmp.set('v.disableClearButton', false);
        var filterOption=cmp.find('conField').get('v.value');
        var contactList=cmp.get('v.contactHistory');
        var searchKey=cmp.get('v.contFilterBox');
        var temp=[];
        for(var i=0;i<contactList.length;i++){
            if(filterOption=='Name'){
                if(contactList[i].Name){
                    if((contactList[i].Name && (contactList[i].Name+'').indexOf(searchKey) > -1))
                    {
                        temp.push(contactList[i]);
                    }
                }
            }
            if(filterOption=='Email'){
                if(contactList[i].Email){
                    if((contactList[i].Email && (contactList[i].Email+'').indexOf(searchKey) > -1))
                    {
                        temp.push(contactList[i]);
                    }
                }
            }
        }
        if(temp.length>0){
            cmp.set('v.contactHistory',temp);
        }else{
            cmp.set('v.contactHistory',temp);
        }
    },

    //Clear action on changing filter Type
    clearConBox :function (cmp, event, helper) {
        var picklistOption=cmp.find('conField').get('v.value');
        if(picklistOption=='Name' || picklistOption=='Email' ){
            cmp.find('conField').set('v.value','');
            cmp.set('v.disableApplyButton', true);
            cmp.set('v.disableClearButton', true);
            cmp.set('v.disableShipToContactFilter',true);
            cmp.find('conField').set('v.value','');
            cmp.find('contFilterBoxId').set('v.value','');
        }

        cmp.set('v.contactHistory',cmp.get('v.allContactHistory'));
    },

    //Action to sort Contact History List
    sortConHistory:function(component, event, helper) {
        /*var fieldName = event.currentTarget.id;
        helper.sortConHisTable(component, fieldName);
        helper.sortBycon(component,helper, fieldName);
        component.set("v.conselectedTabsoft1", fieldName);*/
        var fieldName = event.currentTarget.id;
        //alert(fieldName);
        // call the helper function with pass sortField Name
        helper.sortByContacts(component,helper, fieldName);
        component.set("v.AccselectedTabsoft", fieldName);
        var a=component.get("v.AccsortAsc");
    },

    tableRowClicked: function(component, event, helper) {
        var rowClickEvent = component.getEvent("KMTableRowClickEvent");
        rowClickEvent.setParams({
            "recordId" : event.currentTarget.dataset.id,
            "type" : event.currentTarget.dataset.type,
            "tableName" : 'contactTable'
        });
        rowClickEvent.fire();
    },

})