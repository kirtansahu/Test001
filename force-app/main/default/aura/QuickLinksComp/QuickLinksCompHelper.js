({
    //METHOD TO GET ALL CATEGORY AND CUSTOM LINK RECORDS
	fetchCategoryAndCustomLinkRecords : function(component) {
        (this).startWaiting(component);
        (this).doCallout(component, 'c.fetchCategoryAndCustomLinks', {"location": component.get("v.location")} , function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                component.set("v.activeCategory", result.colapsedCatgories);
                component.set("v.lstCategoryWrapper", result.allCatgories);
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
	}
})