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

/// @file       zMain.pde
/// @brief      top-level application logic

////////////////////////////////////////////////////////////////////////////////
// Startup initialisation
////////////////////////////////////////////////////////////////////////////////

extern "C" {
/// external reference to the end of the BSS for use in checking memory consumption
extern int __bss_end;
}

void setup()
{
        // Initialise the display driver object
        lcd.begin(LCD_COLUMNS, LCD_ROWS);

        // configure the programmable characters we'll be using
        lcd.createChar(LCD_CHAR_ROLL_LEFT,  const_cast<uint8_t *>(lcdCharRollLeft));
        lcd.createChar(LCD_CHAR_ROLL_RIGHT, const_cast<uint8_t *>(lcdCharRollRight));
        lcd.createChar(LCD_CHAR_UP_ARROW,   const_cast<uint8_t *>(lcdCharUpArrow));
        lcd.createChar(LCD_CHAR_DOWN_ARROW, const_cast<uint8_t *>(lcdCharDownArrow));
        lcd.createChar(LCD_CHAR_MINUS_ONE,  const_cast<uint8_t *>(lcdCharMinusOne));
        lcd.createChar(LCD_CHAR_BATTERY,    const_cast<uint8_t *>(lcdCharBattery));
        lcd.createChar(LCD_CHAR_MODIFY,     const_cast<uint8_t *>(lcdCharModify));

        // Set up the keypad
        keypad.begin();

        // Set up the rotary encoder interrupt
        PCMSK1 |= ((1 << PCINT9) | (1 << PCINT10));
        PCICR |= (1 << PCIE1);

        // load the NVRAM
        nvram.load();

        // get us a link
        Serial.begin(nvram.nv.serialSpeed * 100.0);

        // free memory check
        {
                int     freemem;
                freemem = ((int)&freemem) - ((int)&__bss_end);
                //Serial.print("Free memory ");
                PrintPSTR(PSTR("Free memory "));
                Serial.println(freemem);
        }
        
        // Set the waypoint count to zero
        mavWptCount.count = 0;
        
        // Set the home position to zero
        gcsLat = 0;
        gcsLon = 0;
        gcsAlt = 0;


//        uint8_t i;
//        float param_value;
//
//        PrintPSTR(PSTR("Parameter values: \n"));
//        for (i=0;i<Parameters::COUNT;i++) {
//          nvram.load_param(&i,&param_value);
//          Serial.println(param_value);
//        }
//
//        Serial.println(Parameters::COUNT);
        
        // start the startup tune
        beep.play(BEEP_STARTUP);

        // Start the menu system
        Page::begin();
}

////////////////////////////////////////////////////////////////////////////////
// One pass through the top-level loop
////////////////////////////////////////////////////////////////////////////////
void loop()
{
        // do comms processing
        comm.update();

        // handle button events
        Page::handleEvent((Page::event)keypad.pressed());

        // and update the current page
        Page::update();

        // update the link status bug & alarm
        watchdog.check();

        // update the antenna tracker
//        tracker.update();

        // update the currently-playing tune
        beep.update();
}

