classdef AvoidedTarget < Target
    properties
        t0           % Reference time
        edge         % Connection edge
    end

    methods
        function obj = AvoidedTarget(baseTarget, t0, edge)
            % Unconditional superclass constructor call (MUST BE FIRST)
            obj = obj@Target(baseTarget.index, baseTarget.position);
            
            % Copy all properties from base target
            props = properties(baseTarget);
            for i = 1:length(props)
                if isprop(obj, props{i})
                    obj.(props{i}) = baseTarget.(props{i});
                end
            end

            % Set avoidance-specific properties
            obj.t0 = t0;
            obj.edge = edge;
        end

        % Zero-argument constructor (optional, only needed if you explicitly call AvoidedTarget())
        function obj = AvoidedTarget()
            obj = obj@Target();  % Zero-argument superclass call
        end

        function J = objective(obj, ~)
            % Simplified objective for avoided targets
            J = obj.R; % Just use current uncertainty
        end
    end
end