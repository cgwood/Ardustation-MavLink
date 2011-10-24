// Created 2011 By Colin G http://www.diydrones.com/profile/ColinG

#define COMMANDFIELDWIDTH 18
#define CMDVALCOUNT       6

PROGMEM const prog_char confirmReset_Index[] =
	//01234567890123456789
	 "  This will reset\n"
	 "    the mission\n"
	 "    Press OK to\n"
	 "      Confirm";

PROGMEM const prog_char confirmRequest_Params[] =
      //01234567890123456789
       " This will request\n"
       "  the parameters\n"
       "   Press OK to\n"
       "     Confirm";

PROGMEM const prog_char confirmStop_Stream[] =
      //01234567890123456789
       "   This will stop\n"
       "   the data stream\n"
       "    Press OK to\n"
       "      Confirm";

PROGMEM const prog_char confirmStart_Stream[] =
      //01234567890123456789
       " This will restart\n"
       "  the data stream\n"
       "   Press OK to\n"
       "     Confirm";

PROGMEM const prog_char confirmSet_GCSHome[] =
      //01234567890123456789
       "This will initialise\n"
       "  the GCS's Home\n"
       "position. Ensure the\n"
       "UAV is next to GCS";
       
PROGMEM const prog_char confirmReset_Home[] =
      //01234567890123456789
       "This will initialise\n"
       "the Aircraft's Home\n"
       "position. Ensure it\n"
       "is **on the GROUND**";
       
//  struct msg_command_upload {
//	uint8_t action;
//	uint16_t itemNumber;
//	uint16_t listLength;
//	uint8_t commandID;
//	uint8_t p1;
//	int32_t p2;
//	int32_t p3;
//	int32_t p4;

//////////////////////////////////////////////////////////////////////////////
// Commands page
////////////////////////////////////////////////////////////////////////////////

PageCommands::PageCommands(const prog_char *textCommands)
{
  /// Copy the header and types to internal storage
  _textCommands = textCommands;
}


void
PageCommands::_enter(uint8_t fromPage)
{     
  lcd.clear();
  _render();
}


void
PageCommands::_update(void)
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
PageCommands::_render(void)
{
  uint8_t         c;
  uint8_t         i,j,k;
  uint8_t         row;
  const prog_char *str;
  str = _textCommands;
  
  lcd.clear();
  row = 0;
  
  i=0;
  for(j=0;j<_stateFirstVal+4;j++) { //Need to go from zero to read through the string
    if (j>=_stateFirstVal)
      lcd.setCursor(1,j-_stateFirstVal);
      
    k=0;

    for (;;) {
      c = pgm_read_byte_near(_textCommands + i++);
      if (0 == c)
        break;
      if ('\n' == c)
        break;
      else {
        if (j>=_stateFirstVal && j<CMDVALCOUNT && k++<COMMANDFIELDWIDTH)
          lcd.write(c);
      }
    }
  }
        
  // redraw the "choosing" marker
  _paintMarker();
}

/// Draw the "choosing" marker
void
PageCommands::_paintMarker(void)
{
  if (_state > 0 && _state < 100) {
    lcd.setCursor(0,_state-1 - _stateFirstVal);
    lcd.write('>');
  }
}

/// remove the "choosing" marker
void
PageCommands::_clearMarker(void)
{
  if (_state > 0 && _state < 200) {
    lcd.setCursor(0,_state-1 - _stateFirstVal);
    lcd.write(' ');
  }
}

void
PageCommands::_commandConfirm(void)
{
  switch (_state-201) {
	case 0: // Reset waypoint to zero
		_commandConfirmMessage(confirmReset_Index);
		break;
	case 1: // Request all the parameters
		_commandConfirmMessage(confirmRequest_Params);
		break;
	case 2: // Stop data stream
		_commandConfirmMessage(confirmStop_Stream);
		break;
	case 3: // Restart data stream
		_commandConfirmMessage(confirmStart_Stream);
		break;
	case 4: // Set GCS Home
		_commandConfirmMessage(confirmSet_GCSHome);
		break;
	case 5: // Set UAV Home
		_commandConfirmMessage(confirmReset_Home);
		break;
  }
}

void
PageCommands::_commandConfirmMessage(const prog_char *str)
{
  uint8_t         c;
  uint8_t         row;
  
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
PageCommands::_commandSend(void)
{
	uint8_t i;
	mavlink_message_t msg;
  
//  struct BinComm::msg_command_upload command;
	switch (_state - 201)
	{
	case 0: // Reset waypoint index
//		mavlink_msg_waypoint_request_list_pack(0xFF, 0xFA, &msg, 1, 1);
		// Restart the mission by setting the current waypoint to waypoint 1
		mavlink_msg_waypoint_set_current_pack(0xFF, 0xFA, &msg, 1, 1, 1);
		comm.send(&msg);
		break;
	case 1: // Request parameters
		mavlink_msg_param_request_list_pack(0xFF, 0xFA, &msg, 1, 1);
		comm.send(&msg);
		break;
	case 2: // Stop Stream
		mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_ALL, 0, 0);
		comm.send(&msg);
		break;
	case 3: // Start Stream
		comm.request();
		break;
	case 4: // GCS Home
		gcsLat = mavGPS.lat;
		gcsLon = mavGPS.lon;
		gcsAlt = mavGPS.alt;
		break;
	case 5: // UAV Home
//		mavlink_msg_command_pack(0xFF, 0xFA, &msg, 1, 1, MAV_CMD_DO_SET_HOME, 0, 1, 0, 0, 0);
		// uint8_t system_id, uint8_t component_id, mavlink_message_t* msg, uint8_t target_system, uint8_t target_component, uint16_t seq, uint8_t frame, uint8_t command, uint8_t current, uint8_t autocontinue, float param1, float param2, float param3, float param4, float x, float y, float z)
		if (mavWptCount.count != 0) {
			mavlink_msg_waypoint_count_pack(0xFF, 0xFA, &msg, 1, 1, mavWptCount.count);
			comm.send(&msg);
//			mavlink_msg_waypoint_pack(0xFF, 0xFA, &msg, 1, 1, 0, MAV_FRAME_GLOBAL, MAV_CMD_DO_SET_HOME, 0, 0, 1, 0, 0, 0, 0, 0, 0);
			mavlink_msg_waypoint_pack(0xFF, 0xFA, &msg, 1, 1, 0, MAV_FRAME_GLOBAL, MAV_CMD_NAV_WAYPOINT, 1, 1, 0, 0, 0, 0, mavGPS.lat, mavGPS.lon, mavGPS.alt);
			comm.send(&msg);
			delay(50);
        	mavlink_msg_waypoint_request_pack(0xFF, 0xFA, &msg, 1, 1, 0);
        	comm.send(&msg);
		}
		break;
	}

/* --- OLD BINCOMM CODE FOR REFERENCE ONLY --- */
//    case BINCOMM: // Reset waypoint to zero
//      command.action = 1;       // Execute immediately
//      command.itemNumber = 0;   // Not required
//      command.listLength = 0;   ///@bug <--- EEK!! This is bad
//      command.commandID = 0x31; // The command ID for RESET_INDEX
//      command.p1 = 0;           // Simply set these to zero, unused
//      command.p2 = 0;
//      command.p3 = 0;
//      command.p4 = 0;
//      comm.send_msg_command_upload(command.action, command.itemNumber, command.listLength, command.commandID, command.p1, command.p2, command.p3, command.p4);
      
      //comm.send_msg_command_upload(1, 0, 0, 0x31, 0, 0, 0, 0);
//
//      break;
//    case BINCOMM: // Initialise home to current location
      // Upon completing this, the plane will wiggle its servo and send a ready to fly message
      // No IMU calibration is done here, so plane orientation is not important
      // Plane altitude is, on the other hand, important as this is one of the variables set
      // Do not do this whilst flying!
//      command.action = 1;       // Execute immediately
//      command.itemNumber = 0;   // Not required
//      command.listLength = 0;   ///@bug <--- EEK!! This is bad
//      command.commandID = 0x44; // The command ID for CMD_RESET_HOME
//      command.p1 = 0;           // Simply set these to zero, unused
//      command.p2 = 0;
//      command.p3 = 0;
//      command.p4 = 0;
//      comm.send_msg_command_upload(command.action, command.itemNumber, command.listLength, command.commandID, command.p1, command.p2, command.p3, command.p4);
      
      //comm.send_msg_command_upload(1, 0, 0, 0x44, 0, 0, 0, 0);
      
//      break;
//    case 3: // Fly the square
//      // Send the messages in reverse, when the first waypoint is given we start the mission
//      for (i=0; i<6; i++)
//      {
//        //memcpy(&command, &mission1[i], sizeof(command));
//        command = mission1++;
//        Serial.print("Sending, with action=");
//        Serial.print(command.action, DEC);
//        Serial.print(", Item number = ");
//        Serial.print(command.itemNumber, DEC);
//        Serial.print(", p1=");
//        Serial.println(command.p1, DEC);
//        comm.send_msg_command_upload(command.action, command.itemNumber, command.listLength, command.commandID, command.p1, command.p2, command.p3, command.p4);
//      }
//      // Now execute the mission... This really really could do with having the previous messages ack'd before sending
//      memcpy(&command, &mission1[0], sizeof(command));
//      comm.send_msg_command_upload(1, command.itemNumber, command.listLength, command.commandID, command.p1, command.p2, command.p3, command.p4);
    
}

void
PageCommands::_handleEvent(Page::event eventCode)
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
          // Picking
          else if (_state > 1 && _state < 100) {
            if (_state == (_stateFirstVal + 1)) {
              _stateFirstVal--;
              _updated = true;
            }
            _state--;
          }
          // Confirming
          else if (_state > 200)
            return;
          break;
  case DOWN:
          // Navigation
          if (_state == 0) {
            if (_stateFirstVal < CMDVALCOUNT-4) {
              _stateFirstVal++;
              _updated = true;
            }
          }
          // Picking
          else if (_state > 0 && _state < CMDVALCOUNT) {
            if (_state == (_stateFirstVal + 4)) {
              _stateFirstVal++;
              _updated = true;
            }
            _state++;
          }
          // Confirming
          else if (_state > 200)
            return;
          break;
  case OK:
          // Enter picking mode
          if (_state == 0) {
            _state = _stateFirstVal + 1;
          }
          // Choose command
          else if(_state < 100) {
            // Update the state
            _state += 200;
            _commandConfirm();
            return;
          }
          // Confirming
          else if(_state > 200) {
            // Save the value
            _commandSend();
            _state = 0;
            _updated = true;
            return; // Leave before we draw the marker again
          }
          break;
  case LEFT:
          // Navigation
          if (_state == 0)
            _leave(LEFT);
          else // Selection, ignore
            return;
          break;
  case RIGHT:
          // Navigation
          if (_state == 0)
            _leave(RIGHT);
          else // Selection, ignore
            return;
          break;
  case CANCEL:
          if (_state == 0) {
            _leave(CANCEL);
            return;         // avoid drawing the cursor
          }
          else {
            _state = 0;
            _updated = true;
          }
          
  }
  _paintMarker();
}
