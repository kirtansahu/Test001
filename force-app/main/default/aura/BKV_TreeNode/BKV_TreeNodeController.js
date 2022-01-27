({
    handleExpand : function(component, event, helper) {
        var elementId = event.getSource().get("v.title");
        var allElements = document.getElementsByClassName(elementId);
        if(allElements && allElements.length > 0){
            allElements[0].className = allElements[0].className.replace("-false","-true");
        }
		/*var allNodes = component.get("v.baseNode");
        for(var i = 0; i<allNodes.length; i++){
            if(allNodes[i].value == elementId){
                allNodes[i].isExpanded = true;
                break;
            }
        }
        component.set("v.baseNode", allNodes);*/
	},
    
    handleColapse : function(component, event, helper) {
        var elementId = event.getSource().get("v.title");
		/*var allNodes = component.get("v.baseNode");
        for(var i = 0; i<allNodes.length; i++){
            if(allNodes[i].value == elementId){
                allNodes[i].isExpanded = false;
                break;
            }
        }
        component.set("v.baseNode", allNodes);*/
        var allElements = document.getElementsByClassName(elementId);
        if(allElements && allElements.length > 0){
            allElements[0].className = allElements[0].className.replace("-true","-false");
        }
	},
    
    handleDelete : function(component, event, helper) {
        var elementId = event.getSource().get("v.title");
        var element = null;
        var allNodes = component.get("v.baseNode");
        for(var i = 0; i<allNodes.length; i++){
            if(allNodes[i].value == elementId){
                element = allNodes[i];
                break;
            }
        }
        
        if(element){
            if(confirm("Are you sure you want to delete "+element.label+"/"+element.value+" ?")){
                helper.startWaiting(component);
                helper.doCallout(component, "c.deleteRole", {"userRoleId": element.value}, function(response) {
                    let state = response.getState();
                    helper.myLog('=============== state '+state);
                    if (state === "SUCCESS") {
                        helper.doShowToast(component, "Success", "Deleted Successfully", "success");
                        var allNodes2 = [];
                        for(var i = 0; i<allNodes.length; i++){
                            if(allNodes[i].value != elementId){
                                allNodes2.push(allNodes[i]);
                            }
                        }
                        component.set("v.baseNode", allNodes2);
                    } else if (state === "ERROR") {
                        helper.handleErrors(component, response.getError());
                    }
                    helper.stopWaiting(component);
                });
            }
        }
    },
})