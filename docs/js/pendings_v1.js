function submitForm()
{ f = document.pendingsForm;

  if (f.animalia_scientificname.checked || f.plantae_scientificname.checked || f.animalia_name.checked || f.plantae_name.checked) { f.submit(); return true }

  return false;
}

function toogleCheck(obj)
{ var f = document.pendingsForm;
  if (obj.name != 'animalia_scientificname')	{ f.animalia_scientificname.checked = false }
  if (obj.name != 'animalia_name')		{ f.animalia_name.checked = false }
  if (obj.name != 'plantae_scientificname')	{ f.plantae_scientificname.checked = false }
  if (obj.name != 'plantae_name')		{ f.plantae_name.checked = false }
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

