({
	init: function(component, event) {
		this.startWaiting(component);
		this.updateAccountAndOpportunityColumn(component, event);
		this.doCallout(component, 'c.viewAccountTeamData', { objOppId: component.get('v.recordId') }, function(
			response
		) {
			let state = response.getState();
			if (component.isValid() && state === 'SUCCESS') {
				var objTeamWrapper = response.getReturnValue();
				var DisableRecCount = 0;
				var oppSelectedRows = [];
				var accSelectedRows = [];
				for (var i = 0; i < objTeamWrapper.lstAccTeam.length; i++) {
					var row = objTeamWrapper.lstAccTeam[i];
					if (row.UserId) {
						row.UserName = row.User.Name;
						row.TerritoryName = row.Territory2.Name;
						row.RoleName = row.RoleInTerritory2;
					}
					accSelectedRows.push(objTeamWrapper.lstAccTeam[i].Id);
				}
				component.set('v.listofOppTeam', objTeamWrapper.lstOppTeam);

				for (var i = 0; i < objTeamWrapper.lstOppTeam.length; i++) {
					var row = objTeamWrapper.lstOppTeam[i];
					if (row.User) {
						row.UserName = row.User.Name;
					}
					oppSelectedRows.push(objTeamWrapper.lstOppTeam[i].Id);
				}
				component.set('v.listofAccountTeam', objTeamWrapper.lstAccTeam);
				component.set('v.listofOppTeam', objTeamWrapper.lstOppTeam);
				component.set('v.oppSelectedRows', oppSelectedRows);
				component.set('v.accSelectedRows', accSelectedRows);
			} else if (component.isValid() && state === 'ERROR') {
				var errors = response.getError();
				this.handleErrors(component, errors);
			}
		});

		this.doCallout(component, 'c.defineAccess', { objOppId: component.get('v.recordId') }, function(response) {
			let state = response.getState();
			if (component.isValid() && state === 'SUCCESS') {
				var result = response.getReturnValue();
				component.set('v.hasAccess', result);
			} else if (component.isValid() && state === 'ERROR') {
				var errors = response.getError();
				this.handleErrors(component, errors);
			}
		});
		this.stopWaiting(component);
	},

	addOpportunityTeamMemeber: function(component, event) {
		this.startWaiting(component);
		var recordId = component.get('v.recordId');
		var listofAccountTeam = component.get('v.listofAccountTeam');
		var listofOppTeam = component.get('v.listofOppTeam');
		var accSelected = [];
		var oppSelected = [];
		var oppRemoved = [];
		accSelected = component.find('accTableId').getSelectedRows();
		oppSelected = component.find('oppTableId').getSelectedRows();

		for (var i = 0; i < listofOppTeam.length; i++) {
			if (!oppSelected.includes(listofOppTeam[i])) {
				oppRemoved.push(listofOppTeam[i]);
			}
		}

		this.doCallout(
			component,
			'c.updateOpportunityTeam',
			{
				lstAddAccTeam: accSelected,
				lstRemoveOppTeam: oppRemoved,
				objOppId: recordId
			},
			function(response) {
				let state = response.getState();
				if (component.isValid() && state === 'SUCCESS') {
					var result = response.getReturnValue();
					this.doShowToast(component, 'Success', result, 'success');
					this.navigateToOppRecord(component, event, recordId);
				} else if (component.isValid() && state === 'ERROR') {
					var errors = response.getError();
					this.handleErrors(component, errors);
				}
				this.stopWaiting(component);
			}
		);
	},

	updateAccountAndOpportunityColumn: function(component, event) {
		component.set('v.accColumns', [
			{
				label: 'User',
				fieldName: 'UserName',
				type: 'text',
				sortable: true
			},
			{
				label: 'Territory',
				fieldName: 'TerritoryName',
				type: 'text',
				sortable: true
			},
			{
				label: 'Role',
				fieldName: 'RoleName',
				type: 'text',
				sortable: true
			}
		]);
		component.set('v.oppColumns', [
			{ label: 'User', fieldName: 'UserName', type: 'text' },
			{ label: 'Position', fieldName: 'Position__c', type: 'text' },
			{ label: 'Primary?', fieldName: 'isPrimary__c', type: 'boolean' }
		]);
	},

	navigateToOppRecord: function(component, event, recordId) {
		var navEvt = $A.get('e.force:navigateToSObject');
		navEvt.setParams({
			recordId: recordId,
			slideDevName: 'related'
		});
		navEvt.fire();
	},

	/*sortData: function(cmp, fieldName, sortDirection) {
		var data = cmp.get('v.listofAccountTeam');
		var reverse = sortDirection !== 'asc';
		data.sort(this.sortBy(fieldName, reverse));
		cmp.set('v.listofAccountTeam', data);
    },*/

    sortData : function(cmp, fieldName, sortDirection){
        var data = cmp.get("v.listofAccountTeam");
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        data.sort(function(a,b){
            var a = key(a) ? key(a).toLowerCase() : '';
            var b = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((a>b) - (b>a));
        });
        cmp.set("v.listofAccountTeam",data);
    },

	sortBy: function(field, reverse, primer) {
		var key = primer
			? function(x) {
					return primer(x[field]);
			  }
			: function(x) {
					return x[field];
			  };
		reverse = !reverse ? 1 : -1;
		return function(a, b) {
			return (a = key(a)), (b = key(b)), reverse * ((a > b) - (b > a));
		};
	}
});