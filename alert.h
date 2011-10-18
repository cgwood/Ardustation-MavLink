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

/// @file       alert.h
/// @brief      alert viewer

#define ALERT_HISTORY   4       ///< number of alert messages to save

#define ALERT_NONE      255     ///< flag in _newestAlert for 'no alerts'

/// @class      PageAlert
/// @brief      A viewer for alert messages.
///
class PageAlert : public Page {
public:
        PageAlert(void);

        static void     notify(void *arg, mavlink_message_t *buf); //uint8_t messageID, uint8_t messageVersion,
protected:
        void            _enter(uint8_t fromPage);
        void            _handleEvent(Page::event eventCode);
        void            _update(void);
        bool            _isStartup(const char *text);

private:
        virtual void    _notify(struct msg_status_text *alert);

        uint8_t         _nextAlert(uint8_t index);
        uint8_t         _previousAlert(uint8_t index);

        bool            _updated;
        uint8_t         _displaying;
        uint8_t         _oldestAlert;
        uint8_t         _newestAlert;
        uint16_t        _alertCount;

        struct {
                uint8_t severity;
                char    text[50];
        }               _alert[ALERT_HISTORY];

};

