// DateTimeOriginal format is "YYYY:MM:DD HH:MM:SS"+0x00, total 20bytes.
//GPSLatitude and GPSLongitude: Indicates the latitude. The latitude is expressed as three RATIONAL values giving the degrees, minutes, and seconds, respectively. When degrees, minutes and seconds are expressed, the format is dd/1,mm/1,ss/1. When degrees and minutes are used and, for example, fractions of minutes are given up to two decimal places, the format is dd/1,mmmm/100,0/1.

var hasCoords = false;
var badCoords = false;

function decimalCoord(str,ref)
{ var p = str.split(",");
  var ll = (p[0]/1)+(p[1]/60)+(p[2]/3600);
  ll *= ref.match(/N|E/) ? 1 : -1;
  return ll.toFixed(4);
}

function getExif(e,n)
{ var src, i, file, max_imgs;
  if (e.type == 'change')
  { src = e.target.files }
  else if (e.type == 'drop')
  { src = e.dataTransfer.files }
  else { return; }
  // lida com multiplas imagens
  if (n < 4)
  { max_imgs = 4-n } // num. max. imagens interacao
  else
  { max_imgs = 8-n } // num. max. imagens plantas
  for (i=0;i<src.length;i++)
  { file = src[i];
    getSingleExif(e,n,file);
    if (i+1===max_imgs) break; // para no limite de imagens
    n++;
  }
}

function getSingleExif(e,n,file)
{ var img = document.getElementById('output_'+n);
  var src_orig;
  if (img.tagName.toLowerCase() === 'img')
  { src_orig = img.src;
  }
  else if (img.tagName.toLowerCase() === 'image')
  { src_orig = img.attributes.getNamedItem('xlink:href').value; }
  var loading_img = 'imgs/loading.gif';
  if (img.tagName.toLowerCase() === 'img')
  { img.src = loading_img; }
  else if (img.tagName.toLowerCase() === 'image')
  { img.setAttributeNS("http://www.w3.org/1999/xlink",'xlink:href',loading_img); }

  EXIF.getData(file, function()
  { var lat;
    var lon;
    var exif_lat = EXIF.getTag(this, "GPSLatitude");
    var exif_lon = EXIF.getTag(this, "GPSLongitude");

    if (exif_lat) { lat = decimalCoord(exif_lat.toString(),EXIF.getTag(this, "GPSLatitudeRef")) }
    if (exif_lon) { lon = decimalCoord(exif_lon.toString(),EXIF.getTag(this, "GPSLongitudeRef")) }
    var alt = EXIF.getTag(this, "GPSAltitude");
    var datum = EXIF.getTag(this, "GPSMapDatum");

    var dt  = EXIF.getTag(this, "DateTimeOriginal");
//    if (!dt) { dt = EXIF.getTag(this, "DateTime"); }
//    if (!dt) { dt = EXIF.getTag(this, "DateTimeDigitized"); }

    var ori = EXIF.getTag(this, "Orientation");
    var f = top.document.recordForm;

    if (lat && lon)
    { if ((f.decimallatitude.value && ((Math.abs(f.decimallatitude.value) - Math.abs(lat))) > 0.01) ||
          (f.decimallongitude.value && ((Math.abs(f.decimallongitude.value) - Math.abs(lon))) > 0.01))
      { if (!badCoords)
        { message({ msg: 'Coordenadas entre as fotos são muito diferentes. Por favor use o mapa para marcar o local correto da observação.',type: 'warn' });
	  badCoords = true;
	}
      }

      if (lat)	{ f.decimallatitude.value	= lat }
      if (lon)	{ f.decimallongitude.value	= lon }
      if (alt)	{ f.elevation.value		= alt }
      if (datum)	{ f.datum.value		= datum }
	if (! top.marker)
	{ top.placeMarker(new google.maps.LatLng( Number(lat),Number(lon)),map);
	  top.fillGeoInfo(false);
	  if (Number(lat) && Number(lon)) { message({ msg: 'Coordenadas da coleta detectadas da foto', type: 'info' }) }
	}
    }

    if (dt)
    { var d = dt.match(/^\d\d\d\d:\d\d:\d\d/).toString().split(":");
      f.eventdate.value = d[2]+'/'+d[1]+'/'+d[0];

      var t = dt.match(/\d\d:\d\d:\d\d$/).toString().split(":");
      f.verbatimeventdate.value	= dt.toString();

      f.eventtime.selectedIndex = Math.floor(t[0]/2);
    }


  });
  openFile(n,file);
  if (img.tagName.toLowerCase() === 'img')
  { if (img.src === loading_img) { img.src = src_orig; }
  }
  else if (img.tagName.toLowerCase() === 'image')
  { if (img.attributes.getNamedItem('xlink:href').value === loading_img)
    { img.setAttributeNS("http://www.w3.org/1999/xlink",'xlink:href',src_orig); }
  }
}

var openFile = function(n,file)
{ var reader = new FileReader();
  reader.onload = function()
  { var dataURL = reader.result;
    var output = document.getElementById('output_'+n);
    if (output.tagName.toLowerCase() === 'img')
    { output.src = dataURL;
    }
    else if (output.tagName.toLowerCase() === 'image')
    { output.setAttributeNS("http://www.w3.org/1999/xlink",'xlink:href',dataURL); }
  };
  reader.readAsDataURL(file);
};

// =====================================================================================
function consist(lang)
{ var f = document.recordForm;

  var messages = { pt:	{ Intro		: 'Favor fornecer todos os dados obrigatórios:',
			  Images	: 'carregue pelo menos uma imagem de planta e uma da interação observada',
			  TaxGroup	: 'informe "Que animal é esse?"',
			  Location	: 'use o mapa para informar a "Localização" da observação',
			  EventDate	: 'informe a data da observação',
			},
		   en:	{ Intro		: 'Please provide all the mandatory information:',
			  Images	: 'upload at least one image of the plant and one of the observed inteaction',
			  TaxGroup	: 'inform the taxonomic group of the anima',
			  Location	: 'use the map to inform location of the observation',
			  EventDate	: 'inform the date of the observation',
			}
		 };

  var error = false; var msg = {};

  if (f.country.value == '')
  { f.country.style.backgroundColor = '#fdd'; error = true; msg.Location = 1 }
  else { f.country.style.backgroundColor = '#dfd' } 

  if (f.stateprovince.value == '')
  { f.stateprovince.style.backgroundColor = '#fdd'; error = true; msg.Location = 1 }
  else { f.stateprovince.style.backgroundColor = '#dfd' } 

  if (f.municipality.value == '')
  { f.municipality.style.backgroundColor = '#fdd'; error = true; msg.Location = 1 }
  else { f.municipality.style.backgroundColor = '#dfd' } 

  if (f.decimallatitude.value == '')
  { f.decimallatitude.style.backgroundColor = '#fdd'; error = true; msg.Location = 1 }
  else { f.decimallatitude.style.backgroundColor = '#dfd' } 

  if (f.decimallongitude.value == '')
  { f.decimallongitude.style.backgroundColor = '#fdd'; error = true; msg.Location = 1 }
  else { f.decimallongitude.style.backgroundColor = '#dfd' } 

  var ed = f.eventdate.value;
  if (ed == '')
  { f.eventdate.style.backgroundColor = '#fdd'; error = true; msg.EventDate = 1 }
  else
  { var d = ed.split("\/");
    if (isValidDate(d[0],d[1],d[2]) && notFutureDate(d[0],d[1],d[2]))
    { f.eventdate.style.backgroundColor = '#dfd' } 
    else
    { f.eventdate.style.backgroundColor = '#fdd'; error = true; msg.EventDate = 1 }
  }

  if (f.taxgrp.selectedIndex == 0)
  { f.taxgrp.style.backgroundColor = '#fdd'; error = true; msg.TaxGroup = 1 }
  else { f.taxgrp.style.backgroundColor = '#dfd' } 

// interacao

  var n = 0;
  for (i=0;i<=3;i++)
  { if (document.getElementById('foto_'+i).value != '') { n++ } }
  if (n < 1) { error = true; msg.Images = 1 }

// planta

  var n = 0;
  for (i=4;i<=7;i++)
  { if (document.getElementById('foto_'+i).value != '') { n++ } }
  if (n < 1) { error = true; msg.Images = 1 }

  if (error)
  { var text = '';
    for (key in msg)
    { text += messages[lang][key] + '<br/>' }

    message({ msg: messages[lang]['Intro'] + '<p/>' + text,type: 'error' });
    return false;
  }
  else
  {
    f.submit();
    message({ msg: 'Enviando dados. Por favor aguarde.',type: 'info', timeout: 20000 });
    top.document.getElementById('divMain').innerHTML = "";
  }
}

// =============  Drag & Drop stuff ===================

// Esta variavel evita a remocao da classe dragover quando, depois de ativado o dragenter,
//  o mouse entra num subelemento, ativando o dragleave do div
var cnt_ctrl = 0;

// Retorna as coordenadas de um elemento qq em relacao ao documento
function getCoords(elem) {
  var box = elem.getBoundingClientRect();

  var body = document.body;
  var docEl = document.documentElement;

  var scrollTop = window.pageYOffset || docEl.scrollTop || body.scrollTop;
  var scrollLeft = window.pageXOffset || docEl.scrollLeft || body.scrollLeft;

  var clientTop = docEl.clientTop || body.clientTop || 0;
  var clientLeft = docEl.clientLeft || body.clientLeft || 0;

  var top  = box.top +  scrollTop - clientTop;
  var left = box.left + scrollLeft - clientLeft;

  return { top: Math.round(top), left: Math.round(left) };
}
// Drop de arquivos
function handleFileDrop(e) {
  var parts = e.target.id.split('_');
  if (parts.length === 2) {
    var n = parseInt(parts[1]);
    getExif(e,n);
    //document.getElementById('img_'+n).classList.remove('dragover');
    this.classList.remove('dragover');
  }
  cnt_ctrl = 0;
}
function handleDragEnter(e) {
  e.stopPropagation();
  e.preventDefault();
  cnt_ctrl++;
  this.classList.add('dragover');
}
function handleDragLeave (e) {
  e.stopPropagation();
  e.preventDefault();
  cnt_ctrl--;
  if (cnt_ctrl === 0) {
    this.classList.remove('dragover');
  }
}
function handleDragOver(e) {
  var x = e.pageX;
  var y = e.pageY;
  var input = this.firstElementChild;
  var coords = {top: 0, left: 0};
  var buffer = 2; // distancia ate a margem do input para que o mouse nao fique no limiar dele
  e.stopPropagation();
  e.preventDefault();
  if (input && input.type === 'file') {
    // pega coordenadas do div, pois as coordenadas do input são relativas a ele
    coords = getCoords(this);
    // faz com que o input siga o mouse para estar na area do drop
    input.style.top = (y - coords.top - buffer) + 'px';
    input.style.left = (x - coords.left - buffer) + 'px';
  }
  e.dataTransfer.dropEffect = 'copy';
}

function showDiv(d)
{ var divs = ['Main','Help','Glossary'];

  for (i=0;i<=2;i++)
  { document.getElementById('div'+divs[i]).style.visibility = 'hidden';
    document.getElementById('subMenuItem'+divs[i]).className = 'subMenuOff';
  }

  document.getElementById('subMenuItem'+d).className = 'subMenuOn';
  document.getElementById('div'+d).style.visibility = 'visible';
}

function pergunta()
{ alert('?');
}
