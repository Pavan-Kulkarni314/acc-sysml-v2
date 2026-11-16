package ACC_StakeholderNeeds {
    doc /*
     * Stakeholder needs (STK): what drivers, passengers and the vehicle owner
     * expect from the ACC function, written in their own terms.
     * System requirements in ACC_SystemRequirements are derived from these needs.
     */

    private import ACC_Context::*;

    requirement def StakeholderNeed {
        doc /* A need stated from the stakeholder's point of view. Not directly verifiable. */
        subject acc : AccSystem;
    }

    requirement <'STK-01'> holdChosenSpeed : StakeholderNeed {
        doc /* The driver needs the vehicle to hold a chosen speed without pressing the accelerator pedal. */
        subject :>> acc;
        stakeholder driver : Driver;
    }

    requirement <'STK-02'> keepSafeDistance : StakeholderNeed {
        doc /* The driver needs the vehicle to keep a safe distance to the vehicle ahead automatically. */
        subject :>> acc;
        stakeholder driver : Driver;
    }

    requirement <'STK-03'> driverStaysInControl : StakeholderNeed {
        doc /* The driver needs to be able to override or switch off the function at any time. */
        subject :>> acc;
        stakeholder driver : Driver;
    }

    requirement <'STK-04'> knowFunctionState : StakeholderNeed {
        doc /* The driver needs to know at all times whether the function is controlling the vehicle. */
        subject :>> acc;
        stakeholder driver : Driver;
    }

    requirement <'STK-05'> comfortableRide : StakeholderNeed {
        doc /* Passengers need speed changes made by the function to feel smooth. */
        subject :>> acc;
        stakeholder passengers : Passenger[*];
    }

    requirement <'STK-06'> failSafely : StakeholderNeed {
        doc /* The vehicle owner needs the function to hand control back safely when something goes wrong. */
        subject :>> acc;
        stakeholder owner : VehicleOwner;
    }
}
