
clear; clc;


input_file = fullfile('data', 'output', 'phantom_data.mat');
if ~isfile(input_file), error('Run make_phantom.m first!'); end
data = load(input_file);

fprintf('Original Grid: [%d x %d x %d]\n', size(data.vol_mask));
fprintf('Downsampling to 64x64x64 for feasible 3D MRI simulation...\n');


% We use 'nearest' to keep the mask binary (0 or 1), no blurry edges
target_dim = [64, 64, 64];
vol_3d_small = imresize3(data.vol_mask, target_dim, 'nearest');


scale_ratio = size(data.vol_mask, 1) / target_dim(1);
new_dx = data.dx * scale_ratio;


% Initialize Background (Water)
Rho = ones(size(vol_3d_small)) * 1.0; 
T1  = ones(size(vol_3d_small)) * 3.0; 
T2  = ones(size(vol_3d_small)) * 0.2; 
T2Star = ones(size(vol_3d_small)) * 0.05; 


tissue_mask = (vol_3d_small == 1);
Rho(tissue_mask) = 0.8;
T1(tissue_mask)  = 0.9;
T2(tissue_mask)  = 0.05;
T2Star(tissue_mask) = 0.03;

% Add 3D Speckle Noise, because it's fun!
Rho(tissue_mask) = Rho(tissue_mask) .* (1 + 0.05 * randn(sum(tissue_mask(:)), 1));

%% 4. Create VObj Structure
VObj = struct();
VObj.Name = 'Fetus_3D_LowRes';
VObj.Model = 'Normal';
VObj.Gyro = 267522187.44;

VObj.XDim = target_dim(1);
VObj.YDim = target_dim(2);
VObj.ZDim = target_dim(3); % Now it has actual Z-depth!
VObj.XDimRes = new_dx;
VObj.YDimRes = new_dx;
VObj.ZDimRes = new_dx;

VObj.Rho = double(Rho);
VObj.T1  = double(T1);
VObj.T2  = double(T2);
VObj.T2Star = double(T2Star);

VObj.ECon = zeros(size(Rho)); 
VObj.MassDen = zeros(size(Rho)); 
VObj.MagSus = zeros(size(Rho)); 

%% 5. Save
output_path = fullfile('data', 'output', 'mrilab_phantom_3d.mat');
save(output_path, 'VObj');
fprintf('Success! 3D Phantom saved to: %s\n', output_path);
