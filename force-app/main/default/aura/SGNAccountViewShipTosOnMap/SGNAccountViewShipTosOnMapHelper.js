({
	handleChildAddressMap : function(component, event) {
		(this).startWaiting(component);
        var recordId = component.get('v.recordId');
        (this).doCallout(component, 'c.childAddressMap', {'recId': recordId}, function(response) {
            let state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {
                var result = response.getReturnValue();
                if(result.length == ''){
                    component.set('v.isModalOpen', true);
                }else{
                    var locations = [];
                    for(var i=0; i< result.length; i++){
                        var shiptoname = result[i].Name + ' [ LTM Sales: ' + result[i].LTM_Sales__c + ' ]';
                        var shippingAddress = result[i].Address_1__c + ', ' + result[i].Address_2__c + ', ' + result[i].ShippingStreet + ', ' + result[i].Address_4__c + ', ' + result[i].ShippingCity + ', ' + result[i].ShippingState + ' ' + result[i].ShippingPostalCode + ' ' + result[i].ShippingCountry;
                        locations.push({
                            'location': {
                                'Street': result[i].ShippingStreet,
                                'City': result[i].ShippingCity,
                                'PostalCode': result[i].ShippingPostalCode,
                                'State': result[i].ShippingState,
                                'Country': result[i].ShippingCountry
                            },
                            'icon': 'standard:account',
                            'title': shiptoname,
                            'description': shippingAddress
                        });
                    }
                    component.set('v.isModalOpen', false);
                    component.set('v.mapMarkers', locations);
                    component.set('v.zoomLevel', 3);
                    component.set('v.markersTitle', 'Child Accounts Locations');
                }
            } else if (component.isValid() && state === 'ERROR') {
                var errors = response.getError();
                (this).handleErrors(component, errors);
            }
            (this).stopWaiting(component);
        });
	}
})