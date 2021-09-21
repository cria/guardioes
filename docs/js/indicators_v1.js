// -------------------------------------
function submitIndicatorsForm(msg)
{ var f = document.getElementById('indicatorsForm');

  var day_ini  = f.day_ini[f.day_ini.selectedIndex].value;
  var month_ini  = f.month_ini[f.month_ini.selectedIndex].value;
  var year_ini = f.year_ini[f.year_ini.selectedIndex].value;

  var day_fim = f.day_fim[f.day_fim.selectedIndex].value;
  var month_fim = f.month_fim[f.month_fim.selectedIndex].value;
  var year_fim = f.year_fim[f.year_fim.selectedIndex].value;

  var error = 0;

  if (day_ini)
  { if (!month_ini || !year_ini)	{ error = 1 } }
  else if (month_ini && !year_ini) { error = 2 }

  if (day_fim)
  { if (!month_fim || !year_fim)	{ error = 3 } }
  else if (month_fim && !year_fim) { error = 4 }

  if (year_ini)
  { if (!month_ini) { month_ini = 1 }
    if (!day_ini) { day_ini = 1 }
  }

  if (year_fim)
  { if (!month_fim) { month_fim = 12 }
    if (!day_fim) { day_fim = maxDayOf(month_fim,year_fim) }
  }

  if (year_ini && year_fim)
  { var ini = new Date(); ini.setFullYear(year_ini, month_ini-1, day_ini);
    var fim = new Date(); fim.setFullYear(year_fim, month_fim-1, day_fim);

    if (fim < ini) { error = 5 }
  }

  if (error) { alert(msg) }
  else { f.submit() }
}
