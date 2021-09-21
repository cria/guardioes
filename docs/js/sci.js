<script type="text/javascript">
	 var	p_s_options = {	script: "plantae_scinames_options?", 
				varname: "sciname", 
				json: true,
				minchars: 1,
				delay: 10,
				offsety: 0,
				timeout: 10000,
				noresults: "Nome não encontrado",
				cache: false,
				maxresults: 35,
				callback: function(obj) { d = document.searchForm; e = obj.info.split(':'); d.p_family.value = e[0]; document.getElementById('p_FullName').innerHTML = e[1] }
			};
	 var	p_s = new bsn.AutoSuggest('p_sciname', p_s_options);

	 var	p_f_options = {	script: "plantae_family_options?", 
				varname: "family", 
				json: true,
				minchars: 1,
				delay: 10,
				offsety: 0,
				timeout: 10000,
				noresults: "Nome não encontrado",
				cache: false,
				maxresults: 35,
				callback: function(obj) { }
			};
	 var	p_f = new bsn.AutoSuggest('p_family', p_f_options);

	 var	a_s_options = {	script: "animalia_scinames_options?", 
				varname: "sciname", 
				json: true,
				minchars: 1,
				delay: 10,
				offsety: 0,
				timeout: 10000,
				noresults: "Nome não encontrado",
				cache: false,
				maxresults: 35,
				callback: function(obj) { d = document.searchForm; e = obj.info.split(':'); d.a_family.value = e[0]; document.getElementById('a_FullName').innerHTML = e[1] }
			};
	  var	a_s = new bsn.AutoSuggest('a_sciname', a_s_options);

	 var	a_f_options = {	script: "animalia_family_options?", 
				varname: "family", 
				json: true,
				minchars: 1,
				delay: 10,
				offsety: 0,
				timeout: 10000,
				noresults: "Nome não encontrado",
				cache: false,
				maxresults: 35,
				callback: function(obj) { }
			};
	  var	a_f = new bsn.AutoSuggest('a_family', a_f_options);
</script>
