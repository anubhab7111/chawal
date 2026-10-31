// chawal Firefox prefs; firefox/install.sh merges this into <profile>/user.js.
// Firefox ignores chrome/userChrome.css unless this is on.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Keep pages opaque. When true, a page with no background of its own (llvm.org,
// FastAPI /docs) shows the transparent window behind it and reads as dark.
user_pref("browser.tabs.allow_transparent_browser", false);
