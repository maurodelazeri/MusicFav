/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	__webpack_require__(3);
	__webpack_require__(1);
	module.exports = __webpack_require__(2);


/***/ },
/* 1 */
/***/ function(module, exports, __webpack_require__) {

	(function (Provider) {
	    Provider[Provider["Youtube"] = 0] = "Youtube";
	    Provider[Provider["SoundCloud"] = 1] = "SoundCloud";
	    Provider[Provider["Vimeo"] = 2] = "Vimeo";
	    Provider[Provider["Raw"] = 3] = "Raw";
	})(exports.Provider || (exports.Provider = {}));
	var Provider = exports.Provider;
	var Track = (function () {
	    function Track(provider, url, serviceId) {
	        this.provider = provider;
	        this.url = url;
	        this.serviceId = serviceId;
	    }
	    Track.prototype.toJSON = function () {
	        return {
	            provider: Provider[this.provider],
	            url: this.url,
	            serviceId: this.serviceId
	        };
	    };
	    return Track;
	})();
	exports.Track = Track;
	var Playlist = (function () {
	    function Playlist(document) {
	        this.title = document.title;
	        this.url = document.location.href;
	        this.tracks = [];
	    }
	    Playlist.prototype.addTrack = function (track) {
	        this.tracks.push(track);
	    };
	    Playlist.prototype.toJSON = function () {
	        return {
	            title: this.title,
	            url: this.url,
	            tracks: this.tracks
	        };
	    };
	    return Playlist;
	})();
	exports.Playlist = Playlist;


/***/ },
/* 2 */
/***/ function(module, exports, __webpack_require__) {

	var models = __webpack_require__(1);
	var Scraper = (function () {
	    function Scraper() {
	    }
	    Scraper.prototype.title = function (document) {
	        return document.title;
	    };
	    Scraper.prototype.extractPlaylist = function (document) {
	        var playlist = new models.Playlist(document);
	        var iframes = document.getElementsByTagName('iframe');
	        var found;
	        for (var i = 0; i < iframes.length; i++) {
	            var src = iframes.item(i).src;
	            if (src.match(/www.youtube.com\/embed/)) {
	                found = src.match(/www.youtube.com\/embed\/(.+)/);
	                var id = found[1].split('?')[0];
	                var t = new models.Track(0 /* Youtube */, src, id);
	                playlist.addTrack(t);
	            }
	            else if (src.match(/api.soundcloud.com\/tracks\//)) {
	                var _src = decodeURIComponent(src);
	                found = _src.match(/api.soundcloud.com\/tracks\/(.+)/);
	                var id = found[1].split('&')[0];
	                var t = new models.Track(1 /* SoundCloud */, src, id);
	                playlist.addTrack(t);
	            }
	        }
	        return playlist;
	    };
	    return Scraper;
	})();
	module.exports = Scraper;


/***/ },
/* 3 */
/***/ function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(global) {module.exports = global["playlistify"] = __webpack_require__(4);
	/* WEBPACK VAR INJECTION */}.call(exports, (function() { return this; }())))

/***/ },
/* 4 */
/***/ function(module, exports, __webpack_require__) {

	exports.Model = __webpack_require__(1);
	exports.Scraper = __webpack_require__(2);


/***/ }
/******/ ])