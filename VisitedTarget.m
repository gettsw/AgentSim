classdef VisitedTarget < Target
    

    properties
<<<<<<< HEAD
        tz % event times
        dwellTime
        R0_val
        t0_val
        A_val
        B_val
        travelTime
=======
        tbar_i
        tbar_i1
>>>>>>> 3a3695fd3f050358983bb6025a022c97100794b5

    end

    methods
<<<<<<< HEAD
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
        
=======
        function obj = VisitedTarget()
            
            syms t A B R0 t0 t_z real
            
            % === Parameters and arrival times ===
            A_val = Target.A;
            B_val = 2;
            R0_val = 3;
            t0_val = 0;
            t_arr_vals = [1, 2, 3];  % event times
            N = length(t_arr_vals);
            t_ = sym('t_', [1 N], 'real');
            
            % === Build functions ===
            S = 0;
            for i = 1:N
                S = S + (t - t_(i)) * heaviside(t - t_(i));
            end
            R_raw = R0 + A*(t - t0) - B * S;
            R_s = R_raw * heaviside(t_z - t);
            
            % Substitute numerical values into R_raw (excluding t_z since we're solving R_raw=0)
            R_raw_num = subs(R_raw, [A, B, R0, t0, t_], [A_val, B_val, R0_val, t0_val, t_arr_vals]);
            
            % Solve symbolically and get all real solutions
            solutions = solve(R_raw_num == 0, t, 'Real', true);
            
            % Convert to numeric and filter valid solutions
            tz_candidates = double(solutions);
            tz_candidates = tz_candidates(tz_candidates >= t0_val); % Only times after t0
            
            % Find the smallest (earliest) solution
            if ~isempty(tz_candidates)
                correct_tz = min(tz_candidates);
                
            end
            
            
            % Time vector for plotting
            t_vals = linspace(t0_val, tbar_i1 + Target.dwellTime, 500);
            
            % === Substitute numeric values ===
            S_num = subs(S, [t_, t], [t_arr_vals, t]);
            v_i_num = heaviside(t - t0_val) - heaviside(t - correct_tz);
            R_s_num = subs(R_s, ...
                [A, B, R0, t0, t_, t_z], ...
                [A_val, B_val, R0_val, t0_val, t_arr_vals, correct_tz]);

            S_vals = double(subs(S_num, t, t_vals));
            v_i_vals = double(subs(v_i_num, t, t_vals));
            R_vals = double(subs(R_s_num, t, t_vals));
            area_vals = (1/tbar_i1 + Target.dwellTime) * cumtrapz(t_vals, R_vals);
     
        end

>>>>>>> 3a3695fd3f050358983bb6025a022c97100794b5
        
    end
end