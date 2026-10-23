// chawal Firefox rice prefs; firefox/install.sh merges this into <profile>/user.js.
// about:config: rice.tint = "subtle" | "tinted" | "off" (set explicitly: an unset pref matches "off"),
// rice.solid = true for opaque bars.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("rice.tint", "subtle");
