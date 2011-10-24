/*
 * tracker.h
 *
 *  Created on: 24 Oct 2011
 *      Author: Colin Greatwood
 */

/// @file       tracker.h
/// @brief      antenna tracking

/// @class      Tracker
/// @brief      Points the antenna at the aircraft

// Macros for angle conversions
#define toRad(x) (x*PI)/180.0
#define toDeg(x) (x*180.0)/PI

// Limits for the antenna elevation
#define tilt_pos_upper_limit 140 // Upper tilt limit (antenna points to the sky)
#define tilt_pos_lower_limit 60 //  Lower tilt limit (anntenna points straight ahead)

class Tracker {
public:
	Tracker();

        /// Notify the tracker of a new home position
        ///
        static void 	notify(void *arg, mavlink_message_t *messageData);

        /// Update the position of the servos for the antenna
        ///
        void			update(void);

private:
        int   _pan;		///< Pan  servo position
        int   _tilt;	///< Tilt servo position
        float _uavDist; ///< Distance to UAV
        float _uavBear; ///< Bearing to UAV
        float _uavElev; ///< Elevation to UAV
        float _offset;  ///< An offset for rotating servo limit point, currently not used
        Servo Pan;		///< Pan servo
        Servo Tilt;		///< Tilt servo

        /// Update the position of the servos for the antenna
        ///
        void			_update(void);

        /// Calculate the bearing to the aircraft
        ///
        float			_bearing(float lat1, float lat2, float lon1, float lon2);

        /// Calculate the distance to the aircraft
        ///
        float			_distance(float lat1, float lat2, float lon1, float lon2);
};


