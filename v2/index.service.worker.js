// This service worker is required to expose an exported Godot project as a
// Progressive Web App. It provides an offline fallback page telling the user
// that they need an Internet connection to run the project if desired.
// Incrementing CACHE_VERSION will kick off the install event and force
// previously cached resources to be updated from the network.
const CACHE_VERSION = "1693055340|3003033294";
const CACHE_PREFIX = "Arrow-sw-cache-";
const CACHE_NAME = CACHE_PREFIX + CACHE_VERSION;
const OFFLINE_URL = "index.offline.html";
// Files that will be cached on load.
const CACHED_FILES = ["index.html","index.js","index.offline.html","index.icon.png","index.apple-touch-icon.png"];
// Files that we might not want the user to preload, and will only be cached on first load.
const CACHABLE_FILES = ["index.wasm","index.pck"];
const FULL_CACHE = CACHED_FILES.concat(CACHABLE_FILES);

self.addEventListener("install", (event) => {
	event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(CACHED_FILES)));
});

self.addEventListener("activate", (event) => {
	event.waitUntil(caches.keys().then(
		function (keys) {
			// Remove old caches.
			return Promise.all(keys.filter(key => key.startsWith(CACHE_PREFIX) && key != CACHE_NAME).map(key => caches.delete(key)));
		}).then(function() {
			// Enable navigation preload if available.
			return ("navigationPreload" in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();
		})
	);
});

async function fetchAndCache(event, cache, isCachable) {
	// Use the preloaded response, if it's there
	let response = await event.preloadResponse;
	if (!response) {
		// Or, go over network.
		response = await self.fetch(event.request);
	}
	if (isCachable) {
		// And update the cache
		cache.put(event.request, response.clone());
	}
	return response;
}

self.addEventListener("fetch", (event) => {
	const isNavigate = event.request.mode === "navigate";
	const url = event.request.url || "";
	const referrer = event.request.referrer || "";
	const base = referrer.slice(0, referrer.lastIndexOf("/") + 1);
	const local = url.startsWith(base) ? url.replace(base, "") : "";
	const isCachable = FULL_CACHE.some(v => v === local) || (base === referrer && base.endsWith(CACHED_FILES[0]));
	if (isNavigate || isCachable) {
		event.respondWith(async function () {
			// Try to use cache first
			const cache = await caches.open(CACHE_NAME);
			if (event.request.mode === "navigate") {
				// Check if we have full cache during HTML page request.
				const fullCache = await Promise.all(FULL_CACHE.map(name => cache.match(name)));
				const missing = fullCache.some(v => v === undefined);
				if (missing) {
					try {
						// Try network if some cached file is missing (so we can display offline page in case).
						return await fetchAndCache(event, cache, isCachable);
					} catch (e) {
						// And return the hopefully always cached offline page in case of network failure.
						console.error("Network error: ", e);
						return await caches.match(OFFLINE_URL);
					}
				}
			}
			const cached = await cache.match(event.request);
			if (cached) {
				return cached;
			} else {
				// Try network if don't have it in cache.
				return await fetchAndCache(event, cache, isCachable);
			}
		}());
	}
});

self.addEventListener("message", (event) => {
	// No cross origin
	if (event.origin != self.origin) {
		return;
	}
	const id = event.source.id || "";
	const msg = event.data || "";
	// Ensure it's one of our clients.
	self.clients.get(id).then(function (client) {
		if (!client) {
			return; // Not a valid client.
		}
		if (msg === "claim") {
			self.skipWaiting().then(() => self.clients.claim());
		} else if (msg === "clear") {
			caches.delete(CACHE_NAME);
		} else if (msg === "update") {
			self.skipWaiting().then(() => self.clients.claim()).then(() => self.clients.matchAll()).then(all => all.forEach(c => c.navigate(c.url)));
		} else {
			onClientMessage(event);
		}
	});
});

