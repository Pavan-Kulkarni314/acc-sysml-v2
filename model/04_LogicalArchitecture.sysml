package ACC_LogicalArchitecture {
    doc /*
     * Logical (functional) architecture: what the ACC system has to do,
     * independent of the hardware that does it. Functions exchange items
     * through flows; logical components perform the functions.
     */

    // ------------------------------------------------------------------
    // Items exchanged between functions
    // ------------------------------------------------------------------
    item def ObjectList {
        doc /* Objects detected in front of the vehicle with distance, relative speed and lateral position. */
    }
    item def TargetObject {
        doc /* The object selected as the relevant vehicle ahead in the ego lane. */
    }
    item def DriverSettings {
        doc /* Main switch state, set speed and selected time gap. */
    }
    item def VehicleMotionState {
        doc /* Ego vehicle speed, yaw rate and pedal positions. */
    }
    item def AccelerationRequest {
        doc /* Requested longitudinal acceleration (positive) or deceleration (negative). */
    }
    item def HealthStatus {
        doc /* Fault and blockage information from the ACC components. */
    }
    item def AccStatus {
        doc /* Function state, set speed, time gap and warnings shown to the driver. */
    }

    // ------------------------------------------------------------------
    // Function definitions
    // ------------------------------------------------------------------
    action def DetectObjects {
        out item objects : ObjectList;
    }
    action def SelectTarget {
        in item objects : ObjectList;
        in item motion : VehicleMotionState;
        out item target : TargetObject;
    }
    action def ReadDriverInputs {
        out item settings : DriverSettings;
    }
    action def ControlLongitudinalMotion {
        in item target : TargetObject;
        in item settings : DriverSettings;
        in item motion : VehicleMotionState;
        out item request : AccelerationRequest;
    }
    action def LimitAndArbitrate {
        doc /* Applies the acceleration and deceleration limits and gives the driver's pedal inputs priority. */
        in item request : AccelerationRequest;
        in item motion : VehicleMotionState;
        out item limitedRequest : AccelerationRequest;
    }
    action def MonitorHealth {
        out item health : HealthStatus;
    }
    action def InformDriver {
        in item settings : DriverSettings;
        in item health : HealthStatus;
        out item status : AccStatus;
    }

    // ------------------------------------------------------------------
    // Functional chain
    // ------------------------------------------------------------------
    action provideAcc {
        doc /* Top-level ACC function: from sensing and driver input to an acceleration request and driver information. */
        in item motion : VehicleMotionState;
        out item limitedRequest : AccelerationRequest;
        out item status : AccStatus;

        action detectObjects : DetectObjects;
        action selectTarget : SelectTarget;
        action readDriverInputs : ReadDriverInputs;
        action controlMotion : ControlLongitudinalMotion;
        action limitAndArbitrate : LimitAndArbitrate;
        action monitorHealth : MonitorHealth;
        action informDriver : InformDriver;

        flow detectObjects.objects to selectTarget.objects;
        flow selectTarget.target to controlMotion.target;
        flow readDriverInputs.settings to controlMotion.settings;
        flow controlMotion.request to limitAndArbitrate.request;
        flow readDriverInputs.settings to informDriver.settings;
        flow monitorHealth.health to informDriver.health;

        // Delegation between the top-level parameters and the inner functions
        bind selectTarget.motion = motion;
        bind controlMotion.motion = motion;
        bind limitAndArbitrate.motion = motion;
        bind limitedRequest = limitAndArbitrate.limitedRequest;
        bind status = informDriver.status;
    }

    // ------------------------------------------------------------------
    // Logical components
    // ------------------------------------------------------------------
    part def SensingComponent;
    part def ControlComponent;
    part def HmiComponent;
    part def DiagnosticsComponent;

    part logicalArchitecture {
        part sensing : SensingComponent {
            perform provideAcc.detectObjects;
        }
        part control : ControlComponent {
            perform provideAcc.selectTarget;
            perform provideAcc.controlMotion;
            perform provideAcc.limitAndArbitrate;
        }
        part hmi : HmiComponent {
            perform provideAcc.readDriverInputs;
            perform provideAcc.informDriver;
        }
        part diagnostics : DiagnosticsComponent {
            perform provideAcc.monitorHealth;
        }
    }
}
