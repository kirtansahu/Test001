/**
 * Used for special calls from Lightning components
 * @param msg
 * @param port
 */
window.sendToWDE = function(msg, port, useLocalHost) {
    console.log("sendToWDE");
    msg.CI = 'ignore'; // ignore the connection id for these calls
    //var strHref = sessionStorage.getItem('refUrl');
	var strHref =document.documentURI

    function getUrlParameter(name) {
        name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
        var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
        var results = regex.exec(strHref);
        return !results ? null : decodeURIComponent(results[1].replace(/\+/g, ' '));
    }

    if (!port) {
        port = getUrlParameter('port') | "5050";
    }

    var host = useLocalHost == 'true' || getUrlParameter('useLocalHost') === 'true' ? 'localhost' : 'localhost';
	
	var url = 'https://' + host + ':' + port;
    console.log("url=" + url + ' (' + strHref + ')');
    var stringifyMsg = JSON.stringify(msg);
    console.log("msg=" + stringifyMsg);

    jQuery.ajax({
		url: url,
        data: "/request=" + stringifyMsg,
        type: 'GET',
        processData: false,
        timeout: 10000,
        cache: false,
        dataType: 'jsonp',
        error: function (xhr, ajaxOptions, thrownError) {
            console.error(url + ' ' + ajaxOptions + ' - ' + xhr.status + ' ' + thrownError);
        }
    });
};