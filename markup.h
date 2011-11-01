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

/// @file       markup.h
/// @brief      format string substitution and output

// WARNING: if indices here are changed, all markup format strings
//          must be adjusted to correspond.
#define V_FLIGHTMODE    1       ///< 6 chars ASCII text
#define V_SATS          2       ///< 2 chars 0-99
#define V_VOLTAGE       3       ///< 4 chars 0.0 - 99.9
#define V_ROLL          4       ///< 1 char glyph, 2 chars degrees 0-99 
#define V_PITCH         5       ///< 1 char glyph, 2 chars degrees 0-99 
#define V_YAW           6       ///< 1 char glyph, 2 chars degrees 0-99 
#define V_LATITUDE      7       ///< 9 chars -90.00000 - 90.00000
#define V_LONGITUDE     8       ///< 10 chars -180.00000 - 180.00000
#define V_ALTITUDE      9       ///< 4 chars 0 - 9999
#define V_GROUNDSPEED   10      ///< 3 chars -99 - 999
#define V_GROUNDCOURSE  11      ///< 3 chars 0 - 359
#define V_P_ALTITUDE    12      ///< 4 chars 0-999
#define V_AIRSPEED      13      ///< 3 chars -99 - 999
#define V_COMMANDID     14      ///< 2 chars Current command index, i.e. waypoint number
#define V_FIX           15      ///< 4 chars 0.00 - 9.99
#define V_VLOCAL        16      ///< 4 chars 0.00 - 9.99
// Page Mission
#define V_WPNUMBER      17      ///< 2 chars
#define V_WPCOUNT       18      ///< 2 chars
#define V_WPTYPE        19      ///< 10 chars
#define V_BEARERR       20      ///< 3 chars - Bearing error between a/c and waypoint
#define V_WPDIST        21      ///< 3 chars - Distance to next waypoint
#define V_WPETA         22      ///< 3 chars - ETA at next waypoint
#define V_P1            23      ///< Holder for p1
#define V_P2            24      ///< Holder for p2
#define V_P3            21      ///< Holder for p3
#define V_P4            22      ///< Holder for p4
#define V_WPHNUMBER     25      ///< 2 chars
#define V_WPHCOUNT      26      ///< 2 chars
#define V_WPHTYPE       27      ///< 10 chars
#define V_HP1           28      ///< Holder for p1
#define V_HP2           29      ///< Holder for p2
#define V_HP3           30      ///< Holder for p3
#define V_HP4           31      ///< Holder for p4
#define V_HOMEDIST      31      ///< 4 chars - straight line distance from home
#define V_MAX           64      ///< maximum substitution code (must be multiple of 16)

// XXX might want to use uint32 and avoid the whole which-array-element question
#define AVAIL(_x)         (1 << ((_x) % 16))
//#define AVAIL_HEARTBEAT   (AVAIL(V_FLIGHTMODE) | AVAIL(V_VOLTAGE)   | AVAIL(V_VLOCAL))
#define AVAIL_SYS_STATUS  (AVAIL(V_FLIGHTMODE) | AVAIL(V_VOLTAGE)   | AVAIL(V_VLOCAL))
#define AVAIL_ATTITUDE    (AVAIL(V_ROLL)       | AVAIL(V_YAW)       | AVAIL(V_PITCH))
#define AVAIL_LOCATION    (AVAIL(V_LATITUDE)   | AVAIL(V_LONGITUDE) | AVAIL(V_ALTITUDE)  | AVAIL(V_GROUNDSPEED) | AVAIL(V_GROUNDCOURSE) | AVAIL(V_FIX))
#define AVAIL_GPSSTATUS   (AVAIL(V_SATS))
#define AVAIL_PRESSURE    (AVAIL(V_P_ALTITUDE) | AVAIL(V_AIRSPEED))
#define AVAIL_WP_CURR     (AVAIL(V_COMMANDID))
#define AVAIL_WP_COUNT    (AVAIL(V_WPCOUNT))
#define AVAIL_COMMAND     (AVAIL(V_WPNUMBER)   | AVAIL(V_WPTYPE)    | AVAIL(V_BEARERR)   | AVAIL(V_P1) | AVAIL(V_P2) | AVAIL(V_P3) | AVAIL(V_P4))
#define AVAIL_COMMANDHOME (AVAIL(V_WPHNUMBER)  | AVAIL(V_WPHCOUNT)  | AVAIL(V_WPHTYPE)   | AVAIL(V_HP1) | AVAIL(V_HP2) | AVAIL(V_HP3) | AVAIL(V_HP4))
//#define AVAIL_VALUE       (AVAIL(V_BEARERR))

// How many commands to remember:
// APM is set to send these on process must and mays, but we might not be interested in them yet
// The current command is specified in the heartbeat
#define CMDBUFSIZE 2

class Markup {
public:
        Markup() {_cmdbufpos=0;_voltage=0;_currWpt=10;_beepWpt=0;};

        void            emit(const prog_char *str);
        static void     message(void *arg, mavlink_message_t *buf); //, uint8_t messageID, uint8_t messageVersion
private:
        void            _substitute(uint8_t key);
        uint16_t        _subAttitude(float *value, uint8_t glyphNegative, uint8_t glyphPositive);
        uint16_t        _subYaw(float *value, uint8_t glyphNegative, uint8_t glyphPositive);
        bool            _available(uint8_t key);
        void            _message(mavlink_message_t *buf); //uint8_t messageID, uint8_t messageVersion,
        uint16_t        _availability[V_MAX / 16];

        // cached packets
        uint16_t _voltage;
        uint8_t _satcount;
        uint8_t _currWpt;
        bool	_beepWpt;
        mavlink_sys_status_t _syspacket;
        mavlink_attitude_t _attpacket;
//        mavlink_gps_raw_t _gpspacket;
//        uint8_t _num_sats;
//        mavlink_gps_status_t _gpsstatus;
//        mavlink_raw_pressure_t _prepacket;
        mavlink_waypoint_current_t _pktCurrWptNum;
//        mavlink_waypoint_count_t _pktWptCount;
        mavlink_waypoint_t _pktCurrWpt;
        mavlink_waypoint_t _pktHomeWpt;
        mavlink_waypoint_t _pktTempWpt;
/*
        struct msg_heartbeat    _heartbeat;
        struct msg_attitude     _attitude;
        struct msg_location     _location;
        struct msg_pressure     _pressure;
        struct msg_command_list _commandCurr;
        struct msg_command_list _commandBuf[CMDBUFSIZE];
        struct msg_command_list _commandHome;
        struct msg_value        _value;     // A value
        struct msg_value        _valueBerr; // Bearing error
        */
        uint8_t _cmdbufpos; // Position in the command buffer to write to next (we cycle through the buffer each time we get a command message)
        // ... more?
};

