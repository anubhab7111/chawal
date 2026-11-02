// Glass for Obsidian: gives the vault window an alpha channel and loads
// glass.css into it, so Hyprland blurs the wallpaper behind the chrome.
//
// Obsidian has no switch for this on Linux, so it is done from the outside:
// install.sh puts a small loader in electron's flags file (`-r`), which requires
// this before Obsidian's main process starts.
//
// Only the window that gets transparency gets the CSS, so if the loader cannot
// find this file Obsidian opens with the plain opaque theme.
'use strict';

const Module = require('module');
const fs = require('fs');
const path = require('path');

const CSS = path.join(__dirname, 'glass.css');

// The flags file applies to everything on this electron, Obsidian included.
const isObsidian = process.argv.some((arg) => /[/\\]obsidian[/\\]app\.asar$/.test(arg));

if (isObsidian) {
  const load = Module._load;
  let patched;

  const patch = (electron) => {
    class GlassWindow extends electron.BrowserWindow {
      constructor(options = {}) {
        // Vault windows ask for this colour; the starter and help windows do
        // not, and have no glass styles to go with an alpha channel.
        const glass = options.backgroundColor === '#00000000';
        super(glass ? { ...options, transparent: true } : options);
        if (glass) {
          // Read on every load, so reloading the window picks up CSS edits.
          this.webContents.on('dom-ready', () => {
            fs.promises
              .readFile(CSS, 'utf8')
              .then((css) => this.webContents.insertCSS(css))
              .catch((err) => console.error('glass:', err));
          });
        }
      }
    }
    // electron's exports are getter-only, hence a proxy over assignment.
    return new Proxy(electron, {
      get: (target, key, receiver) =>
        key === 'BrowserWindow' ? GlassWindow : Reflect.get(target, key, receiver),
    });
  };

  Module._load = function (request) {
    const loaded = load.apply(this, arguments);
    if (request !== 'electron' || !loaded.BrowserWindow) return loaded;
    patched = patched || patch(loaded);
    return patched;
  };
}
