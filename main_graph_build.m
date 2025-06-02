clc;
clear;
close all;

% === Load image ===
disp('Read Image.');
img = imread('compressed_image.png');           
[R, C, ~] = size(img);
disp('Image Imported.');
hsv_img = rgb2hsv(img);              
disp('Convert RGB Matrix Into HSV.');

% === Setup graph ===
nodes = R * C;
SOURCE = nodes + 1;
SINK   = nodes + 2;
adjList = cell(nodes + 2, 1);        % Include image nodes + source + sink
weight_list = [];                   % Store edge weights
deviation_param = 3;

% 8-connected neighbor offsets (half-storage)
offsets = [ ...
     0  1;
     1  0;
     1  1;
     1 -1;
];

% === Build HSV-weighted undirected adjacency list ===
for i = 1:R
    for j = 1:C
        ind = (i - 1) * C + j;
        for k = 1:size(offsets, 1)
            nr = i + offsets(k, 1);
            nc = j + offsets(k, 2);

            if nr >= 1 && nr <= R && nc >= 1 && nc <= C 
                nind = (nr - 1) * C + nc;
                hsv_i = squeeze(hsv_img(i, j, :));
                hsv_j = squeeze(hsv_img(nr, nc, :));

                dissimilarity = ...
                    (hsv_i(1) - hsv_j(1))^2 * 1 + ...
                    (hsv_i(2) - hsv_j(2))^2 * 0.1 + ...
                    (hsv_i(3) - hsv_j(3))^2 * 2;

                weight = exp(-deviation_param * dissimilarity);
                cap = 1e6*round(weight,6);
                adjList{ind}(end + 1, :) = [nind, cap];
                adjList{nind}(end + 1, :) = [ind, cap];
                weight_list(end + 1) = cap;
            end
        end
    end
end

disp('Main Adjacency Complete.');
disp('Loading scribbled parts.');

% === Load scribbles ===
foreground = readmatrix('image_foreground.csv');
background = readmatrix('image_background.csv');

% === Clamp and connect foreground to SOURCE ===
disp('Connect foreground to source.');
for k = 1:size(foreground, 1)
    r = max(1, min(R, foreground(k, 1)));
    c = max(1, min(C, foreground(k, 2)));
    nodeIndex = (r - 1) * C + c;
    adjList{SOURCE}(end + 1, :) = [nodeIndex, Inf];
end

% === Clamp and connect background to SINK ===
disp('Connect background to sink.');
for k = 1:size(background, 1)
    r = max(1, min(R, background(k, 1)));
    c = max(1, min(C, background(k, 2)));
    nodeIndex = (r - 1) * C + c;
    adjList{nodeIndex}(end + 1, :) = [SINK, Inf];
end

disp('Graph with 8-connected HSV-weighted edges and scribble seeds built.');

% === Save graph data ===
save('graph_data.mat', 'adjList', 'R', 'C', 'SOURCE', 'SINK');
disp('Graph data saved to graph_data.mat');

% === Plot edge weight distribution ===
figure;
histogram(weight_list, 'BinMethod', 'auto', 'FaceColor', [0.2 0.6 0.8]);
xlabel('Edge Weight');
ylabel('Frequency');
title('Distribution of Edge Weights');
grid on;
