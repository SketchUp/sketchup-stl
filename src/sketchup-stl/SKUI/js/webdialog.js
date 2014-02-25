/*******************************************************************************
 *
 * module WebDialog
 *
 ******************************************************************************/


var WebDialog = function() {
  return {


    /* Returns an array of the viewports' size.
     */
    get_client_size : function() {
      return [ $(window).width(), $(window).height() ];
    },


    /* Returns the IE document mode.
     */
    documentMode : function() {
      return document.documentMode;
    },


    /* Returns the quirks mode for the document.
     */
    compatMode : function() {
      // CSS1Compat = Standard
      return document.compatMode;
    },


    userAgent : function() {
      return navigator.userAgent;
    },


    add_scripts : function(scripts) {
      var $head = $('head');
      for (var i = 0; i < scripts.length; ++i)
      {
        var script = scripts[i];
        // Must use a closure to ensure `script` is returned properly.
        (function(script) {
          jQuery.getScript(script, function() {
            Sketchup.callback('SKUI::Window.on_script_loaded', script);
          });
        })(scripts[i]);
      }
      return null;
    }


  };

}(); // WebDialog
