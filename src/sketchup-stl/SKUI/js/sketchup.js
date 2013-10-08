/*******************************************************************************
 *
 * module Sketchup
 *
 ******************************************************************************/


var Sketchup = function() {

  // http://jsfiddle.net/thomthom/cN4Rb/3/
  // (?) Extract 'Mac' from OSX' 'Mac; Safari' platform string?
  var environment_regex = /SketchUp\/(\d+\.\d+)\s\(([^)]+)\)/;
  var environment = environment_regex.exec( navigator.userAgent );

  return {

    /* Relay events back to the webdialog.
     */
    callback : function( event_name /*, *args*/ ) {
      var args = Array.prototype.slice.call( arguments );
      var message = args.join( '||' );
      Bridge.queue_message( message );
    },

    /* Relay control events back to the webdialog.
     */
    control_callback : function( ui_id, event_name, event_args ) {
      var args = [
        'SKUI::Control.on_event',
        ui_id,
        event_name
      ].concat( event_args );
      Sketchup.callback.apply( this, args );
      //Sketchup.callback( 'SKUI::Control.on_event', ui_id, event, args );
    },

    /* Returns the hosting SketchUp version from the user agent string.
     * (i) Supported SketchUp versions:
     *     Windows: SketchUp 8 (?)
     *         OSX: SketchUp 2013
     */
    version : function() {
      if ( environment == null ) {
        return null;
      } else {
        return environment[1];
      }
    },

    /* Returns the host platform from the user agent string.
     * (i) Supported SketchUp versions:
     *     Windows: SketchUp 8 (?)
     *         OSX: SketchUp 2013
     */
    platform : function() {
      if ( environment == null ) {
        return 'OSX'; // (!) Might incorrect to assume this.
      } else {
        return environment[2]; // 'WIN'
      }
    },

    /* Return true if SketchUp is the host for the WebDialog.
     * (i) Supported SketchUp versions:
     *     Windows: SketchUp 8 (?)
     *         OSX: SketchUp 2013
     */
    is_host : function() {
      return environment != null;
    }


  };


  /* Helper function to simulate the Ruby *splat argument syntax. */
  function get_splat_args( func, args ) {
    return Array.prototype.slice.call( args, func.length );
  }

}(); // Sketchup