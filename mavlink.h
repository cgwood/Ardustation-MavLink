// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: t -*-
//
// Copyright (c) 2010 Michael Smith. All rights reserved.
// Modified 2011 By Colin G http://www.diydrones.com/profile/ColinG
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//	  notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//	  notice, this list of conditions and the following disclaimer in the
//	  documentation and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.	IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//
// Modified by Colin for Mavlink usage

/// @file		mavlink.h
/// @brief		Definitions for the ArduPilot Mega mavlink communications
///				library..

#define MSG_ANY  1010
#define MSG_NULL 9090

#include <string.h>
#include <inttypes.h>
#include <GCS_MAVLink.h>
#include "WProgram.h"

// data streams active and rates
#define MAV_DATA_STREAM_POSITION_ACTIVE 1
#define MAV_DATA_STREAM_RAW_SENSORS_ACTIVE 1
#define MAV_DATA_STREAM_EXTENDED_STATUS_ACTIVE 1
#define MAV_DATA_STREAM_RC_CHANNELS_ACTIVE 1
#define MAV_DATA_STREAM_RAW_CONTROLLER_ACTIVE 0
#define MAV_DATA_STREAM_EXTRA1_ACTIVE 1

// update rate is times per second (hz)
#define MAV_DATA_STREAM_POSITION_RATE 5
#define MAV_DATA_STREAM_RAW_SENSORS_RATE 5
#define MAV_DATA_STREAM_EXTENDED_STATUS_RATE 5
#define MAV_DATA_STREAM_RAW_CONTROLLER_RATE 5
#define MAV_DATA_STREAM_RC_CHANNELS_RATE 5
#define MAV_DATA_STREAM_EXTRA1_RATE 5

///
/// @class		MAVComm
/// @brief		Class providing protocol en/decoding services for the ArduPilot
///				Mega mavlink telemetry protocol.
///
/// The protocol definition, including structures describing
/// messages, MessageID values and helper functions for sending
/// and unpacking messages are automatically generated.
///
/// See protocol/protocol.def for a description of the message
/// definitions, and protocol/protocol.h for the generated
/// definitions.
///
/// Protocol messages are sent using the send_* functions defined in
/// protocol/protocol.h, and handled on reception by functions defined
/// in the handlerTable array passed to the constructor.
///
class MAVComm {
public:
	struct MessageHandler;

	//////////////////////////////////////////////////////////////////////
	/// Constructor.
	///
	/// @param handlerTable			Array of callout functions to which
	///								received messages will be sent.	 More than
	///								one handler for a given messageID may be
	///								registered; handlers are called in the order
	///								they appear in the table.  A single handler
	///								may be registered for more than one message,
	///								as the message ID is passed to the handler
	///								when it is received.
	///
	/// @param interface			The stream that will be used
	///								for telemetry communications.
	///
	/// @param rxBuffSize		    Size of receive buffer allocated by interface.
	///								This is used to warn for buffer overflow.
	///

	///
	MAVComm(const MessageHandler *handlerTable,
			Stream *interface = NULL);

	///
	/// Optional initialiser.
	///
	/// If the interface stream isn't known at construction time, it
	/// can be set here instead.
	///
	/// @param interface			The stream that will be used for telemetry
	///								communications.
	///
	void			init(Stream *interface);

private:
      //mavlink_message_t _msg;
      //mavlink_status_t _status;
/*
	/// OTA message header
	struct MessageHeader {
        uint8_t         length;
        uint8_t         messageID;
        uint8_t         messageVersion;
	};

	/// Incoming header/packet buffer
	/// XXX we could make this smaller
	union {
		uint8_t					bytes[0];
		MessageHeader			header;
		uint8_t					payload[256];
	} _decodeBuf;
	
	/// Boolean, is the library on the aircraft of the ground control station
	bool _isAirborne;
	*/


//	  mavlink_message_t msg;
//	  mavlink_status_t status;
public:

	//////////////////////////////////////////////////////////////////////
	/// Message reception callout descriptor
	///
	/// An array of these handlers is passed to the constructor to delegate
	/// processing for received messages.
	///
	struct MessageHandler {
		uint8_t		messageID;						///< messageID for which the handler will be called
		void			(* handler)(void *arg,
//									uint8_t messageId,
//									uint8_t messageVersion,
									mavlink_message_t *messageData); ///< function to be called
									//mavlink_message_t* msg); ///< function to be called
		void			*arg;							///< argument passed to function
	};

	//////////////////////////////////////////////////////////////////////
	/// @name		Decoder interface
	//@{

	/// Consume bytes from the interface and feed them to the decoder.
	///
	/// If a packet is completed, then any callbacks associated
	/// with the packet's messageID will be called.
	///
	/// If no bytes are passed to the decoder for a period determined
	/// by DEC_MESSAGE_TIMEOUT, the decode state machine will reset
	/// before processing the next byte.  This can help re-synchronise
	/// after a link loss or in-flight failure.
	///

	void					update(void);
	void					send(mavlink_message_t* msg);
        void  request(void);

	//@}

private:
	const MessageHandler	*_handlerTable; ///< callout table
	Stream					*_interface;	///< Serial port we send/receive using.

	/// Send bytes as part of a message.
	///
	/// @param	bytes			Pointer to the byte(s) to send.
	/// @param	count			Count of bytes to send.
	void					_send(const void *bytes, uint8_t count);
	void					_handleMessage(mavlink_message_t* msg);
};
