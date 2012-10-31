/* Importer namespace */
var Importer = function() {
  return {
  
    init : function() {
      Importer.setup_events();
    },
    
    // Ensure links are opened in the default browser.
    setup_events : function() {
      // Import
      $('#btnAccept').on('click', function(event) {
        window.location = 'skp:Event_Accept';
      });
      // Cancel
      $('#btnCancel').on('click', function(event) {
        window.location = 'skp:Event_Cancel';
      });
    }
    
  };
  
}(); // Importer

$(document).ready( Importer.init );