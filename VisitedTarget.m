classdef VisitedTarget < Target
    properties
        t0           % Time when agent arrived at target
        tz           % Time when agent departs from target  
        dwellTime    % Time spent at target
        R0_val       % Initial uncertainty value
        t0_val       % Initial time value
        A_val        % Uncertainty growth rate
        B_val        % Uncertainty reduction rate
        travelTime   % Time taken to travel to this target
        J_i          % Objective function value
    end

    methods
        function obj = VisitedTarget(baseTarget, t0, edge)
            % Unconditional superclass constructor call
            obj = obj@Target(baseTarget.index, baseTarget.position);
            
            % Copy all properties from baseTarget
            props = properties(baseTarget);
            for i = 1:length(props)
                if isprop(obj, props{i})
                    obj.(props{i}) = baseTarget.(props{i});
                end
            end

            % Set visit-specific properties
            obj.t0 = t0;
            obj.t0_val = t0;
            obj.R0_val = baseTarget.R;
            obj.A_val = baseTarget.A;
            obj.B_val = baseTarget.B;
            obj.travelTime = edge.length / 80; % Travel time = distance/speed
        end

        function J = objective(obj, dwellTime)
            % Validate input
            if dwellTime <= 0
                error('dwellTime must be positive');
            end

            % Calculate important time points
            t_arr = obj.t0_val + obj.travelTime;
            t_z_val = t_arr + dwellTime;

            % Symbolic calculation
            syms t;
            S = (t - t_arr) * heaviside(t - t_arr);
            R_raw = obj.R0_val + obj.A_val*(t - obj.t0_val) - obj.B_val * S;
            R_s = R_raw * heaviside(t_z_val - t);

            % Numeric integration
            t_vals = linspace(obj.t0_val, t_z_val, 500);
            R_vals = double(subs(R_s, t, t_vals));
            J = (1/(obj.travelTime + dwellTime)) * trapz(t_vals, R_vals);

            % Store results
            obj.tz = t_z_val;
            obj.dwellTime = dwellTime;
            obj.J_i = J;
        end
    end
end