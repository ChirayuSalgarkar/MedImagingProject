clear; clc;

input_file = fullfile('data', 'output', 'phantom_data.mat');
if ~isfile(input_file), error('Run make_phantom.m first!'); end
data = load(input_file);

z_idx = round(size(data.vol_mask, 3) / 2);
slice_mask = data.vol_mask(:, :, z_idx);

fprintf('Converting Slice %d for MRiLab...\n', z_idx);

Rho = ones(size(slice_mask)) * 1.0; 
T1  = ones(size(slice_mask)) * 3.0; 
T2  = ones(size(slice_mask)) * 0.2; 
T2Star = ones(size(slice_mask)) * 0.05;

tissue_mask = (slice_mask == 1);
Rho(tissue_mask) = 0.8;
T1(tissue_mask)  = 0.9;
T2(tissue_mask)  = 0.05;
T2Star(tissue_mask) = 0.03;

Rho(tissue_mask) = Rho(tissue_mask) .* (1 + 0.05 * randn(sum(tissue_mask(:)), 1));

VObj = struct();
VObj.Name = 'Fetus_Phantom';
VObj.Model = 'Normal';
VObj.Gyro = 267522187.44;

VObj.XDim = size(slice_mask, 1);
VObj.YDim = size(slice_mask, 2);
VObj.ZDim = 1; 
VObj.XDimRes = data.dx;
VObj.YDimRes = data.dx;
VObj.ZDimRes = data.dx;

VObj.Rho = double(Rho);
VObj.T1  = double(T1);
VObj.T2  = double(T2);
VObj.T2Star = double(T2Star);

VObj.ECon = zeros(size(Rho)); 
VObj.MassDen = zeros(size(Rho)); 
VObj.MagSus = zeros(size(Rho)); 

output_path = fullfile('data', 'output', 'mrilab_phantom.mat');
save(output_path, 'VObj');
fprintf('Success! MRiLab phantom saved to: %s\n', output_path);
fprintf('You can now load this file in the MRiLab GUI.\n');
