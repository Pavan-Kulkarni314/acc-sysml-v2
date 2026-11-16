package ACC_Behaviour {
    doc /*
     * State machine of the ACC function. The ACC control unit exhibits it
     * (see ACC_PhysicalArchitecture). Requirement IDs in the comments show
     * which system requirement each transition implements.
     */

    private import ISQ::*;
    private import SI::*;

    // ------------------------------------------------------------------
    // Signals (triggers)
    // ------------------------------------------------------------------
    attribute def MainSwitchOn;
    attribute def MainSwitchOff;
    attribute def SetPressed;
    attribute def ResumePressed;
    attribute def CancelPressed;
    attribute def BrakePressed;
    attribute def AcceleratorPressed;
    attribute def AcceleratorReleased;
    attribute def TargetDetected;
    attribute def TargetLost;
    attribute def FaultDetected;
    attribute def FaultCleared;

    // ------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------
    state def AccStates {
        in attribute egoSpeed : SpeedValue;

        first start then off;

        state off {
            doc /* Function switched off. No requests are sent. */
        }
        state standby {
            doc /* Function ready. Waiting for the driver to set or resume a speed. */
        }
        state active {
            doc /* Function controls the vehicle speed or the time gap. */
            first start then speedControl;

            state speedControl {
                doc /* No relevant vehicle ahead: hold the set speed (SYS-02). */
            }
            state gapControl {
                doc /* Vehicle ahead detected: hold the selected time gap (SYS-05). */
            }

            transition speedToGap first speedControl accept TargetDetected then gapControl;
            transition gapToSpeed first gapControl accept TargetLost then speedControl;
        }
        state override {
            doc /* Driver presses the accelerator. No deceleration is requested (SYS-09). */
        }
        state fault {
            doc /* Radar fault or blockage. No requests are sent and the driver is informed (SYS-12). */
        }

        // Switching on and off
        transition offToStandby first off accept MainSwitchOn then standby;
        transition standbyToOff first standby accept MainSwitchOff then off;
        transition activeToOff first active accept MainSwitchOff then off;
        transition faultToOff first fault accept MainSwitchOff then off;

        // Activation only at or above 30 km/h (SYS-03)
        transition setFromStandby first standby
            accept SetPressed if egoSpeed >= 30 ['km/h'] then active;
        transition resumeFromStandby first standby
            accept ResumePressed if egoSpeed >= 30 ['km/h'] then active;

        // Driver override (SYS-08, SYS-09)
        transition brakeInActive first active accept BrakePressed then standby;
        transition cancelInActive first active accept CancelPressed then standby;
        transition acceleratorInActive first active accept AcceleratorPressed then override;
        transition acceleratorReleased first override accept AcceleratorReleased then active;
        transition brakeInOverride first override accept BrakePressed then standby;

        // Fault handling (SYS-12)
        transition faultInStandby first standby accept FaultDetected then fault;
        transition faultInActive first active accept FaultDetected then fault;
        transition faultInOverride first override accept FaultDetected then fault;
        transition faultCleared first fault accept FaultCleared then standby;
    }
}
