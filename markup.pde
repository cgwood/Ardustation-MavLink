// -*- Mode: C++; c-basic-offset: 8; indent-tabs-mode: nil -*-
//-
// Copyright (c) 2010 Michael Smith. All rights reserved.
// Modified 2011 By Colin G http://www.diydrones.com/profile/ColinG
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.

/// @file       markup.pde
/// @brief      parser/renderer for display markup microlanguage
///

/// Display strings are marked up with cursor control (newlines)
/// and variable substitution requests, which are bytes with the
/// high bit set.
///
/// Newlines cause the cursor to move down one row and back to
/// column 0.
///
/// Variables are identified by the low seven bits of the byte,
/// and are always printed in their "usual" format.
/// If the low bits are all zero the byte is treated as an escape
/// and the next character is emitted without processing.
///
/// Some assumptions about the programmable character set of the 
/// display are made:
///
/// \x0 reserved for link status character
/// \x1 "roll left"
/// \x2 "roll right"
/// \x3 "arrow up"
/// \x4 "arrow down"
/// \x5 "to the power of minus 1"
/// \x6 --unused-- (battery?)
/// \x7 --unused---
///
/// Useful characters from the LCD character set:
///
/// \x1e right arrow
/// \x1f left arrow
/// \xdf degrees

#define GLYPH_ROLL_LEFT         '\x1'
#define GLYPH_ROLL_RIGHT        '\x2'
#define GLYPH_PITCH_UP          '\x3'
#define GLYPH_PITCH_DOWN        '\x4'
#define GLYPH_YAW_RIGHT         '\x7e'
#define GLYPH_YAW_LEFT          '\x7f'

//PROGMEM const prog_char stringModesString[] =
//        "MANUAL\0"
//        "CIRCLE\0"
//        "STABILIZE\0"
//        "3\0"
//        "4\0"
//        "FBW A\0"
//        "FBW B\0"
//        "7\0"
//        "8\0"
//        "9\0"
//        "AUTO\0"
//        "RTL\0"
//        "LOITER\0"
//        "TAKEOFF\0"
//        "LAND\0";
//Stringtab       stringModes(stringModesString);

//PROGMEM const prog_char commandModesString[] =
//        "Unknown\0"
//        "Waypoint\0"
//        "Loiter\0"
//        "LoiterTurn\0"
//        "LoiterTime\0"
//        "Return2Ltr\0"
//        "Land\0"
//        "Take off\0"
//        "Unknown\0";
//Stringtab       commandModes(commandModesString);

void
Markup::emit(const prog_char *str)
{
        uint8_t         c;
        uint8_t         row;
        bool            escaped;

        // setup
        /// @todo support rendering other than from top left
        lcd.setCursor(0, 0);
        row = 0;
        escaped = false;

        // walk the format string
        for (;;) {
                c = pgm_read_byte_near(str++);
                // end of format string
                if (0 == c)
                        break;
                if (escaped) {
                        lcd.write(c);
                        escaped = false;
                        continue;
                }
                // newline?
                if ('\n' == c) {
                        lcd.setCursor(0, ++row);
                        continue;
                }
                // escape?
                if (0x80 == c) {
                        escaped = true;
                        continue;
                }
                // substitution?
                if (0x80 & c) {
                        _substitute(c & 0x7f);
                        continue;
                }
                // emit
                lcd.write(c);
        }
}

// printf by any other name...
void
Markup::_substitute(uint8_t key)
{
        bool            available;
        uint8_t         fieldWidth;      // number of character positions to use
        uint8_t         decPos;         // buffer position for decimal point
        char            decBuf[12];
        uint8_t         i;
        bool            negative;
        union {
                const prog_char *c;
                uint32_t        u;
                int32_t         s;
        } value;
        enum {
                STRING,         // character string in program memory
                UNSIGNED,       // unsigned value
                SIGNED          // signed value with optional leading -
        } format;

        // test for value availability
        available = _available(key);
        if (!available) {
                // default to a string of dashes - individual handlers will set width
                value.c = PSTR("----------");
                format = STRING;
        }
        fieldWidth = 0;
        decPos = 0;
        negative = false;

        switch (key) {
        case V_FLIGHTMODE:
                fieldWidth = 9;
                format = STRING;
                if (available) {
//                value.c = stringModes.lookup(_syspacket.mode);
//                  if (NULL == value.c)
//                    value.c = PSTR("??MODE??");
                  if (_syspacket.mode == MAV_MODE_MANUAL)
                    value.c = (PSTR("MANUAL"));
                  else if (_syspacket.mode == MAV_MODE_GUIDED)
                    value.c = (PSTR("GUIDED"));
                  else if (_syspacket.mode == MAV_MODE_TEST1)
                    value.c = (PSTR("STABILIZE"));
                  else if (_syspacket.mode == MAV_MODE_TEST2) {
                    if (_syspacket.nav_mode == 1)
                      value.c = (PSTR("FBW A"));
                    else if (_syspacket.nav_mode == 2)
                      value.c = (PSTR("FBW B"));
                    else
                      value.c = (PSTR("TEST 2"));
                  }
                  else if (_syspacket.mode == MAV_MODE_AUTO) {
                    if (_syspacket.nav_mode == MAV_NAV_LOITER)
                      value.c = (PSTR("LOITER"));
                    if (_syspacket.nav_mode == MAV_NAV_WAYPOINT)
                      value.c = (PSTR("AUTO"));
                    if (_syspacket.nav_mode == MAV_NAV_RETURNING)
                      value.c = (PSTR("RTL"));
                    else
                      value.c = PSTR("??AUTO??");
                  }
                  else if (_syspacket.mode == MAV_MODE_UNINIT && _syspacket.nav_mode == MAV_NAV_GROUNDED)
                    value.c = PSTR("STARTUP");
                  else
                    value.c = PSTR("??MODE??");
                }
                break;
//        case V_TIME:
//                fieldWidth = 5;
////                if (available) {
////                        format = UNSIGNED;
////                        value.u = _heartbeat.timeStamp;
////                }
//                break;
        case V_VOLTAGE:
                fieldWidth = 4;
                if (available) {
                        format = UNSIGNED;
                        decPos = 1;
                        value.u = _syspacket.vbat / 10;
                }
                break;
        case V_VLOCAL:
                fieldWidth = 4;
                if (available) {
                        format = UNSIGNED;
                        decPos = 2;
                        value.u = analogRead(A1);
                        value.u *= 1.9679; //value.u = value.u*5.0*13.3*100/3.3/1024.0;
                        if (_voltage == 0)
                          _voltage = value.u;
                        else
                          _voltage = 0.98*_voltage + 0.02*value.u;
                        value.u = _voltage;
                }
                break;
        case V_SATS:
        	fieldWidth = 2;
        	if (available) {
        		format = UNSIGNED;
        		decPos = 0;
        		value.u = _satcount; //_gpsstatus.satellites_visible;
        	}
        case V_FIX:
          fieldWidth = 7;
          if (available) {
            format = STRING;
            switch (_gpspacket.fix_type) {
              case 0:
                value.c = PSTR("NO FIX");
                break;
              case 1:
                value.c = PSTR("NO FIX2");
                break;
              case 2:
                value.c = PSTR("2D FIX");
                break;
              case 3:
                value.c = PSTR("3D FIX");
                break;
              default:
                value.c = PSTR("BADGPS");
            }
            //value.u = _gpspacket.fix_type;
          }
          break;
        case V_ROLL:
                if (available) {
                        fieldWidth = 2;
                        format = UNSIGNED;
                        value.u = _subAttitude(&_attpacket.roll, GLYPH_ROLL_LEFT, GLYPH_ROLL_RIGHT);
                } else {
                        fieldWidth = 3;
                }
                break;
        case V_PITCH:
                if (available) {
                        fieldWidth = 2;
                        format = UNSIGNED;
                        value.u = _subAttitude(&_attpacket.pitch, GLYPH_PITCH_DOWN, GLYPH_PITCH_UP);
                } else {
                        fieldWidth = 3;
                }
                break;
        case V_YAW:
                if (available) {
                        fieldWidth = 3;
                        format = UNSIGNED;
                        // different sub function
                        value.u = _subYaw(&_attpacket.yaw, GLYPH_YAW_LEFT, GLYPH_YAW_RIGHT);
                } else {
                        fieldWidth = 3;
                }
                break;
        case V_LATITUDE:
                fieldWidth = 8;
                if (available) {
                        format = SIGNED;
                        decPos = 5;
                        value.s = _gpspacket.lat*1e5;
                }
                break;
        case V_LONGITUDE:
                fieldWidth = 9;
                if (available) {
                        format = SIGNED;
                        decPos = 5;
                        value.s = _gpspacket.lon*1e5;
                }
                break;
        case V_ALTITUDE:
                fieldWidth = 4;
                if (available) {
                        format = SIGNED;
                        value.s = constrain((_gpspacket.alt), -999, 9999);
                }
                break;
        case V_P_ALTITUDE:
                fieldWidth = 4;
//                if (available) {
//                  format = SIGNED;
//                  // Pressure calculation taken from APM 2.24 code (sensors.pde)
//              	  abs_pressure = ((float)abs_pressure * .7) + ((float)barometer.Press * .3);
//              	  scaling = (float)g.ground_pressure / (float)abs_pressure;
//              	  temp = ((float)g.ground_temperature) + 273.15f;
//              	  x = log(scaling) * temp * 29271.267f;
//                  value.s = constrain((_prepacket.alt), -999, 9999);
//                }
                break;
        case V_GROUNDSPEED:
                fieldWidth = 3;
                if (available) {
                        format = UNSIGNED;
                        // Groundspeed is unsigned
                        value.u = constrain(_gpspacket.v, 0, 999);
                }
                break;
        case V_GROUNDCOURSE:
                fieldWidth = 3;
                if (available) {
                        format = UNSIGNED;
                        value.u = constrain(_gpspacket.hdg, 0, 359);
                }
                break;
                /*
        // Waypoint info page
        case V_HOMEDIST:
                fieldWidth = 4;
                if (available) {
                  // Gives 2D distance from home, altitude isn't taken into account, yet...
                  // Convert to radians
                  float lat1 = _commandHome.p3/10000000.0 * 0.0174532925;
                  float lat2 = _gpspacket.lat/10000000.0 * 0.0174532925;
                  float long1 = _commandHome.p4/10000000.0 * 0.0174532925;
                  float long2 = _gpspacket.lon/10000000.0 * 0.0174532925;
                  
                  // Find difference
                  float dlat = lat2 - lat1;
                  float dlong = long2 - long1;
                  
                  // Calculate distance
                  float a = sin(dlat / 2.0) * sin(dlat / 2.0) +
                            cos(lat1) * cos(lat2) *
                            sin(dlong / 2.0) * sin(dlong / 2.0);
                  value.u = 6371000.0 * 2.0 * atan2(sqrt(a), sqrt(1 - a));
                  
                  format = UNSIGNED;
                } else {
                  //comm.send_msg_command_request(0);
                }
                break;
                */
        case V_COMMANDID:
                fieldWidth = 2;
                if (available) {
                  //value.u = _heartbeat.commandIndex;
                  value.u = _pktCurrWpt.seq;
                  format = UNSIGNED;
                }
                break;
        case V_WPHCOUNT:
                fieldWidth = 2;
                if (available) {
                  value.u = _pktWptCount.count;
                  format = UNSIGNED;
                }
                break;
        case V_WPTYPE:
                fieldWidth = 10;
                if (available) {
//                  if (_heartbeat.commandIndex == 0)
//                  {
//                    value.c = PSTR("Home\0");
//                  }
//                  else
//                  {
//                    //value.c = commandModes.lookup(constrain(_command[_heartbeat.commandIndex].commandID-15,0,8));
//                    switch(_commandCurr.commandID) {
//                      case 0x10:
//                        value.c = PSTR("Waypoint  ");
//                        break;
//                      case 0x11:
//                        value.c = PSTR("Loiter    ");
//                        break;
//                      case 0x12:
//                        value.c = PSTR("LoiterTurn");
//                        break;
//                      case 0x13:
//                        value.c = PSTR("LoiterTime");
//                        break;
//                      case 0x14:
//                        value.c = PSTR("Return2Ltr");
//                        break;
//                      case 0x15:
//                        value.c = PSTR("Land      ");
//                        break;
//                      case 0x16:
//                        value.c = PSTR("Take off  ");
//                        break;
//                      default:
//                        value.c = PSTR("Unknown   ");
//                        break;
//                    }
//                  }
                  format = STRING;
                }
                break;
        case V_BEARERR:
                fieldWidth = 4;
                if (available) {
                  //value.s = _valueBerr.value / 100;
                  if (value.s > 180)
                    value.s = value.s-360;
                  format = SIGNED;
                }
                break;
//        case V_WPDIST:
//                fieldWidth = 4;
//                if (available) {
//                  /// @bug Assumes that we have the current location available, which is normally reasonable
//                  // Calculates the distance between the waypoint and the current location - move to function?
//                  // Gives 2D distance, altitude isn't taken into account, yet...   
//                  // Convert to radians
//                  float lat1 = _commandCurr.p3/10000000.0 * 0.0174532925;
//                  float lat2 = _gpspacket.lat/10000000.0 * 0.0174532925;
//                  float long1 = _commandCurr.p4/10000000.0 * 0.0174532925;
//                  float long2 = _gpspacket.lon/10000000.0 * 0.0174532925;
//                  
//                  // Find difference
//                  float dlat = lat2 - lat1;
//                  float dlong = long2 - long1;
//                  
//                  // Calculate distance
//                  float a = sin(dlat / 2.0) * sin(dlat / 2.0) +
//                            cos(lat1) * cos(lat2) *
//                            sin(dlong / 2.0) * sin(dlong / 2.0);
//                  value.u = 6371000.0 * 2.0 * atan2(sqrt(a), sqrt(1 - a));
//                  format = UNSIGNED;
//                }
//                break;
//        case V_WPETA:
//                fieldWidth = 3;
//                if (available && _gpspacket.v > 0) {
//                  // Calculates the ETA, based upon distance and speed, assuming we're on track
//                  // Based upon 2D distance, altitude isn't taken into account, yet...    
//                  
//                  // Convert to radians
//                  float lat1 = _commandCurr.p3/10000000.0 * 0.0174532925;
//                  float lat2 = _gpspacket.lat/10000000.0 * 0.0174532925;
//                  float long1 = _commandCurr.p4/10000000.0 * 0.0174532925;
//                  float long2 = _gpspacket.lon/10000000.0 * 0.0174532925;
//                  
//                  // Find difference
//                  float dlat = lat2 - lat1;
//                  float dlong = long2 - long1;
//                  
//                  // Calculate distance
//                  float a = sin(dlat / 2.0) * sin(dlat / 2.0) +
//                            cos(lat1) * cos(lat2) *
//                            sin(dlong / 2.0) * sin(dlong / 2.0);
//                  value.u = 6371000.0 * 2.0 * atan2(sqrt(a), sqrt(1 - a));
//                            
//                  // Calculate speed
//                  value.u /= _gpspacket.v / 100;
//                  format = UNSIGNED;
//                }
//                else
//                  value.c = PSTR("----------");
//                break;
        default:
                //Serial.print("unrecognised format code ");
                PrintPSTR(PSTR("unrecognised format code "));
                Serial.println((int)key, 16);
//                Serial.printf_P(PSTR("unrecognised format code %x\n"), (int)key);
                // debugging hint
                fieldWidth = 1;
                format = STRING;
                value.c = PSTR("?");
                break;
        }

        switch (format) {
        case STRING:
                while (fieldWidth--) {
                        i = pgm_read_byte_near(value.c);
                        if (0 == i) {
                                lcd.write(' ');
                        } else {
                                lcd.write(i);
                                value.c++;
                        }
                }
                break;
        case SIGNED:
                if (value.s < 0) {
                        negative = true;
                        value.u = -value.s;
                } else {
                        value.u = value.s;      // XXX arguably a NOP
                }
                // FALLTHROUGH
        case UNSIGNED:
                decBuf[0] = '0' + (value.u % 10);
                value.u /= 10;
                for (i = 1; i < fieldWidth; i++) {
                        if (i == decPos) {
                                decBuf[i] = '.';
                        } else if ((0 == value.u) && (i > (decPos + 1))) {
                                decBuf[i] = ' ';
                        } else {
                                decBuf[i] = '0' + (value.u % 10);
                                value.u /= 10;
                        }
                }
                if (negative)
                        decBuf[i-1] = '-';
                        
                // The following line makes the field one bigger if a negative sign is required...
                        //decBuf[i++] = '-';
                
                while (i-- > 0)
                        lcd.write(decBuf[i]);
                break;
        }
}

uint16_t
Markup::_subAttitude(float *value, uint8_t glyphNegative, uint8_t glyphPositive)
{
        if (*value < 0) {
                lcd.write(glyphNegative);
                return(constrain(-*value*57.2957795, 0, 99));
        }
        if (*value > 0) {
                lcd.write(glyphPositive);
                return(constrain(*value*57.2957795, 0, 99));
        }
//        lcd.write(' ');
        lcdPrintPSTR(PSTR(" "));
        return(0);
}

uint16_t
Markup::_subYaw(float *value, uint8_t glyphNegative, uint8_t glyphPositive)
{
    if (*value < 0) {
            lcd.write(glyphNegative);
            return(constrain(-(*value*57.2957795), 0, 999));
    }
    if (*value >= 0) {
            lcd.write(glyphPositive);
            return(constrain(*value*57.2957795, 0, 999));
    }
        lcd.write(' ');
        lcdPrintPSTR(PSTR(" "));
        return(0);
}

bool
Markup::_available(uint8_t key)
{
        uint8_t word, bit;

        // compute index for availability bit
        word = key / 16;
        bit = key % 16;

        // test and return
        return((_availability[word] & (1U << bit)) ? true : false);
}

void
Markup::message(void *arg, mavlink_message_t *buf) //uint8_t messageID, uint8_t messageVersion,
{
        ((Markup *)arg)->_message(buf); //messageID, messageVersion,
}

void
Markup::_message(mavlink_message_t *buf) //uint8_t messageID, uint8_t messageVersion,
{
        switch (buf->msgid) {
            
        case MAVLINK_MSG_ID_SYS_STATUS:
            mavlink_msg_sys_status_decode((mavlink_message_t*)buf, &_syspacket);
            _availability[0] |= AVAIL_SYS_STATUS;
            break;
                
        case MAVLINK_MSG_ID_ATTITUDE:
            mavlink_msg_attitude_decode((mavlink_message_t*)buf, &_attpacket);
            _availability[0] |= AVAIL_ATTITUDE;
            break;

        case MAVLINK_MSG_ID_GPS_RAW:
            mavlink_msg_gps_raw_decode((mavlink_message_t*)buf, &_gpspacket);
            _availability[0] |= AVAIL_LOCATION;
            break;

        case MAVLINK_MSG_ID_GPS_STATUS:
//        	mavlink_gps_status_t gpsstatus;
//            mavlink_msg_gps_status_decode((mavlink_message_t*)buf, &gpsstatus);
//            _satcount = gpsstatus.satellites_visible;
//            _availability[0] |= AVAIL_GPSSTATUS;

        	// Satellite count is just the first 8 bits of the message
//        	memcpy(&_satcount,&buf[8],sizeof(uint8_t));
//        	PrintPSTR(PSTR("Satellites in view: "));
//        	Serial.println(_satcount,DEC);
            break;

// Not used, so commented out for space savings
//        case MAVLINK_MSG_ID_RAW_PRESSURE:
//            mavlink_msg_raw_pressure_decode((mavlink_message_t*)buf, &_prepacket);
//            _availability[0] |= AVAIL_PRESSURE;
//            break;

        case MAVLINK_MSG_ID_WAYPOINT_CURRENT:
            mavlink_msg_waypoint_current_decode((mavlink_message_t*)buf, &_pktCurrWpt);
            _availability[0] |= AVAIL_WP_CURR;
            break;
        case MAVLINK_MSG_ID_WAYPOINT_COUNT:
            mavlink_msg_waypoint_count_decode((mavlink_message_t*)buf, &_pktWptCount);
            _availability[0] |= AVAIL_WP_COUNT;
            break;
            
//        case MAVLINK_MSG_ID_PARAM_VALUE:
//                // Find what type of pid message
//                memcpy(&_pidtemp, buf, sizeof(_pidtemp));
//                if (_pidtemp.pidSet == 0) {
//                  dst = &_pidroll;
//                  _availability[2] |= AVAIL_PIDROLL;
//                }
//                if (_pidtemp.pidSet == 1) {
//                  dst = &_pidpitch;
//                  _availability[2] |= AVAIL_PIDPITCH;
//                }
//                if (_pidtemp.pidSet == 2) {
//                  dst = &_pidyaw;
//                  _availability[2] |= AVAIL_PIDYAW;
//                }
//                len = sizeof(_pidtemp);
//                break;
/*                
        case MAVLINK_MSG_ID_COMMAND:
                dst = &_commandBuf[_cmdbufpos];
                len = sizeof(_commandBuf[_cmdbufpos]);
                memcpy(dst, buf, len);
                if (_commandBuf[_cmdbufpos].itemNumber == 0) {
                  dst = &_commandHome;
                  len = sizeof(_commandBuf[_cmdbufpos]);
                  memcpy(dst, buf, len);
                  _availability[1] |= AVAIL_COMMANDHOME;
                }
                // Increase the next buffer posn
                _cmdbufpos++,DEC;
                if (_cmdbufpos >= CMDBUFSIZE)
                  _cmdbufpos = 0;
                // All the copying has been done already
                dst = NULL;
                break;
                
        case MAVLINK_MSG_ID_PARAM_VALUE:
                dst = &_value;
                len = sizeof(_value);
                memcpy(dst, buf, len);
                
//		if (_value.valueID == BinComm::MSG_VAR_BEARING_ERROR)
//                {
//                  dst = &_valueBerr;
//                  _availability[1] |= AVAIL_VALUE;
//                }

		break;
*/
        default:
                PrintPSTR(PSTR("Received unknown message "));
                Serial.println(buf->msgid,DEC);
        }
}



//        case MAVLINK_MSG_ID_HEARTBEAT:
//            //dst = &_heartbeat;
//            //len = sizeof(_heartbeat);
//            _availability[0] |= AVAIL_HEARTBEAT;
//
//            /*
//            // Check that _commandCurr is still the current waypoint
//            if (_commandCurr.itemNumber != _heartbeat.commandIndex || !(_available(V_WPNUMBER))) {
//              for (i=0; i<CMDBUFSIZE; i++) {
//                if (_heartbeat.commandIndex == _commandBuf[i].itemNumber) {
//                  memcpy(&_commandCurr, &_commandBuf[i], sizeof(_commandBuf[i]));
//                  _availability[1] |= AVAIL_COMMAND;
//                  break;
//                }
//              }
//            }
//            */
//            break;
