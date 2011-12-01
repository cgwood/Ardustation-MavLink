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

/// @file       page.h
/// @brief      definitions for the menu page class and related subclasses

/// @name PageNames     Page names and unique codes
/// @brief      Pages must be assigned a unique code.  By convention,
///             pages < 100 are utility pages, and pages > 100 are part
///             of the application menu tree.  The page code 0 is reserved.
//@{
#define P_BANNER                1       ///< welcome banner
#define P_PICKER                2       ///< pick widget

#define P_SUMMARY               103
#define P_MISSION               106
#define P_SETUP                 104
#define P_ALERT                 105
#define P_PIDSETUP              108
#define P_NAVPIDSETUP           107
//#define P_PIDCONFIRM            109
//#define P_NAVPIDCONFIRM         110
#define P_APMSETTINGS           111
#define P_COMMANDS              112

#define P_MAIN                  P_SUMMARY       ///< this is the default/main page
//@}

/// How long to display the banner page at startup (ms)
#define PAGE_BANNER_TIMEOUT     1500

/// How long to display the confirmation page (ms)
#define PAGE_CONFIRM_TIMEOUT   10000

/// Minimum interval between redraw of status pages
#define STATUS_UPDATE_INTERVAL  250

// APM settings page vars
#define APMNAMEFIELDWIDTH 12
#define APMVALCOUNT 18

/// @class      Page
/// @brief      abstract class describing one page in the menu tree
///
class Page {
public:
        /// Event codes used by handleEvent and to explain to the superclass
        /// why we are leaving.
        enum event {
                NOP = 0,
                UP,             ///< cursor up
                DOWN,           ///< cursor down
                LEFT,           ///< cursor left
                RIGHT,          ///< cursor right
                OK,             ///< ok button
                CANCEL,         ///< cancel button
                TIMEOUT,        ///< timeout event
                NONE            ///< ignore this event
        };

        /// initialise the page system, draw the first page
        ///
        static void     begin();

        /// give the current page a chance to update
        ///
        static void     update();

        /// force the display to move to a given page
        ///     
        /// @param newPage      page number for the new page
        ///
        static void     forcePage(uint8_t newPage);

        /// send the current page an event
        ///
        /// @param eventCode    event to be sent to the page
        ///
        static void     handleEvent(Page::event eventCode);

protected:
        /// Notification from the page system that the page has been entered,
        /// implemented by the subclass.
        ///
        /// @param fromPage     the page that was just left
        ///
        virtual void    _enter(uint8_t fromPage) = 0;

        /// Periodic update call, implemented by the subclass.
        ///
        /// @todo rate limit this?
        ///
        virtual void    _update(void);

        /// Notification of an event, implemented by the subclass.
        ///
        /// @param eventCode    event code being delivered
        ///
        virtual void    _handleEvent(Page::event eventCode);

        /// Departure request from the page subclass.
        ///
        /// @param eventCode    The event causing the page to leave,
        ///                     used to decide which page to make current
        ///                     next.
        ///
        static void     _leave(Page::event reasonCode);

        /// Transition to a new page, either called by the subclass when
        /// it is doing explicit navigation (e.g. returning to the page that
        /// called it) or due to an external page force.
        ///
        /// @param newPage      page number for the new page    
        ///
        static void     _goPage(uint8_t newPage);

private:
        /// Accessor for the pageCode for pageIndex in the navigation map
        ///
        /// @param pageIndex    page for which code is to be fetched
        /// @returns            page code
        ///
        static uint8_t  _pageCode(uint8_t pageIndex);

        /// Accessor for the page class instance for pageIndex in the navigation map
        ///
        /// @param pageIndex    page for which this is to be fetched
        /// @returns            class instance pointer
        ///
        static Page     *_pageThis(uint8_t pageIndex);

        /// Accessor for the exitIndex page exit code for pageIndex in the navigation map
        ///
        /// @param pageIndex    page for which the exit direction is to be fetched
        /// @param exitIndex    exit index for which the exit direction is to be fetched
        /// @returns            page exit direction
        ///
        static uint8_t  _pageExit(uint8_t pageIndex, uint8_t exitIndex);
};

/// @class      PageText
/// @brief      A page displaying text
///
class PageText : public Page {
public:
        /// Constructor
        ///
        /// @param text         Text that the page will display
        /// @param timeout      If nonzero, the number of milliseconds that the
        ///                     page will wait before attempting to leave with a TIMEOUT.
        ///        
        PageText(const prog_char *text = NULL, unsigned long timeout = 0) :
                _text           (text),
                _timeout        (timeout) {};
protected:
        virtual void    _enter(uint8_t fromPage);
        virtual void    _update(void);

        /// Render the page
        ///
        virtual void    _render(void);

        /// text to be displayed by the page
        const prog_char *_text;

        /// optional timeout
        unsigned long   _timeout;

        /// time that the page was entered (for timeout purposes)
        unsigned long   _enterTime;
};

/// @class      PageStatus
/// @brief      A screen of dynamic text
///
class PageStatus : public PageText {
public:
        /// Constructor
        ///
        /// @param text         Text that the page will display
        /// @param timeout      If nonzero, the number of milliseconds that the
        ///                     page will wait before attempting to leave with a TIMEOUT.
        ///        
	PageStatus(const prog_char *text = NULL, unsigned long timeout = 0) : 
                PageText(text, timeout) {};

        /// A message delivery callback that can be used to force the page      
        /// to update.
        ///
        /// @param arg          Expected to be the class pointer for the instance interested
        ///                     in the message.
        /// @param messageID    Message ID of the message being received.
        /// @param messageVersion Message version of the message being received.
        /// @param buf          Pointer to the message payload.
        ///
        static void     notify(void *arg, mavlink_message_t *buf); // uint8_t messageID, uint8_t messageVersion,
protected:
        void            _update(void);
        void            _render(void);

        /// flag indicating that the data the page should be redrawn
        bool            _updated;

        /// timestamp of the last page redraw, used to rate-limit redraw operations
        unsigned long   _lastRedraw;
};

/// @class      PagePicker
/// @brief      A list picker
///
class PagePicker : public Page {
public:
        PagePicker() {};

        /// Configure the picker and run it.
        ///
        /// This call causes the current page to be forced away to the picker.  The current
        /// page will be re-entered when the user selects OK or Cancel in the picker.
        ///
        /// @param col          Display column at which the picker should draw data.
        ///                     Note that the 'pick active' cursor is drawn one column to the left.
        /// @param row          Row at which the picker should draw data.
        /// @param index        The current selection index.
        /// @param pickList     A newline-separated list of display values.
        ///
        void            pick(uint8_t col, uint8_t row, uint8_t index, const prog_char *pickList);

        /// Fetch the result of the most recent pick action.
        ///
        /// @returns            Selection index of the value picked.  If the user cancelled,
        ///                     the index will be the same as was paseed to ::pick.
        uint8_t         result(void);

        /// Print the display value from \a pickList for the given \a index.
        ///
        /// This method can be used by pages containing picked items to avoid having to
        /// parse the picklist themselves or keep two copies of the displayed values.
        ///
        /// @param index        The selection index to be printed.
        /// @param pickList     A newline-separated list of display values.
        ///
        static void     printValueForIndex(uint8_t index, const prog_char *pickList);

protected:
        void            _enter(uint8_t fromPage);
        void            _handleEvent(Page::event eventCode);

private:
        /// Update the display with the value for the current index.
        ///
        void            _draw();                

        uint8_t         _fromPage;      ///< page we entered from and will return to
        uint8_t         _index;         ///< currently selected value
        uint8_t         _default;       ///< _index on entry, for Cancel
        uint8_t         _row;           ///< row to draw at
        uint8_t         _col;           ///< column to draw at
        uint8_t         _longest;       ///< length of the longest item in the picklist
        uint8_t         _max;           ///< number of entries in the picklist - 1
        const prog_char *_pickList;     ///< reference to the pick list text
};

/// @class      pageSetup
/// @brief      The setup page
///
class PageSetup : public Page {
public:
        PageSetup() {};
protected:
        void            _enter(uint8_t fromPage);
        void            _handleEvent(Page::event eventCode);
private:
        /// current state of the internal navigation state machine
        uint8_t         _state;
};        

/// @class      pagePIDSetup
/// @brief      The PID setup page
///

class PagePIDSetup : public Page {
public:
        PagePIDSetup(const prog_char *textHeader, const uint8_t *pidTypes, const uint8_t *pid_p, const uint8_t *pid_i, const uint8_t *pid_d);
        /// A message delivery callback that can be used to force the page      
        /// to update.
        ///
        /// @param arg          Expected to be the class pointer for the instance interested
        ///                     in the message.
        /// @param messageID    Message ID of the message being received.
        /// @param messageVersion Message version of the message being received.
        /// @param buf          Pointer to the message payload.
        ///
        static void     notify(void *arg, mavlink_message_t *buf);
protected:
        void            _enter(uint8_t fromPage);
        void            _handleEvent(Page::event eventCode);
        void            _update(void);
        void            _render(void);
        void            _clearMarker(void);
        void            _paintMarker(void);
        void            _alterLocal(float alterMag);
        void            _voidLocal(void);
        void            _uploadConfirm(void);
        void            _uploadLocal(void);
        void            _message(void); //
private:
        /// current state of the internal navigation state machine
        /// 0         = Viewing
        /// 1 - 9     = Navigating
        /// 101 - 109 = Editing
        /// 201 - 209 = Uploading
        //mavlink_param_value_t _packet;
        uint8_t                 _state;
        /// Values onboard the aircraft
        //struct msg_pid          _pidlive[3];
        /// Local temp value
        //struct msg_pid          _pidtemp;
        
        /// Local editing temp value
        ///
        float _value_temp;
        
        /// Availability of pid values
        bool                             _avail[3];
        
protected:
        /// flag indicating that the data the page should be redrawn
        bool            _updated;

        /// timestamp of the last page redraw, used to rate-limit redraw operations
        unsigned long   _lastRedraw;

        /// text to be displayed for PID headings
        const prog_char *_textHeader;

        /// PID Types to be displayed (in same order as _textHeader)
        const uint8_t   *_pidTypes;

        /// PID indices (in same order as _textHeader)
        const uint8_t   *_pid_p;
        const uint8_t   *_pid_i;
        const uint8_t   *_pid_d;
}; 

/// @class      pageAPMSetup
/// @brief      The APM setup page
///

class PageAPMSetup : public Page {
public:
        PageAPMSetup(const prog_char *textHeader, const uint8_t *Types, const uint8_t *scale, const uint8_t *decPos);
        /// A message delivery callback that can be used to force the page      
        /// to update.
        ///
        /// @param arg          Expected to be the class pointer for the instance interested
        ///                     in the message.
        /// @param messageID    Message ID of the message being received.
        /// @param messageVersion Message version of the message being received.
        /// @param buf          Pointer to the message payload.
        ///
        static void     notify(void *arg, mavlink_message_t *buf);
protected:
        void            _enter(uint8_t fromPage);
        void            _handleEvent(Page::event eventCode);
        void            _update(void);
        void            _render(void);
        void            _clearMarker(void);
        void            _paintMarker(void);
        void            _alterLocal(float alterMag);
        void            _voidLocal(void);
        void            _uploadLocal(void);
        void            _uploadConfirm(void);
        void            _message(void);
private:
        /// current state of the internal navigation state machine
        uint8_t                     _state;
        
//        /// Values onboard the aircraft
//        struct msg_value   _value_live[APMVALCOUNT];
//
//        /// Local temp value
//        struct msg_value   _value_temp;
//

        /// Local editing temp value
        ///
        float	_value_temp;
        
        /// Temp variable for live value
        ///
        //float	_value_live;

        /// Availability of values
        bool	_avail[APMVALCOUNT];
        
        /// Position on the screen when scrolling
        /// Refers to first value out of four being displayed
        uint8_t	_stateFirstVal;
        
        
protected:
        /// flag indicating that the data the page should be redrawn
        bool            _updated;

        /// timestamp of the last page redraw, used to rate-limit redraw operations
        unsigned long   _lastRedraw;

        /// text to be displayed for APM settings, up to xxx characters
        const prog_char *_textHeader;

        /// Types to be displayed (in same order as _textHeader)
        const uint8_t   *_Types;
        
        /// Scaling for values, e.g. / 1000 is -3
        const uint8_t   *_scale;
        
        /// How many decimal places the value is given
        const uint8_t   *_decPos;
};        


/// @class      pageCommands
/// @brief      The Command sending page
///

class PageCommands : public Page {
public:
        PageCommands(const prog_char *textCommands);
//        /// A message delivery callback that can be used to force the page      
//        /// to update.
//        ///
//        /// @param arg          Expected to be the class pointer for the instance interested
//        ///                     in the message.
//        /// @param messageID    Message ID of the message being received.
//        /// @param messageVersion Message version of the message being received.
//        /// @param buf          Pointer to the message payload.
//        ///
//        static void     notify(void *arg, uint8_t messageID, uint8_t messageVersion, void *buf);
protected:
        void            _enter(uint8_t fromPage);
        void            _handleEvent(Page::event eventCode);
        void            _update(void);
        void            _render(void);
        void            _clearMarker(void);
        void            _paintMarker(void);
        void            _commandConfirm(void);
        void            _commandConfirmMessage(const prog_char *str);
        void            _commandSend(void);
//      void            _message(uint8_t messageID, uint8_t messageVersion, void *buf);
private:
        /// current state of the internal navigation state machine
        uint8_t                     _state;
        
        /// Position on the screen when scrolling
        /// Refers to first value out of four being displayed
        uint8_t                     _stateFirstVal;
        
        
protected:
        /// flag indicating that the data the page should be redrawn
        bool            _updated;

        /// timestamp of the last page redraw, used to rate-limit redraw operations
        unsigned long   _lastRedraw;

        /// text to be displayed for APM settings, up to xxx characters
        const prog_char *_textCommands;
};        
