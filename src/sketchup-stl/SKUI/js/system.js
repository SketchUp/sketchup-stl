/*******************************************************************************
 *
 * module System
 *
 ******************************************************************************/


var System = function() {

  return {

    font_names : function() {
      var rgFonts = new Array();
      if ( Sketchup.platform() == 'PC' ) {
        var $body = $('body');
        var $object = $('<object>');
        $object.attr('CLASSID', 'clsid:3050f819-98b5-11cf-bb82-00aa00bdce0b');
        $object.attr('width',  '0px');
        $object.attr('height', '0px');
        $body.append( $object );
        var dlgHelper = $object.get(0);
        // Extract list of font names.
        var nFontLen = dlgHelper.fonts.count;
        for ( var i = 1; i < nFontLen + 1; i++ ) {
          rgFonts.push( dlgHelper.fonts(i) );
        }
        rgFonts.sort();
        // Clean up
        $object.remove();
      }
      return rgFonts;
    }


  };

}(); // System