% scripts/make_phantom_mrilab_master.m
% Purpose: High-Fidelity "Baby Yoda" Phantom Generation for MRiLab
% Features: 128^3 Resolution, Procedural Internal Anatomy, 1.5T Physics


clear; clc; close all;

%% 1. Configuration
% High density for "well setup" simulation. 
GRID_SIZE = 128; 

input_file = fullfile('data', 'input', 'BabyMSR.stl');
output_file = fullfile('data', 'output', 'BabyYoda_MRiLab_128.mat');

%% 2. Load and Voxelize STL
if ~isfile(input_file), error('STL not found at %s', input_file); end
fprintf('Loading STL and generating high-density volume (%dx%dx%d)...\n', GRID_SIZE, GRID_SIZE, GRID_SIZE);

mesh = stlread(input_file);

% Create a tight grid around the object
pad = 0.05 * max(range(mesh.Points)); % 5% padding
x_grid = linspace(min(mesh.Points(:,1))-pad, max(mesh.Points(:,1))+pad, GRID_SIZE);
y_grid = linspace(min(mesh.Points(:,2))-pad, max(mesh.Points(:,2))+pad, GRID_SIZE);
z_grid = linspace(min(mesh.Points(:,3))-pad, max(mesh.Points(:,3))+pad, GRID_SIZE);

[X, Y, Z] = ndgrid(x_grid, y_grid, z_grid);

% Voxelize using alphaShape (Robust method)
shp = alphaShape(mesh.Points);
shp.Alpha = criticalAlpha(shp, 'one-region');
mask_body = inShape(shp, X(:), Y(:), Z(:));
mask_body = reshape(mask_body, size(X));

% Calculate Resolution (dx)
dx = x_grid(2) - x_grid(1);
fprintf('Voxelization Complete. Resolution: %.2f mm\n', dx*1000);

%% 3. Generate Procedural Anatomy (The "In Depth" Part)
% We use Euclidean Distance Transform to find "how deep" inside the model we are.
fprintf('Generating internal organs using distance transforms...\n');

D = bwdist(~mask_body);         % Distance from surface
D_norm = D / max(D(:));         % Normalized 0.0 (Skin) to 1.0 (Center)

% --- Define Anatomical Layers ---
% 1. Skin/Fat: Surface layer (0% - 15% depth)
mask_skin = (D_norm > 0 & D_norm <= 0.15);

% 2. Skull (Bone): A hard shell deep inside (60% - 75% depth)
mask_bone = (D_norm > 0.60 & D_norm <= 0.75);

% 3. Brain (White Matter): The core (75% - 100% depth)
mask_brain = (D_norm > 0.75);

% 4. Soft Tissue (Muscle): The filler between Skin and Bone
mask_muscle = mask_body & ~mask_skin & ~mask_bone & ~mask_brain;

% 5. Air/Background
mask_air = ~mask_body;

%% 4. Assign MRI Physics (1.5 Tesla Values)
%  Physical property justification
fprintf('Assigning T1/T2/Rho values...\n');

Rho = zeros(size(mask_body)); 
T1  = zeros(size(mask_body)); 
T2  = zeros(size(mask_body)); 
T2Star = zeros(size(mask_body));

% --- BACKGROUND (Air) ---
% Air has no signal.
Rho(mask_air) = 0; T1(mask_air) = 0; T2(mask_air) = 0;

% --- SKIN / FAT ---
% Short T1 (Bright), Intermediate T2
Rho(mask_skin) = 0.9; 
T1(mask_skin)  = 0.5;  % 500ms
T2(mask_skin)  = 0.08; % 80ms

% --- MUSCLE ---
% Intermediate T1, Short T2
Rho(mask_muscle) = 0.8;
T1(mask_muscle)  = 0.9;  % 900ms
T2(mask_muscle)  = 0.05; % 50ms

% --- BONE (Skull) ---
% No mobile protons -> No Signal (Black hole)
Rho(mask_bone) = 0.05; 
T1(mask_bone)  = 0.3; 
T2(mask_bone)  = 0.001; % <1ms (Invisible)

% --- BRAIN (High Water Content) ---
% Long T1, Long T2 (Bright on T2-weighted)
Rho(mask_brain) = 0.95;
T1(mask_brain)  = 1.1;  % 1100ms
T2(mask_brain)  = 0.1;  % 100ms

% Add "Bio-Texture" (Speckle Noise)
% Real tissue isnt perfect. This makes it look realistic.
noise = 1 + 0.03 * randn(size(Rho));
Rho(mask_body) = Rho(mask_body) .* noise(mask_body);


%% 5. Pack into VObj Structure for MRiLab
VObj = struct();
VObj.Name = 'BabyYoda_HighFi';
VObj.Model = 'Normal';
VObj.Gyro = 267522187.44; 

% Dimensions
VObj.XDim = GRID_SIZE;
VObj.YDim = GRID_SIZE;
VObj.ZDim = GRID_SIZE;
VObj.XDimRes = dx;
VObj.YDimRes = dx;
VObj.ZDimRes = dx;

% Physics Maps
VObj.Rho = double(Rho);
VObj.T1  = double(T1);
VObj.T2  = double(T2);
VObj.T2Star = double(T2Star);

% Required Fields (Must match Rho size)
VObj.ChemShift = zeros(size(Rho)); 
VObj.ECon = zeros(size(Rho)); 
VObj.MassDen = zeros(size(Rho)); 
VObj.MagSus = zeros(size(Rho)); 

% --- FIX: Add TypeNum AND Type Struct ---
% 1. The Map (Who is where?)
TypeNum = zeros(size(Rho));
TypeNum(mask_skin)   = 1;
TypeNum(mask_muscle) = 2;
TypeNum(mask_bone)   = 3;
TypeNum(mask_brain)  = 4;
VObj.TypeNum = double(TypeNum);

% 2. The Legend (What is what?)
% MRiLab crashes if TypeNum exists but 'Type' struct is missing! update, still broken somehow
VObj.Type = struct();

% Define Tissue 1: Skin
VObj.Type(1).Name = 'Skin';
VObj.Type(1).Color = [1 0.8 0.6]; % Peach

% Define Tissue 2: Muscle
VObj.Type(2).Name = 'Muscle';
VObj.Type(2).Color = [0.8 0.2 0.2]; % Red

% Define Tissue 3: Bone
VObj.Type(3).Name = 'Bone';
VObj.Type(3).Color = [1 1 1]; % White

% Define Tissue 4: Brain
VObj.Type(4).Name = 'Brain';
VObj.Type(4).Color = [0.5 0.5 0.5]; % Gray


%% 6. Save and Verify
save(output_file, 'VObj');
fprintf('SUCCESS: High-Fidelity Phantom saved to %s\n', output_file);

% Quality Control Plot (Visual Check)
figure('Name', 'Phantom Internal Anatomy', 'Color', 'white');
mid_slice = round(GRID_SIZE/2);

subplot(1,3,1); imagesc(Rho(:,:,mid_slice)); axis image; title('Proton Density (Structure)'); colormap gray;
subplot(1,3,2); imagesc(T1(:,:,mid_slice)); axis image; title('T1 Map (Tissue Type)'); colormap hot;
subplot(1,3,3); imagesc(T2(:,:,mid_slice)); axis image; title('T2 Map (Fluidity)'); colormap parula;

sgtitle('Baby Yoda: Internal Procedural Anatomy');
