package ACC_Analysis {
    doc /*
     * Engineering analyses that justify derived design values.
     *
     * Radar range: at the highest set speed (160 km/h = 44.4 m/s) and the
     * largest time gap (2.2 s) the following distance is about 98 m.
     * With a margin of 1.5 for detecting and confirming a target before it
     * is needed, the radar needs about 147 m, which gives CMP-RAD-01 (150 m).
     */

    private import ScalarValues::Real;
    private import ISQ::*;
    private import SI::*;
    private import ACC_Context::*;
    private import ACC_PhysicalArchitecture::*;

    calc def FollowingDistance {
        doc /* Distance to the vehicle ahead for a given speed and time gap: d = v * t. */
        in speed : SpeedValue;
        in timeGap : DurationValue;
        return distance : LengthValue = speed * timeGap;
    }

    analysis def RadarRangeAnalysis {
        doc /* Checks that the radar can see far enough to follow a vehicle at the highest set speed and the largest time gap. */
        subject acc : AccSystem;
        in attribute radarRange : LengthValue;
        in attribute margin : Real;

        objective {
            doc /* The radar range shall be at least the longest following distance multiplied by the margin. */
            require constraint { radarRange >= margin * requiredRange }
        }

        return requiredRange : LengthValue = FollowingDistance(acc.maxSetSpeed, acc.maxTimeGap);
    }

    analysis radarRangeCheck : RadarRangeAnalysis {
        subject :>> acc = vehicleDesign.acc;
        in attribute :>> radarRange = vehicleDesign.acc.radar.detectionRange;
        in attribute :>> margin = 1.5;
    }
}
