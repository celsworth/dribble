const dtFormat = new Intl.DateTimeFormat('default', {
	day: '2-digit', month: '2-digit', year: 'numeric',
	hour: '2-digit', minute: '2-digit', second: '2-digit',

	//hour12: false,
	timeZoneName: 'short'
});

// <localtime posix="1601468962000">
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
