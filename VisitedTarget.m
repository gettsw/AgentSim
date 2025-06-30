classdef VisitedTarget < Target
    

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
        function obj = VisitedTarget(baseTarget, t0, edge)
            obj@Target(baseTarget.index, baseTarget.position); 
            
            obj.R = baseTarget.R;
            obj.A = baseTarget.A;
            obj.B = baseTarget.B;
            obj.t0 = t0;

            travelTime = edge.length / 80;

        end

        function [tz, dwellTime] = RHCSimpleOptimizer(obj)
            t_arr = t0 + travelTime;
            t0 = obj.t0_val;
            A = obj.A_val;
            B = obj.B_val;
            R0 = obj.R0_val;

            S = (t - t_arr) * heaviside(t - t_arr);
            R_raw = R0 + A*(t - t0) - B * S; 

            solutions = solve(R_raw == 0, 'Real', true);

            tz_candidates = double(solutions);
            tz_candidates = tz_candidates(tz_candidates >= t0);

            obj.tz = min(tz_candidates);

            R_s = R_raw *heaviside(obj.tz - t);

            %solve logic
        end
        
        
    end
end