classdef Agent < handle
    properties
        index          % Unique identifier
        position       % [x,y] coordinates
        orientation    % Angle in radians (0 points to right)
        speed          % Units per second
        color          % Display color
        size           % Triangle side length
        graphicHandle  % Patch graphic handle
        textHandle     % Text label handle
        ax             % Axis handle for drawing
        current_target_idx % Current target index
        dwellTime = 0;       % Current remaining dwell time in seconds
        movementActive = false;    % Is the agent currently moving?
        xSteps = [];               % Path X
        ySteps = [];               % Path Y
        stepIndex = 1;

        % NEW: property to store the planned next target (position)
        nextTarget = [];

        % Properties for neighborhood optimization
        cluster_J        % Optimal objective value
        cluster_H_opt    % Optimal dwell time
        cluster_optimized = false % Flag to track if optimization was performed
    end

    methods
        function obj = Agent(index, position, speed)
            % Constructor
            obj.index = index;
            obj.position = position;
            obj.orientation = 0;
            obj.speed = speed;
            obj.color = [0.8, 0.2, 0.2];
            obj.size = 8;
            obj.graphicHandle = [];
            obj.textHandle = [];
            obj.current_target_idx = [];

            % Initialize optimization properties
            obj.cluster_J = Inf;
            obj.cluster_H_opt = 0;
            obj.cluster_optimized = false;

            % Ensure nextTarget starts empty
            obj.nextTarget = [];
        end

        function draw(obj, ax)
            obj.ax = ax;

            if ~isempty(obj.graphicHandle) && isvalid(obj.graphicHandle)
                delete(obj.graphicHandle);
            end
            if ~isempty(obj.textHandle) && isvalid(obj.textHandle)
                delete(obj.textHandle);
            end

            [x, y] = obj.calculateVertices();

            obj.graphicHandle = patch(ax, x, y, obj.color, ...
                'EdgeColor', 'k', ...
                'LineWidth', 1.5, ...
                'FaceAlpha', 0.8);

            obj.textHandle = text(ax, obj.position(1), obj.position(2), ...
                num2str(obj.index), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontWeight', 'bold', ...
                'Color', 'w', ...
                'FontSize', 8);
        end

        function [x, y] = calculateVertices(obj)
            height = obj.size * sqrt(3)/2;

            x_base = [obj.size/2, -obj.size/2, -obj.size/2, obj.size/2];
            y_base = [0, height/2, -height/2, 0];

            x_rot = x_base * cos(obj.orientation) - y_base * sin(obj.orientation);
            y_rot = x_base * sin(obj.orientation) + y_base * cos(obj.orientation);

            % Translate to current position
            x = x_rot + obj.position(1);
            y = y_rot + obj.position(2);
        end

        function updatePosition(obj)
            % Update the graphic handles with current position/orientation
            [x, y] = obj.calculateVertices();
            set(obj.graphicHandle, 'XData', x, 'YData', y);
            set(obj.textHandle, 'Position', [obj.position(1), obj.position(2), 0]);
        end

        function moveTo(obj, targetPos)
            % Simply update the position and orientation (no animation)
            delta = targetPos - obj.position;
            obj.orientation = atan2(delta(2), delta(1));
            obj.position = targetPos;
        end

        function [targetPos, current_idx] = randomChoice(obj, targets, adjMatrix)
            num_targets = length(targets);
            current_idx = -1;
            % Use same proximity threshold as main loop (0.1) for consistency
            proximityThresh = 0.1;
            for i = 1:num_targets
                if norm(obj.position - targets(i).position) < proximityThresh
                    current_idx = i;
                    break;
                end
            end

            if current_idx == -1
                error("Agent is not near any known target to start the walk.");
            end

            neighbors = find(adjMatrix(current_idx, :));
            if isempty(neighbors)
                targetPos = [];
                return;
            end

            % Choose next target randomly from neighbors
            next_idx = neighbors(randi(length(neighbors)));
            targetPos = targets(next_idx).position;
            obj.current_target_idx = next_idx;
        end

        function [targetPos, current_idx, optimalH] = RHCSimple(obj, targets, adjMatrix, simTime, edges)
            num_targets = length(targets);
            current_idx = -1;

            % --- Find current target index the agent is on ---
            % Use same threshold as main loop
            proximityThresh = 0.1;
            for i = 1:num_targets
                if norm(obj.position - targets(i).position) < proximityThresh
                    current_idx = i;
                    break;
                end
            end

            if current_idx == -1
                error('Agent is not near any known target to start the walk.');
            end

            neighbors = find(adjMatrix(current_idx, :));
            if isempty(neighbors)
                targetPos = [];
                optimalH = [];
                return;
            end

            % --- Initialize tracking variables ---
            minJ = inf;
            bestNeighborIdx = [];
            optimalH = [];
            bestCluster = {};  % Cell array for best cluster

            % --- Evaluate each neighbor ---
            for i = 1:length(neighbors)
                neighborIdx = neighbors(i);

                % Skip neighbors with residing agents
                if ~isempty(targets(neighborIdx).residingAgents)
                    continue;
                end

                % --- Use a cell array for processed targets ---
                processedTargets = {};

                % Find the edge between current and neighbor. If no edge, skip.
                edge = obj.findEdge(current_idx, neighborIdx, edges);
                if isempty(edge) || isempty(targets(neighborIdx))
                    continue;
                end

                % Create a temporary target object for this neighbor (visited)
                tempVisitedTarget = Target(targets(neighborIdx).index, targets(neighborIdx).position);
                tempVisitedTarget.initializeAsVisited(targets(neighborIdx), simTime, edge);
                processedTargets{end+1} = tempVisitedTarget;

                % Create temporary targets for all other neighbors (avoided)
                for j = 1:length(neighbors)
                    otherIdx = neighbors(j);
                    if otherIdx ~= neighborIdx
                        % Create a temporary target and initialize it as avoided
                        tempAvoidedTarget = Target(targets(otherIdx).index, targets(otherIdx).position);
                        tempAvoidedTarget.initializeAsAvoided(targets(otherIdx), simTime);
                        processedTargets{end+1} = tempAvoidedTarget;
                    end
                end

                % --- Optimize dwell time ---
                if ~isempty(processedTargets)
                    % Convert cell array to standard object array
                    [currentH, currentJ] = obj.optimizeClusterDwellTime(processedTargets);

                    % Track best neighbor
                    if currentJ < minJ
                        minJ = currentJ;
                        bestNeighborIdx = neighborIdx;
                        bestCluster = processedTargets;
                        optimalH = currentH;
                    end
                end
            end

            % --- Return results ---
            if ~isempty(bestNeighborIdx)
                targetPos = targets(bestNeighborIdx).position;
                current_idx = bestNeighborIdx;
            else
                targetPos = [];
                optimalH = [];
            end
        end

        % ========== NEIGHBORHOOD OPTIMIZATION METHODS ==========

        function [H_opt, J] = optimizeClusterDwellTime(obj, cluster)
            % Split cluster into visited and avoided targets
            visited = [];
            avoided = {};

            for i = 1:length(cluster)
                target = cluster{i};
                if ~isempty(target.travelTime)
                    visited = target;
                else
                    avoided{end+1} = target; %#ok<AGROW>
                end
            end

            if isempty(visited)
                error('Cluster must contain one visited target.');
            end

            % Objective function (numeric-only)
            cost_fn = @(H) visited.objectiveVisited_numeric(H) + ...
                sum(cellfun(@(a) a.objectiveAvoided_numeric(H), avoided));

            % Bounds and initial guess
            H_lower = 0.1;
            H_upper = 6;
            H0 = (H_lower + H_upper) / 2;

            % Options for fmincon
            options = optimoptions('fmincon', ...
                'Display', 'off', ...
                'Algorithm', 'sqp', ...
                'TolFun', 1e-6, ...
                'TolX', 1e-6);

            % Optimize dwell time
            [H_opt, J] = fmincon(cost_fn, H0, [], [], [], [], H_lower, H_upper, [], options);

            % Update visited and avoided targets with optimized dwell time
            visited.objectiveVisited_numeric(H_opt);
            for j = 1:length(avoided)
                avoided{j}.objectiveAvoided_numeric(H_opt);
            end

            % Store results in agent
            obj.cluster_H_opt = H_opt;
            obj.cluster_J = J;
            obj.cluster_optimized = true;
        end


        function J = getOptimalJ(obj)
            % Returns the optimal cost J
            if ~obj.cluster_optimized
                error('Optimization has not been performed yet.');
            end
            J = obj.cluster_J;
        end

        function H_opt = getOptimalDwellTime(obj)
            % Returns the optimal dwell time H
            if ~obj.cluster_optimized
                error('Optimization has not been performed yet.');
            end
            H_opt = obj.cluster_H_opt;
        end

    end

    methods (Access = private)
        function edge = findEdge(obj, sourceIdx, destIdx, edges)
            % Helper function to find edge between two targets
            edge = []; % return empty if not found
            if isempty(edges)
                return;
            end
            for e = edges
                if (e.targets(1).index == sourceIdx && e.targets(2).index == destIdx) || ...
                   (e.targets(1).index == destIdx && e.targets(2).index == sourceIdx)
                    edge = e;
                    return;
                end
            end
            % if not found, return [] instead of error
        end
    end
end
