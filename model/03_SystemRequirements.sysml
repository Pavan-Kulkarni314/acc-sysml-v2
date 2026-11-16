package ACC_SystemRequirements {
    doc /*
     * System requirements (SYS) for the ACC system.
     * Each requirement has one "shall" statement in an EARS pattern
     * (The..., When..., While..., If... then...), a measurable constraint where
     * possible, and a derivation link back to a stakeholder need (see bottom of file).
     *
     * Values are illustrative and based on public ACC literature (e.g. the ranges
     * discussed around ISO 15622). They are not taken from any company specification.
     */

    private import ISQ::*;
    private import SI::*;
    private import ACC_Context::*;
    private import ACC_StakeholderNeeds::*;
    private import RequirementDerivation::*;

    requirement def SystemRequirement {
        doc /* A verifiable requirement on the ACC system as a whole. */
        subject acc : AccSystem;
    }

    // ------------------------------------------------------------------
    // Speed control
    // ------------------------------------------------------------------
    requirement <'SYS-01'> setSpeedRange : SystemRequirement {
        doc /* The ACC system shall allow the driver to select a set speed from 30 km/h to 160 km/h. */
        require constraint { acc.minSetSpeed <= 30 ['km/h'] and acc.maxSetSpeed >= 160 ['km/h'] }
    }

    requirement <'SYS-02'> speedControlAccuracy : SystemRequirement {
        doc /* While no vehicle is ahead and the road is level, the ACC system shall keep the vehicle speed within 2 km/h of the set speed. */
        require constraint { acc.speedControlTolerance <= 2 ['km/h'] }
    }

    requirement <'SYS-03'> activationCondition : SystemRequirement {
        doc /* The ACC system shall activate only when the vehicle speed is at least 30 km/h and no system fault is present. */
        require constraint { acc.minActivationSpeed >= 30 ['km/h'] }
    }

    // ------------------------------------------------------------------
    // Gap control
    // ------------------------------------------------------------------
    requirement <'SYS-04'> timeGapSelection : SystemRequirement {
        doc /* The ACC system shall offer at least 3 selectable time gaps between 1.0 s and 2.2 s. */
        require constraint {
            acc.numberOfTimeGapSettings >= 3 and
            acc.minTimeGap >= 1.0 [s] and
            acc.maxTimeGap <= 2.2 [s]
        }
    }

    requirement <'SYS-05'> timeGapAccuracy : SystemRequirement {
        doc /* While following a vehicle that drives at constant speed, the ACC system shall hold the selected time gap within 0.2 s. */
        require constraint { acc.timeGapTolerance <= 0.2 [s] }
    }

    // ------------------------------------------------------------------
    // Comfort limits
    // ------------------------------------------------------------------
    requirement <'SYS-06'> decelerationLimit : SystemRequirement {
        doc /* The ACC system shall not request a vehicle deceleration greater than 3.5 m/s². */
        require constraint { acc.maxDecelerationRequest <= 3.5 ['m/s²'] }
    }

    requirement <'SYS-07'> accelerationLimit : SystemRequirement {
        doc /* The ACC system shall not request a vehicle acceleration greater than 2.0 m/s². */
        require constraint { acc.maxAccelerationRequest <= 2.0 ['m/s²'] }
    }

    // ------------------------------------------------------------------
    // Driver override and information
    // ------------------------------------------------------------------
    requirement <'SYS-08'> brakeOverride : SystemRequirement {
        doc /* When the driver presses the brake pedal, the ACC system shall switch to standby within 100 ms. */
        require constraint { acc.brakeOverrideReactionTime <= 0.1 [s] }
    }

    requirement <'SYS-09'> acceleratorOverride : SystemRequirement {
        doc /* While the driver presses the accelerator pedal, the ACC system shall not request any deceleration. */
    }

    requirement <'SYS-10'> statusDisplay : SystemRequirement {
        doc /* The ACC system shall display the current ACC state, the set speed and the selected time gap to the driver. */
    }

    // ------------------------------------------------------------------
    // Safety-related behaviour
    // ------------------------------------------------------------------
    requirement <'SYS-11'> takeoverRequest : SystemRequirement {
        doc /* When the deceleration needed to keep the time gap exceeds 3.5 m/s², the ACC system shall give the driver a visual and acoustic takeover request within 200 ms. */
        require constraint { acc.takeoverWarningTime <= 0.2 [s] }
    }

    requirement <'SYS-12'> faultReaction : SystemRequirement {
        doc /* When the radar sensor reports a fault or blockage, the ACC system shall switch to the fault state and inform the driver within 500 ms. */
        require constraint { acc.faultReactionTime <= 0.5 [s] }
    }

    // ------------------------------------------------------------------
    // Traceability: stakeholder need -> system requirements
    // ------------------------------------------------------------------
    #derivation connection {
        end #original ::> holdChosenSpeed;
        end #derive ::> setSpeedRange;
        end #derive ::> speedControlAccuracy;
        end #derive ::> activationCondition;
    }

    #derivation connection {
        end #original ::> keepSafeDistance;
        end #derive ::> timeGapSelection;
        end #derive ::> timeGapAccuracy;
    }

    #derivation connection {
        end #original ::> driverStaysInControl;
        end #derive ::> brakeOverride;
        end #derive ::> acceleratorOverride;
    }

    #derivation connection {
        end #original ::> knowFunctionState;
        end #derive ::> statusDisplay;
    }

    #derivation connection {
        end #original ::> comfortableRide;
        end #derive ::> decelerationLimit;
        end #derive ::> accelerationLimit;
    }

    #derivation connection {
        end #original ::> failSafely;
        end #derive ::> takeoverRequest;
        end #derive ::> faultReaction;
    }
}
