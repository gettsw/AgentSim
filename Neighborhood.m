classdef Neighborhood
    properties (Access = private)
        cluster  % Cell array of VisitedTarget + AvoidedTarget objects
        J        % Optimal objective value
        H_opt    % Optimal dwell time
        is_optimized = false % Flag to track if optimization was performed
    end

    methods
        function obj = Neighborhood(classedTargets)
            obj.cluster = classedTargets;
            obj.J = Inf;
            obj.H_opt = 0;
        end

        function J = getOptimalJ(obj)
            % Returns the optimal cost J
            if ~obj.is_optimized
                obj.optimize();
            end
            J = obj.J;
        end
        
        function H_opt = getOptimalDwellTime(obj)
            % Returns the optimal dwell time H
            if ~obj.is_optimized
                obj.optimize();
            end
            H_opt = obj.H_opt;
        end
        
        function optimize(obj)
            % Private optimization method (called by both getter methods)
            % === Split cluster ===
            visited = [];
            avoided = {};
        
            for i = 1:length(obj.cluster)
                target = obj.cluster{i};
                if isa(target, 'VisitedTarget')
                    visited = target;
                elseif isa(target, 'AvoidedTarget')
                    avoided{end+1} = target; %#ok<AGROW>
                end
            end
        
            if isempty(visited)
                error('Neighborhood must contain one VisitedTarget.');
            end
        
            % === Objective function J(H) ===
            cost_fn = @(H) visited.objective(H) + ...
                sum(cellfun(@(a) a.objective(H), avoided));
        
            % === Optimization ===
            H_lower = 0.1;  % small positive time to avoid division-by-zero
            H_upper = 10;   % max dwell time
        
            options = optimset('TolX', 1e-3, 'Display', 'off');
            [obj.H_opt, obj.J] = fminbnd(cost_fn, H_lower, H_upper, options);
        
            % Recompute and store final values in each target
            visited.objective(obj.H_opt);
            for j = 1:length(avoided)
                avoided{j}.objective(obj.H_opt);
            end
            
            obj.is_optimized = true;
        end
    end
end