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

/// @file       alert.pde
/// @brief      alert viewer

PROGMEM const prog_char startupMessage[] = "<startup_ground>";

PageAlert::PageAlert(void)
{
        _oldestAlert = _newestAlert = ALERT_NONE;
}

void
PageAlert::notify(void *arg, mavlink_message_t *buf) // uint8_t messageID, uint8_t messageVersion,
{
        ((PageAlert *)arg)->_notify((struct msg_status_text *)buf);
}

void
PageAlert::_notify(struct msg_status_text *alert)
{
        if (ALERT_NONE == _newestAlert) {
                // first entry in the ring
                _newestAlert = _oldestAlert = 0;
        } else {
                // rotate indices around the ring
                _newestAlert = _nextAlert(_newestAlert);
                if (_newestAlert == _oldestAlert)
                        _oldestAlert = _nextAlert(_oldestAlert);

                // force display to follow newest alert
                _displaying = _newestAlert;
                        
        }

        // save the alert
        _alertCount++;
        _alert[_newestAlert].severity = alert->severity;
        strlcpy(_alert[_newestAlert].text, alert->text, sizeof(_alert[_newestAlert].text));
        
        // analyse the message, is it a startup message? if so don't moan if we lose the comm link!
        if (_isStartup(alert->text)) 
          watchdog.reboot();
        
        // Beep about it
        if (alert->severity <= 200)
          beep.play(BEEP_NOTICE);
        else
          beep.play(BEEP_CRITICAL);
        

        // mark as needing update
        _updated = true;
}

bool
PageAlert::_isStartup(const char *text)
{
  uint8_t i;
  const prog_char *str;
  
  str = startupMessage;
  
  for (i=0;i<sizeof(startupMessage);i++) {
    if (pgm_read_byte_near(str) == 0)
      break;
    if (text[i] != pgm_read_byte_near(str++))
      return 0;
  }
  return 1;
}

uint8_t
PageAlert::_nextAlert(uint8_t index)
{
        if (++index == ALERT_HISTORY)
                index = 0;
        return(index);
}

uint8_t
PageAlert::_previousAlert(uint8_t index)
{
        if (index-- == 0)
                index = ALERT_HISTORY - 1;
        return(index);
}

void
PageAlert::_enter(uint8_t fromPage)
{
        // start by displaying the newest alert
        _displaying = _newestAlert;
        _updated = true;
}

void
PageAlert::_update(void)
{
        uint8_t         row, col, pos, c;

        // if nothing has changed, do nothing here
        if (!_updated)
                return;
        _updated = false;
        lcd.clear();

        // if we have no alerts, we have no alerts...
        if (ALERT_NONE == _newestAlert) {
                lcd.setCursor(2, 1);
                lcd.print("No Alerts");
                return;
        }

        // display the alert header
        lcd.print("ALERT ");
        lcd.print(_alertCount);
        switch (_alert[_displaying].severity) {
        case 0:
                lcd.print(" INFO");
                //beep.play(BEEP_NOTICE);
                break;
        case 255:
                lcd.print(" CRITICAL");
                //beep.play(BEEP_CRITICAL);
                break;
        default:
                lcd.print(" ?");
                lcd.print(_alert[_displaying].severity);
        }

        // display the alert
        row = 0;
        pos = 0;
        col = 0; //LCD_COLUMNS;
        lcd.setCursor(row, col);
        for (pos = 0; pos < sizeof(_alert[_displaying].text); pos++) {
                if (++col >= LCD_COLUMNS) {
                        col = 0;
                        row++;
                        lcd.setCursor(col, row);
                }
                c = _alert[_displaying].text[pos];
                if (0 == c)
                        break;
                lcd.write(c);
        }

        // display the scroll arrows if there are other alerts to view
        if (_displaying != _oldestAlert) {
                lcd.setCursor(LCD_COLUMNS - 2, LCD_ROWS - 1);
                lcd.write(LCD_CHAR_UP_ARROW);
        }
        if (_displaying != _newestAlert) {
                lcd.setCursor(LCD_COLUMNS - 1, LCD_ROWS - 1);
                lcd.write(LCD_CHAR_DOWN_ARROW);
        }
}

void
PageAlert::_handleEvent(Page::event eventCode)
{
        switch (eventCode) {
        case UP:
                if (_displaying != _oldestAlert) {
                        _displaying = _previousAlert(_displaying);
                        _updated = true;
                } else {
                        beep.play(BEEP_BADKEY);
                }
                break;
        case DOWN:
                if (_displaying != _newestAlert) {
                        _displaying = _nextAlert(_displaying);
                        _updated = true;
                } else {
                        beep.play(BEEP_BADKEY);
                }
                break;
        default:
                Page::_handleEvent(eventCode);
        }
}
