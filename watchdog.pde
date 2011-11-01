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

/// @file       watchdog.pde
/// @brief      message activity watchdog

const uint8_t Watchdog::_linkWait[8]  = {0x1f, 0x1b, 0x15, 0x1d, 0x1b, 0x1f, 0x1b, 0x1f};
const uint8_t Watchdog::_linkOK[8]    = {0x04, 0x02, 0x1f, 0x06, 0x0c, 0x1f, 0x08, 0x04};
const uint8_t Watchdog::_linkLost[8] = {0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x00, 0x1b, 0x1b};

void
Watchdog::check(void)
{
        if (0 == _lastStamp) {
                // we have never seen a packet
                if ((millis() - _lastRequest) > REQUEST_RATE) {
                  comm.request();
                  _lastRequest = millis();
                }

                // Swap the bug character to "where is the link"
                // Doing this every iteration is a bit wasteful, but we only do this while
                // there is nothing else to do.
                _bugWait();
        } else {
                if (0 == _lastAlarm) {
                        // we are not currently in an alarm condition

                        // if we have just timed out, next time around the alarm will sound
                        if ((millis() - _lastStamp) > MESSAGE_TIMEOUT && (millis() - _lastGroundStamp) > GROUND_MESSAGE_TIMEOUT) {
                                _lastAlarm = 1;
                                _alarmInvert = true;

                                // XXX we should save the last GPS data here in NVRAM
                                // for lost-model recovery purposes.
                        }
                                
                } else {
                        // we are currently in an alarm condition

                        // is it time to sound the alarm beep again?
                        if ((millis() - _lastAlarm) > MESSAGE_ALARM_RATE) {
                                _lastAlarm = millis();

                                // Only beep if packet tones are on:
                                if (nvram.nv.packetSounds)
                                	beep.play(BEEP_CRITICAL);

                                // toggle the bug glyph between "where is the link" and "hey you!"
                                if (_alarmInvert) {
                                        _bugLost();
                                } else {
                                        _bugWait();
                                }
                                _alarmInvert = !_alarmInvert;
                        }
                }
        }

        // Refresh the bug
        lcd.setCursor(LCD_COLUMNS - 1, 0);
        lcd.write(LCD_CHAR_LINK);
}

void
Watchdog::reset(void *arg, mavlink_message_t *messageData) //uint8_t messageID, uint8_t messageVersion,
{
        ((Watchdog *)arg)->_reset();
}

void
Watchdog::reboot(void)
{
  _reboot();
}

void
Watchdog::_reboot(void)
{
  _lastGroundStamp = millis();
}

void
Watchdog::_reset(void)
{
        // kill the alarm if it's going and swap the bug character back 
        if (0 != _lastAlarm) {
                _lastAlarm = 0;
                _bugOK();
        }

        // if this is the first time we have seen the link, make with the happy
        if (0 == _lastStamp) {
                beep.play(BEEP_CONNECTED);
                _bugOK();
        }

        // and remember when we saw this packet
        _lastStamp = millis();
}

void
Watchdog::_bugWait(void)
{
        lcd.createChar(LCD_CHAR_LINK, const_cast<uint8_t *>(_linkWait));
}

void
Watchdog::_bugOK(void)
{
        lcd.createChar(LCD_CHAR_LINK, const_cast<uint8_t *>(_linkOK));
}

void
Watchdog::_bugLost(void)
{
        lcd.createChar(LCD_CHAR_LINK, const_cast<uint8_t *>(_linkLost));
}

