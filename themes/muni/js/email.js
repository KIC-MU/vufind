// <![CDATA[
function prevedEmaily() {
	if (document.getElementById) {
		// vsechny tagy span v dokumentu
		var emaily = document.getElementsByTagName('span');
		
		for (var i = 0; i < emaily.length; i++) {
			var trida = emaily[i].getAttributeNode('class');

			// maji-li tridu email
      if (trida != null && trida.value == 'email') {
				var customText = emaily[i].getAttributeNode('data-text');
				// nahradime obrazky tecky a zavinace textem 
				var tecka = document.createTextNode('.');
				var zavinac = document.createTextNode('@');
				var tecky = emaily[i].getElementsByTagName('img');
				for (var j = 0; j < tecky.length; j) {
					if (tecky[j].getAttribute('alt') == ' zavinac | at ') {
						emaily[i].replaceChild(zavinac, tecky[j]);
						emaily[i].normalize();
					}
					else {
						emaily[i].replaceChild(tecka, tecky[j]);
						emaily[i].normalize();
					}
				}
       

				// jeste udelame kliakci mail
				var odkaz = document.createElement('a');
				var text; 
				if (customText == null || customText.value == '') {
					text = document.createTextNode(emaily[i].firstChild.nodeValue);
				}
				else {
					text = document.createTextNode(customText.value);
				}
        var href = document.createAttribute('href');
				href.value = 'mailto:' + emaily[i].firstChild.nodeValue;
				odkaz.setAttributeNode(href);
				odkaz.appendChild(text);
        
				emaily[i].replaceChild(odkaz, emaily[i].firstChild);       
      } 	
    }
  }
}

prevedEmaily();
// ]]>
