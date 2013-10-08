var path = '../js/';

// Libraries
$LAB
.script( path + 'lib/jquery.js' )
.script( path + 'lib/jquery.textchange.min.js' )

// Utilities
.script( path + 'utilities.js' ).wait()

// Classes
.script( path + 'color.js' )
.script( path + 'point3d.js' )
.script( path + 'string.js' )
.script( path + 'vector3d.js' )

// Modules
.script( path + 'bridge.js' )
.script( path + 'common.js' )
.script( path + 'console.js' )
.script( path + 'sketchup.js' )
.script( path + 'system.js' )
.script( path + 'ui.js' )
.script( path + 'webdialog.js' ).wait() // All these can be loaded async.

// UI Controls
.script( path + 'ui.base.js' ).wait() // Control extends this.
.script( path + 'ui.control.js' ).wait() // All controls extends this.
.script( path + 'ui.button.js' )
.script( path + 'ui.checkbox.js' ).wait() // RadioButton extends this.
.script( path + 'ui.container.js' )
.script( path + 'ui.groupbox.js' )
.script( path + 'ui.image.js' )
.script( path + 'ui.label.js' )
.script( path + 'ui.listbox.js' )
.script( path + 'ui.radiobutton.js' )
.script( path + 'ui.textbox.js' )
.script( path + 'ui.window.js' ).wait(function() {
  $(document).ready(function() {
    UI.init();
  })
});
