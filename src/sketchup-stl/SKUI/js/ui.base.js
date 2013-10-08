/*******************************************************************************
 *
 * class UI.Base
 *
 ******************************************************************************/


function Base( jquery_element ) {
  this.control = jquery_element;
  this.typename = this.constructor.get_typename();
  this.parent = null;
}

Base.prototype.attach = function() {
  this.control.appendTo( this.parent );
  this.control.data( 'control_class', this.typename );
  return;
};

Base.prototype.callback = function( event_name, arguments ) {
  var ui_id = this.control.attr( 'id' );
  Sketchup.control_callback( ui_id, event_name, arguments );
  return;
};

Base.prototype.update = function( properties ) {
  for ( property in properties ) {
    setter = 'set_' + property;
    value = properties[property];
    value = ( value === null ) ? '' : value;
    if ( setter in this ) {
      //Console.log( setter );
      this[setter]( value );
    }
  }
  return;
};

Base.prototype.set_ui_id = function( value ) {
  this.control.attr( 'id', value );
  return value;
};

Base.prototype.set_parent = function( value ) {
  if ( value == 'Window' ) {
    var $parent = $( 'body' );
  } else {
    var $parent = $( '#' + value );
  }
  this.parent = $parent;
  return value;
};

Base.prototype.set_background_color = function( value ) {
  if ( value instanceof Color ) {
    // IE8 Fallback due to lack of RGBa support.
    this.control.css( 'background-color', value.opaque().to_css() );
  }
  this.control.css( 'background-color', value.to_css() );
  return value;
};

Base.prototype.set_foreground_color = function( value ) {
  if ( value instanceof Color ) {
    // IE8 Fallback due to lack of RGBa support.
    this.control.css( 'color', value.opaque().to_css() );
  }
  this.control.css( 'color', value.to_css() );
  return value;
};

Base.prototype.set_font = function( value ) {
  if ( $.type( value ) == 'string' ) {
    this.control.css( 'font', value ); // enum SystemFont
  } else {
    this.control.css( value ); // class Font
  }
  return value;
};
