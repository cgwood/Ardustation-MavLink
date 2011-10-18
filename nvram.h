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

/// @file       nvram.h
/// @brief      non-volatile memory

/// Simple non-volatile memory support.
///
class NVRAM {
public:
        NVRAM() {};

        /// Load all variables from NVRAM
        ///
        void    load(void);

        /// Load parameters from NVRAM
        ///
        void    load_param(uint8_t *param_id, float *param_value);

        /// Save all variables to NVRAM
        ///
        void    save(void);

        /// Save parameters to NVRAM
        ///
        void    save_param(uint8_t *param_id, float *param_value);

        /// Definition of the load/save area
        ///
        struct nv_data {
                uint16_t        serialSpeed;
                uint16_t        lowVoltage;
                uint32_t        savedLatitude;
                uint32_t        savedLongitude;
                uint8_t         muted;
                uint8_t         packetSounds;
        };

        struct nv_data  nv;             ///< saved variables

private:
        /// Read bytes from NVRAM
        ///
        /// @param address      offset in NVRAM to read from
        /// @param size         count of bytes to read
        /// @param value        buffer to read into
        ///
        void            _loadx(uint8_t address, uint8_t size, void *value);

        /// Write bytes to NVRAM
        ///
        /// @param address      offset in NVRAM to write to
        /// @param size         count of bytes to write
        /// @param value        buffer to write from
        ///
        void            _savex(uint8_t address, uint8_t size, void *value);
};

