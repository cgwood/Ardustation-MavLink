// Created 2011 By Colin G http://www.diydrones.com/profile/ColinG

// This file is no longer used, but was created to define variables to ease the transition between BinComm and MavLink

struct msg_status_text {
	uint8_t severity;
	char text[50];
};

struct msg_heartbeat {
	uint8_t flightMode;
//	uint16_t timeStamp;
	uint16_t batteryVoltage;
	uint16_t commandIndex;
};

struct msg_attitude {
	int16_t roll;
	int16_t pitch;
	uint16_t yaw;
};

struct msg_location {
	int32_t latitude;
	int32_t longitude;
	int32_t altitude;
	uint16_t groundSpeed;
	uint16_t groundCourse;
//	uint32_t timeOfWeek;
};

struct msg_pressure {
	int32_t pressureAltitude;
	int16_t airSpeed;
};

struct msg_command_list {
	uint16_t itemNumber;
	uint16_t listLength;
	uint8_t commandID;
//	uint8_t p1;
//	int32_t p2;
	int32_t p3;
	int32_t p4;
};

struct msg_value {
	uint8_t valueID;
	uint32_t value;
};

struct msg_pid {
	uint8_t pidSet;
//	int32_t p;
        int32_t p;
	int32_t i;
	int32_t d;
	int16_t integratorMax;
};
/*
inline void
send_msg_command_request(
	const uint16_t UNSPECIFIED)
{
	
};

inline void
send_msg_value_request(
	const uint8_t valueID,
	const uint8_t broadcast)
{};

inline void
send_msg_pid_request(
	const uint8_t pidSet)
{};

inline void
send_msg_pid_set(
	const uint8_t pidSet,
	const int32_t p,
	const int32_t i,
	const int32_t d,
	const int16_t integratorMax)
{};

inline void
send_msg_value_set(
	const uint8_t valueID,
	const uint32_t value)
{};
*/
