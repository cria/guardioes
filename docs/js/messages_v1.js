function messageOff()
{ if (document.getElementById && !document.all)
  { document.getElementById("divMsg").style.visibility = 'hidden';
    document.getElementById("divMsg").style.display = 'none';
  }
  else if (document.all)
  { document.all["divMsg"].style.visibility = 'hidden';
    document.all["divMsg"].style.display = 'none';
  }
}
// ==================================================================================
function message(msg,type)
{ var m; var t;

  if (document.getElementById && !document.all)
  { m = document.getElementById("divMsg"); t = (window.pageYOffset +45) + "px" }
  else if (document.all)
  { m = document.all["divMsg"]; t = (document.body.scrollTop + 45) + "px" }

  var to = msg.length * 50;
  if (to < 4000) { to = 4000 }

  msg = "<table class='w100 h100'>" +
	"<tr><th>"+msg+"</th>" +
	"<td width='5px'><a href='javascript:messageOff()' class='white maior'><b><big>&#xd7;</big></b></a></td></tr>"+
	"</table>";

  m.innerHTML = msg;
  var s = m.style;
  s.top = t;
  s.visibility = 'visible';
  s.display = 'block';

  if (type == 'error')
  { s.backgroundColor = '#c03';
    s.color = '#fff';
  }
  else 
  if (type == 'warn')	/* warning */
  { s.backgroundColor = '#c93';
    s.color = '#fff';
    setTimeout("messageOff()",to);
  }
  else /* success */
  { s.backgroundColor = '#696';
    s.color = '#fff';
    setTimeout("messageOff()",to);
  }
} 
