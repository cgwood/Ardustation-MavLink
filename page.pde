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

/// @file       page.pde
/// @brief      Implementation of the page class and the trivial pages.

/// A node in the menu tree
struct page_menu_node {
        uint8_t pageCode;       ///< page code for this page
        Page    *thisPage;      ///< Page subclass handling the page
        uint8_t exits[7];       ///< navigation exits (up,down,left,right,ok,cancel,timeout)
};

/// The top-level navigation tree.
/// If a page forwards events to the superclass, this tree can be used to implement
/// navigation between pages.
///
/// @note I sure do miss desginated initialisers...
/*
struct page_menu_node pageNavigation[] PROGMEM = {
        {P_BANNER,       &welcomePage,   0,       0,       0,             0,               0,               0,      P_MAIN },
        {P_PICKER,       &pickerPage,    0,       0,       0,             0,               0,               0,      0 },
        {P_SUMMARY,      &summaryPage,   P_SETUP, P_ALERT, P_PIDSETUP,    P_MISSION,       0,               0,      0 },    // currently the 'main' page aka P_MAIN
};
*/
struct page_menu_node pageNavigation[] PROGMEM = {
        //Page ID,       Page pointer,   UP,      Down,    Left,          Right,           Okay,            Cancel, Timeout
        // utility pages
        {P_BANNER,       &welcomePage,   0,       0,       0,             0,               0,               0,      P_MAIN },
        {P_PICKER,       &pickerPage,    0,       0,       0,             0,               0,               0,      0 },
        //{P_PIDCONFIRM,   &PidConfirmPage,0,       0,       0,             0,               P_PIDSETUP,      P_MAIN, P_MAIN}, 
        //{P_NAVPIDCONFIRM,&PidConfirmPage,0,       0,       0,             0,               P_NAVPIDSETUP,   P_MAIN, P_MAIN},  
        
        // functional pages
        {P_SETUP,        &setupPage,     0,       0,       0,             0,               0,               P_MAIN, 0 },
//        {P_ALERT,        &alertPage,     0,       0,       0,             0,               P_MAIN,          P_MAIN, 0 },
//        {P_PIDSETUP,     &PidPage,       0,       0,       0, P_MAIN,          0,               P_MAIN, 0 },
//        {P_APMSETTINGS,  &APMPage,       0,       0,       0,             P_PIDSETUP,   0,               P_MAIN, 0 },
        {P_PIDSETUP,     &PidPage,       0,       0,       P_NAVPIDSETUP, P_MAIN,          0,               P_MAIN, 0 },
        {P_NAVPIDSETUP,  &NavPidPage,    0,       0,       P_APMSETTINGS, P_PIDSETUP,      0,               P_MAIN, 0 },
        {P_APMSETTINGS,  &APMPage,       0,       0,       0,             P_NAVPIDSETUP,   0,               P_MAIN, 0 },
        
        // status pages
        {P_SUMMARY,      &summaryPage,   P_SETUP, 00, P_PIDSETUP,    P_COMMANDS,       0,               0,      0 },    // currently the 'main' page aka P_MAIN
//        {P_MISSION,      &MissionPage,   P_SETUP, 0,       P_SUMMARY,     P_COMMANDS,      0,               P_MAIN, 0 },
        {P_COMMANDS,     &CommandsPage,  0,       0,       P_SUMMARY,     0,               0,               P_MAIN, 0 },
};
uint8_t currentPage;    ///< index into pageNavigation for the page being displayed

/// Size of the pageNavigation array
#define P_MAX   (sizeof(pageNavigation) / sizeof(pageNavigation[0]))

////////////////////////////////////////////////////////////////////////////////
// Public interface to the page system.
////////////////////////////////////////////////////////////////////////////////

void
Page::begin(void)
{
        currentPage = 0;
        _goPage(P_BANNER);
}

void
Page::update(void)
{
        _pageThis(currentPage)->_update();
}

void
Page::forcePage(uint8_t newPage)
{
        // should sanity-check newPage?
        _goPage(newPage);
}

void
Page::handleEvent(Page::event eventCode)
{
        if (NOP != eventCode)
                _pageThis(currentPage)->_handleEvent(eventCode);
}

////////////////////////////////////////////////////////////////////////////////
// Subclass interface and default methods
////////////////////////////////////////////////////////////////////////////////

void
Page::_leave(Page::event reasonCode)
{
        uint8_t newPage;

        // work out what the new page would be
        newPage = _pageExit(currentPage, (uint8_t)reasonCode - 1);

        if (0 == newPage) {
                // issue a disapproving sound
                beep.play(BEEP_BADKEY);
        } else {
                // Does the old page require any leaving actions
                switch (_pageCode(currentPage)) {
                  case P_MISSION:
                    // Stop broadcasting
                    //comm.send_msg_value_request(BinComm::MSG_VAR_BEARING_ERROR, 0);
                    break;
                }
                
                // transition to the new page
                _goPage(newPage);
        }
}

void
Page::_goPage(uint8_t newPage)
{
        uint8_t         i;
                
        // Does the new page require any actions
        switch (newPage) {
          case P_PIDSETUP:
            // dont request pid values if just returning from confimation screen
            //if (_pageCode(currentPage) != P_PIDCONFIRM) {
//              comm.send_msg_pid_request(pidTypesRPY[0]);
//              comm.send_msg_pid_request(pidTypesRPY[1]);
//              comm.send_msg_pid_request(pidTypesRPY[2]);
            //}
            break;
//          
//          case P_NAVPIDSETUP:
//            // dont request pid values if just returning from confimation screen
//            //if (_pageCode(currentPage) != P_NAVPIDCONFIRM) {
//              comm.send_msg_pid_request(pidTypesNav[0]);
//              comm.send_msg_pid_request(pidTypesNav[1]);
//              comm.send_msg_pid_request(pidTypesNav[2]);
//            //}
//            break;
//          case P_APMSETTINGS:
//            for (i=0;i<APMVALCOUNT;i++)
//              comm.send_msg_value_request(APMSettingsIDs[i], 0);
//            break;
          case P_MISSION:
            //comm.send_msg_value_request(BinComm::MSG_VAR_BEARING_ERROR, 1);
            break;
          case P_SUMMARY:
            //mavlink_message_t msg;
            //mavlink_msg_request_data_stream_pack(127, 0, &msg, 7, 1, MAV_DATA_STREAM_RAW_SENSORS, MAV_DATA_STREAM_RAW_SENSORS_RATE, MAV_DATA_STREAM_RAW_SENSORS_ACTIVE);
            //comm.send(&msg);
            break;
        }
            

        // find the page offset for the page code
        for (i = 0; i < P_MAX; i++) {
                if (_pageCode(i) == newPage) {
                        // enter, telling the page where we came from
                        _pageThis(i)->_enter(_pageCode(currentPage));
                        currentPage = i;
                        return;
                }
        }
}

void
Page::_update(void)
{
        // do nothing
}

void
Page::_handleEvent(Page::event eventCode)
{
        // default behaviour is to attempt to navigate based on the event
        _leave(eventCode);
}

uint8_t
Page::_pageCode(uint8_t pageIndex)
{
        PGM_P   pnBase = (PGM_P)&pageNavigation[pageIndex];

        return(pgm_read_byte_near(pnBase + offsetof(page_menu_node, pageCode)));
}

Page *
Page::_pageThis(uint8_t pageIndex)
{
        PGM_P   pnBase = (PGM_P)&pageNavigation[pageIndex];

        return((Page *)pgm_read_word_near(pnBase + offsetof(page_menu_node, thisPage)));
}

uint8_t
Page::_pageExit(uint8_t pageIndex, uint8_t exitIndex)
{
        PGM_P   pnBase = (PGM_P)&pageNavigation[pageIndex];

        return(pgm_read_byte_near(pnBase + offsetof(page_menu_node, exits) + exitIndex));
}


////////////////////////////////////////////////////////////////////////////////
// Page containing text.
////////////////////////////////////////////////////////////////////////////////

void
PageText::_enter(uint8_t fromPage)
{
        lcd.clear();
        _render();
        _enterTime = millis();
}

void
PageText::_update(void)
{
        if (_timeout && ((millis() - _enterTime) > _timeout))
                _leave(TIMEOUT);
}

void
PageText::_render(void)
{
        char            c;
        uint8_t         i;
        uint8_t         row = 0;

        for (i = 0;; i++) {
                c = pgm_read_byte_near(_text + i);
                if (0 == c) {
                        break;
                } else if ('\n' == c) {
                        lcd.setCursor(0, ++row);
                } else {
                        lcd.write(c);
                }
        }
}

////////////////////////////////////////////////////////////////////////////////
// Status (format string based) page.
////////////////////////////////////////////////////////////////////////////////

void
PageStatus::notify(void *arg, mavlink_message_t *buf) //uint8_t messageID, uint8_t messageVersion,
{
        ((PageStatus *)arg)->_updated = true;
}

void
PageStatus::_update(void)
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

        // call superclass
        PageText::_update();
}

void
PageStatus::_render(void)
{
        markup.emit(_text);
}

////////////////////////////////////////////////////////////////////////////////
// Pick widget
////////////////////////////////////////////////////////////////////////////////

void
PagePicker::pick(uint8_t col, uint8_t row, uint8_t index, const prog_char *pickList)
{
        char            c;
        uint8_t         i;
        uint8_t         len;

        // save the state we will need
        _col = col;
        _row = row;
        _default = _index = index;
        _pickList = pickList;

        // find the longest element in the pick list and count entries
        _longest = 0;
        len = 0;
        _max = 0;
        i = 0;
        for (;;) {
                c = pgm_read_byte_near(_pickList + i++);
                if (0 == c)
                        break;
                if ('\n' == c) {
                        len = 0;
                        _max++;
                } else {
                        len++;
                        if (len > _longest)
                                _longest = len;
                }
        }

        // in the case of a bad index, pick the first entry in the list
        if (_index > _max)
                _index = 0;

        // and force the display to the picker page
        Page::forcePage(P_PICKER);
}

uint8_t
PagePicker::result(void)
{
        return(_index);
}

void
PagePicker::_enter(uint8_t fromPage)
{
        // save the page we'll return to
        _fromPage = fromPage;

        // draw the "picking" marker
        lcd.setCursor(_col - 1, _row);
        lcd.write('>');

        // draw the current selection
        _draw();
}

void
PagePicker::_handleEvent(Page::event eventCode)
{
        // Special case up/down for lists with only two entries
        // to achieve a toggle effect
        if (1 == _max) {
                if ((UP == eventCode) || (DOWN == eventCode)) {
                        _index = (_index == 0) ? 1 : 0;
                        _draw();
                }
        } else {
                // Regular up/down navigation for lists with more than
                // two entries.
                switch(eventCode) {
                case UP:
                        if (_index > 0) {
                                _index--;
                                _draw();
                        } else {
                                beep.play(BEEP_BADKEY);
                        }
                        break;
                case DOWN:
                        if (_index < _max) {
                                _index++;
                                _draw();
                        } else {
                                beep.play(BEEP_BADKEY);
                        }
                        break;
                }
        }

        switch(eventCode) {
        case CANCEL:
                _index = _default;
                _draw();
                // FALLTHROUGH
        case OK:
                // erase the "picking" marker
                lcd.setCursor(_col - 1, _row);
                lcd.write(' ');

                _goPage(_fromPage);
                break;
        }
}

void
PagePicker::printValueForIndex(uint8_t index, const prog_char *pickList)
{
        uint8_t i;
        char    c;

        // find the index'th entry in the list
        i = 0;
        while (index > 0) {
                c = pgm_read_byte_near(pickList + i++);
                if ('\n' == c)
                        index--;

                // if we run off the end of the list, return the first value consistent
                // with the behaviour of ::pick
                if (0 == c) {
                        i = 0;
                        break;
                }
        }

        // copy bytes to limit or \n
        for (;;) {
                c = pgm_read_byte_near(pickList + i++);
                if (('\n' == c) || (0 == c))
                        break;
                lcd.print(c);
        }
}

void
PagePicker::_draw(void)
{
        uint8_t         i;

        // clear the picker area
        lcd.setCursor(_col, _row);
        for (i = 0; i < _longest; i++)
                lcd.write(' ');

        // print the current value
        lcd.setCursor(_col, _row);
        printValueForIndex(_index, _pickList);
}                

////////////////////////////////////////////////////////////////////////////////
// Setup page
////////////////////////////////////////////////////////////////////////////////

/// @name baudrate options
//@{
const prog_char setupPickBaud[] PROGMEM = "  9600\n 19200\n 38400\n 57600\n115200";
long            setupBaud[] = {96, 192, 384, 576, 1152};
uint8_t         currentBaud = 2;
//@}

/// pick string for sound on/muted
const prog_char setupPickMute[] PROGMEM = "on\nmuted";

/// pick string for "on/off"
const prog_char setupPickOnOff[] PROGMEM = "off\non";

/// @name voltage options
//@{
const prog_char setupPickVoltage[] PROGMEM = " 11.1v\n 10.0v\n  9.3v\n  7.0v\n  6.5v\n  6.2v";
long            setupVoltage[] = {111,100,93,70,65,62};
uint8_t         currentVoltage = 4;
//@}

/// @name state machine states
/// values < 100 are while control is on the setup page, > 100 while editing in a picker
//@{
#define SS_C_MUTE       0
#define SS_P_MUTE       100
#define SS_C_PKTSOUND   1
#define SS_P_PKTSOUND   101
#define SS_C_SPEED      2
#define SS_P_SPEED      102
#define SS_C_VOLTAGE    3
#define SS_P_VOLTAGE    103
#define SS_C_MAX        3
//@}

void
PageSetup::_enter(uint8_t fromPage)
{
        uint8_t         i;

        if (_state < 100) {
                // navigation entry
                lcd.clear();
                _state = 0;

                //lcd.print(" Sound         ");
                lcdPrintPSTR(PSTR(" Sound         "));
                PagePicker::printValueForIndex(nvram.nv.muted, setupPickMute);

                lcd.setCursor(0, 1);
//                lcd.print(" Packet tones  ");
                lcdPrintPSTR(PSTR(" Packet tones  "));
                PagePicker::printValueForIndex(nvram.nv.packetSounds, setupPickOnOff);

                // Serial port speed setup
                lcd.setCursor(0, 2);
//                lcd.print(" Serial speed ");
                lcdPrintPSTR(PSTR(" Serial speed "));
                // set something based on the NVRAM setup
                for (i = 0; i < (sizeof(setupBaud) / sizeof(setupBaud[0])); i++) {
                        if (nvram.nv.serialSpeed == setupBaud[i]) {
                                currentBaud = i;
                                break;
                        }
                }
		PagePicker::printValueForIndex(currentBaud, setupPickBaud);

                // Low voltage warning
                lcd.setCursor(0, 3);
//                lcd.print(" Low Voltage  ");
                lcdPrintPSTR(PSTR(" Low Voltage  "));
                // set something based on the NVRAM setup
                for (i = 0; i < (sizeof(setupVoltage) / sizeof(setupVoltage[0])); i++) {
                        if (nvram.nv.lowVoltage == setupVoltage[i]) {
                                currentVoltage = i;
                                break;
                        }
                }
		PagePicker::printValueForIndex(currentVoltage, setupPickVoltage);
        } else {
                // return from picker
                switch (_state) {
                case SS_P_SPEED:
                        currentBaud = pickerPage.result();
                        nvram.nv.serialSpeed = setupBaud[currentBaud];
                        nvram.save();
                        _state = SS_C_SPEED;
                        break;
                case SS_P_MUTE:
                        nvram.nv.muted = pickerPage.result();
                        nvram.save();
                        _state = SS_C_MUTE;
                        break;
                case SS_P_PKTSOUND:
                        nvram.nv.packetSounds = pickerPage.result();
                        nvram.save();
                        _state = SS_C_PKTSOUND;
                        break;
                case SS_P_VOLTAGE:
                        currentVoltage = pickerPage.result();
                        nvram.nv.lowVoltage = setupVoltage[currentVoltage];
                        nvram.save();
                        _state = SS_C_VOLTAGE;
                        break;
                }
        }
        // draw the "choosing" marker
        lcd.setCursor(0, _state);
        lcd.write('>');
}

void
PageSetup::_handleEvent(Page::event eventCode)
{
        // remove the "choosing" marker
        lcd.setCursor(0, _state);
        lcd.write(' ');

        switch (eventCode) {
        case UP:
                if (_state > 0)
                        _state--;
                break;
        case DOWN:
                if (_state < SS_C_MAX)
                        _state++;
                break;
        case OK:
                _state += 100;
                switch (_state) {
                case SS_P_MUTE:
                        pickerPage.pick(15, 0, nvram.nv.muted, setupPickMute);
                        return;
                case SS_P_PKTSOUND:
                        pickerPage.pick(15, 1, nvram.nv.packetSounds, setupPickOnOff);
                        return;
                case SS_P_SPEED:
                        pickerPage.pick(14, 2, currentBaud, setupPickBaud);
                        return;
                case SS_P_VOLTAGE:
                        pickerPage.pick(14, 3, currentVoltage, setupPickVoltage);
                        return;
                }
                break;
        case LEFT:
        case RIGHT:
                break;
        case CANCEL:
                _leave(CANCEL);
                return;         // avoid re-drawing the chooser
        }

        // redraw the "choosing" marker
        lcd.setCursor(0, _state);
        lcd.write('>');
}


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
	int32_t         value;
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
				value_local *= pow(10,PIDDECPOS);
				decBuf[0] = '0' + ((int)floor(value_local+0.1) % 10);
				value_local /= 10;
				for (j=1;j<PIDFIELDWIDTH;j++) {
					if (j == PIDDECPOS) {
						decBuf[j] = '.';
					}
					else if ((0 == value_local) && (j > (PIDDECPOS + 1))) {
						decBuf[j] = ' ';
					}
					else {
						decBuf[j] = '0' + ((int)floor(value_local+0.1) % 10);
						value_local /= 10;
					}
				}
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
