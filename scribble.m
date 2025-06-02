clc;
clear;
close all;

% === Load Image ===
img = imread(['compressed_image.png']);
imshow(img);
title('Draw FOREGROUND (green) strokes. Press ENTER to switch to red.');
hold on;

% === Draw Multiple Foreground Scribbles ===
foreground = [];
disp('Drawing foreground (green)...');

while true
    h = drawfreehand('Color', 'g');
    path = round(h.Position);
    if ~isempty(path)
        foreground = [foreground; [path(:,2), path(:,1)]];
    end

    % Wait for Enter to switch
    disp('Draw another or press ENTER to switch to red...');
    k = waitforbuttonpress;
    if k == 1 && strcmp(get(gcf,'CurrentCharacter'), char(13))  % Enter key
        break;
    end
end

% === Draw Multiple Background Scribbles ===
title('Draw BACKGROUND (red) strokes. Press ENTER when done.');
background = [];
disp('Drawing background (red)...');

while true
    h = drawfreehand('Color', 'r');
    path = round(h.Position);
    if ~isempty(path)
        background = [background; [path(:,2), path(:,1)]];
    end

    % Wait for Enter to finish
    disp('Draw another or press ENTER to finish...');
    k = waitforbuttonpress;
    if k == 1 && strcmp(get(gcf,'CurrentCharacter'), char(13))  % Enter key
        break;
    end
end

% === Save Coordinates to CSV ===
writematrix(foreground, 'image_foreground.csv');
writematrix(background, 'image_background.csv');
disp('Foreground and background coordinates saved.');

% === Overlay and Save Scribble Visualization ===
imshow(img);
hold on;
plot(foreground(:,2), foreground(:,1), 'g.', 'MarkerSize', 5);
plot(background(:,2), background(:,1), 'r.', 'MarkerSize', 5);
title('Scribbled Image');
hold off;
saveas(gcf, 'scribble_overlay.png');
disp('Scribble overlay saved as scribble_overlay.png');
