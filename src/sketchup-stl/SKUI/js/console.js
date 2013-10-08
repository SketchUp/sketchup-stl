/*******************************************************************************
 *
 * module Console
 *
 ******************************************************************************/

var Console = function() {
  return {


    /* Relay strings back to the SketchUp Ruby Console.
     */
    log : function( string ) {
      Sketchup.callback( 'SKUI::Console.log', string );
    }


  };

}(); // Console