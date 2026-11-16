package ACC_ComponentRequirements {
    doc /*
     * Component requirements (CMP) derived from the system requirements and
     * allocated to the physical components. Values are illustrative.
     */

    private import ISQ::*;
    private import SI::*;
    private import ACC_SystemRequirements::*;
    private import ACC_PhysicalArchitecture::*;
    private import RequirementDerivation::*;

    // ------------------------------------------------------------------
    // Front radar
    // ------------------------------------------------------------------
    requirement <'CMP-RAD-01'> radarDetectionRange {
        doc /* The front radar shall detect vehicles in the ego lane at distances up to at least 150 m. */
        subject radar : FrontRadar;
        require constraint { radar.detectionRange >= 150 [m] }
    }

    requirement <'CMP-RAD-02'> radarCycleTime {
        doc /* The front radar shall send an updated object list at least every 50 ms. */
        subject radar : FrontRadar;
        require constraint { radar.cycleTime <= 0.05 [s] }
    }

    requirement <'CMP-RAD-03'> radarBlockageReport {
        doc /* The front radar shall report a sensor blockage to the ACC control unit within 300 ms after the blockage starts. */
        subject radar : FrontRadar;
        require constraint { radar.blockageReportTime <= 0.3 [s] }
    }

    // ------------------------------------------------------------------
    // ACC control unit
    // ------------------------------------------------------------------
    requirement <'CMP-ECU-01'> controlCycleTime {
        doc /* The ACC control unit shall calculate a new acceleration request at least every 20 ms. */
        subject ecu : AccControlUnit;
        require constraint { ecu.cycleTime <= 0.02 [s] }
    }

    requirement <'CMP-ECU-02'> requestLimiting {
        doc /* The ACC control unit shall limit every acceleration request to the range from -3.5 m/s² to +2.0 m/s². */
        subject ecu : AccControlUnit;
        require constraint {
            ecu.maxDecelerationOutput <= 3.5 ['m/s²'] and
            ecu.maxAccelerationOutput <= 2.0 ['m/s²']
        }
    }

    // ------------------------------------------------------------------
    // Instrument cluster
    // ------------------------------------------------------------------
    requirement <'CMP-HMI-01'> statusUpdateLatency {
        doc /* The instrument cluster shall show a new ACC state within 100 ms after the state message arrives. */
        subject cluster : InstrumentCluster;
        require constraint { cluster.displayLatency <= 0.1 [s] }
    }

    // ------------------------------------------------------------------
    // Traceability: system requirement -> component requirements
    // ------------------------------------------------------------------
    // CMP-RAD-01 is justified by ACC_Analysis::radarRangeCheck
    #derivation connection {
        end #original ::> timeGapSelection;
        end #derive ::> radarDetectionRange;
    }
    #derivation connection {
        end #original ::> timeGapAccuracy;
        end #derive ::> radarCycleTime;
        end #derive ::> controlCycleTime;
    }
    #derivation connection {
        end #original ::> faultReaction;
        end #derive ::> radarBlockageReport;
    }
    #derivation connection {
        end #original ::> decelerationLimit;
        end #derive ::> requestLimiting;
    }
    #derivation connection {
        end #original ::> statusDisplay;
        end #derive ::> statusUpdateLatency;
    }

    // ------------------------------------------------------------------
    // Satisfaction: component requirements -> components
    // ------------------------------------------------------------------
    part componentDesignContext {
        ref design :> vehicleDesign;

        satisfy radarDetectionRange by design.acc.radar;
        satisfy radarCycleTime by design.acc.radar;
        satisfy radarBlockageReport by design.acc.radar;
        satisfy controlCycleTime by design.acc.controlUnit;
        satisfy requestLimiting by design.acc.controlUnit;
        satisfy statusUpdateLatency by design.acc.cluster;
    }
}
