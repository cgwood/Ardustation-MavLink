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

/// @file       watchdog.h
/// @brief      message activity watchdog

/// Period for data streaming requests, when there's not yet been a heartbeat
#define REQUEST_RATE 1000

/// time from last packet receipt to alarm starting
#define MESSAGE_TIMEOUT         5000

/// time from last packet receipt to alarm starting
#define GROUND_MESSAGE_TIMEOUT  30000

/// interval between alarm beeps
#define MESSAGE_ALARM_RATE      500

/// @class      Watchdog
/// @brief      The watchdog fires an alarm when packet traffic stops
class Watchdog {
public:
        Watchdog() {_lastRequest = millis();};

        /// Reset the watchdog.
        /// Installed as a message handler, registered for MSG_ALL.
        ///
        /// @param messageID            ignored
        /// @param messageVersion       ignored
        /// @param messageData          ignored
        ///
        static void    reset(void *arg, mavlink_message_t *messageData); //uint8_t messageID, uint8_t messageVersion,
        
        /// Reset the watchdog due to APM reboot
        ///
        void           reboot(void);

        /// Periodic call to check the watchdog state.
        ///
        /// Maintains a bug in the upper-right corner of the display.
        /// If a packet has not been received for \a PACKET_TIMEOUT milliseconds,
        /// starts an alarm and updates the bug.
        ///
        void            check(void);

private:
        /// internal watchdog reset
        ///
        void            _reset(void);
        
        /// internal watchdog reboot
        ///
        void            _reboot(void);

        /// set the bug character to "where's the link"
        ///
        void            _bugWait(void);

        /// set the bug character to "link ok"
        ///
        void            _bugOK(void);

        /// set the bug character to "lost link"
        ///
        void            _bugLost(void);

        /// timestamp of the last comm request sent
        unsigned long   _lastRequest;

        /// timestamp of the last message received
        unsigned long   _lastStamp;

        /// timestamp of the last ground startup message received
        unsigned long   _lastGroundStamp;

        /// timestamp of the last alarm beep issued
        unsigned long   _lastAlarm;

        /// timestamp of the last time the glyph was drawn
        unsigned long   _lastRedraw;

        /// alarm glyph toggle
        bool            _alarmInvert;

        static const uint8_t _linkWait[8];
        static const uint8_t _linkOK[8];
        static const uint8_t _linkLost[8];
};


