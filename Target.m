classdef Target < handle
    properties
        index
        position
        residingAgents
        recentArrivals
        arrivalTimes
        departureTimes
        color
        markerSize
        graphicHandle
        labelHandle
        barHandle           % Rectangular bar for uncertainty
        R                   % Uncertainty state
        A                   % Growth rate
        B = 10               % Decay rate

        % Visited target properties
        t0                  % Time when agent arrived
        tz                  % Time when agent departs
        dwellTime           % Time spent at target
        R0_val              % Initial uncertainty value
        t0_val              % Initial time value
        travelTime          % Travel time
        J_i                 % Objective function value

        % Avoided target properties
        tz_avoided          % Virtual "event" time: end of horizon

        % Precomputed calculation values
        A_val
        B_val
    end

    properties (Access = private)
        prevAgentIDs
    end

    methods
        function obj = Target(index, position)
            obj.index = index;
            obj.position = position;
            obj.residingAgents = [];
            obj.recentArrivals = [];
            obj.arrivalTimes = [];
            obj.departureTimes = [];
            obj.color = 'b';
            obj.markerSize = 8;
            obj.graphicHandle = [];
            obj.labelHandle = [];
            obj.barHandle = [];
            obj.R = 0;
            obj.A = 1;
            obj.prevAgentIDs = [];

            obj.t0 = [];
            obj.tz = [];
            obj.dwellTime = [];
            obj.R0_val = [];
            obj.t0_val = [];
            obj.travelTime = [];
            obj.J_i = [];
            obj.tz_avoided = [];
            obj.A_val = [];
            obj.B_val = [];
        end

        function draw(obj, ax)
            obj.barHandle = rectangle(ax, ...
                'Position', obj.computeBarPosition(), ...
                'FaceColor', 'y', ...
                'EdgeColor', 'k', ...
                'LineWidth', 0.5, ...
                'FaceAlpha', 0.5, ...
                'HandleVisibility', 'off');

            obj.graphicHandle = plot(ax, obj.position(1), obj.position(2), 'o', ...
                'MarkerSize', obj.markerSize, ...
                'MarkerFaceColor', obj.color, ...
                'MarkerEdgeColor', 'k');

            obj.labelHandle = text(ax, obj.position(1), obj.position(2) - 0.04, ...
                num2str(obj.index), ...
                'Color', obj.color, ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'center');
        end

        function updateUncertainty(obj, dt)
            Ni = length(obj.residingAgents);
            vi = double(obj.R > 0 || obj.A / obj.B > Ni);
            dR = (obj.A - obj.B * Ni) * vi * dt;
            obj.R = max(0, obj.R + dR);

            if ~isempty(obj.barHandle) && isvalid(obj.barHandle)
                set(obj.barHandle, 'Position', obj.computeBarPosition());
            end
        end

        function updateResidingAgents(obj, agentList, globalTime)
            if isempty(agentList)
                currentIDs = [];
            elseif isobject(agentList)
                currentIDs = [agentList.index];
            elseif iscell(agentList)
                currentIDs = cellfun(@(x) x.index, agentList);
            else
                error('Invalid agentList type: %s', class(agentList));
            end

            newArrivals = setdiff(currentIDs, obj.prevAgentIDs);
            departures = setdiff(obj.prevAgentIDs, currentIDs);

            for id = newArrivals(:)'
                obj.arrivalTimes(end+1) = globalTime;
                obj.recentArrivals(end+1) = double(id);
            end

            for id = departures(:)'
                obj.departureTimes(end+1) = globalTime;
                obj.recentArrivals(obj.recentArrivals == id) = [];
            end

            if isempty(obj.recentArrivals)
                obj.arrivalTimes = [];
                obj.departureTimes = [];
            end

            obj.prevAgentIDs = currentIDs;
            obj.residingAgents = agentList;
        end

        % ================= VISITED TARGET METHODS =================
        function initializeAsVisited(obj, baseTarget, t0, edge)
            % Copy properties
            props = properties(baseTarget);
            for i = 1:length(props)
                if isprop(obj, props{i}) && ~strcmp(props{i}, 'index') && ~strcmp(props{i}, 'position')
                    obj.(props{i}) = baseTarget.(props{i});
                end
            end

            obj.t0 = t0;
            obj.t0_val = t0;
            obj.R0_val = baseTarget.R;
            obj.A_val = baseTarget.A;
            obj.B_val = baseTarget.B;
            obj.travelTime = edge.length / 80; % distance / speed
        end

        function J = objectiveVisited_numeric(obj, dwellTime)
            % Ensure positive dwell time
            dwellTime = max(dwellTime, 1e-6) - obj.travelTime;
        
            % Compute arrival and departure times
            t_arr = obj.t0_val + obj.travelTime;
            t_z_val = t_arr + dwellTime;
        
            % Time vector for numerical integration
            t_vals = linspace(t_arr, t_z_val, 200);
        
            % --- Compute raw uncertainty ---
            R_raw = obj.R0_val + obj.A_val*(t_vals - obj.t0_val) - obj.B_val*(t_vals - t_arr);
        
            % --- Heaviside-like mask: stop uncertainty when it hits zero ---
            heaviside_mask = double(R_raw >= 0);  % 1 where R_raw >= 0, else 0
            R_vals = R_raw .* heaviside_mask;
        
            % --- Trapezoidal integration of uncertainty ---
            integral_val = trapz(t_vals, R_vals);
        
            % --- Objective function: average over travel+dwell time ---
            J = integral_val / (obj.travelTime + dwellTime);
        
            % --- Store results in the target/agent object ---
            obj.tz = t_z_val;      % departure time
            obj.dwellTime = dwellTime;
            obj.J_i = J;
        end



        % ================= AVOIDED TARGET METHODS =================
        function initializeAsAvoided(obj, baseTarget, t0)
            obj.R0_val = baseTarget.R;
            obj.A_val = baseTarget.A;
            obj.t0_val = t0;
        end

        function J = objectiveAvoided_numeric(obj, H)
            J = (obj.R0_val * H + 0.5 * obj.A_val * H^2) / H;
            obj.J_i = J;
        end

        % ================= HELPER METHODS =================
        function resetTypeSpecificProperties(obj)
            obj.t0 = [];
            obj.tz = [];
            obj.dwellTime = [];
            obj.R0_val = [];
            obj.t0_val = [];
            obj.travelTime = [];
            obj.J_i = [];
            obj.tz_avoided = [];
            obj.A_val = [];
            obj.B_val = [];
        end
    end

    methods (Access = private)
        function pos = computeBarPosition(obj)
            barWidth = 1.5;
            scale = 2;
            barHeight = obj.R * scale;
            barX = obj.position(1) - barWidth / 2;
            barY = obj.position(2) + 1;
            pos = [barX, barY, barWidth, barHeight];
        end
    end
end
