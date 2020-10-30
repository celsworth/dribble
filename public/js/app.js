let app, ws;

const windowResizeObserver = new ResizeObserver(entries => {
	entries.forEach(entry => {
		// for some reason a resize event of 0x0 occurs when we set
		// display: none, so ignore those
		if (entry.target.offsetWidth > 0 && entry.target.offsetHeight > 0) {
			debouncedWindowResizeObserved(entry);
		}
	});
});

let debouncedWindowResizeObserved = debounce(entry => {
  app.ports.windowResizeObserved.send({
	id: entry.target.id,
	width: entry.target.offsetWidth,
	height: entry.target.offsetHeight
  });
} , 200);

const dtFormat = new Intl.DateTimeFormat('default', {
	day: '2-digit', month: '2-digit', year: 'numeric',
	hour: '2-digit', minute: '2-digit', second: '2-digit',

	//hour12: false,
	timeZoneName: 'short'
});

// <local-time posix="1601468962000">
customElements.define('local-time',
	class extends HTMLElement {
		constructor() { super(); }
		connectedCallback() { this.setTextContent(); }
		attributeChangedCallback() { this.setTextContent(); }
		static get observedAttributes() { return ['posix']; }

		setTextContent()
		{
			const posix = this.getAttribute('posix');
			this.textContent = dtFormat.format(posix);
		}
	}
);

customElements.define('context-menu',
	class extends HTMLElement {
		constructor() { super(); }

		// attempt to keep context menu visible on screen by showing it
		// to left/top of cursor if necessary
		connectedCallback() {
			let iWidth = window.innerWidth;
			let oLeft = this.offsetLeft;

			let iHeight = window.innerHeight;
			let oTop = this.offsetTop;

			if (oLeft + this.offsetWidth > iWidth)
			{
				this.style.right = (iWidth - oLeft) + "px";
				this.style.left = "";
			}

			if (oTop + this.offsetHeight > iHeight)
			{
				this.style.bottom = (iHeight - oTop) + "px";
				this.style.top = "";
			}
		}
	}
);

/* unused
function humanFileSize(bytes, units, dp) {
	let suffixes, thresh;

	if (units == "si") {
		suffixes = ['kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
		thresh = 1000;
	} else {
		suffixes = ['KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
		thresh = 1024;
	}

	let u = -1;
	const r = 10**dp;

	do {
		bytes /= thresh;
		++u;
	} while (Math.round(Math.abs(bytes) * r) / r >= thresh && u < suffixes.length - 1);

	return bytes.toFixed(dp) + ' ' + suffixes[u];
}

// <human-bytes bytes="999999", units="si", dp="1">
customElements.define('human-bytes',
	class extends HTMLElement {
		constructor() { super(); }
		connectedCallback() { this.setTextContent(); }
		attributeChangedCallback() { this.setTextContent(); }
		static get observedAttributes() { return ['bytes', 'units', 'dp']; }

		setTextContent()
		{
			const bytes = this.getAttribute('bytes');
			const units = this.getAttribute('units');
			const dp = this.getAttribute('dp');
			this.textContent = humanFileSize(bytes, units, dp)
		}
	}
);
*/

function debounce(func, wait, immediate) {
	var timeout;
	return function() {
		var context = this, args = arguments;
		var later = function() {
			timeout = null;
			if (!immediate) func.apply(context, args);
		};
		var callNow = immediate && !timeout;
		clearTimeout(timeout);
		timeout = setTimeout(later, wait);
		if (callNow) func.apply(context, args);
	};
};

function connect() {
	const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
	const ws_path = `${protocol}//${location.host}/ws`;

	ws = new WebSocket(ws_path);

	ws.onopen = function(event) {
		app.ports.websocketStatusUpdated.send({connected: true});
	}

	ws.onclose = function(e) {
		console.log('Socket is closed. Reconnect will be attempted in 2 seconds.', e.reason);
		setTimeout(function() {
			connect();
		}, 2000);

		app.ports.websocketStatusUpdated.send({connected: false});
	};

	ws.onerror = function(err) {
		// console.error('Socket encountered error: ', err.message, 'Closing socket');
		ws.close();
	};

	ws.onmessage = function(e) {
		//console.log('Message:', e.data);
		app.ports.messageReceiver.send(e.data);
	};
}


