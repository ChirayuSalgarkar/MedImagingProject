function run_ct_parallel2d()
%  2D CT simulation using radon/iradon
%
% Automatically:
%   - loads phantom_data.mat
%   - selects middle slice
%   - performs radon iradon reconstruction
%   - displays original & reconstructed slice
%   - saves results

%% Locate Phantom
base_dir = fullfile('D:', 'Profiles', 'jib7395', 'Downloads', ...
                    'astra-toolbox-2.4.0-matlab-win-x64', ...
                    'astra-2.4.0', 'data', 'output');

vol_file = fullfile(base_dir, 'phantom_data.mat');



S = load(vol_file);
if ~isfield(S, 'mu')
    error('phantom_data.mat must contain variable mu.');
end

mu = S.mu;   
[nx, ny, nz] = size(mu);

%% Select Slice 
slice_index = round(nz / 2);   % automatic middle slice
truth_slice = mu(:,:,slice_index);

fprintf('Running CT on slice %d of %d...\n', slice_index, nz);

%%  Prepare Slice 
% Radon requires square images
N = max(size(truth_slice));
truth_resized = imresize(truth_slice, [N N]);

%% CT Simulation 
angles = 0:1:179;
sinogram = radon(truth_resized, angles);

recon_slice = iradon(sinogram, angles, 'linear', 'Ram-Lak', 1, N);

%%  Display Results 
figure('Name','CT Reconstruction','Color','w','Position',[100 100 1100 500]);

subplot(1,2,1);
imagesc(truth_resized); colormap(gray); axis image off;
title(sprintf('Original Slice (z=%d)', slice_index));

subplot(1,2,2);
imagesc(recon_slice); colormap(gray); axis image off;
title('Reconstructed Slice');

%%  Save Output 
save_path = fullfile(base_dir, ...
    sprintf('ct_slice_%03d_simple.mat', slice_index));

save(save_path, 'truth_resized', 'recon_slice');

fprintf('Saved: %s\n', save_path);
fprintf('CT simulation complete.\n');