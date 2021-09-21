var ajax_url = '/search';
var ajax_par = '';
var hintRequest;

// -------------------------------------
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

//AJAX GET

// -------------------------------------
function loadRecord(rid)
{ var httpRequest = new ajaxRequest();

  if (!httpRequest) { return false; }

  httpRequest.open('GET', ajax_url+'?'+ajax_par, true);

  httpRequest.onreadystatechange = function ()
  { if (httpRequest.readyState == 4)
    { if (httpRequest.status == 200)
      { document.getElementById('divRec'+rid).innerHTML = httpRequest.responseText }
    }
  }
  httpRequest.send(null);
}
// -------------------------------------

function findPos(obj)
{ var curleft = curtop = 0;
  if (obj.offsetParent)
  { do { curleft += obj.offsetLeft;
         curtop += obj.offsetTop;
       } while (obj = obj.offsetParent);
  }
  return [curleft,curtop];
}
// -------------------------------------------------------------------------
function showIdentForm(obj,user_id,record_id,kingdom)
{ s_f = new bsn.AutoSuggest('family',
        { script: '/suggestions/dictionary_scinames?kingdom='+kingdom+'&', varname: 'family',
          json: true, minchars: 1, delay: 10, offsety: 0, timeout: 10000,
          noresults: "Nome não encontrado", cache: false, maxresults: 35,
	  callback: function(obj) { }
        });
  s_s = new bsn.AutoSuggest('scientificname',
        { script: '/suggestions/dictionary_scinames?kingdom='+kingdom+'&', varname: 'sciname',
          json: true, minchars: 1, delay: 10, offsety: 0, timeout: 10000,
          noresults: "Nome não encontrado", cache: false, maxresults: 35,
	  callback: function(obj)
	  { d = document.identForm; e = obj.info.split(':'); d.family.value = e[0]; }

        });

  var f = document.identForm;
  f.record_id.value		= record_id;
  f.kingdom.value		= kingdom;
  f.user_id.value		= user_id;

  f.family.value		= '';
  f.scientificname.value	= '';
  f.vernacularname.value	= '';
  f.identificationremarks.value	= '';

  f.style.visibility = 'visible';
  f.style.backgroundColor = '#fefefe';
  f.style.boxShadow = '0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19)';

  xy = findPos(document.getElementById(obj));

  var d = document.getElementById('divIdent');
  xy[1] -= 200;
  if (obj.match(/p_/)) { xy[0] -= 200 }
  d.style.left = xy[0]+'px';
  d.style.top  = xy[1]+'px';
}
// -------------------------------------------------------------------------
//	openNotifyForm(34,'a|p')
// -------------------------------------------------------------------------
function openNotifyForm(rid,taxgrp)
{ var notification = window.open('/notify?rid='+rid+'&taxgrp='+taxgrp, "notifyWin", "width=800,height=600");
}

// -------------------------------------------------------------------------
function submitIdentForm(prg)
{ var f = document.identForm;

  ajax_par =	'rid='+f.record_id.value+
		'&user_id='+f.user_id.value+
		'&action=identify'+
		'&mode=work'+
		'&ajax=true'+
		'&kingdom='+f.kingdom.value+
		'&family='+f.family.value+
		'&vernacularname='+f.vernacularname.value+
		'&scientificname='+f.scientificname.value+
		'&identificationremarks='+f.identificationremarks.value;

  loadRecord(f.record_id.value);
  hideIdentForm();
}

// -------------------------------------------------------------------------
function hideIdentForm()
{ var f = document.identForm;
  f.record_id.value             = '';
  f.kingdom.value               = '';
  f.user_id.value		= '';

  f.family.value                = '';
  f.scientificname.value        = '';
  f.vernacularname.value        = '';
  f.identificationremarks.value = '';

  f.style.visibility = 'hidden';

}
// -------------------------------------------------------------------------
function validateIdent(rid,ident_id)
{ ajax_par = 'rid='+rid+'&ident_id='+ident_id+'&action=validate&mode=work&ajax=true';
  loadRecord(rid);
}
// -------------------------------------------------------------------------
function invalidateIdent(rid,ident_id)
{ if (confirm(areYouSure()))
  { ajax_par = 'rid='+rid+'&ident_id='+ident_id+'&action=invalidate&mode=work&ajax=true';
    loadRecord(rid);
  }
}
// -------------------------------------------------------------------------
function deleteIdent(rid,ident_id)
{ if (confirm(areYouSure()))
  { ajax_par = 'rid='+rid+'&ident_id='+ident_id+'&action=delIdent&mode=work&ajax=true';
    loadRecord(rid);
  }
}
// -------------------------------------------------------------------------
function deleteRecord(record_id)
{ if (confirm(areYouSure()))
  { var f = document.searchForm;
    f.rid.value = record_id;
    f.action.value = 'delRecord';
    f.submit();
  }
}
// -------------------------------------------------------------------------
function changeGroup(rid,taxgrp)
{ ajax_par = 'rid='+rid+'&taxgrp='+taxgrp+'&action=changeGroup&mode=work&ajax=true';
  loadRecord(rid);
}
// -------------------------------------------------------------------------
function changeHabit(rid,habit)
{ ajax_par = 'rid='+rid+'&habit='+habit+'&action=changeHabit&mode=work&ajax=true';
  loadRecord(rid);
}
// -------------------------------------------------------------------------
function changeInteraction(rid,interaction)
{ ajax_par = 'rid='+rid+'&interaction='+interaction+'&action=changeInteraction&mode=work&ajax=true';
  loadRecord(rid);
}
// -------------------------------------------------------------------------
function clearForm(frm)
{ var f = document.getElementById(frm);
  var frm_elements = f.elements;

  for (i = 0; i < frm_elements.length; i++)
  { field_type = frm_elements[i].type.toLowerCase();
    switch (field_type)
    { case "text":
      case "password":
      case "textarea":
      case "hidden":
            frm_elements[i].value = "";
            break;
      case "radio":
      case "checkbox":
            if (frm_elements[i].checked)
            {
                frm_elements[i].checked = false;
            }
            break;
      case "select-one":
      case "select-multi":
            frm_elements[i].selectedIndex = -1;
            break;
      default:
            break;
    }
  }
  f.action.value = 'search';
}

// -------------------------------------

function editRecord(rid)
{ ajax_par = 'rid='+rid+'&action=search&mode=work&ajax=true';
  loadRecord(rid);
}

// -------------------------------------
function doneRecord(rid)
{ ajax_par = 'rid='+rid+'&action=search&mode=view&ajax=true';
  loadRecord(rid)
}

// -------------------------------------
function submitSearchForm(par)
{ var d = document.getElementById('searchForm');
  d.report.value = par.report;
  if (par.offset !== undefined)	{ d.offset.value	= par.offset }
  if (par.graph_type)	{ d.graph_type.value	= par.graph_type }
  if (par.order_by)	{ d.order_by.value	= par.order_by }
  d.submit();
}
