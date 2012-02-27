// Created 2011 By Colin G http://www.diydrones.com/profile/ColinG

/// @file       params.h
/// @brief      Reads and writes parameters

#if ISPLANE == 1
// Define the parameters of interest here - Update enumeration to match any changes here
prog_char param_0[]  PROGMEM = "RLL2SRV_P";
prog_char param_1[]  PROGMEM = "RLL2SRV_I";
prog_char param_2[]  PROGMEM = "RLL2SRV_D";
prog_char param_3[]  PROGMEM = "RLL2SRV_IMAX";
prog_char param_4[]  PROGMEM = "PTCH2SRV_P\0\0\0\0\0";
prog_char param_5[]  PROGMEM = "PTCH2SRV_I";
prog_char param_6[]  PROGMEM = "PTCH2SRV_D";
prog_char param_7[]  PROGMEM = "PTCH2SRV_IMAX";
prog_char param_8[]  PROGMEM = "YW2SRV_P";
prog_char param_9[]  PROGMEM = "YW2SRV_I";
prog_char param_10[] PROGMEM = "YW2SRV_D";
prog_char param_11[] PROGMEM = "YW2SRV_IMAX";
prog_char param_12[] PROGMEM = "HDNG2RLL_P";
prog_char param_13[] PROGMEM = "HDNG2RLL_I";
prog_char param_14[] PROGMEM = "HDNG2RLL_D";
prog_char param_15[] PROGMEM = "HDNG2RLL_IMAX";
#if AIRSPEEDSENSOR == 1
prog_char param_16[] PROGMEM = "ARSP2PTCH_P";
prog_char param_17[] PROGMEM = "ARSP2PTCH_I";
prog_char param_18[] PROGMEM = "ARSP2PTCH_D";
prog_char param_19[] PROGMEM = "ARSP2PTCH_IMAX";
#else
prog_char param_16[] PROGMEM = "ALT2PTCH_P";
prog_char param_17[] PROGMEM = "ALT2PTCH_I";
prog_char param_18[] PROGMEM = "ALT2PTCH_D";
prog_char param_19[] PROGMEM = "ALT2PTCH_IMAX";
#endif
prog_char param_20[] PROGMEM = "ENRGY2THR_P";
prog_char param_21[] PROGMEM = "ENRGY2THR_I";
prog_char param_22[] PROGMEM = "ENRGY2THR_D";
prog_char param_23[] PROGMEM = "ENRGY2THR_IMAX";
prog_char param_24[] PROGMEM = "WP_LOITER_RAD";
prog_char param_25[] PROGMEM = "WP_RADIUS";
prog_char param_26[] PROGMEM = "XTRK_GAIN_SC";
prog_char param_27[] PROGMEM = "XTRK_ANGLE_CD";
prog_char param_28[] PROGMEM = "TRIM_ARSPD_CM";
prog_char param_29[] PROGMEM = "ARSPD_FBW_MIN";
prog_char param_30[] PROGMEM = "ARSPD_FBW_MAX";
prog_char param_31[] PROGMEM = "THR_MIN";
prog_char param_32[] PROGMEM = "THR_MAX";
prog_char param_33[] PROGMEM = "TRIM_THROTTLE";
prog_char param_34[] PROGMEM = "LIM_ROLL_CD";
prog_char param_35[] PROGMEM = "LIM_PITCH_MIN";
prog_char param_36[] PROGMEM = "LIM_PITCH_MAX";
prog_char param_37[] PROGMEM = "ALT_HOLD_RTL";
prog_char param_38[] PROGMEM = "KFF_PTCH2THR";
prog_char param_39[] PROGMEM = "KFF_THR2PTCH";
prog_char param_40[] PROGMEM = "KFF_PTCHCOMP";
prog_char param_41[] PROGMEM = "LOG_BITMASK";
#else
// Define the parameters of interest here - Update enumeration to match any changes here
prog_char param_0[]  PROGMEM = "RATE_RLL_P";
prog_char param_1[]  PROGMEM = "RATE_RLL_I";
prog_char param_2[]  PROGMEM = "RATE_RLL_D";
prog_char param_3[]  PROGMEM = "RATE_RLL_IMAX";
prog_char param_4[]  PROGMEM = "RATE_PIT_P\0\0\0\0\0";
prog_char param_5[]  PROGMEM = "RATE_PIT_I";
prog_char param_6[]  PROGMEM = "RATE_PIT_D";
prog_char param_7[]  PROGMEM = "RATE_PIT_IMAX";
prog_char param_8[]  PROGMEM = "RATE_YAW_P";
prog_char param_9[]  PROGMEM = "RATE_YAW_I";
prog_char param_10[] PROGMEM = "RATE_YAW_D";
prog_char param_11[] PROGMEM = "RATE_YAW_IMAX";

prog_char param_12[] PROGMEM = "STB_RLL_P";
prog_char param_13[] PROGMEM = "STB_RLL_I";
prog_char param_14[] PROGMEM = "STAB_D";
prog_char param_15[] PROGMEM = "STB_RLL_IMAX";
prog_char param_16[] PROGMEM = "STB_PIT_P";
prog_char param_17[] PROGMEM = "STB_PIT_I";
prog_char param_18[] PROGMEM = "STAB_D";
prog_char param_19[] PROGMEM = "STB_PIT_IMAX";
prog_char param_20[] PROGMEM = "STB_YAW_P";
prog_char param_21[] PROGMEM = "STB_YAW_I";
prog_char param_22[] PROGMEM = "STAB_D";
prog_char param_23[] PROGMEM = "STB_YAW_IMAX";

prog_char param_24[] PROGMEM = "WP_LOITER_RAD";
prog_char param_25[] PROGMEM = "WP_RADIUS";
prog_char param_26[] PROGMEM = "XTRK_GAIN_SC";
prog_char param_27[] PROGMEM = "XTRK_ANGLE_CD";
prog_char param_28[] PROGMEM = "TRIM_ARSPD_CM";
prog_char param_29[] PROGMEM = "ARSPD_FBW_MIN";
prog_char param_30[] PROGMEM = "ARSPD_FBW_MAX";
prog_char param_31[] PROGMEM = "THR_RATE_P";
prog_char param_32[] PROGMEM = "THR_RATE_I";
prog_char param_33[] PROGMEM = "THR_RATE_D";
prog_char param_34[] PROGMEM = "LIM_ROLL_CD";
prog_char param_35[] PROGMEM = "LIM_PITCH_MIN";
prog_char param_36[] PROGMEM = "LIM_PITCH_MAX";
prog_char param_37[] PROGMEM = "ALT_HOLD_RTL";
prog_char param_38[] PROGMEM = "KFF_PTCH2THR";
prog_char param_39[] PROGMEM = "KFF_THR2PTCH";
prog_char param_40[] PROGMEM = "KFF_PTCHCOMP";
prog_char param_41[] PROGMEM = "LOG_BITMASK";
#endif

PROGMEM const char *paramTable[] = {
		param_0, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9,
		param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18,
		param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27,
		param_28, param_29, param_30, param_31, param_32, param_33, param_34, param_35, param_36,
		param_37, param_38, param_39, param_40, param_41 };
  
/// @class      Watchdog
/// @brief      The watchdog fires an alarm when packet traffic stops
class Parameters {
public:
        Parameters() {};

        /// Notify the parameter class.
        /// Installed as a message handler, registered for MSG_ALL.
        ///
        /// @param messageID            ignored
        /// @param messageVersion       ignored
        /// @param messageData          ignored
        ///
        static void    notify(void *arg, mavlink_message_t *buf); //uint8_t messageID, uint8_t messageVersion,
//        static void    notify(void *arg, uint8_t messageID, uint8_t messageVersion, void *messageData);

        void set_param(uint8_t param_id, float newVal);

        // Parameter enumeration. THIS MUST FOLLOW THE SAME ORDER AS THE PROG_CHARS
        enum PARAMID {
            SROLLP,
            SROLLI,
            SROLLD,
            SROLLMAX,
            SPITP,
            SPITI,
            SPITD,
            SPITMAX,
            SYAWP,
            SYAWI,
            SYAWD,
            SYAWMAX,
			NROLLP,
			NROLLI,
			NROLLD,
			NROLLMAX,
			NPITP,
			NPITI,
			NPITD,
			NPITMAX,
			NYAWP,
			NYAWI,
			NYAWD,
			NYAWMAX,
            WP_LOITER_RAD,
            WP_RADIUS,
            XTRK_GAIN_SC,
            XTRK_ANGLE_CD,
            TRIM_ARSPD_CM,
            ARSPD_FBW_MIN,
            ARSPD_FBW_MAX,
        	THRTL_MIN,
        	THRTL_MAX,
        	THRTL_CRUISE,
        	ROLL_LIM,
        	PITCH_MIN,
        	PITCH_MAX,
        	RTL_ALT,
            KFF_PTCH2THR,
            KFF_THR2PTCH,
            KFF_PTCHCOMP,
            LOG_BITMASK,
            COUNT
        };

//        ARSP2PTCH_P,
//        ARSP2PTCH_I,
//        ARSP2PTCH_D,
//        ARSP2PTCH_IMAX,
//        ENRGY2THR_P,
//        ENRGY2THR_I,
//        ENRGY2THR_D,
//        ENRGY2THR_IMAX,

private:
        /// internal notification
        ///
        void            _notify(mavlink_message_t *buf);
        
        /// Upload a new parameter value
        ///
        void _set_param(uint8_t param_id, float newVal);

        /// Conversion from parameter ID into local ID
        ///
        int8_t _local_id(mavlink_param_value_t *mav_pkt, uint8_t *ID);
        
        /// Parameter setting packet
        ///
//        mavlink_param_set_t _pktSet;

        /// Parameter packet
        ///
        mavlink_param_value_t _packet;

};


