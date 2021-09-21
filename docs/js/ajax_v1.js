	var hintRequest;

	function ajaxRequest()
	{ var activexmodes=["Msxml2.XMLHTTP", "Microsoft.XMLHTTP"] //activeX versions to check for in IE
	  if (window.ActiveXObject)  // Test for support for ActiveXObject in IE first (as XMLHttpRequest in IE7 is broken)
	  { for (var i=0; i<activexmodes.length; i++)
	    { try { return new ActiveXObject(activexmodes[i]) }
	      catch(e) { }
	    }
 	  }
	  else if (window.XMLHttpRequest) return new XMLHttpRequest()
	       else return false
	}

//	AJAX GET

	function fillGeoInfo(force)
	{ var httpRequest = new ajaxRequest();

	  if (!httpRequest) { return false; }

	  lat = document.recordForm.decimallatitude.value;
	  lon = document.recordForm.decimallongitude.value;

	  httpRequest.open('GET', '/infoxy/lat/'+lat+'/long/'+lon, true);

	  httpRequest.onreadystatechange = function ()
	  { if (httpRequest.readyState == 4)
	    { if (httpRequest.status == 200)
	      { var p = httpRequest.responseText.trim().split(';');
		var f = document.recordForm;
		if (f.country.value == '' || force == true ) { f.country.value = p[0] }
		if (f.stateprovince.value == '' || force == true ) { f.stateprovince.value = p[1] }
		if (f.municipality.value == '' || force == true ) { f.municipality.value = p[2] }
		if (f.locality.value == '' || force == true )
		{ if (p[2] != p[3]) { f.locality.value = p[3] }
		  else { f.locality.value = '' }
		}
	      }
	    }
  	  }
	  httpRequest.send(null);
	}
