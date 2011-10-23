// Created 2011 By Colin G http://www.diydrones.com/profile/ColinG

// These defines are the values for bitmasking logging stuff
#define MASK_LOG_ATTITUDE_FAST 0
#define MASK_LOG_ATTITUDE_MED 2
#define MASK_LOG_GPS 4
#define MASK_LOG_PM 8
#define MASK_LOG_CTUN 16
#define MASK_LOG_NTUN 32
#define MASK_LOG_MODE 64
#define MASK_LOG_RAW 128
#define MASK_LOG_CMD 256
// bits in log_bitmask
#define LOGBIT_ATTITUDE_FAST	(1<<0)
#define LOGBIT_ATTITUDE_MED	(1<<1)
#define LOGBIT_GPS		(1<<2)
#define LOGBIT_PM		(1<<3)
#define LOGBIT_CTUN		(1<<4)
#define LOGBIT_NTUN		(1<<5)
#define LOGBIT_MODE		(1<<6)
#define LOGBIT_RAW		(1<<7)
#define LOGBIT_CMD		(1<<8)

////////////////////////////////////////////////////////////////////////////////
// APM Setup page
////////////////////////////////////////////////////////////////////////////////

/// @todo Could make this a generic parameter editing page?
PageAPMSetup::PageAPMSetup(const prog_char *textHeader, const uint8_t *Types, const uint8_t *scale, const uint8_t *decPos)
{
  uint8_t i;
  
  /// Copy the header and types to internal storage
  _textHeader = textHeader;
  _Types = Types;
  _scale = scale;
  _decPos = decPos;
  
  /// Initially, no values are available
  for (i=0;i<APMVALCOUNT;i++)
    _avail[i] = 1;
}


void
PageAPMSetup::_enter(uint8_t fromPage)
{     
        uint8_t i;
        
        /// XXX Currently all values will be available, better if we check they're correct first
        for (i=0;i<APMVALCOUNT;i++) {
          //if (!_avail[i])
          //  comm.send_msg_value_request(_Types[i], 0);
        	_avail[i] = 1;
        }
        _state = 0;
        _stateFirstVal = 0;
        lcd.clear();
        _render();
}

void
PageAPMSetup::notify(void *arg, mavlink_message_t *buf)
{
//  // Put the message to the protected message function
//  ((PageAPMSetup *)arg)->_message(messageID, messageVersion, buf);

	((PageAPMSetup *)arg)->_message();
}

/// XXX Change these _message functions to change avail, and nothing else
void
PageAPMSetup::_message(void)
{
	// Exit edit mode and denote the value as available
	_state = 0;

	// Notify the update function
	_updated = true;

//        // Read the data
//        void    *dst;
//        uint8_t i;
//
//        if (messageID == MAVLINK_MSG_ID_PARAM_VALUE) {
////          memcpy(&_value_temp, buf, sizeof(_value_temp));
//          for (i=0;i<APMVALCOUNT;i++) {
//            // Compare against the types this page holds
//            if (_value_temp.valueID == _Types[i]) {
//              // Copy to the live value
//              dst = &_value_live[i];
////              memcpy(dst, buf, sizeof(_value_temp));
//
//              // Exit edit mode and denote the value as available
//              _state = 0;
//              _avail[i] = 1;
//
//              // Notify the update function
//              _updated = true;
//
//              // We've found it, exit loop
//              break;
//            }
//          }
//        }
}

void
PageAPMSetup::_update(void)
{
        // don't waste time redrawing if we have no changes to announce
        if (!_updated)
                return;
                
        // don't redraw too often
        if ((millis() - _lastRedraw) < STATUS_UPDATE_INTERVAL)
                return;
          
        // redraw the page
        _render();
        _updated = false;
        _lastRedraw = millis();
}


void
PageAPMSetup::_render(void)
{
        uint8_t         c;
        uint8_t         i;
        uint8_t         j;
        uint8_t         k;
        uint8_t         lineno;
        char            decBuf[20-APMNAMEFIELDWIDTH];
        uint32_t        value;
    	float			value_local;
        
        lcd.clear();
        // Write the value names down the left hand side
        i=0;
        for(j=0;j<_stateFirstVal+4;j++) { //Need to go from zero to read through the string
          if (j>=_stateFirstVal)
            lcd.setCursor(0,j-_stateFirstVal);
            
          k=0;
  
          for (;;) {
            c = pgm_read_byte_near(_textHeader + i++);
            if (0 == c)
              break;
            if ('\n' == c)
              break;
            else {
              if (j>=_stateFirstVal && k++<APMNAMEFIELDWIDTH)
                lcd.write(c);
            }
          }
        }
        
        // Write the values
        for (lineno=0;lineno<4;lineno++) {
          lcd.setCursor(APMNAMEFIELDWIDTH+2, lineno);
            
          i=_stateFirstVal+lineno;
          if (i >= APMVALCOUNT)
            break;
            
          if (_avail[i] == 1) {
            // Load the value, either editing or live val
            if (i == (_state-101))
              value = _value_temp;
             else {
                 j = _Types[i];
                 nvram.load_param(&j,&value_local);
                 value = (uint32_t)floor(value_local+0.5);
             }
              //value = _value_live[i].value;
              
            // Is it an On / Off value?
            if (99 == _decPos[i] && 99 == _scale[i]) {
              if (value > 0) {
                decBuf[0] = 'N'; decBuf[1] = 'O'; j = 2;
              }
              else {
                decBuf[0] = 'F'; decBuf[1] = 'F'; decBuf[2] = 'O'; j = 3;
              }
            }
            else {
              // Scale the value and fix for the number of decimal places
              value *= pow(10,_decPos[i] - _scale[i]);
              decBuf[0] = '0' + (value % 10);
              value /= 10;
              for (j=1;j<(16-APMNAMEFIELDWIDTH);j++) {
                if (j == _decPos[i]) {
                  decBuf[j] = '.';
                } else if ((0 == value) && (j > (_decPos[i] + 1))) {
                  decBuf[j] = ' ';
                } else {
                  decBuf[j] = '0' + (value % 10);
                  value /= 10;
                }
              }
            }
          }
          else {
            // Data unavailable, display dashes
            for (j=0;j<16-APMNAMEFIELDWIDTH;j++)
              decBuf[j] = '-';
          }
          // Display the data
          lcd.write(' ');
          while (j-- > 0)
            lcd.write(decBuf[j]);
          lcd.write(' ');
        }
        
        // redraw the "choosing" marker
        _paintMarker();
}

/// Draw the "choosing" marker
void
PageAPMSetup::_paintMarker(void)
{
        if (_state > 0 && _state < 100) {
          lcd.setCursor(APMNAMEFIELDWIDTH,_state-1 - _stateFirstVal);
          lcd.write('>');
        }
        else if (_state > 100)
        {
          lcd.setCursor(APMNAMEFIELDWIDTH,_state-101 - _stateFirstVal);
          lcd.write(LCD_CHAR_MODIFY);
        }
}

/// remove the "choosing" marker
void
PageAPMSetup::_clearMarker(void)
{
        if (_state > 0 && _state < 200) {
          if (_state > 100)
            lcd.setCursor(APMNAMEFIELDWIDTH,_state-101 - _stateFirstVal);
          else
            lcd.setCursor(APMNAMEFIELDWIDTH,_state-1 - _stateFirstVal);
          lcd.write(' ');
        }
}

void
PageAPMSetup::_alterLocal(float alterMag)
{
  // Is it an on off?
//  if (99 == _scale[_state-101] && 99 == _decPos[_state-101]) {
//    Serial.println(alterMag, DEC);
//    if (alterMag > 0) {
//      switch (_value_temp) {
//        case 0x50: _value_temp = LOGBIT_ATTITUDE_FAST; break;
//        case 0x51: _value_temp = LOGBIT_ATTITUDE_MED;  break;
//        case 0x52: _value_temp = LOGBIT_GPS;           break;
//        case 0x53: _value_temp = LOGBIT_PM;            break;
//        case 0x54: _value_temp = LOGBIT_CTUN;          break;
//        case 0x55: _value_temp = LOGBIT_NTUN;          break;
//        case 0x56: _value_temp = LOGBIT_MODE;          break;
//        case 0x57: _value_temp = LOGBIT_RAW;           break;
//        case 0x58: _value_temp = LOGBIT_CMD;           break;
//      }
//    }
//    else
//      _value_temp = 0;
//  }
//  else {
    // We don't do negative values here
    if (_value_temp + alterMag < 0)
      _value_temp = 0;
    else
      _value_temp += alterMag;
//  }
    
  // kick the update function
  _updated = true;
}

void
PageAPMSetup::_voidLocal(void)
{
  // Reset _state
  _state = 0;
  
  // kick the update function
  _updated = true;
}

void
PageAPMSetup::_uploadConfirm(void)
{
  uint8_t         c;
  uint8_t         row;
  const prog_char *str;
  str = confirmMessage;
  
  lcd.clear();
  row = 0;
  
  for (;;) {
    c = pgm_read_byte_near(str++);
    if (0 == c)
      break;
    if ('\n' == c) {
      lcd.setCursor(0, ++row);
      continue;
    }
    // emit
    lcd.write(c);
  }
}

void
PageAPMSetup::_uploadLocal(void)
{
	uint8_t j;

	// Send the value that we edited
	j = _Types[_state-201];
	params.set_param(j, _value_temp);
    
	// Reset _state
	_state = 0;

	// kick the update function
	_updated = true;
}

void
PageAPMSetup::_handleEvent(Page::event eventCode)
{
        _clearMarker();
        
        switch (eventCode) {
        case UP:
                // Navigation
                if (_state == 0) {
                  if (_stateFirstVal > 0) {
                    _stateFirstVal --;
                    _updated = true;
                  }
                }
                else if (_state > 1 && _state < 100) {
                  if (_state == (_stateFirstVal + 1)) {
                    _stateFirstVal--;
                    //_render();
                    _updated = true;
                  }
                  _state--;
                }
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(1 * pow(10,_scale[_state-101]-_decPos[_state-101]));
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case DOWN:
                // Navigation
                if (_state == 0) {
                  if (_stateFirstVal < APMVALCOUNT-4) {
                    _stateFirstVal ++;
                    _updated = true;
                  }
                }
                else if (_state > 0 && _state < APMVALCOUNT) {
                  if (_state == (_stateFirstVal + 4)) {
                    _stateFirstVal++;
                    //_render();
                    _updated = true;
                  }
                  _state++;
                }
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(-1 * pow(10,_scale[_state-101]-_decPos[_state-101]));
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case OK:
                if (_state == 0) {
                  // Allow selection if the value is available
                  if (_avail[_stateFirstVal])
                    _state = _stateFirstVal + 1;
                }
                else if(_state < 100) {
                  // Allow editing if the value is available
                  if (_avail[(_state-1)]) {
                	  uint8_t j;
                      j = _Types[_state-1];
                      nvram.load_param(&j,&_value_temp);
                    // Copy the value to temp for editing
//                    memcpy(&_value_temp, _value_live[_state-1], sizeof(_value_temp));
                    //_value_temp.valueID = _value_live[_state-1].valueID;
                    //_value_temp.value = _value_live[_state-1].value;
                    // Update the state
                    _state += 100;
                  }
                }
                else if(_state > 100 && _state < 200) {
                  // Save the value
                  //_leave(OK);
                  _state += 100;
                  _uploadConfirm();
                  return; // Leave before we draw the marker again
                }
                else if(_state > 200) {
                  // Save the value
                  //_leave(OK);
                  _uploadLocal();
                  return; // Leave before we draw the marker again
                }
                break;
        case LEFT:
                // Navigation
                if (_state == 0)
                  _leave(LEFT);
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(-10 * pow(10,_scale[_state-101]-_decPos[_state-101]));
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case RIGHT:
                // Navigation
                if (_state == 0)
                  _leave(RIGHT);
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(10 * pow(10,_scale[_state-101]-_decPos[_state-101]));
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case CANCEL:
                if (_state == 0) {
                  _leave(CANCEL);
                  return;         // avoid drawing the cursor
                }
                else {
                  if (_state > 100)
                    // Don't save the changes to local variable
                    _voidLocal();
                  else
                    _state = 0;
                }
                
        }
        _paintMarker();
}

