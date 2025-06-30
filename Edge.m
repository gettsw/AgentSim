classdef Edge < handle
    properties
        index
        targets % [target1, target2]
        length
        lineHandle
    end
    
    methods
        function obj = Edge(index, targetPair)
            obj.index = index;
            obj.targets = targetPair;
            obj.length = 0;
            obj.lineHandle = [];
        end
        
        function draw(obj, ax)
            p1 = obj.targets(1).position;
            p2 = obj.targets(2).position;
            obj.length = norm(p2 - p1); 
            obj.lineHandle = plot(ax, [p1(1) p2(1)], [p1(2) p2(2)], 'k-', 'LineWidth', 1.5);
        end
    end
end