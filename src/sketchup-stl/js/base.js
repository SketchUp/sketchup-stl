/* UI namespace */
var UI = function() {
  
  var KEYCODE_ENTER = 13;
  var KEYCODE_ESC   = 27;
  
  return {
  
    init : function() {
      UI.activate_key_shortcuts();
      UI.sync_checkbox_values();
      // Disable native browser functions to make the dialog appear more native.
      UI.disable_select();
      UI.disable_context_menu();
      // Ready Event
      window.location = 'skp:Window_Ready';
    },
    
    // Ensure links are opened in the default browser.
    activate_key_shortcuts : function() {
      $(document).on('keyup', function(event) {
        switch ( event.keyCode ) {
        case KEYCODE_ENTER:
          $('button.default').first().trigger('click');
          break;
        case KEYCODE_ESC:
          $('button.cancel').first().trigger('click');
          break;
        }
      });
    },
    
    // Ensure links are opened in the default browser.
    disable_select : function() {
      $(document).on('mousedown selectstart', function(event) {
        return $(event.target).is('input, textarea, select, option');
      });
      // Add extra CSS rules for OSX. Without text will highlight when the user
      // right click on text.
      $(':not(input, textarea, select, option)').css('user-select', 'none');
    },
    
    // Ensure links are opened in the default browser.
    disable_context_menu : function() {
      $(document).on('contextmenu', function(event) {
        return $(event.target).is('input[type=text], textarea');
      });
    },
    
    /* Update the value attribute of checkbox elements as it's state changes.
     * This way the value can be pulled from WebDialog.get_element_value from
     * Ruby side.
     */
    sync_checkbox_values : function() {
      // Set initial value
      $('input[type=checkbox]').each(function(index) {
        $checkbox = $(this);
        $checkbox.val( $checkbox.prop('checked') );
      });
      // Keep value in sync
      $('input[type=checkbox]').on('change', function(event) {
        $checkbox = $(this);
        $checkbox.val( $checkbox.prop('checked') );
      });
    },
    
    // Set the value of the given element.
    update_value : function(element_id, value) {
      $element = $('#' + element_id);
      $element.val( value );
      if ( $element.attr('type') == 'checkbox' ) {
        $element.prop( 'checked', value );
      }
    }
    
  };
  
}(); // UI

$(document).ready( UI.init );