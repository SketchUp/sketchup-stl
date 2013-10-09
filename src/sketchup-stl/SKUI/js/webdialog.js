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
    }


  };

}(); // WebDialog