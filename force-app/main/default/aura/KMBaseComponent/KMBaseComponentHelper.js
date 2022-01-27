({
    callServer : function(component,method,params,callback) {
        var action=component.get(method);
        if(params){
            action.setParams(params);
        }
        action.setCallback(this,function(response){
            var state=response.getState();
            // console.log('state'+state);
            if(state==='SUCCESS'){
                //console.log('resultheader=='+response.getReturnValue());
                callback.call(this,response.getReturnValue());
            }
            
        });
        $A.enqueueAction(action);
        
    }
})