% make_phantom.m
% Purpose: Convert STL mesh into a voxelized 3D volume for CT simulation (ASTRA)

clear; clc;

%% 1. Configuration


input_path = 'D:\Profiles\jib7395\Downloads\astra-toolbox-2.4.0-matlab-win-x64\astra-2.4.0\data\input\babyMSR.stl';

output_path = 'D:\Profiles\jib7395\Downloads\astra-toolbox-2.4.0-matlab-win-x64\astra-2.4.0\data\output\phantom_data.mat';

out_dir = fileparts(output_path);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end


%% 2. Load and Scale STL Mesh


if ~isfile(input_path)
    error('STL file not found:\n%s', input_path);
end

fprintf('Loading STL from:\n%s\n\n', input_path);
mesh = stlread(input_path);

fprintf('Original Bounds (X): %.2f to %.2f\n', min(mesh.Points(:,1)), max(mesh.Points(:,1)));

width_x = max(mesh.Points(:,1)) - min(mesh.Points(:,1));

% Detect units
if width_x > 1
    fprintf('Detected large object → assuming STL units are millimeters.\n');
    fprintf('Scaling to meters...\n\n');
    scale_factor = 1e-3;
    scaled_points = mesh.Points * scale_factor;
    mesh = triangulation(mesh.ConnectivityList, scaled_points);
else
    fprintf('Mesh units appear to be meters. No scaling applied.\n\n');
end

fprintf('Scaled Bounds (X): %.4f to %.4f meters\n', min(mesh.Points(:,1)), max(mesh.Points(:,1)));
fprintf('Loaded STL: %d faces, %d vertices.\n\n', size(mesh.ConnectivityList,1), size(mesh.Points,1));


%% 3. Define Voxel Grid

dx = 1e-3;    % 1 mm resolution in meters
pad = 5e-3;   % 5 mm padding

min_bounds = min(mesh.Points) - pad;
max_bounds = max(mesh.Points) + pad;

x_vec = min_bounds(1):dx:max_bounds(1);
y_vec = min_bounds(2):dx:max_bounds(2);
z_vec = min_bounds(3):dx:max_bounds(3);

nx = numel(x_vec);
ny = numel(y_vec);
nz = numel(z_vec);

fprintf('Voxel grid dimensions: [%d x %d x %d]\n\n', nx, ny, nz);

[X, Y, Z] = ndgrid(x_vec, y_vec, z_vec);


%% 4. Voxelization using alphaShape

fprintf('Voxelizing mesh using alphaShape...\n');

shp = alphaShape(mesh.Points(:,1), mesh.Points(:,2), mesh.Points(:,3));
shp.Alpha = criticalAlpha(shp, 'one-region');

inside_mask = inShape(shp, X(:), Y(:), Z(:));
vol_mask = reshape(inside_mask, [nx ny nz]);

fprintf('Voxelization complete. Filled volume fraction: %.2f%%\n\n', ...
        100 * mean(vol_mask(:)) );


%% 5. Assign attenuation coefficients


mu_background = 0.18;   % 1/m
mu_fetus      = 0.22;   % 1/m

mu = ones(nx, ny, nz) * mu_background;
mu(vol_mask == 1) = mu_fetus;


%% 6. Save phantom


save(output_path, ...
    'mu', 'vol_mask', ...
    'x_vec', 'y_vec', 'z_vec', ...
    'dx');

fprintf('Phantom saved successfully:\n%s\n\n', output_path);


%% 7. Quick visualization

figure;
mid = round(nz/2);
imagesc(y_vec, x_vec, squeeze(vol_mask(:,:,mid)));
axis image;
colormap gray;
colorbar;
title('Phantom Mid-Z Slice');
xlabel('Y (m)');
ylabel('X (m)');
