package ACC_PhysicalArchitecture {
    doc /*
     * Physical architecture: the hardware components of the ACC system, their
     * ports and interfaces, the allocation of logical components to them, and
     * which component design satisfies which system requirement.
     *
     * Design values are illustrative.
     */

    private import ISQ::*;
    private import SI::*;
    private import ACC_Context::*;
    private import ACC_LogicalArchitecture::*;
    private import ACC_Behaviour::*;
    private import ACC_SystemRequirements::*;

    // ------------------------------------------------------------------
    // Ports and interfaces
    // ------------------------------------------------------------------
    port def ObjectListPort {
        out item objects : ObjectList;
    }
    port def DriverSettingsPort {
        out item settings : DriverSettings;
    }
    port def AccelerationRequestPort {
        out item request : AccelerationRequest;
    }
    port def StatusPort {
        out item status : AccStatus;
    }

    interface def ObjectListInterface {
        doc /* Radar object list sent over the vehicle CAN FD bus. */
        end sender : ObjectListPort;
        end receiver : ~ObjectListPort;
    }
    interface def DriverSettingsInterface {
        end sender : DriverSettingsPort;
        end receiver : ~DriverSettingsPort;
    }
    interface def AccelerationRequestInterface {
        doc /* Acceleration request to the brake and powertrain control units. */
        end sender : AccelerationRequestPort;
        end receiver : ~AccelerationRequestPort;
    }
    interface def StatusInterface {
        end sender : StatusPort;
        end receiver : ~StatusPort;
    }

    // ------------------------------------------------------------------
    // Component definitions
    // ------------------------------------------------------------------
    part def FrontRadar {
        doc /* 77 GHz long-range radar sensor mounted behind the front bumper. */
        attribute detectionRange : LengthValue;
        attribute cycleTime : DurationValue;
        attribute blockageReportTime : DurationValue;
        port objectOut : ObjectListPort;
    }

    part def AccControlUnit {
        doc /* ECU that runs target selection, longitudinal control, limiting and the ACC state machine. */
        attribute cycleTime : DurationValue;
        attribute vehicleSpeed : SpeedValue;
        attribute maxDecelerationOutput : AccelerationValue;
        attribute maxAccelerationOutput : AccelerationValue;
        port objectIn : ~ObjectListPort;
        port settingsIn : ~DriverSettingsPort;
        port requestOut : AccelerationRequestPort;
        port statusOut : StatusPort;

        exhibit state accStates : AccStates {
            in attribute :>> egoSpeed = vehicleSpeed;
        }
    }

    part def SteeringWheelSwitches {
        doc /* Buttons for on/off, set, resume, cancel and time gap selection. */
        port settingsOut : DriverSettingsPort;
    }

    part def InstrumentCluster {
        doc /* Driver display showing ACC state, set speed, time gap and warnings. */
        attribute displayLatency : DurationValue;
        port statusIn : ~StatusPort;
    }

    part def BrakeControlUnit {
        doc /* ESC unit that builds brake pressure on request. Outside the ACC system boundary. */
        port requestIn : ~AccelerationRequestPort;
    }

    part def PowertrainControlUnit {
        doc /* Engine or e-motor control unit that sets drive torque on request. Outside the ACC system boundary. */
        port requestIn : ~AccelerationRequestPort;
    }

    // ------------------------------------------------------------------
    // Vehicle design (physical structure with design values)
    // ------------------------------------------------------------------
    part vehicleDesign : Vehicle {
        part acc : AccSystem {
            part radar : FrontRadar {
                attribute :>> detectionRange = 160 [m];
                attribute :>> cycleTime = 0.05 [s];
                attribute :>> blockageReportTime = 0.3 [s];
            }
            part controlUnit : AccControlUnit {
                attribute :>> cycleTime = 0.02 [s];
                attribute :>> maxDecelerationOutput = 3.5 ['m/s²'];
                attribute :>> maxAccelerationOutput = 2.0 ['m/s²'];
            }
            part switches : SteeringWheelSwitches;
            part cluster : InstrumentCluster {
                attribute :>> displayLatency = 0.1 [s];
            }

            // Design values for the system characteristics constrained in ACC_SystemRequirements
            attribute :>> minSetSpeed = 30 ['km/h'];
            attribute :>> maxSetSpeed = 160 ['km/h'];
            attribute :>> minActivationSpeed = 30 ['km/h'];
            attribute :>> speedControlTolerance = 1.5 ['km/h'];
            attribute :>> minTimeGap = 1.0 [s];
            attribute :>> maxTimeGap = 2.2 [s];
            attribute :>> numberOfTimeGapSettings = 4;
            attribute :>> timeGapTolerance = 0.15 [s];
            attribute :>> maxDecelerationRequest = 3.5 ['m/s²'];
            attribute :>> maxAccelerationRequest = 2.0 ['m/s²'];
            attribute :>> brakeOverrideReactionTime = 0.06 [s];
            attribute :>> takeoverWarningTime = 0.15 [s];
            attribute :>> faultReactionTime = 0.4 [s];

            interface : ObjectListInterface connect
                sender ::> radar.objectOut to receiver ::> controlUnit.objectIn;
            interface : DriverSettingsInterface connect
                sender ::> switches.settingsOut to receiver ::> controlUnit.settingsIn;
            interface : StatusInterface connect
                sender ::> controlUnit.statusOut to receiver ::> cluster.statusIn;
        }

        part brakeUnit : BrakeControlUnit;
        part powertrainUnit : PowertrainControlUnit;

        interface : AccelerationRequestInterface connect
            sender ::> acc.controlUnit.requestOut to receiver ::> brakeUnit.requestIn;
        interface : AccelerationRequestInterface connect
            sender ::> acc.controlUnit.requestOut to receiver ::> powertrainUnit.requestIn;
    }

    // ------------------------------------------------------------------
    // Allocation: logical components -> physical components
    // ------------------------------------------------------------------
    allocate logicalArchitecture.sensing to vehicleDesign.acc.radar;
    allocate logicalArchitecture.control to vehicleDesign.acc.controlUnit;
    allocate logicalArchitecture.diagnostics to vehicleDesign.acc.controlUnit;
    allocate provideAcc.readDriverInputs to vehicleDesign.acc.switches;
    allocate provideAcc.informDriver to vehicleDesign.acc.cluster;

    // ------------------------------------------------------------------
    // Satisfaction: system requirements -> design
    // ------------------------------------------------------------------
    part accDesignContext {
        ref design :> vehicleDesign;

        satisfy setSpeedRange by design.acc;
        satisfy speedControlAccuracy by design.acc;
        satisfy activationCondition by design.acc;
        satisfy timeGapSelection by design.acc;
        satisfy timeGapAccuracy by design.acc;
        satisfy decelerationLimit by design.acc;
        satisfy accelerationLimit by design.acc;
        satisfy brakeOverride by design.acc;
        satisfy acceleratorOverride by design.acc;
        satisfy statusDisplay by design.acc;
        satisfy takeoverRequest by design.acc;
        satisfy faultReaction by design.acc;
    }
}
