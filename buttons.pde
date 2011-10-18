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

/// @file       buttons.pde
/// @brief      Driver for charlieplexed buttons
/// @discussion Supports debouncing and button chords.
/// @note       Due the pulldowns on the ArduStation board, this implementation
///             doesn't use the Arduino's internal pullups.

/// Pins to be driven/scanned.
/// The pin sequence is almost completely repeated to avoid
/// having to implement wraparound logic.
///
uint8_t buttonPins[] = {PB_PIN0, PB_PIN1, PB_PIN2, PB_PIN0, PB_PIN1};

/// Count of actual buttons, derived from the buttonPins array
#define BUTTON_PIN_COUNT    ((sizeof(buttonPins) / 2) + 1)

/// Each row corresponds to a driven pin.  Each column corresponds to
/// a pin forward in the buttonPins array to be scanned, and gives
/// the scan code to return if the scan shows a connection.
///
uint8_t buttonScanPins[BUTTON_PIN_COUNT][BUTTON_PIN_COUNT - 1] = {
        { B_UP,     B_DOWN  },
        { B_CANCEL, B_OK    },
        { B_LEFT,   B_RIGHT }
};

/// @note we depend on the pins otherwise being left alone.
void
Buttons::begin(void)
{
        uint8_t i;

        // tristate all of the pins
        for (i = 0; i < BUTTON_PIN_COUNT; i++) {
                pinMode(buttonPins[i], INPUT);
                digitalWrite(buttonPins[i], LOW);
        }
}

// Scan the charlieplex, look for a button that is pressed
uint8_t
Buttons::_scan(void)
{
        uint8_t drivePin, sniffPin;
        uint8_t scanCode;

        scanCode = 0;

        // iterate driven pins
        for (drivePin = 0; drivePin < BUTTON_PIN_COUNT; drivePin++) {
                // drive the pin high
                pinMode(buttonPins[drivePin], OUTPUT);
                digitalWrite(buttonPins[drivePin], HIGH);

                // iterate sniffable pins
                for (sniffPin = (drivePin + BUTTON_PIN_COUNT - 1); sniffPin > drivePin; sniffPin--) {
                        // sniff the pin to see if it is pulled high by the diode/switch
                        // to the driven pin
                        if (HIGH == digitalRead(buttonPins[sniffPin])) {
                                scanCode = buttonScanPins[drivePin][sniffPin - drivePin - 1];
                                break;
                        }
                }

                // release the driven pin
                pinMode(buttonPins[drivePin], INPUT);
                digitalWrite(buttonPins[drivePin], LOW);

                // did we find a button closed?
                if (0 != scanCode)
                        break;
        }

        return(scanCode);
}

// Primitive debounced button scan
uint8_t
Buttons::_scanDebounced(void)
{
        unsigned long   scanStart;
        uint8_t         scanCode;

        // get initial state, bail immediately if no buttons pressed
        if (0 == (scanCode = _scan()))
                return(0);

        // note that we can't just pick a deadline due to clock wrap
        scanStart = millis();

        // ensure we check at least twice
        /// @bug this blocks - should save state over multiple calls
        do {
                // if the state changed, bail
                if (scanCode != _scan())
                        return(0);
        } while ((millis() - scanStart) < BUTTON_DEBOUNCE_TIMER);

        return(scanCode);
}

uint8_t
Buttons::pressed(void)
{
         uint8_t         newButton;
        
        // find what is currently being pressed
        newButton = _scanDebounced();

        // If the new state differs from the previous state, the
        // new state is interesting and we will report it.
        if (newButton != _currentButton) {
                _currentButton = newButton;

                // if we are reporting an actual button press, give
                // audio feedback
                if (0 != newButton)
                        beep.play(BEEP_KEY);

                return(newButton);
        }

        // State has not changed, report "no button press"
        /// @note implement auto-repeat here
        return(0);
}

