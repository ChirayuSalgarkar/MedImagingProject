function recon_volume_2dFBP()
  
    % Simple 2D BP reconstruction for each slice of a 3D phantom
    % Uses MATLAB radon/iradon
    

    % --- Default phantom path ---
    phantomFile = fullfile('D:', 'Profiles', 'jib7395', 'Downloads', ...
        'astra-toolbox-2.4.0-matlab-win-x64', 'astra-2.4.0', 'data', 'output', ...
        'phantom_data.mat');

    if ~isfile(phantomFile)
        error('phantom_data.mat not found at: %s', phantomFile);
    end

    % Load phantom 
    data = load(phantomFile);
    if isfield(data, 'mu')
        vol = data.mu;      
    elseif isfield(data, 'vol')
        vol = data.vol;
    else
        error('phantom_data.mat must contain variable "mu" or "vol"');
    end

    % Setup
    [Nx, Ny, Nz] = size(vol);
    theta = 0:1:179; % 180 projection angles
    reconVol = zeros(Nx, Ny, Nz);

    % Loop through slices
    for i = 1:Nz
        slice = vol(:, :, i);

        % Forward projection
        sino = radon(slice, theta);

        % FBP Reconstruction
        recon = iradon(sino, theta, 'linear', 'Ram-Lak', 1, max(Nx, Ny));

        % Resize back to original slice size if needed
        if size(recon,1) ~= Nx || size(recon,2) ~= Ny
            recon = imresize(recon, [Nx, Ny]);
        end

        reconVol(:, :, i) = recon;
    end

    % Save output 
    outFile = fullfile(fileparts(phantomFile), 'phantom_data_recon3D.mat');
    save(outFile, 'reconVol', 'vol');
    fprintf('Reconstruction complete. Saved to: %s\n', outFile);
end
