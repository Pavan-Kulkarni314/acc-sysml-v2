package ACC_Verification {
    doc /*
     * Verification cases (TC) for the system and component requirements.
     * Each case names its method (test, analysis, demonstration, inspection)
     * and the requirements it verifies. HIL = hardware-in-the-loop test bench.
     */

    private import ISQ::*;
    private import SI::*;
    private import VerificationCases::*;
    private import ACC_Context::*;
    private import ACC_SystemRequirements::*;
    private import ACC_ComponentRequirements::*;
    private import ACC_PhysicalArchitecture::*;

    verification def AccSystemVerification {
        subject acc : AccSystem;
    }

    // ------------------------------------------------------------------
    // Speed control
    // ------------------------------------------------------------------
    verification <'TC-01'> setSpeedRangeTest : AccSystemVerification {
        doc /* Test track: try to set 25, 30, 160 and 165 km/h. Pass if 30 and 160 km/h are accepted and 25 and 165 km/h are rejected. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify setSpeedRange; }
    }

    verification <'TC-02'> speedControlTest : AccSystemVerification {
        doc /* Test track, level road, no vehicle ahead: hold 100 km/h for 60 s and log the speed. Pass if the speed stays within 2 km/h of the set speed. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify speedControlAccuracy; }
    }

    verification <'TC-03'> activationTest : AccSystemVerification {
        doc /* HIL: press Set at 25 km/h, at 30 km/h, and at 50 km/h with an injected radar fault. Pass if only the 30 km/h case activates. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify activationCondition; }
    }

    // ------------------------------------------------------------------
    // Gap control
    // ------------------------------------------------------------------
    verification <'TC-04'> timeGapMenuInspection : AccSystemVerification {
        doc /* Step through all time gap settings in the vehicle and record them. Pass if at least 3 settings exist, all between 1.0 s and 2.2 s. */
        @VerificationMethod { kind = VerificationMethodKind::inspect; }
        objective { verify timeGapSelection; }
    }

    verification <'TC-05'> timeGapFollowingTest : AccSystemVerification {
        doc /* Test track: follow a target vehicle driving at a constant 80 km/h for each time gap setting. Pass if the measured time gap stays within 0.2 s of the setting. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify timeGapAccuracy; }
    }

    // ------------------------------------------------------------------
    // Comfort limits
    // ------------------------------------------------------------------
    verification <'TC-06'> accelerationLimitTest : AccSystemVerification {
        doc /* HIL: run cut-in, hard-braking target and target-leaving scenarios and log the acceleration request. Pass if it stays between -3.5 and +2.0 m/s². */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective {
            verify decelerationLimit;
            verify accelerationLimit;
        }
    }

    // ------------------------------------------------------------------
    // Driver override (worked example with test steps and a verdict)
    // ------------------------------------------------------------------
    verification <'TC-07'> brakeOverrideTest : AccSystemVerification {
        doc /* HIL: with ACC active at 80 km/h, send a brake pedal signal and measure the time until the ACC state is standby. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify brakeOverride; }

        action applyBrake {
            doc /* Send "brake pedal pressed" on the vehicle bus at time t0. */
        }
        then action measureReaction {
            doc /* Log the time from t0 until the ACC state signal shows standby. */
            out reactionTime : DurationValue;
        }
        then action evaluate {
            in reactionTime : DurationValue = measureReaction.reactionTime;
            out verdict : VerdictKind = PassIf(reactionTime <= 0.1 [s]);
        }
        return verdict : VerdictKind = evaluate.verdict;
    }

    verification <'TC-08'> acceleratorOverrideTest : AccSystemVerification {
        doc /* HIL: while following a braking target, press the accelerator. Pass if no deceleration is requested while the pedal is pressed. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify acceleratorOverride; }
    }

    verification <'TC-09'> statusDisplayDemo : AccSystemVerification {
        doc /* In the vehicle: go through off, standby, active and fault and check the display in each state. Pass if state, set speed and time gap are always shown. */
        @VerificationMethod { kind = VerificationMethodKind::demo; }
        objective { verify statusDisplay; }
    }

    // ------------------------------------------------------------------
    // Safety-related behaviour
    // ------------------------------------------------------------------
    verification <'TC-10'> takeoverRequestTest : AccSystemVerification {
        doc /* HIL: let the target brake at 6 m/s². Pass if visual and acoustic warnings start within 200 ms after the needed deceleration exceeds 3.5 m/s². */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify takeoverRequest; }
    }

    verification <'TC-11'> faultReactionTest : AccSystemVerification {
        doc /* HIL: inject a radar blockage while ACC is active. Pass if the state is fault and the driver is informed within 500 ms. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        objective { verify faultReaction; }
    }

    // ------------------------------------------------------------------
    // Component level
    // ------------------------------------------------------------------
    verification <'TC-12'> radarRangeByAnalysis {
        doc /* Analysis: run ACC_Analysis::radarRangeCheck and compare the result with the radar data sheet. */
        @VerificationMethod { kind = VerificationMethodKind::analyze; }
        subject radar : FrontRadar;
        objective { verify radarDetectionRange; }
    }

    verification <'TC-13'> radarCycleTimeTest {
        doc /* HIL: log the radar object list messages for 10 min. Pass if the longest interval between two messages is at most 50 ms. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        subject radar : FrontRadar;
        objective { verify radarCycleTime; }
    }

    verification <'TC-14'> controlCycleTimeTest {
        doc /* HIL: log the ACC acceleration request messages for 10 min. Pass if the longest interval between two messages is at most 20 ms. */
        @VerificationMethod { kind = VerificationMethodKind::test; }
        subject ecu : AccControlUnit;
        objective { verify controlCycleTime; }
    }

    // Open points (not yet verified): CMP-RAD-03, CMP-ECU-02, CMP-HMI-01
}
