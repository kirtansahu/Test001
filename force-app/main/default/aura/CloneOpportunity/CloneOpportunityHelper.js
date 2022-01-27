({
    doInit: function (component, event){
        (this).startWaiting(component);
        (this).doCallout(component, 
                         'c.getOpportunityRecord', 
                         {'recordId':component.get("v.recordId")}, 
                         function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                component.set("v.opp", result);
                component.set("v.isOppCloned", true);
                this.getOpportunityChildRecordDetails(component, event);
                this.getFieldsAndSection(component, event);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }else{
                (this).stopWaiting(component);
            }
        });
    },
    
    getOpportunityChildRecordDetails : function (component, event){
    	(this).doCallout(component, 
                         'c.getOpportunityChildRecordInformation', 
                         {'recordId':component.get("v.recordId")}, 
                         function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                let result = response.getReturnValue();
                component.set("v.hasOpportunityProduct", result.hasOpportunityProduct);
                component.set("v.hasOpporunityProductLine", result.hasOpporunityProductLine);
                component.set("v.hasOpportunityTeamMember", result.hasOpportunityTeamMember);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }else{
                (this).stopWaiting(component);
            }
        });
    },
        
    getFieldsAndSection: function (component, event){
        (this).startWaiting(component);
        (this).doCallout(component, 
                         'c.fetchPageLayoutFieldsAndSection', 
                         {'opp':component.get("v.opp")}, 
                         function(response) {
                             let state = response.getState();
                             if (component.isValid() && state === 'SUCCESS') {
                                 let result = response.getReturnValue();
                                 component.set("v.layoutSections", result);
                                 var inputFields = component.find("fieldId");
                                 if(inputFields != null && inputFields != undefined && inputFields.length > 0){
                                     for(var i=0;i<inputFields.length;i++){
                                         let fieldName = inputFields[i].get("v.fieldName");
                                         if(fieldName != null && fieldName != '' && fieldName != undefined && fieldName == 'StageName'){
                                             inputFields[i].set('v.value', 'New');
                                         }
                                     }
                                 }
                             } else if (component.isValid() && state === 'ERROR') {
                                 var errors = response.getError();
                                 (this).handleErrors(component, errors);
                             }
                             (this).stopWaiting(component);
                         });
    },
    
    cloneOppAndGetLineItems: function (component, fields){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.cloneOpportunityAndReturnCloneRecordId', {'opp': fields,'sourceOppRecordId':component.get("v.recordId")}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.saved", true);
                (this).fetchOpportunityProducts(component,event, result);
                (this).fetchOpportunityProductLine(component,event, result);
                var opportunity = component.get("v.opp");
                var accountId = fields['AccountId'];
                if(accountId != null && accountId != undefined){
                    if(accountId == opportunity.AccountId){
                        component.set("v.isAccountUpdated", true);
                        (this).fetchOpportunityTeamMember(component,event, result);
                    }
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
    
    fetchOpportunityProducts : function(component, event, clonedOppId){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.getOpportunityProducts', {'sourceOppRecordId':component.get("v.recordId"), 'cloneOppId':clonedOppId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                let resObj = JSON.parse(result);
                //Set the cloned opportunity record id
                component.set("v.clonedOppRecordId", resObj.clonedOppId);
                // Set the data-table columns with additional action column 
                // which will allow users to delete a line item 
                var actions = [
                    { label: 'Delete', name: 'delete' }
                ];
                let actionCol = { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left' } };
                resObj.columns.push(actionCol);
                //Find the Product2.Name column and change the fieldName so that we can reference the parent name
                let product2Col = resObj.columns.find(c=>c.fieldName == "Product2.Name");
                if(product2Col.fieldName != undefined){
                    product2Col.fieldName = "Product2Name";    
                }
				component.set('v.columns', resObj.columns);
                //Set the products data to display in the data-table
                //In order to display product names, we will have to flatten the column names 
                for (var i = 0; i < resObj.data.length; i++) {
                    var row = resObj.data[i];
                    if (row.Product2) row.Product2Name = row.Product2.Name;
                }
                if(resObj.data.length != undefined && resObj.data.length >0){
                    component.set("v.showOppItem", true);
                }
                component.set('v.products', resObj.data);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
    
    fetchOpportunityProductLine : function(component, event, clonedOppId){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.getOpportunityProductLine', {'sourceOppRecordId':component.get("v.recordId"), 'cloneOppId':clonedOppId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                //console.log('==result=='+JSON.stringify(result));
                let resObj = JSON.parse(result);
                //Set the cloned opportunity record id
                component.set("v.clonedOppRecordId", resObj.clonedOppId);
                // Set the data-table columns with additional action column 
                // which will allow users to delete a line item 
                var actions = [
                    { label: 'Delete', name: 'delete' }
                ];
                let actionCol = { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left' } };
                resObj.columns.push(actionCol);
                //Find the Product2.Name column and change the fieldName so that we can reference the parent name
                /*let product2Col = resObj.columns.find(c=>c.fieldName == "Opportunity__c");
                if(product2Col.fieldName != undefined){
                    product2Col.fieldName = "OpportunityName";    
                }*/
				component.set('v.productLineColumns', resObj.columns);
                //Set the products data to display in the data-table
                //In order to display product names, we will have to flatten the column names 
                for (var i = 0; i < resObj.data.length; i++) {
                    var row = resObj.data[i];
                    if (row.Opportunity__c){
                        row.Opportunity__c = row.Opportunity__r.Name;
                    } 
                    if (row.Product_Line__c){
                        row.Product_Line__c = row.Product_Line__r.Name;
                    } 
                }
                var isShowOppItem = component.get("v.showOppItem");
                if(resObj.data.length != undefined && resObj.data.length >0 && !isShowOppItem){
                    component.set("v.showOppProductLineItem", true);
                }
                component.set('v.productLine', resObj.data);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
    
    fetchOpportunityTeamMember : function(component, event, clonedOppId){
        (this).startWaiting(component);
        (this).doCallout(component, 'c.getOpportunityTeamMembers', {'sourceOppRecordId':component.get("v.recordId"), 'cloneOppId':clonedOppId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                let resObj = JSON.parse(result);
                //Set the cloned opportunity record id
                component.set("v.clonedOppRecordId", resObj.clonedOppId);
                var actions = [
                    { label: 'Delete', name: 'delete' }
                ];
                let actionCol = { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left' } };
                resObj.columns.push(actionCol);
				component.set('v.oppTeamMemberColumns', resObj.columns);
                for (var i = 0; i < resObj.data.length; i++) {
                    var row = resObj.data[i];
                    if (row.OpportunityId){
                        row.OpportunityId = row.Opportunity.Name;
                    } 
                    if (row.UserId){
                        row.UserId = row.User.Name;
                    } 
                }
                var isShowOppItem = component.get("v.showOppItem");
                var isshowOppProductLineItem = component.get("v.showOppProductLineItem");
                if(resObj.data.length != undefined && resObj.data.length >0 && !isShowOppItem && !isshowOppProductLineItem){
                    component.set("v.showOppTeamMember", true);
                }else if(!isShowOppItem && !isshowOppProductLineItem){
                    this.navigateToOppRecord(component, component.get("v.clonedOppRecordId"));
                }
                component.set('v.oppTeamMembers', resObj.data);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
    },
    
    navigateToOppRecord: function (component, recordId) {
       	(this).startWaiting(component);
        (this).navigateToRecord(component, recordId);
        (this).stopWaiting(component);
    },
    
    
    cloneOppLineItems: function (component, event){
    	(this).startWaiting(component);
        var isShowOppItem = component.get("v.showOppItem");
        var isShowOppProductLineItem = component.get("v.showOppProductLineItem");
        var isShowOppTeamMember = component.get("v.showOppTeamMember");
        
        if(typeof event.getParam === "function"){
            component.set('v.savedDraftValues', event.getParam('draftValues'));   
        }else{
            component.set('v.savedDraftValues', []);   
        }
        let isValidData = (this).validate(component, event, component.get('v.savedDraftValues'), isShowOppItem);
        if(isValidData){
            let lstSourceLineItemIds = [];
            if(isShowOppItem){
                for(let oli of component.get("v.products")){
                    lstSourceLineItemIds.push(oli.Id);	    
                }    
            }
            let lstSourceProdLineItemIds = [];
            if(isShowOppProductLineItem){
                for(let oli of component.get("v.productLine")){
                    lstSourceProdLineItemIds.push(oli.Id);	    
                }
            }
            
            let lstSourceOppTeamMemberIds = [];
            if(isShowOppTeamMember){
                for(let oppTeamMember of component.get("v.oppTeamMembers")){
                    lstSourceOppTeamMemberIds.push(oppTeamMember.Id);	    
                }
            }
            
            (this).doCallout(component, 'c.cloneOpportunityLineItems', {'sourceOppRecordId': component.get("v.recordId"),
                                                                       'clonedOppRecordId': component.get("v.clonedOppRecordId"),
                                                                       'lstSourceLineItemIds': lstSourceLineItemIds,
                                                                       'lstLineItemsChanges': component.get("v.savedDraftValues"),
                                                                       'lstSourceProdLineItemIds': lstSourceProdLineItemIds,
                                                                       'lstProdLineItemsChanges': component.get("v.savedDraftValues"),
                                                                       'lstSourceOppTeamMemberIds':lstSourceOppTeamMemberIds,
                                                                       'lstOpportunityTeamMember': component.get("v.savedDraftValues")}, function(response) {
                let state = response.getState();
                if (component.isValid() && state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    if(isShowOppItem){
                        var productLine = component.get("v.productLine");
                        var oppTeamMember = component.get("v.oppTeamMembers");
                        if(productLine != null && productLine != undefined && productLine.length>0){
                            component.set("v.isDataChanged", false);
                            component.set('v.showOppItem', false);
                            component.set('v.showOppTeamMember', false);
                            component.set('v.showOppProductLineItem', true);
                            component.set('v.hasOpportunityProduct', false);
                            component.find("oppLineItem").set("v.draftValues", null);
                            component.find("oppProdLineItem").set("v.draftValues", null);
                        } else if(!isShowOppTeamMember && oppTeamMember != null && oppTeamMember != undefined && oppTeamMember.length>0){
                            component.find("oppLineItem").set("v.draftValues", null);
                            component.set("v.isDataChanged", false);
                            component.set('v.showOppItem', false);
                            component.set('v.showOppProductLineItem', false);
                            component.set('v.showOppTeamMember', true);
                            component.set("v.isAccountUpdated", false); 
                            component.set('v.hasOpportunityProduct', false);
                            component.set('v.hasOpporunityProductLine', false);
                        }else{
                            this.navigateToOppRecord(component, result);
                        }
                    }else if(isShowOppProductLineItem){
                        var oppTeamMember = component.get("v.oppTeamMembers");
                        if(oppTeamMember != null && oppTeamMember != undefined && oppTeamMember.length>0){
                            component.find("oppProdLineItem").set("v.draftValues", null);
                            component.set("v.isDataChanged", false);
                            component.set('v.showOppItem', false);
                            component.set('v.showOppProductLineItem', false);
                            component.set('v.showOppTeamMember', true);
                            component.set("v.isAccountUpdated", false); 
                            component.set('v.hasOpportunityProduct', false);
                            component.set('v.hasOpporunityProductLine', false);
                        }else{
                            this.navigateToOppRecord(component, result);
                        }
                    }else if(isShowOppTeamMember){
                        this.navigateToOppRecord(component, result); 
                    }
                } else if (component.isValid() && state === 'ERROR') {
                    var errors = response.getError();
                    (this).handleErrors(component, errors);
                }
                (this).stopWaiting(component);
            })
        }else{
            (this).stopWaiting(component);
        }
    },
    
    deleteRow: function (component, row){
    	var rows = component.get('v.products');
        var rowIndex = rows.indexOf(row);
        rows.splice(rowIndex, 1);
        component.set('v.products', rows);    
    },
    
    deleteProdLineRow: function (component, row){
    	var rows = component.get('v.productLine');
        var rowIndex = rows.indexOf(row);
        rows.splice(rowIndex, 1);
        component.set('v.productLine', rows);    
    },
    
    deleteOppTeamMemberRow: function (component, row){
    	var rows = component.get('v.oppTeamMembers');
        var rowIndex = rows.indexOf(row);
        rows.splice(rowIndex, 1);
        component.set('v.oppTeamMembers', rows);    
    },
    
    sortData: function (component, fieldName, sortDirection) {
        var products = component.get("v.products");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        products.sort(this.sortBy(fieldName, reverse))
        component.set("v.products", products);
    },
    
    sortProdLineData: function (component, fieldName, sortDirection) {
        var productLine = component.get("v.productLine");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        productLine.sort(this.sortBy(fieldName, reverse))
        component.set("v.productLine", productLine);
    },
    
    sortOppTeamMemberData: function (component, fieldName, sortDirection) {
        var oppTeamMembersData = component.get("v.oppTeamMembers");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        oppTeamMembersData.sort(this.sortBy(fieldName, reverse))
        component.set("v.oppTeamMembers", oppTeamMembersData);
    },
    
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
    validate: function(component, event, items, showOppItem) {
        console.log('validate called');
        let isShowOppProductLineItem = component.get('v.showOppProductLineItem');
        let isShowOppTeamMember = component.get('v.showOppTeamMember');
        let rows = {};
        let isValid = true;
        var columns = [];
        
        if(showOppItem){
          columns = component.get("v.columns");
        }else if(isShowOppProductLineItem){
          columns = component.get("v.productLineColumns");
        }else if(isShowOppTeamMember){
          columns = component.get("v.oppTeamMemberColumns");
        }
        
        for(let oli of items){
            let messages = [];
            let fieldNames = [];
            for(let col of columns){
                if(col.required && oli[col.fieldName] == ''){
                	messages.push('Enter a valid ' + col.label);	
                    fieldNames.push(col.fieldName);
                }    
            }
            if(fieldNames.length > 0){
                isValid = false;
            	let title = "We found " + fieldNames.length + " errors.";  
                rows[oli.Id] = {
                    title: title,
                    messages: messages,
                    fieldNames: fieldNames
                };
            } 
        }
        
        if(!isValid){
            if(showOppItem){
                component.set('v.errors', {
                    rows: rows,
                    table: {
                        title: 'Your entry cannot be saved. Fix the errors and try again.'
                    }
                });
            }else if(isShowOppProductLineItem){
                component.set('v.prodLineErrors', {
                    rows: rows,
                    table: {
                        title: 'Your entry cannot be saved. Fix the errors and try again.'
                    }
                });
            }else if(isShowOppTeamMember){
                component.set('v.oppTeamMemberErrors', {
                    rows: rows,
                    table: {
                        title: 'Your entry cannot be saved. Fix the errors and try again.'
                    }
                });
            }
        }
        
        return isValid;
    },
    
    showSpinner : function( component ) {
        $A.util.removeClass( component.find( 'spinner' ), 'slds-hide' );
    },

    hideSpinner : function( component ) {
        $A.util.addClass( component.find( 'spinner' ), 'slds-hide' );
    },
    
    doShowToastMessage: function(component, title, message, type) {
        (this).doShowToast(component, title, message, type);
    },

})