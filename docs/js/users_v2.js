	function update(id,obj)
	{ f = top.document.usersForm;
	  if (confirm(areYouSure()))
	  { f.user_id.value = id;
	    f.change_field.value = obj.name;
	    f.change_value.value = obj[obj.selectedIndex].value;
	    f.submit();
	  }
	  else
	  { f.reset() }
	}
