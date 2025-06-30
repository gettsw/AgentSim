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
            for i = 1:num_targets
                if norm(obj.position - targets(i).position) < 1e-2
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

        function [targetPos, current_idx] = RHCSimple(obj, targets, adjMatrix)
            num_targets = length(targets);
            current_idx = -1;
            for i = 1:num_targets
                if norm(obj.position - targets(i).position) < 1e-2
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
<<<<<<< HEAD
            
            % Define the spacial horizon for the agent
            cluster = [];
            for i = 1:neighbors
                if targets(neighbors(i)).redsidingAgents ~= Agent.empty(0,0)
                    cluster(end +1) = neighbors(i);
                end
            end
                

           % Optimize Control decisions
            


=======
        
            % Choose next target
            next_idx = neighbors(randi(num_targets));
            targetPos = targets(next_idx).position;
            obj.current_target_idx = next_idx;

           for i=1:neighbors
               classedTarget = Target.empty(num_targets, 0);
               if(neighbors(i).residingAgents == [])
                    if(neighbors(i).arrivalTimes == []) % Visited Target
                       classedTarget = VisitedTarget(i, nieghbors(i).position)
                    
                        
                    end

               end
           end
>>>>>>> 3a3695fd3f050358983bb6025a022c97100794b5
            
        end

    end
end