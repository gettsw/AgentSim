classdef AvoidedTarget < Target
    properties
        tz             % Virtual "event" time: end of horizon
        R0_val
        A_val
        J_i              % Accumulated uncertainty
    end

    methods
        function obj = AvoidedTarget(baseTarget, t0)
            obj@Target(baseTarget.index, baseTarget.position);
            
            obj.R0_val = baseTarget.R;
            obj.A_val = baseTarget.A;
            
            
        end

        function J = objective(obj, H)
            % === Inputs ===
            A = obj.A_val;
            R0 = obj.R0_val;
            

    
            % === Closed-form integration result ===
            J = (1 / H) * (R0 * H + 0.5 * A * H^2);

            obj.J_i = J;  % Store in object
        end
    end
end
