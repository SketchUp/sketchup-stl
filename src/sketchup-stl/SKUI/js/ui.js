/*******************************************************************************
 *
 * module UI
 *
 ******************************************************************************/


var UI = function() {
  return {

    KEYCODE_ENTER : 13,
    KEYCODE_ESC   : 27,

    MIN_IE_VERSION : 8.0,


    init : function() {
      UI.check_environment();
      Bridge.init();
      UI.add_system_hooks();
      UI.redirect_links();
      // Initialize controls. Some need some global events to function properly.
      // (?) Automate these call?
      Window.init();
      Button.init();
      RadioButton.init();
      // Disable native browser functions to make the dialog appear more native.
      UI.disable_select();
      UI.disable_context_menu();
      // Ready Event
      Sketchup.callback('SKUI::Window.on_ready')
    },

    /* Checks for old versions of the browser engine and warns users of older
     * versions that their browser is not supported.
     * This isn't using feature testing because the requirements is based on
     * CSS support, not HTML or JS support.
     */
    check_environment : function() {
      // Safari don't include a version number. So we cannot test that. But most
      // likely it'll be more up to date and compatible than IE.
      //
      // IE11 changed the user-agent string. The MSDN docs says 'msie' has been
      // dropped, but in the SketchUp webdialog it still appear:
      // https://github.com/thomthom/SKUI/issues/92#issuecomment-37624654
      // However, the version number is missing, so we try to pick that from
      // the document mode instead.
      // I haven't found any info to how the embedded IE engines behaves - all I
      // know is that it has different rules for compatibility.
      var version = 0.0;
      var is_IE = false;
      if ( document.documentMode ) {
        // Internet Explorer 8+.
        version = document.documentMode;
        is_IE = true;
        // Check that documentMode matches with the Trident token  just in case
        // there is a way for the user to force some compatibility mode.
        // In which case a different message should be displayed.
        // IE8  => Trident/4.0
        // IE9  => Trident/5.0
        // IE10 => Trident/6.0
        // IE11 => Trident/7.0
        var trident_pattern = /\sTrident\/(\d+\.\d+)/;
        var trident = trident_pattern.exec( navigator.userAgent );
        var real_version =  parseFloat(trident[1]) + 4; // Bold assumption?
        if ( version < UI.MIN_IE_VERSION && version != real_version ) {
          var $warning = $('<div class="warning"/>');
          $warning.text( 'Internet Explorer (' + real_version + ') has been ' +
            'forced into compatibility mode (' + version + ') which prevents ' +
            'SKUI from functioning properly.' );
          $warning.appendTo( $('body') );
          return;
        }
      } else {
        // Internet Explorer before version 8.
        var ie_pattern = /msie\s+(\d+\.\d+)/i;
        var ie_result = ie_pattern.exec( navigator.userAgent );
        if (ie_result) {
          version = parseFloat(ie_result[1]);
          is_IE = true;
        }
      }
      if ( is_IE && version < UI.MIN_IE_VERSION ) {
        var $warning = $('<div class="warning"/>');
        // In IE11 navigator.appName now returns "Netscape". Oh joy!
        $warning.text( 'Detected Internet Explorer ' + version + '. At least ' +
          'version ' + UI.MIN_IE_VERSION + ' is required for SKUI to ' +
          'function properly.' );
        $warning.appendTo( $('body') );
      }
    },

    /* Ensure links are opened in the default browser. This ensures that the
     * WebDialog doesn't replace the content with the target URL.
     */
    redirect_links : function() {
      $(document).on('click', 'a[href]', function()
      {
        Sketchup.callback('SKUI::Window.on_open_url', this.href)
        return false;
      } );
    },


    /* Disables text selection on elements other than input type elements where
     * it makes sense to allow selections. This mimics native windows.
     */
    disable_select : function() {
      $(document).on('mousedown selectstart', function(e) {
        return $(e.target).is('input, textarea, select, option');
      });
    },


    /* Disables the context menu with the exception for textboxes in order to
     * mimic native windows.
     */
    disable_context_menu : function() {
      $(document).on('contextmenu', function(e) {
        return $(e.target).is('input[type=text], textarea');
      });
    },


    /* Adds a platform specific class to the BODY element that can be used as a
     * hook for CSS to make platform adjustments.
     */
    add_system_hooks : function() {
      if ( Sketchup.platform() == 'PC' ) {
        $('body').addClass('platform-windows');
      } else {
        $('body').addClass('platform-osx');
      }
    },


    /* Adds a control to the window. Called from the Ruby side with a JSON
     * object describing the control.
     */
    add_control : function(properties) {
      if ( properties.type in UI ) {
        control_class = UI[properties.type];
        control_class.add( properties )
        return true;
      } else {
        alert( 'Invalid Control Type: ' + properties.type );
        return false;
      }
    },


    /* Attaches an event to the control. Used by the control classes to set up
     * the events that is relayed back to the Ruby side.
     *
     * The optional `$child` argument is used when the event is coming from a
     * child DOM element.
     */
    add_event : function( eventname, $control, $child ) {
      control = $child || $control
      control.on( eventname, function( event ) {
        var args = new Array();
        var $c = $(this);
        // Prevent events if control is disabled
        // (?) Find parent of any sub-control?
        if ( $c.hasClass('disabled') ) {
          event.stopPropagation();
          event.preventDefault();
          return false;
        }
        /*
        // http://api.jquery.com/category/events/event-object/
        switch ( eventname )
        {
        case 'click':
          args[0] = event.pageX;
          args[1] = event.pageY;
          break;
        }
        */
        var ui_id = $control.attr( 'id' );
        // Defer some events to allow content to update.
        // (i) When IE8 is not supported longer these events might be deprecated
        //     in favour of HTML5's `input` event.
        var defer_events = [ 'copy', 'cut', 'paste' ];
        if ( $.inArray( eventname, defer_events ) ) {
          setTimeout( function() {
            Sketchup.control_callback( ui_id, eventname, args );
          }, 0 );
        } else {
          Sketchup.control_callback( ui_id, eventname, args );
        }
        return true;
      } );
    },


    /* Returns a Control instance from a jQuery or DOM object.
     */
    get_control : function( jQuery_or_id ) {
      var $control = $( jQuery_or_id );
      var control_class_string = $control.data( 'control_class' );
      var control_class = eval( control_class_string );
      var control = new control_class( $control );
      return control;
    },


    /* Removes a control from the window. Called from the Ruby side.
     */
    remove_control : function( control ) {
      var $control = get_jQuery_object(control);
      $control.remove();
      return true;
    },


    /* Updates the given control with the given JSON properties object. The
     * control argument can be either a jQuery object or a string representing
     * the ID of the DOM element.
     */
    update_properties : function( control_or_ui_id, properties ) {
      var $control = get_jQuery_object( control_or_ui_id );
      if ( properties.type in UI ) {
        var control_class = UI[properties.type];
        var control = new control_class( $control );
        control.update( properties );
        return true;
      } else {
        alert( 'Invalid Control Type: ' + properties.type );
        return false;
      }
    }


  };


  /* PRIVATE */


  /* Returns a jQuery object given a jQuery object or DOM id string.
   */
  function get_jQuery_object( id_or_object ) {
    if ( $.type( id_or_object ) == 'string' ) {
      return $( '#' + id_or_object );
    }
    else {
      return id_or_object;
    }
  }

}(); // UI
