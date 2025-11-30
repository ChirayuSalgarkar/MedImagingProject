% scripts/make_phantom.m
% Purpose: Convert STL mesh into a voxelized 3D matrix (k-Wave compatible)
% Reference: [cite: 14] Convert STL into representation for simulation

clear; clc;

%% 1. Configuration
filename = 'babyMSR.stl'; % Change this to the real file later
input_path = fullfile('data', 'input', filename);
output_path = fullfile('data', 'output', 'phantom_data.mat');

% Load Physics Parameters
p = setup_params(); 

%% 2. Load and Scale STL File
if ~isfile(input_path)
    error('STL file not found at %s', input_path);
end
mesh = stlread(input_path);
fprintf('Original Bounds (X): %.2f to %.2f\n', min(mesh.Points(:,1)), max(mesh.Points(:,1)));

% UNIT CORRECTION: Check if the object is "huge" (likely mm)
% If the object is wider than 1 meter, it is definitely in mm (or inches).
width_x = range(mesh.Points(:,1));
if width_x > 1 
    fprintf('Detected dimensions > 1.0. Assuming units are MM. Scaling to METERS...\n');
    scale_factor = 1e-3;
    
    % Create a new triangulation with scaled points
    scaled_points = mesh.Points * scale_factor;
    mesh = triangulation(mesh.ConnectivityList, scaled_points);
else
    fprintf('Dimensions appear to be in Meters. No scaling applied.\n');
end

fprintf('New Bounds (X): %.4f to %.4f meters\n', min(mesh.Points(:,1)), max(mesh.Points(:,1)));
fprintf('Loaded STL: %d faces, %d vertices.\n', size(mesh.ConnectivityList, 1), size(mesh.Points, 1));

%% 3. Define the Voxel Grid (k-Wave style)
% We need a grid slightly larger than the object
dx = 1e-3; % 1mm resolution (Decrease to 0.5mm for higher quality later)
pad_size = 5e-3; % 5mm padding around object

min_bounds = min(mesh.Points) - pad_size;
max_bounds = max(mesh.Points) + pad_size;

% Create grid vectors
x_vec = min_bounds(1):dx:max_bounds(1);
y_vec = min_bounds(2):dx:max_bounds(2);
z_vec = min_bounds(3):dx:max_bounds(3);

[X, Y, Z] = ndgrid(x_vec, y_vec, z_vec);
fprintf('Grid dimensions: [%d x %d x %d]\n', size(X));

%% 4. Voxelization (Corrected for Surface Mesh)
fprintf('Voxelizing using alphaShape (this may take 1-2 minutes)...\n');

% 1. Create an "alpha shape" from the vertices
% This intelligently wraps a solid volume around your surface points
shp = alphaShape(mesh.Points(:,1), mesh.Points(:,2), mesh.Points(:,3));


shp.Alpha = criticalAlpha(shp, 'one-region'); 

% 3. Check which grid points are inside this shape
% query_points must be columns of x, y, z
inside_mask = inShape(shp, X(:), Y(:), Z(:));

% Reshape back to 3D volume
vol_mask = reshape(inside_mask, size(X));
vol_mask = double(vol_mask); % Convert logical to 0/1

fprintf('Voxelization complete. Volume fraction: %.2f%%\n', 100*mean(vol_mask(:)));

%% 5. Map Physical Properties
% Create property maps based on the mask

medium.sound_speed = ones(size(vol_mask)) * 1500; % Background (Water)
medium.density     = ones(size(vol_mask)) * 1000; % Background (Water)

% Assign Fetal properties inside the mask
medium.sound_speed(vol_mask == 1) = p.us.c0;
medium.density(vol_mask == 1)     = p.us.rho0;
medium.alpha_coeff(vol_mask == 1) = p.us.alpha_coeff;

%% 6. Save and Visualize
save(output_path, 'medium', 'vol_mask', 'X', 'Y', 'Z', 'dx');
fprintf('Phantom saved to %s\n', output_path);

% Quick QC Visualization (Robust method)
figure;
mid_slice_idx = round(size(vol_mask, 3) / 2); % Find the middle index

% Show the middle slice (Matrix indexing: X is rows, Y is columns)
imagesc(y_vec, x_vec, vol_mask(:, :, mid_slice_idx)); 
axis image; 
colormap gray; 
colorbar;
title('Voxelized Phantom Cross-Section (Mid-Z)');
xlabel('Y Position (m)');
ylabel('X Position (m)');
drawnow;