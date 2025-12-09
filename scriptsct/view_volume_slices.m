function view_volume_slices()
% view_volume_slices  for axial, coronal, sagittal planes

%% File paths 
phantom_file = fullfile('D:', 'Profiles', 'jib7395', 'Downloads', ...
    'astra-toolbox-2.4.0-matlab-win-x64', 'astra-2.4.0', 'data', 'output', ...
    'phantom_data.mat');
recon_file = fullfile('D:', 'Profiles', 'jib7395', 'Downloads', ...
    'astra-toolbox-2.4.0-matlab-win-x64', 'astra-2.4.0', 'data', 'output', ...
    'phantom_data_recon3D.mat');

%% Load data 

S_phantom = load(phantom_file, 'mu');
S_recon   = load(recon_file, 'reconVol');

mu        = S_phantom.mu;      % phantom volume
reconVol  = S_recon.reconVol;  % reconstructed volume

%% Normalize for display
mu_norm    = mu / max(mu(:));
recon_norm = reconVol / max(reconVol(:));

%% Get central slice indices
[nx, ny, nz] = size(mu);
cx = round(nx/2);
cy = round(ny/2);
cz = round(nz/2);

%% Extract central slices 
phantom_axial    = squeeze(mu_norm(:,:,cz));
recon_axial      = squeeze(recon_norm(:,:,cz));

phantom_coronal  = squeeze(mu_norm(:,cy,:));
recon_coronal    = squeeze(recon_norm(:,cy,:));

phantom_sagittal = squeeze(mu_norm(cx,:,:));
recon_sagittal   = squeeze(recon_norm(cx,:,:));

%% Display slices
figure('Name','Phantom vs Reconstruction','Color','w','Position',[200 200 1400 800]);

slice_titles = { 'Axial (phantom)', 'Axial (recon)', ...
                 'Coronal (phantom)', 'Coronal (recon)', ...
                 'Sagittal (phantom)', 'Sagittal (recon)' };

slice_images = { phantom_axial,    recon_axial, ...
                 phantom_coronal,  recon_coronal, ...
                 phantom_sagittal, recon_sagittal };

for k = 1:6
    subplot(2,3,k);
    imagesc(slice_images{k});
    axis image off;
    colormap(gray);
    title(slice_titles{k});
end

sgtitle('Phantom vs Reconstruction (Central Slices)','FontSize',16);

fprintf('\nVisualization Complete.\n');
fprintf('Phantom size: %s\n', mat2str(size(mu)));
fprintf('Reconstruction size: %s\n', mat2str(size(reconVol)));
end
