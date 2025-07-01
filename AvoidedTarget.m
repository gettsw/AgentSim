classdef AvoidedTarget < Target
    

    properties
        tz % event times
        dwellTime
        R0_val
        t0_val
        A_val
        travelTime
        J

    end

    methods
        function obj = AvoidedTarget(baseTarget, t0, edge)
            obj@Target(baseTarget.index, baseTarget.position); 
            
            obj.R0_val = baseTarget.R;
            obj.A_val = baseTarget.A;
            obj.B = baseTarget.B;
            obj.t0 = t0;

            travelTime = edge.length / 80; % The denominator is the speed from the Sketch file

        end

        function RHCSimpleOptimizer(obj, H)
           
            A = obj.A_val;
            R0 = obj.R0_val;

       
            obj.J = (.5)*A*H*H + R0*H

            
        end
        
        
    end
end