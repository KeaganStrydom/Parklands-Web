// Source: http://is.gd/mwZp7E
var frag = document.createDocumentFragment();
var node, next;

try {
	webkit.messageHandlers.disableUserInteraction.postMessage("Send from JavaScript");
} catch(err) {
	console.log('error');
}

// Remove ads
window.onload = function () {
	try {
		document.getElementsByClassName("gsc-adBlock")[0].style.display = "none"
	} catch(err) {
		console.log(err)
	}

	// Block other search providers
	hosts.map(host => {
		if (window.location.hostname.indexOf(host) > -1) {
		  document.body.innerHTML = "<h1>Blocked :(</h1>"
		  return
		}
	})

	// Walk the dom looking for the given text in text nodes
	walk(document.body);

	// Insert the result into the current document via a fragment
	node = document.body.firstChild;
	while (node) {
		next = node.nextSibling;
		frag.appendChild(node);
		node = next;
	}
	document.body.innerHTML = ""
	document.body.appendChild(frag);
	
	try {
		webkit.messageHandlers.enableUserInteraction.postMessage("Send from JavaScript");
	} catch(err) {
		console.log('error');
	}
}

// Our walker function
function walk(node) {
	var child, next;
	
	switch (node.nodeType) {
		case 1:  // Element
		case 9:  // Document
		case 11: // Document fragment
			child = node.firstChild;
			while (child) {
				next = child.nextSibling;
				walk(child);
				child = next;
			}
			break;
		case 3: // Text node
			handleText(node);
			break;
	}
}

function handleText(textNode) {
	console.log(textNode)
	words.map(word => {
			  textNode.nodeValue = textNode.nodeValue.replace(new RegExp(` ${word} `, "gi"), "!@#$%");
			  })
}
