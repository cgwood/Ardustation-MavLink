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

/// @file       ArduStationM.pde
/// @brief      Toplevel module for the ArduStationM firmware.

#include <stddef.h>
#include <inttypes.h>
#include <avr/pgmspace.h>
#include <LiquidCrystal.h>
#include <EEPROM.h>
#include <GCS_MAVLink.h>
#include "mavlink.h"
#include "beep.h"
#include "buttons.h"
#include "hardware.h"
#include "markup.h"
#include "nvram.h"
#include "page.h"
#include "utils.h"
#include "watchdog.h"
#include "params.h"

#define AIRSPEEDSENSOR 0			// APM has an airspeed sensor yes/no (alters PID page)
#define SAVEMEM 1					// Save Flash space with short confirmation messages
#define PERFMON 0					// Performance monitoring (debugging)
#define DEBUGMAVLINK 0				// Prints to serial when messages are received, and their ID
#define USETRACKER 0				// Use antenna tracking, 1=yes, 0=no (currently unusable)

// Update rate for streams
#define MAV_ATTITUDE_STREAM_RATE 4	// How many times per second the aircraft's attitude is updated
#define MAV_STREAM_RATE 4			// How many times per second everything else is updated

//#if USETRACKER == 1
//#include <Servo.h>
//#include "tracker.h"
//Tracker			tracker;						///< Antenna tracker
//#endif

// currently unused
//#include "alert.h"

#define MSG_ANY  1010
#define MSG_NULL 9090

#define LCD_COLUMNS    20                       ///< standard display for ArduStation
#define LCD_ROWS        4                       ///< standard display for ArduStation
LiquidCrystal   lcd(2, 3, 4, 5, 6, 7, 8);       ///< display driver instance

/// @name       Custom LCD characters
//@{
#define LCD_CHAR_LINK           0
#define LCD_CHAR_ROLL_LEFT      1
#define LCD_CHAR_ROLL_RIGHT     2
#define LCD_CHAR_UP_ARROW       3
#define LCD_CHAR_DOWN_ARROW     4
#define LCD_CHAR_MINUS_ONE      5
#define LCD_CHAR_BATTERY        6
#define LCD_CHAR_MODIFY         7

const uint8_t   lcdCharRollLeft[]  = {0x00, 0x0e, 0x11, 0x11, 0x14, 0x0c, 0x1c, 0x00};
const uint8_t   lcdCharRollRight[] = {0x00, 0x0e, 0x11, 0x11, 0x05, 0x06, 0x07, 0x00};
const uint8_t   lcdCharUpArrow[]   = {0x04, 0x0e, 0x15, 0x04, 0x04, 0x04, 0x00, 0x00};
const uint8_t   lcdCharDownArrow[] = {0x00, 0x04, 0x04, 0x04, 0x15, 0x0e, 0x04, 0x00};
const uint8_t   lcdCharMinusOne[]  = {0x06, 0x1a, 0x02, 0x07, 0x00, 0x00, 0x00, 0x00};
const uint8_t   lcdCharBattery[]   = {0x0e, 0x1f, 0x11, 0x17, 0x1d, 0x11, 0x1f, 0x00};
const uint8_t   lcdCharModify[]    = {0x08, 0x0c, 0x0e, 0x0f, 0x0e, 0x0c, 0x08, 0x00};
//@}

Buttons         keypad;                         ///< keypad driver
Watchdog        watchdog;                       ///< message receipt watchdog
NVRAM           nvram;                          ///< NVRAM driver
Markup          markup;                         ///< page markup engine
Beep            beep(TONE_PIN);                 ///< tune machine
Parameters      params;                         ///< parameter access

PagePicker      pickerPage;                     ///< picker widget
PageSetup       setupPage;                      ///< setup page
//PageAlert       alertPage;                      ///< alert message viewer

mavlink_waypoint_count_t mavWptCount;        ///< Number of waypoints
mavlink_gps_raw_t        mavGPS;             ///< Current location info
float           gcsLat;                      ///< Latitude of GCS
float           gcsLon;                      ///< Longitude of GCS
float           gcsAlt;                      ///< Altitude of GCS


// APM Settings page
//(const prog_char *textHeader, const uint8_t *Types, const uint8_t *scale, const uint8_t *decPos);
//                                      "123456789012"
PROGMEM const prog_char APMSettings[] = "Loiter rad\n"
                                        "Waypoint rad\n"
                                        "xtrack gain\n"
                                        "xtrack angle\n"
                                        "Cruise speed\n"
                                        "ASP FBW min\n"
										"ASP FBW max\n"
										"Throttle min\n"
										"Throttle max\n"
										"Throt cruise\n"
										"Roll limit\n"
										"Pitch down\n"
										"Pitch up\n"
										"RTL Altitude\n"
                                        "Pitch2Thrtl\n"
										"Thrtl2Pitch\n"
										"Pitch Comp\n"
										"Log bitmask\n";
//"Pitch Comp\n"
//                                        "Log At. Fast\n"
//                                        "Log At. Med\n"
//                                        "Log GPS\n"
//                                        "Log Perf.\n"
//                                        "Log CtrlTune\n"
//                                        "Log NavTune\n"
//                                        "Log Mode\n"
//                                        "Log Raw\n"
//                                        "Log Commands\n";


//Parameters::ARSP2PTCH_P,
//Parameters::ARSP2PTCH_I,
//Parameters::ARSP2PTCH_D,
//Parameters::ARSP2PTCH_IMAX,
//Parameters::ENRGY2THR_P,
//Parameters::ENRGY2THR_I,
//Parameters::ENRGY2THR_D,
//Parameters::ENRGY2THR_IMAX,

const uint8_t APMSettingsIDs[] =
{
	Parameters::WP_LOITER_RAD,
	Parameters::WP_RADIUS,
	Parameters::XTRK_GAIN_SC,
	Parameters::XTRK_ANGLE_CD,
	Parameters::TRIM_ARSPD_CM,
	Parameters::ARSPD_FBW_MIN,
	Parameters::ARSPD_FBW_MAX,
	Parameters::THRTL_MIN,
	Parameters::THRTL_MAX,
	Parameters::THRTL_CRUISE,
	Parameters::ROLL_LIM,
	Parameters::PITCH_MIN,
	Parameters::PITCH_MAX,
	Parameters::RTL_ALT,
	Parameters::KFF_PTCH2THR,
	Parameters::KFF_THR2PTCH,
	Parameters::KFF_PTCHCOMP,
	Parameters::LOG_BITMASK,
};
const uint8_t APMSettingsScale[] = { 0,    0,    2,    2,    2,    0,    0,    0,    0,    0,    2,    2,    2,    2,    0,    0,    0,    0}; // *10^(-x)
const uint8_t APMSettingsDP[] =    { 0,    0,    2,    1,    1,    0,    0,    0,    0,    0,    1,    1,    1,    0,    2,    2,    2,    0}; // 99 in both denotes boolean
//const uint8_t APMSettingsIDs[] = {0x27, 0x26, 0x2d, 0x2e, 0x30, 0x31, 0x32, 0x34, 0x35, 0x36, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58};
//const uint8_t APMSettingsScale[] = { 0,    0,    2,    2,    2,    0,    0,    3,    3,    3,   99,   99,   99,   99,   99,   99,   99,   99,   99}; // *10^(-x)
//const uint8_t APMSettingsDP[] =    { 0,    0,    2,    1,    1,    0,    0,    2,    2,    2,   99,   99,   99,   99,   99,   99,   99,   99,   99}; // 99 in both denotes boolean
                                        
PageAPMSetup   APMPage(APMSettings, APMSettingsIDs, APMSettingsScale, APMSettingsDP);

/// The PID Setup page for Roll Pitch and Yaw
// Header format                            11111 22222 33333
PROGMEM const prog_char pidHeaderRPY[] = "   Roll Pitch  Yaw";
const uint8_t   pid_p[]  = {Parameters::SROLLP, Parameters::SPITP, Parameters::SYAWP};
const uint8_t   pid_i[]  = {Parameters::SROLLI, Parameters::SPITI, Parameters::SYAWI};
const uint8_t   pid_d[]  = {Parameters::SROLLD, Parameters::SPITD, Parameters::SYAWD};
const uint8_t   pidTypesRPY[] = {0x00, 0x01, 0x02};  ///< PID id numbers as per protocol
PagePIDSetup    PidPage(pidHeaderRPY,pidTypesRPY,pid_p,pid_i,pid_d);   ///< PID Setup page for Roll Pitch and Yaw


/// The PID Setup page for Nav Roll Nav Pitch ASP and Energy/Altitude
// Header format                            11111 22222 33333
PROGMEM const prog_char pidHeaderNav[] = "  NvRol NvPit ThAlt";
const uint8_t   nav_pid_p[]  = {Parameters::NROLLP, Parameters::NPITP, Parameters::NYAWP};
const uint8_t   nav_pid_i[]  = {Parameters::NROLLI, Parameters::NPITI, Parameters::NYAWI};
const uint8_t   nav_pid_d[]  = {Parameters::NROLLD, Parameters::NPITD, Parameters::NYAWD};
const uint8_t   pidTypesNav[] = {0x03, 0x04, 0x06};     ///< PID id numbers as per protocol
PagePIDSetup    NavPidPage(pidHeaderNav,pidTypesNav,nav_pid_p,nav_pid_i,nav_pid_d);   ///< PID Setup page for Navigation


#if USETRACKER == 0
/// the PID / APM setup page confirmation message
PROGMEM const prog_char confirmMessage[] =
      //01234567890123456789
	   "\nPress OK to continue";
//       "This will apply the\n"
//       "changes made to the\n"
//       " settings, press\n"
//       "  OK to Upload";
//PageText        PidConfirmPage(confirmMessage, PAGE_CONFIRM_TIMEOUT);    ///< PID Upload confirmation page


/// the about/copyright message
PROGMEM const prog_char aboutMessage[] =
       "  ArduPilot Mega\n"
       "  groundstation\n"
       "  Ver. 29 Oct 2011";
#else
/// the PID / APM setup page confirmation message
PROGMEM const prog_char confirmMessage[] =
      //01234567890123456789
       "\nPress OK to confirm.";
//PageText        PidConfirmPage(confirmMessage, PAGE_CONFIRM_TIMEOUT);    ///< PID Upload confirmation page


/// the about/copyright message
PROGMEM const prog_char aboutMessage[] =
       "  Welcome";
#endif

/// banner displayed at startup
PageText        welcomePage(aboutMessage, PAGE_BANNER_TIMEOUT);

/// Format string for the summary page - see the markup module for
/// a discussion of these codes.
PROGMEM const prog_char summaryPageFormat[] =
        "\x81   \x6\x83V\n"
//		" \x84 \x85 \x8f \x82\n"
		"\x84 \x85 \x86 \x8f\n"
        " \x89m  \x8ams\x5  \x8b\x80\xdf\n"
        "\x87 \x88\n"
        "";
PageStatus      summaryPage(summaryPageFormat); ///< a page with some data


/// Format string for Mission page
PROGMEM const prog_char MissionPageFormat[] =
        "\x81   \x6\x83V\n"
        "\x93  #\x8e/\x92\n"
        "Dist \x95m  ETA \x96s\n"
        "Home \x9fm Vel\x8ams\x5\n"
        "";
//PROGMEM const prog_char MissionPageFormat[] =
//        "\x81   #\x8e/\x9a\n"
//        "\x93  ETA \x96s\n"
//        "Dist \x95m BRNG\x94\x80\xdf\n"
//        "Home \x9fm Vel\x8ams\x5\n"
//        "";
PageStatus      MissionPage(MissionPageFormat); ///< a page with some data

       
PROGMEM const prog_char textCommands[] =
		  //123456789012345678
		   "Restart Mission\n"
	       "Request Parameters\n"
		   "Stop Data Stream\n"
	       "Re-request Stream\n"
	       "Set GCS Home\n"
		   "Reset UAV Home";//\n"
       //"Fly in a square";
PageCommands    CommandsPage(textCommands);     ////< a page for sending commands to the APM

/// Message handlers
///
/// Use MSG_ANY to cause a handler to be called for every packet.
/// Use MSG_HEARTBEAT to cause a handler to be called on a regular basis
/// while we have a link to the controller.
/// StatusPage::notify should be called against every page that has
/// contents interested in the packet for the most rapid update rate.
///
MAVComm::MessageHandler msgHandlers[] = {
        // the watchdog should see every packet
        {MAVLINK_MSG_ID_HEARTBEAT,       Watchdog::reset,        &watchdog},

        // Markup wants to see any packet that it may need later to
        // mark up a page.
//        {MAVLINK_MSG_ID_HEARTBEAT,   Markup::message,   &markup},
        {MAVLINK_MSG_ID_ATTITUDE,         Markup::message,   &markup},
        {MAVLINK_MSG_ID_GPS_RAW,          Markup::message,   &markup},
        {MAVLINK_MSG_ID_GPS_STATUS,       Markup::message,   &markup},
        {MAVLINK_MSG_ID_SYS_STATUS,       Markup::message,   &markup},
        {MAVLINK_MSG_ID_RAW_PRESSURE,     Markup::message,   &markup},
        {MAVLINK_MSG_ID_COMMAND,          Markup::message,   &markup},
        {MAVLINK_MSG_ID_WAYPOINT_CURRENT, Markup::message,   &markup},
        {MAVLINK_MSG_ID_WAYPOINT_COUNT,   Markup::message,   &markup},
        {MAVLINK_MSG_ID_WAYPOINT,         Markup::message,   &markup},
//        {MAVLINK_MSG_ID_WAYPOINT,         Tracker::notify,   &tracker},

        // Messages that cause the summary page to update.
        {MAVLINK_MSG_ID_HEARTBEAT,   PageStatus::notify,     &summaryPage},
        {MAVLINK_MSG_ID_ATTITUDE,    PageStatus::notify,     &summaryPage},
        {MAVLINK_MSG_ID_GPS_RAW,     PageStatus::notify,     &summaryPage},
        {MAVLINK_MSG_ID_GPS_STATUS,  PageStatus::notify,     &summaryPage},
        {MAVLINK_MSG_ID_SYS_STATUS,  PageStatus::notify,     &summaryPage},

        // Messages that cause the parameter pages to update
        {MAVLINK_MSG_ID_PARAM_VALUE, PagePIDSetup::notify,   &PidPage},
        {MAVLINK_MSG_ID_PARAM_VALUE, PagePIDSetup::notify,   &NavPidPage},
        {MAVLINK_MSG_ID_PARAM_VALUE, PageAPMSetup::notify,   &APMPage},

        // Messages that cause the parameter storage to update
        {MAVLINK_MSG_ID_PARAM_VALUE, Parameters::notify,     &params},

        // Messages that cause the Mission page to update 
        {MAVLINK_MSG_ID_HEARTBEAT,        PageStatus::notify,     &MissionPage},
        {MAVLINK_MSG_ID_COMMAND,          PageStatus::notify,     &MissionPage},
        {MAVLINK_MSG_ID_WAYPOINT_CURRENT, PageStatus::notify,     &MissionPage},
        {MAVLINK_MSG_ID_WAYPOINT_COUNT,   PageStatus::notify,     &MissionPage},
        {MAVLINK_MSG_ID_WAYPOINT,         PageStatus::notify,     &MissionPage},
        {MAVLINK_MSG_ID_GPS_RAW,          PageStatus::notify,     &MissionPage},
        // Messages that cause the alert page to update
//        {MAVLINK_MSG_ID_SYS_STATUS, PageAlert::notify,     &alertPage},
        {MSG_NULL,      NULL}
};
MAVComm         comm(msgHandlers, &Serial);              ///< packet processor instance

