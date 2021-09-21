function showResetDiv()
{ var r = document.getElementById('divLoginReset');
  r.style.visibility = 'visible';
}

function hideResetDiv()
{ var r = document.getElementById('divLoginReset');
  r.style.visibility = 'hidden';
}

function submitResetPassword()
{ var fr = document.getElementById('formResetId');
  if (!fr.email.value.match('@')) { alert('e-mail obrigatório') }
  else
  { fr.submit() }
}
