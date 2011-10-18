// Created 2011 By Colin G http://www.diydrones.com/profile/ColinG

void
Parameters::notify(void *arg, mavlink_message_t *buf) //uint8_t messageID, uint8_t messageVersion,
{
        ((Parameters *)arg)->_notify(buf);
}

void
Parameters::_notify(mavlink_message_t *buf)
{
	uint8_t ID;
	int8_t result;
	mavlink_msg_param_value_decode(buf, &_packet);

//	if (_packet.param_index == 1) {
//		PrintPSTR(PSTR("Receiving parameters\n"));
//	}

	result = _local_id(&_packet, &ID);
	if (result == 0) {
//		PrintPSTR(PSTR("Saving parameter "));
//		Serial.print(ID,DEC);
//		PrintPSTR(PSTR(", "));
//		Serial.print(_packet.param_index,DEC);
//		PrintPSTR(PSTR(", "));
//		Serial.println(_packet.param_value,DEC);
		nvram.save_param(&ID, &_packet.param_value);
	}
      
}

void
Parameters::set_param(uint8_t param_id, float newVal)
{
	_set_param(param_id, newVal);
}

void
Parameters::_set_param(uint8_t param_id, float newVal)
{
	char str_param_id[15];
	mavlink_message_t msg;
	uint8_t i;

	// First initialise the string to be empty
	for (i=0;i<15;i++)
		str_param_id[i] = 0;

	// Copy the relevant one into memory
    strcpy_P(str_param_id, (char*)pgm_read_word(&(paramTable[param_id])));

    // Construct the packet
    mavlink_msg_param_set_pack(0xFF, 0x00, &msg, 1, 1, (const int8_t*)str_param_id, newVal);

    // Send it
    comm.send(&msg);

//	mavlink_param_set_t packet;
//	packet.target_system = 0xFF;
//	packet.target_component = 0xFA;
//	packet.param_value = newVal;
//	memcpy(packet.param_id, (int8_t*)param_id, sizeof(int8_t)*15);
//	_mav_finalize_message_chan_send(MAVLINK_COMM_1, MAVLINK_MSG_ID_PARAM_SET, (const char *)&packet, 21);

//	mavlink_msg_param_set_send(MAVLINK_COMM_1, 0xFF, 0xFA, test, newVal); //(const int8_t*)str_param_id, newVal);
}

int8_t
Parameters::_local_id(mavlink_param_value_t *mav_pkt, uint8_t *ID)
{
  // Return the Local ID of the parameter. 0 = success, -1 = fail
  
  uint8_t i;
  char txt_id[15];
    
  for (i=0;i<COUNT;i++) {
    strcpy_P(txt_id, (char*)pgm_read_word(&(paramTable[i])));
    if (strcmp(txt_id,(const char*)mav_pkt->param_id) == 0) {
      *ID = i;
      return 0;
    }
  }
  
  return -1;
}
