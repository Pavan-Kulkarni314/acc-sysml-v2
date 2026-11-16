package ACC_Context {
    doc /*
     * System context of the Adaptive Cruise Control (ACC) function:
     * the system of interest, the actors around it, and its use cases.
     *
     * All values in this model are illustrative. They are based on public
     * literature about ACC systems, not on any company specification.
     */

    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;

    // ------------------------------------------------------------------
    // Actors and external elements
    // ------------------------------------------------------------------
    part def Driver {
        doc /* The person driving the ego vehicle and operating the ACC function. */
    }

    part def Passenger {
        doc /* A person travelling in the ego vehicle who is not driving. */
    }

    part def VehicleOwner {
        doc /* The person or company that owns the ego vehicle and is responsible for its use. */
    }

    part def TargetVehicle {
        doc /* The closest vehicle driving ahead in the same lane as the ego vehicle. */
        attribute speed : SpeedValue;
        attribute distance : LengthValue;
    }

    part def RoadEnvironment {
        doc /* Road, lane markings, weather and other traffic around the ego vehicle. */
    }

    // ------------------------------------------------------------------
    // System of interest
    // ------------------------------------------------------------------
    part def AccSystem {
        doc /*
         * The ACC system: sensing, control and driver interface elements that
         * together keep a set speed or a time gap to the vehicle ahead.
         *
         * The attributes below are the system characteristics that the
         * system requirements constrain. The physical design binds values to them.
         */
        attribute minSetSpeed : SpeedValue;
        attribute maxSetSpeed : SpeedValue;
        attribute minActivationSpeed : SpeedValue;
        attribute speedControlTolerance : SpeedValue;
        attribute minTimeGap : DurationValue;
        attribute maxTimeGap : DurationValue;
        attribute numberOfTimeGapSettings : Natural;
        attribute timeGapTolerance : DurationValue;
        attribute maxDecelerationRequest : AccelerationValue;
        attribute maxAccelerationRequest : AccelerationValue;
        attribute brakeOverrideReactionTime : DurationValue;
        attribute takeoverWarningTime : DurationValue;
        attribute faultReactionTime : DurationValue;
    }

    part def Vehicle {
        doc /* The ego vehicle in which the ACC system is installed. */
        attribute speed : SpeedValue;
    }

    // ------------------------------------------------------------------
    // Use cases
    // ------------------------------------------------------------------
    use case def 'Drive at Set Speed' {
        subject acc : AccSystem;
        actor driver : Driver;
        objective {
            doc /* Hold the speed chosen by the driver when no vehicle is ahead. */
        }
    }

    use case def 'Follow Vehicle Ahead' {
        subject acc : AccSystem;
        actor driver : Driver;
        actor target : TargetVehicle;
        objective {
            doc /* Keep the time gap chosen by the driver to the vehicle ahead. */
        }
    }

    use case def 'Override or Switch Off' {
        subject acc : AccSystem;
        actor driver : Driver;
        objective {
            doc /* Let the driver take back control at any time. */
        }
    }

    // ------------------------------------------------------------------
    // Context structure
    // ------------------------------------------------------------------
    part accContext {
        doc /* The operational context of the ACC system. */
        part driver : Driver;
        part egoVehicle : Vehicle {
            part acc : AccSystem;
        }
        part targetVehicle : TargetVehicle;
        part road : RoadEnvironment;

        use case driveAtSetSpeed : 'Drive at Set Speed' {
            subject :>> acc = egoVehicle.acc;
            actor :>> driver = accContext.driver;
        }
        use case followVehicleAhead : 'Follow Vehicle Ahead' {
            subject :>> acc = egoVehicle.acc;
            actor :>> driver = accContext.driver;
            actor :>> target = targetVehicle;
        }
        use case overrideOrSwitchOff : 'Override or Switch Off' {
            subject :>> acc = egoVehicle.acc;
            actor :>> driver = accContext.driver;
        }
    }
}
