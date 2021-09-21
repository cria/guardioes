var winWidth  = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
var winHeight = window.innerHeight || document.documentElement.clientWidth || document.body.clientWidth;
var userLang  = 'pt';

// ==================================================================================
function switchTheme(obj)
{ var pal = obj[obj.selectedIndex].value;
  document.cookie = "guardioesPalette="+pal;
  document.getElementById('pageColors').setAttribute('href','/css/colors_v'+pal+'.css');
}

// ==================================================================================
function switchLang(lang)
{ document.cookie = "guardioesCookieLang="+lang;
  location.reload();
}
// ==================================================================================
function windowSize()
{ winWidth  = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
  winHeight = window.innerHeight || document.documentElement.clientWidth || document.body.clientWidth;
  document.cookie = "guardioesWindowWidth="+winWidth;
  document.cookie = "guardioesWindowHeight="+winHeight;
//  setLang();
}
// ==================================================================================
function userMenu(i)
{ if (i == 1)	{ document.location = '/register' }
  else 
  if (i == 2)	{ document.location = '/logoff' }

  return false;
}

// ==================================================================================
function fixMenuPosition()
{ if (document.getElementById && !document.all)
  { if ( d = document.getElementById("divTopBanner"))	{ d.style.top = window.pageYOffset + "px" };
    if ( d = document.getElementById("divMsg"))		{ d.style.top = (window.pageYOffset + 45) + "px" };
  }
  else if (document.all)
  { if (d = document.all["divTopBanner"]) { d.style.top  = document.body.scrollTop + "px" };
    if (d = document.all["divMsg"])	  { d.style.top  = (document.body.scrollTop + 45) + "px" };
  }
}

// ==================================================================================
function notFutureDate(day,mon,year)
{ var today = new Date();
  var dt    = new Date(); dt.setFullYear(year,mon-1,day);
  if (dt > today) { return false }
  return true;
}
// ==================================================================================
function isValidDate(day,mon,year)
{ var ok = false;
  if ((day >= 1 && day <= 31) && (mon >= 1 && mon <= 12) && (year >= 1900 && year <= 2100))
  { // bissexto
    if ( day == 29 && (((year % 400) == 0) || ((year % 4) == 0 && (year % 100) != 0))) { ok = true }
    else
    if (day <= 28 && mon == 2) { ok = true }
    else
    if ((day <= 30) && (mon == 4 || mon == 6 || mon == 9 || mon == 11)) { ok = true  }
    else
    if ((day <=31) && (mon == 1 || mon == 3 || mon == 5 || mon == 7 || mon ==8 || mon == 10 || mon == 12)) { ok = true  }

    if (ok)
    { var today = new Date();
      var dt    = new Date(); dt.setFullYear(year,mon-1,day);
      if (dt > today) { ok = false }
    }
  }
  return ok;
}
// ==================================================================================
function maxDayOf(mon,year)
{ for (var i=31;i>27;i--) { if (isValidDate(i,mon,year)) { return i; break } }
}
// ==================================================================================
function fixHome()
{ var prevW = winWidth;
  windowSize();
  if ((prevW <= 1100 && winWidth > 1100) || (prevW > 1100 && winWidth <= 1100))
  { document.location = document.location }
}
// ==================================================================================

function openNote(page)
{ var note = window.open("/showNote?"+page, "", "width=800,height=600"); }

// ==================================================================================
function areYouSure()
{ return userLang == 'pt' ? 'Tem certeza?' : 'Are your sure?'; }

// ==================================================================================
function setLang()
{ var name = "guardioesCookieLang=";
  var decodedCookie = decodeURIComponent(document.cookie);
  var ca = decodedCookie.split(';');
  for(var i = 0; i <ca.length; i++)
  { var c = ca[i];
    while (c.charAt(0) == ' ')
    { c = c.substring(1); }
    if (c.indexOf(name) == 0) { userLang = c.substring(name.length, c.length); }
    }
    return "";
}
// ==================================================================================

onscroll=fixMenuPosition;
onload=windowSize;
onresize=fixHome;
