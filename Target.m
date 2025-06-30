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
        B = 2               % Decay rate
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
            obj.A = 0.5 + (obj.B - 1.5) * rand(); % A ∈ [0.5, B - 1]
            obj.prevAgentIDs = [];
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
    end

    methods (Access = private)
        function pos = computeBarPosition(obj)
            % Returns the [x, y, width, height] of the uncertainty bar
            barWidth = 1.5;
            scale = 2; % scaling factor for visual clarity
            barHeight = obj.R * scale;
            barX = obj.position(1) - barWidth / 2;
            barY = obj.position(2) + 1;
            pos = [barX, barY, barWidth, barHeight];
        end
    end
end
