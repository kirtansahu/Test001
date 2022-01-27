({
	doInit: function(component, event, helper) {
		helper.init(component, event);
	},

	updateOppTeamMemeber: function(component, event, helper) {
		helper.addOpportunityTeamMemeber(component, event);
	},

	handleCancel: function(component, event, helper) {
		$A.get('e.force:closeQuickAction').fire();
	},

	updateColumnSorting: function(component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
		component.set('v.sortedBy', fieldName);
		component.set('v.sortedDirection', sortDirection);
		helper.sortData(component, fieldName, sortDirection);
	}
});