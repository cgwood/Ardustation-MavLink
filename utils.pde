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

/// @file       utils.pde
/// @brief	utility classes and routines

void
PrintPSTR(const prog_char *c) {
  uint8_t i;
  i = pgm_read_byte_near(c++);
  while(0 != i) {
    Serial.print(i);
    i = pgm_read_byte_near(c++);
  }
}

void
lcdPrintPSTR(const prog_char *c) {
  uint8_t i;
  i = pgm_read_byte_near(c++);
  while(0 != i) {
    lcd.write(i);
    i = pgm_read_byte_near(c++);
  }
}

const prog_char *
Stringtab::lookup(int index)
{
        const prog_char *p;
        char            c;

        p = _table;
        while (index) {
                c = pgm_read_byte_near(p++);
                if (0 == c) {
                        index--;
                        if (0 == pgm_read_byte_near(p)) {
                                p = NULL;
                                break;
                        }
                }
        }
        return(p);
}
                
                
