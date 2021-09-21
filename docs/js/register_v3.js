// --------------------------------- abre uma janela com o texto passado como parâmetro
//	TRANSFERIDO PARA MAIN_v2.js
//	function openNote(page)
//	{ var note = window.open("/showNote?"+page, "", "width=800,height=600");
//	}

// --------------------------------- 

	function pintaExpertInfo()
	{ var f = document.formRegistration;
	  if (f.agreement.checked)
	  { if (f.curriculum.value == '')
	    { f.curriculum.style.backgroundColor = '#fee' }

	    var anyExp = false;
	    for (i=0;i<f.expertise.length;i++)
	    { anyExp |= f.expertise[i].checked }

	    if (!anyExp)
	    { document.getElementById('expertiseTable').style.backgroundColor = '#fee' }

	  }
	  else
	  { f.curriculum.style.backgroundColor = '#fff';
	    document.getElementById('expertiseTable').style.backgroundColor = '#fff';
	  }
	}

// --------------------------------- Consist form and submit if OK

	function consist(lang)
	{ var f = document.formRegistration;

	  for (i=0;i<f.length;i++)
	  { if (f[i].type != 'button') { f[i].style.backgroundColor = '#fff'; } }

	  var ok = true;
	  if (f.name.value == '')
	  { ok = false; f.name.style.backgroundColor = '#fee' }

	  if (f.email.value == '')
	  { ok = false; f.email.style.backgroundColor = '#fee'}

	  if (f.nickname.value == '')
	  { ok = false; f.nickname.style.backgroundColor = '#fee'}

	  if (f.birth_day.value == '' || f.birth_month.value == '' || f.birth_year.value == '' ||
		! isValidDate(f.birth_day.value,f.birth_month.value,f.birth_year.value)	||
		! notFutureDate(f.birth_day.value,f.birth_month.value,f.birth_year.value) 
	     )
	  { ok = false;
	    f.birth_day.style.backgroundColor	= '#fee';
	    f.birth_month.style.backgroundColor = '#fee';
	    f.birth_year.style.backgroundColor	= '#fee';
	  }

	  if (f.action.value == 'register')
	  { if (f.password.value == '' || f.password2.value == '' || f.password.value != f.password2.value )
	    { ok = false; f.password.style.backgroundColor = '#fee'; f.password2.style.backgroundColor = '#fee' }
	  }

	  if (f.agreement && f.agreement.checked)
	  { if (f.curriculum.value == '')
	    { ok = false; f.curriculum.style.backgroundColor = '#fee' }

	    var anyExp = false;
	    for (i=0;i<f.expertise.length;i++)
	    { anyExp |= f.expertise[i].checked }

	    if (!anyExp)
	    { ok = false; document.getElementById('expertiseTable').style.backgroundColor = '#fee' }
	  }

	  // apenas quando é um novo registro
	  if (f.terms_guardiao && ! f.terms_guardiao.checked)
	  { ok = false; document.getElementById('terms_guardiao').style.backgroundColor = '#fee' }

 	  if (ok)
	  { document.cookie = "guardioesCookieLang="+f.language[f.language.selectedIndex].value;
	    f.submit();
	  }
	  else
	  { if (lang == 'en') { message({ msg: 'Please check the highlighted fields and try again', type: 'error' }) }
	    else 	      {	message({ msg: 'Por favor, complete os campos assinalados e tente novamente', type: 'error' }) }
	    return false;
	  }
	}
