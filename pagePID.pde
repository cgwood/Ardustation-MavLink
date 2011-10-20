// Created 2011 By Colin G http://www.diydrones.com/profile/ColinG

////////////////////////////////////////////////////////////////////////////////
// PID Setup page
////////////////////////////////////////////////////////////////////////////////

#define PIDFIELDWIDTH 4
#define PIDDECPOS     2

/// @todo Could make this a generic parameter editing page?
PagePIDSetup::PagePIDSetup(const prog_char *textHeader, const uint8_t *pidTypes, const uint8_t *pid_p, const uint8_t *pid_i, const uint8_t *pid_d)
{
	/// Copy the header and types to internal storage
	_textHeader = textHeader;
	_pidTypes = pidTypes;
	_pid_p = pid_p;
	_pid_i = pid_i;
	_pid_d = pid_d;

	/// XXX Initially, all values are available (will require attention)
	_avail[0] = 1;
	_avail[1] = 1;
	_avail[2] = 1;
}


void
PagePIDSetup::_enter(uint8_t fromPage)
{
//        if (fromPage == P_PIDCONFIRM || fromPage == P_NAVPIDCONFIRM)
//          _uploadLocal();

        uint8_t i;

        for (i=0;i<3;i++) {
          //if (!_avail[i])
          //  comm.send_msg_pid_request(_pidTypes[i]);
        }

        _state = 0;
        lcd.clear();
        _render();
}

void
PagePIDSetup::notify(void *arg, mavlink_message_t *buf)
{
//  // Put the message to the protected message function
//  ((PagePIDSetup *)arg)->_message(messageID, messageVersion, buf);
	((PagePIDSetup *)arg)->_message();

}

void
PagePIDSetup::_message(void)
{

	// Exit edit mode
	_state = 0;

	// Notify the update function
	_updated = true;

}

void
PagePIDSetup::_update(void)
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
PagePIDSetup::_render(void)
{
	uint8_t         c;
	uint8_t         i;
	uint8_t         j;
	uint8_t         lineno;
	char            decBuf[PIDFIELDWIDTH];
	uint32_t        value;
	float			value_local;

	lcd.setCursor(0, 0);
	for (i=0;i<19;i++) {
		// Write the header, e.g. roll pitch yaw
		c = pgm_read_byte_near(_textHeader + i);
		if (0 == c)
			break;
		else
			lcd.write(c);
	}
	for (lineno=1;lineno<4;lineno++) {
		lcd.setCursor(0, lineno);
		// Write the left hand labels for PID
		if (lineno==1)
			lcd.print("P:");
		if (lineno==2)
			lcd.print("I:");
		if (lineno==3)
			lcd.print("D:");

		// Write the values
		for (i=0;i<3;i++) {
			value_local = 0;
			if (_avail[i] == 1) {
				// Load the PID into value, either editing or live val
				if (lineno==1) {
//					if (i == (_state-101)%3)
					if (_state == 100 + (lineno-1)*3 + i + 1)
						value_local = _value_temp; //_pidtemp.p;
					else {
						j = _pid_p[i];
						nvram.load_param(&j,&value_local);
					}
				}
				if (lineno==2)   {
//					if (i == (_state-101)%3)
					if (_state == 100 + (lineno-1)*3 + i + 1)
						value_local = _value_temp; //_pidtemp.i;
					else {
						j = _pid_i[i];
						nvram.load_param(&j,&value_local);
					}
				}
				if (lineno==3) {
//					if (i == (_state-101)%3)
					if (_state == 100 + (lineno-1)*3 + i + 1)
						value_local = _value_temp; //_pidtemp.d;
					else {
						j = _pid_d[i];
						nvram.load_param(&j,&value_local);
					}
				}

				// Scale the PID value and fix for the number of decimal places
//				value = (uint32_t)(value_local*100);
//				value *= pow(10,PIDDECPOS-2);
				value_local *= pow(10,PIDDECPOS);
				value = (uint32_t)(floor(value_local+0.5));
				decBuf[0] = '0' + (value % 10);
				value /= 10;
				for (j=1;j<PIDFIELDWIDTH;j++) {
					if (j == PIDDECPOS) {
						decBuf[j] = '.';
					}
					else if ((0 == value) && (j > (PIDDECPOS + 1))) {
						decBuf[j] = ' ';
					}
					else {
						decBuf[j] = '0' + (value % 10);
						value /= 10;
					}
				}
//				value_local *= pow(10,PIDDECPOS);
//				decBuf[0] = '0' + ((int)floor(value_local+0.1) % 10);
//				value_local /= 10;
//				for (j=1;j<PIDFIELDWIDTH;j++) {
//					if (j == PIDDECPOS) {
//						decBuf[j] = '.';
//					}
//					else if ((0 == value_local) && (j > (PIDDECPOS + 1))) {
//						decBuf[j] = ' ';
//					}
//					else {
//						decBuf[j] = '0' + ((int)floor(value_local+0.1) % 10);
//						value_local /= 10;
//					}
//				}
			}
			else {
				// Data unavailable, display dashes
				for (j=0;j<PIDFIELDWIDTH;j++)
					decBuf[j] = '-';
			}
			// Display the data
			lcd.write(' ');
			while (j-- > 0)
				lcd.write(decBuf[j]);
			lcd.write(' ');
		}
	}

	// redraw the "choosing" marker
	_paintMarker();
}

/// Draw the "choosing" marker
void
PagePIDSetup::_paintMarker(void)
{
        if (_state > 0 && _state < 100) {
          lcd.setCursor(((_state-1)%3+1)*6-4,(_state-1)/3+1);
          lcd.write('>');
        }
        else if (_state > 100)
        {
          lcd.setCursor(((_state-101)%3+1)*6-4,(_state-101)/3+1);
          lcd.write(LCD_CHAR_MODIFY);
        }
}

/// remove the "choosing" marker
void
PagePIDSetup::_clearMarker(void)
{
        if (_state > 0 && _state < 200) {
          if (_state > 100)
            lcd.setCursor(((_state-101)%3+1)*6-4,(_state-101)/3+1);
          else
            lcd.setCursor(((_state-1)%3+1)*6-4,(_state-1)/3+1);
          lcd.write(' ');
        }
}

void
PagePIDSetup::_alterLocal(float alterMag)
{
//  uint8_t i,j;
//  i = (_state-101)%3; // Column, i.e. Roll/pitch/yaw
//  j = (_state-101)/3; // Row, i.e. PID

	_value_temp = constrain(_value_temp + alterMag, 0, 3);
//  //@bug sometimes this makes the value wrap around
//  //@{
//  switch ((_state-101)/3) {
//    case 0:
//      _pidtemp.p = constrain(_pidtemp.p + alterMag, 0, 3000000);
//      break;
//    case 1:
//      _pidtemp.i = constrain(_pidtemp.i + alterMag, 0, 3000000);
//      break;
//    case 2:
//      _pidtemp.d = constrain(_pidtemp.d + alterMag, 0, 3000000);
//      break;
//  }
//  //@}

  // kick the update function
  _updated = true;
}

void
PagePIDSetup::_voidLocal(void)
{
  // Reset _state
  _state = 0;

  // kick the update function
  _updated = true;
}

void
PagePIDSetup::_uploadConfirm(void)
{
  uint8_t         c;
  uint8_t         row;
  const prog_char *str;
  str = confirmMessage;

//  lcd.setCursor(0, 0);
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
PagePIDSetup::_uploadLocal(void)
{
//  uint8_t i;
  uint8_t j;
//  i = (_state-101)%3; // Column, i.e. Roll/pitch/yaw

  switch((_state-201)/3) {
  case 0:
	  j = _pid_p[(_state-201)%3];
	  break;
  case 1:
	  j = _pid_i[(_state-201)%3];
	  break;
  case 2:
	  j = _pid_d[(_state-201)%3];
	  break;
  default:
	  return;
  }

  params.set_param(j, _value_temp);
//  params.set_param(_pid_p[i], _value_temp);


  // Send the value that we edited
  //comm.send_msg_pid_set(_pidTypes[(_state-201)%3], _pidtemp.p, _pidtemp.i, _pidtemp.d, _pidtemp.integratorMax);


  // Reset _state
  _state = 0;

  // kick the update function
  _updated = true;
}

void
PagePIDSetup::_handleEvent(Page::event eventCode)
{
  /// State positions are:
  /// 1   2   3
  /// 4   5   6
  /// 7   8   9

        _clearMarker();

        switch (eventCode) {
        case UP:
                // Navigation
                if (_state > 3 && _state < 10)
                  _state -= 3;
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(0.01);
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case DOWN:
                // Navigation
                if (_state > 0 && _state < 7)
                  _state += 3;
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(-0.01);
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case OK:
                if (_state == 0) {
                  // Allow selection if the value is available
//                  if (_avail[(_state-1)%3])
                  if (_avail[0])
                    _state = 1;
                }
                else if(_state < 100) {
                  // Allow editing if the value is available
                  if (_avail[(_state-1)%3]) {
                    // Copy the PID values to temp for editing
                	  uint8_t j;
                	  switch((_state-1)/3) {
                	  case 0:
                		  j = _pid_p[(_state-1)%3];
                		  break;
                	  case 1:
                		  j = _pid_i[(_state-1)%3];
                		  break;
                	  case 2:
                		  j = _pid_d[(_state-1)%3];
                		  break;
                	  default:
                		  return;
                	  }

                	  nvram.load_param(&j,&_value_temp);

//                    _pidtemp.pidSet = _pidlive[(_state-1)%3].pidSet;
//                    _pidtemp.p = _pidlive[(_state-1)%3].p;
//                    _pidtemp.i = _pidlive[(_state-1)%3].i;
//                    _pidtemp.d = _pidlive[(_state-1)%3].d;
//                    _pidtemp.integratorMax = _pidlive[(_state-1)%3].integratorMax;
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
                else if (_state < 100 && _state % 3 != 1)
                  _state -= 1;
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(-0.1);
                // Confirming
                else if (_state > 200)
                  return;
                break;
        case RIGHT:
                // Navigation
                if (_state == 0)
                  _leave(RIGHT);
                else if (_state < 100 && _state % 3 != 0)
                  _state += 1;
                // Editing
                else if (_state > 100 && _state < 200)
                  _alterLocal(0.1);
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


