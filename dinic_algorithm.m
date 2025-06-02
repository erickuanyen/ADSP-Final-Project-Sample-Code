clc;
clear;
close all;

% === Load graph and image ===
disp('Loading graph and image data...');
img = imread("compressed_image.png");
load('graph_data.mat');  % contains adjList, R, C, SOURCE, SINK

% === Run Dinic's Algorithm and measure time ===
tic;
[max_flow, residualList] = dinic_method(adjList, SOURCE, SINK);
elapsed_time = toc;

disp(['Max Flow (Dinic): ', num2str(max_flow)]);
disp(['Elapsed Time: ', num2str(elapsed_time), ' seconds']);

% === Identify foreground using BFS from SOURCE in residual graph ===
disp('Generating cut mask...');
N = R * C;
mask = false(R, C);  % Initialize mask

visited = false(numel(adjList), 1);
queue = SOURCE;
visited(SOURCE) = true;

while ~isempty(queue)
    u = queue(1); queue(1) = [];

    if u <= N
        r = floor((u - 1) / C) + 1;
        c = mod(u - 1, C) + 1;
        mask(r, c) = true;
    end

    for k = 1:size(residualList{u}, 1)
        v = residualList{u}(k,1);
        cap = residualList{u}(k,2);
        if cap > 0 && ~visited(v)
            visited(v) = true;
            queue(end+1) = v;
        end
    end
end

% === Show foreground and background separately ===
foreground = img;
background = img;

for i = 1:R
    for j = 1:C
        if ~mask(i,j)
            foreground(i,j,:) = 0;  % remove background
        else
            background(i,j,:) = 0;  % remove foreground
        end
    end
end

% === Display Results ===
figure; imshow(img); title('Original Image');
figure; imshow(foreground); title('Foreground Segment (Connected to Source)');
figure; imshow(background); title('Background Segment (Connected to Sink)');

% === Overlay the segmentation on the image ===
figure;
imshow(img);
hold on;
redMask = cat(3, ones(R,C), zeros(R,C), zeros(R,C));
h = imshow(redMask);
set(h, 'AlphaData', ~mask * 0.4);  % Red overlay on background
title('Min-Cut Segmentation Result');

% === Generate BFS level map from SOURCE ===
disp('Generating level map from Source...');
level_map_src = -1 * ones(R, C);
level_src = -ones(numel(adjList), 1);
queue = SOURCE;
level_src(SOURCE) = 0;

while ~isempty(queue)
    u = queue(1); queue(1) = [];
    for k = 1:size(residualList{u}, 1)
        v = residualList{u}(k, 1);
        cap = residualList{u}(k, 2);
        if cap > 0 && level_src(v) == -1
            level_src(v) = level_src(u) + 1;
            queue(end+1) = v;
        end
    end
end

for idx = 1:(R*C)
    if level_src(idx) >= 0
        r = floor((idx - 1) / C) + 1;
        c = mod(idx - 1, C) + 1;
        level_map_src(r, c) = level_src(idx);
    end
end

% === Generate BFS level map from SINK ===
disp('Generating level map from Sink...');
level_map_sink = -1 * ones(R, C);
level_sink = -ones(numel(adjList), 1);
queue = SINK;
level_sink(SINK) = 0;

while ~isempty(queue)
    u = queue(1); queue(1) = [];
    for k = 1:size(residualList{u}, 1)
        v = residualList{u}(k, 1);
        cap = residualList{u}(k, 2);
        if cap > 0 && level_sink(v) == -1
            level_sink(v) = level_sink(u) + 1;
            queue(end+1) = v;
        end
    end
end

for idx = 1:(R*C)
    if level_sink(idx) >= 0
        r = floor((idx - 1) / C) + 1;
        c = mod(idx - 1, C) + 1;
        level_map_sink(r, c) = level_sink(idx);
    end
end

% === Display both level maps ===
figure;
imagesc(level_map_src);
axis image off;
colormap(parula);
colorbar;
title('BFS Level Map from Source');

figure;
imagesc(level_map_sink);
axis image off;
colormap(parula);
colorbar;
title('BFS Level Map from Sink');



% === Dinic's Algorithm Function ===
function [max_flow, residualList] = dinic_method(adjList, SOURCE, SINK)
    N = numel(adjList);
    residualList = adjList;
    level = zeros(N,1);
    max_flow = 0;

    while true
        % === BFS to build level graph ===
        level(:) = -1;
        level(SOURCE) = 0;
        queue = SOURCE;

        while ~isempty(queue)
            u = queue(1); queue(1) = [];
            for k = 1:size(residualList{u}, 1)
                v = residualList{u}(k,1);
                cap = residualList{u}(k,2);
                if cap > 0 && level(v) < 0
                    level(v) = level(u) + 1;
                    queue(end+1) = v;
                end
            end
        end

        if level(SINK) < 0
            break; % No more augmenting paths
        end

        % === DFS to find blocking flow ===
        ptr = ones(N,1);
        while true
            pushed = dfs(SOURCE, Inf);
            if pushed == 0
                break;
            end
            max_flow = max_flow + pushed;
        end
    end

    % --- DFS function (nested) ---
    function pushed = dfs(u, flow)
        if u == SINK
            pushed = flow;
            return;
        end

        for i = ptr(u):size(residualList{u},1)
            v = residualList{u}(i,1);
            cap = residualList{u}(i,2);
            if level(v) == level(u)+1 && cap > 0
                min_cap = min(flow, cap);
                tr = dfs(v, min_cap);
                if tr > 0
                    residualList{u}(i,2) = residualList{u}(i,2) - tr;
                    % update backward edge
                    found = false;
                    for j = 1:size(residualList{v},1)
                        if residualList{v}(j,1) == u
                            residualList{v}(j,2) = residualList{v}(j,2) + tr;
                            found = true;
                            break;
                        end
                    end
                    if ~found
                        residualList{v}(end+1,:) = [u, tr];
                    end
                    pushed = tr;
                    return;
                end
            end
            ptr(u) = ptr(u) + 1;
        end
        pushed = 0;
    end
end
