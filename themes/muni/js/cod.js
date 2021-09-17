function cod_doc_write(text) {
  var cod = document.getElementById('cod');
  cod.outerHTML = text;
}

function cod_tag(sysno) {
  if (sysno.substring(0, 5) != 'MUB01') {
    return;
  }

  sysno = sysno.replace(/^MUB0[1-3]/, '');
  var url = 'https://knihomol.phil.muni.cz/system/include/copy-available/' + sysno + '?url=katalog';
  var script = document.createElement('script');
  script.src = url;
  document.body.appendChild(script);
}
