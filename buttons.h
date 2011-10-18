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

/// @file       buttons.h
/// @brief      definitions for keypad support

/// @name       Button name to bit coding.
//@{
#define B_UP            Page::UP
#define B_DOWN          Page::DOWN
#define B_LEFT          Page::LEFT
#define B_RIGHT         Page::RIGHT
#define B_OK            Page::OK
#define B_CANCEL        Page::CANCEL
//@}

/// Debounce timer (milliseconds)
#define BUTTON_DEBOUNCE_TIMER   10

/// @class      Buttons
/// @brief      Keypad driver
class Buttons {
public:
        Buttons() {};

        /// Perform one-time initialisation for the keypad.
        ///
        void            begin(void);

	/// Check for a button press.
	///
	/// Button presses are debounced.  The button is considered 'pressed'
        /// at the end of the debounce period, and does not repeat.
        ///
        /// @return     0       No (new) button has been pressed
        /// @returns            One of the B_* codes defined above.
        ///
        uint8_t         pressed(void);

private:
        /// Scan the button matrix looking for a button that is pressed.
        ///
        /// @return     0       No button is currently pressed
        /// @returns            The B_* code for the first pressed button.
        uint8_t         _scan(void);

        /// Debounce the button matrix scan.
        ///
        /// @return     0       No button has been constantly pressed for
        ///                     the debounce period.
        /// @returns            The B_* code for a debounced keypress.
        ///
        /// @bug this method blocks; it should use external state and be polled
        uint8_t         _scanDebounced(void);

        /// The current/last button reported
        uint8_t         _currentButton;
};

