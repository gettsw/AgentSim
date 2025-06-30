classdef AvoidedTarget < Target
    

    properties
        tz % event times
        dwellTime
        R0_val
        t0_val
        A_val
        B_val
        travelTime

    end

    methods
        function obj = AvoidedTarget(baseTarget, t0, edge)
            obj@Target(baseTarget.index, baseTarget.position); 
            
            obj.R = baseTarget.R;
            obj.A = baseTarget.A;
            obj.B = baseTarget.B;
            obj.t0 = t0;

            travelTime = edge.length / 80;

        end

        function [tz, dwellTime] = RHCSimpleOptimizer(obj)
           
            t0 = obj.t0_val;
            A = obj.A_val;
            B = obj.B_val;
            R0 = obj.R0_val;

            R_s = R0 + A*(t - t0);
            

            %solve logic
        end
        
        
    end
end