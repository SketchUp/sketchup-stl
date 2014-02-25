/*******************************************************************************
 *
 * module Bridge
 *
 ******************************************************************************/


var Bridge = function() {

  /* Due to OSX' async callback nature the messages needs to be queued up and
   * carefully sent in sequence. The next message cannot be sent until a message
   * from Ruby confirms the last message was received.
   */
  var messages = [];
  var busy = false;

  return {


    /* Prepares the communication bridge.
     */
    init : function() {
      bridge = $('<input id="SKUI_RUBY_BRIDGE" type="hidden" />');
      $('body').append( bridge );
    },


    /* Escapes backslashes and single quotes.
     * (private ?)
     */
    escape_string : function( value ) {
      return value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    },


    /* Executes a Javascript command and returns the return value to the
     * Ruby bridge.
     */
    execute : function( code_string ) {
      // Clean up <SCRIPT></SCRIPT> elements which Ruby
      // UI::WebDialog.execute_script leaves behind.
      $('body script').detach();
      // Execute the JavaScript code and put the return value back into the
      // bridge.
      Bridge.return_ruby( eval(code_string) );
    },


    /* Returns the checked state for the Checkbox control given by UI ID.
     */
    get_checkbox_state : function( ui_id ) {
      return $('#'+ui_id+' input').prop('checked');
    },


    /* Returns the checked state for the given jQuery selector.
     */
    get_checked_state : function( selector ) {
      return $(selector).prop('checked');
    },


    /* Returns the HTML for the given jQuery selector.
     */
    get_html : function( selector ) {
      return $(selector).html();
    },


    /* Returns the Rect for the Checkbox control given by UI ID.
     */
    get_control_rect : function( ui_id ) {
      $control = $('#'+ui_id);
      position = $control.position();
      width  = $control.outerWidth();
      height = $control.outerHeight();
      rect = {
        'left'   : position.left,
        'top'    : position.top,
        'right'  : position.left + width,
        'bottom' : position.top + height,
        'width'  : width,
        'height' : height
      }
      return rect;
    },


    /* Returns the text for the given jQuery selector.
     */
    get_text : function( selector ) {
      return $(selector).text();
    },


    /* Returns the value for the given jQuery selector.
     */
    get_value : function( selector ) {
      return $(selector).val();
    },


    /* Process the next message in the queue to Ruby.
     */
    push_message : function() {
      if ( busy ) {
        return false;
      } else {
        message = messages.shift();
        if ( message ) {
          busy = true;
          uri_message = encodeURIComponent( message.add_slashes() );
          window.location = 'skp:SKUI_Callback@' + uri_message;
          return true;
        } else {
          return false;
        }
      }
    },


    /* Ruby calls this when a message has been received which means the next
     * message can be sent.
     */
    pump_message : function() {
      busy = false;
      Bridge.push_message();
      return busy;
    },


    /* Send the next message in the queue to Ruby.
     */
    queue_message : function( message ) {
      messages.push( message );
      return Bridge.push_message();
    },


    /* Resets the Ruby bridge.
     */
    reset : function() {
      $('#SKUI_RUBY_BRIDGE').val( '' );
    },


    /* Returns a Javascript object to the Ruby bridge element so that SketchUp
     * Ruby script can fetch the value.
     */
    return_ruby : function( value ) {
      $('#SKUI_RUBY_BRIDGE').val( Bridge.value_to_ruby(value) );
    },


    /* Sets the ID for the <BODY> element so that the Window class' properties
     * can control the appearance of the window background.
     */
    set_window_id : function( ui_id ) {
      $('body').attr( 'id', ui_id );
    },


    /* Converts Javascript objects into Ruby objects.
     */
    value_to_ruby : function( value ) {
      var ruby_string = '';
      switch ( $.type( value ) ) {
        case 'boolean':
          ruby_string = value.toString();
          break;
        case 'number':
          if ( isNaN( value ) ) {
            ruby_string = '0.0/0.0';
          } else if ( isFinite( value ) ) {
            ruby_string = value.toString();
          } else {
            // Infinite
            ruby_string = ( value > 0 ) ? '1.0/0.0' : '-1.0/0.0';
          }
          break;
        case 'string':
          ruby_string = "'" + Bridge.escape_string( value ) + "'";
          break;
        case 'null':
        case 'undefined':
          ruby_string = 'nil';
          break;
        case 'array':
          ruby_values = $.map(value, function(array_value, index) {
            return Bridge.value_to_ruby( array_value );
          });
          ruby_string = '[' + ruby_values.join(',') + ']';
          break;
        case 'date':
          ruby_string = 'Time.at(' + value.getTime() + ')';
          break;
        case 'regexp':
          // http://www.w3schools.com/jsref/jsref_obj_regexp.asp
          var i = value.ignoreCase ? 'i' : '';
          var g = value.global     ? 'g' : ''; // Not supported in Ruby.
          var m = value.multiline  ? 'm' : '';
          var regex = '/'+value.source+'/'+i+m;
          ruby_string = Bridge.value_to_ruby( regex );
          break;
        case 'function':
          ruby_string = "'<FUNCTION>'";
          break;
        case 'object':
          // Assume JSON.
          var ruby_key = '';
          var ruby_value = '';
          var ruby_hash = new Array();
          $.each(value, function(k, v) {
            ruby_key   = Bridge.value_to_ruby( k );
            ruby_value = Bridge.value_to_ruby( v );
            ruby_hash.push( ruby_key + " => " + ruby_value );
          });
          ruby_string = '{' + ruby_hash.join(',') + '}';
          break;
      }
      return ruby_string;
    }


  };

}(); // Bridge