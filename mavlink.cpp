// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: t -*-
//
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

/// @file       mavlink.pde
/// @brief      Implementation of the ArduPilot Mega binary communications
///		library.

#include "mavlink.h"
#include "WProgram.h"

/// inter-byte timeout for decode (ms)
#define DEC_MESSAGE_TIMEOUT     1000

MAVComm::MAVComm(const MAVComm::MessageHandler *handlerTable,
                 Stream *interface) :
	_handlerTable(handlerTable)
{
	init(interface);
};

void
MAVComm::init(Stream *interface)
{
	_interface = interface;
}

void
MAVComm::update(void)
{
	  mavlink_message_t msg;
	  mavlink_status_t status;
  // process received bytes
  while(_interface->available())
  {
      // receive new packets
      
      uint8_t c = _interface->read();
      
      // Try to get a new message 
      if(mavlink_parse_char(0, c, &msg, &status)) {
		_handleMessage(&msg);
//        if (msg.msgid == MAVLINK_MSG_ID_PARAM_VALUE) {
//          _interface->print("Message received ");
//          _interface->println(msg.msgid,HEX);
//        }
      }
  }
}

#define MSG_ANY  1010
#define MSG_NULL 9090

void
MAVComm::_handleMessage(mavlink_message_t* msg)
{
	uint8_t         tableIndex;
	// call any handler interested in this message
	for (tableIndex = 0; tableIndex < 23; tableIndex++) { //MSG_NULL != _handlerTable[tableIndex].messageID; tableIndex++) {
		if(_handlerTable[tableIndex].messageID == MSG_ANY ||
		   _handlerTable[tableIndex].messageID == msg->msgid ) {
			_handlerTable[tableIndex].handler(_handlerTable[tableIndex].arg, msg); //msg->msgid, 1,
								
			/*	// This is all for acknowledgements, comment out for now
			// don't acknowledge an acknowledgement, will echo infinitely
			// also don't acknowledge if we are a GCS
			if (msg->msgid != MSG_ACKNOWLEDGE && _isAirborne == 1) 
				send_msg_acknowledge(msg->msgid, _decoderSumA, _decoderSumB);
			// Always acknowledge a critical alert (although this is acknowledging all status messages)
			else if (msg->msgid == MSG_STATUS_TEXT)
				send_msg_acknowledge(msg->msgid, _decoderSumA, _decoderSumB);
			*/
		} else {
			// XXX should send a NAK of some sort here
		}
	}
}

void
MAVComm::request()
{
	// Request data streams
	mavlink_message_t msg;

//	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_RAW_SENSORS, 2, 1);
//	this->send(&msg);
	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_EXTENDED_STATUS, 2, 1);
	this->send(&msg);
//	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_RC_CHANNELS, 2, 1);
//	this->send(&msg);
//	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_RAW_CONTROLLER, 2, 1);
//	this->send(&msg);
//	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, 5, 2, 1);
//	this->send(&msg);
//	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_POSITION, 2, 1);
//	this->send(&msg);
	mavlink_msg_request_data_stream_pack(0xFF, 0xFA, &msg, 1, 1, MAV_DATA_STREAM_EXTRA1, 2, 1);
	this->send(&msg);
}

void 
MAVComm::send(mavlink_message_t* msg)
{
  _interface->write(MAVLINK_STX);
  _interface->write(msg->len);
  _interface->write(msg->seq);
  _interface->write(msg->sysid);
  _interface->write(msg->compid);
  _interface->write(msg->msgid);
  for(uint16_t i = 0; i < msg->len; i++)
  {
    _interface->write(msg->payload[i]);
  }
//  _interface->write(msg->checksum);
  _interface->write(msg->ck_a);
  _interface->write(msg->ck_b);
}
