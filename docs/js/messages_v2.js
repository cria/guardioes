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
// message({ msg: 'message', type: 'warn|error|info' })
function message(par)
{ var m; var t;

  if (document.getElementById && !document.all)
  { m = document.getElementById("divMsg"); t = (window.pageYOffset +45) + "px" }
  else if (document.all)
  { m = document.all["divMsg"]; t = (document.body.scrollTop + 45) + "px" }

  var to = par.timeout ? par.timeout : par.msg.length * 50;
  if (to < 4000) { to = 4000 }

  par.msg = "<table class='w100 h100'>" +
	"<tr><th>"+par.msg+"</th>" +
	"<td width='5px'><a href='javascript:messageOff()' class='white maior'><b><big>&#xd7;</big></b></a></td></tr>"+
	"</table>";

  m.innerHTML = par.msg;
  var s = m.style;
  s.top = t;
  s.visibility = 'visible';
  s.display = 'block';

  if (par.type == 'error')	/* error */
  { s.backgroundColor = 'var(--error)';
    s.color = '#fff';
  }
  else 
  if (par.type == 'warn')	/* warning */
  { s.backgroundColor = 'var(--warning)';
    s.color = '#fff';
    setTimeout("messageOff()",to);
  }
  else				/* info */
  { s.backgroundColor = 'var(--success)';
    s.color = '#fff';
    setTimeout("messageOff()",to);
  }
} 
