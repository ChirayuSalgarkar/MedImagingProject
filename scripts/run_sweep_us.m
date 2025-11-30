% scripts/run_sweep_us.m
% Purpose: Simulate a full 12-slice Ultrasound Sweep of the Fetus
% Reference: Reconstruct image slices from multiple cross-sections 

clear; clc; close all;

%% 1. Configuration
num_slices = 12; % How many slices do you want? (12 fits in a 3x4 grid)
input_file = fullfile('data', 'output', 'phantom_data.mat');
p = setup_params();

%% 2. Load Phantom and Calculate Slices
if ~isfile(input_file), error('Run make_phantom.m first!'); end
data = load(input_file);

% Find the range where the fetus actually exists (ignore empty water)
z_indices = find(squeeze(sum(sum(data.vol_mask, 1), 2)) > 0);
start_idx = z_indices(1);
end_idx = z_indices(end);

% Pick 'num_slices' evenly spaced indices
slice_indices = round(linspace(start_idx, end_idx, num_slices));

fprintf('Starting Sweep Simulation of %d slices...\n', num_slices);
fprintf('Estimated Time: ~%d minutes.\n', round(num_slices * 0.8));

%% 3. Pre-allocate Storage
% We need to know image size first
Nx = size(data.vol_mask, 1);
Ny = size(data.vol_mask, 2);
sweep_volume = zeros(Nx, Ny, num_slices);

%% 4. The Simulation Loop
for i = 1:num_slices
    z_idx = slice_indices(i);
    fprintf('  > Simulating Slice %d/%d (Z-Index: %d)... ', i, num_slices, z_idx);
    
    % --- A. Extract Slice Physics ---
    medium.sound_speed = squeeze(data.medium.sound_speed(:, :, z_idx));
    medium.density     = squeeze(data.medium.density(:, :, z_idx));
    medium.alpha_coeff = squeeze(data.medium.alpha_coeff(:, :, z_idx));
    medium.alpha_power = p.us.alpha_power;

    % --- B. Setup k-Wave Grid ---
    kgrid = kWaveGrid(Nx, data.dx, Ny, data.dx);

    % --- C. Setup Probe (Linear Array at Top) ---
    sensor.mask = zeros(Nx, Ny);
    sensor.mask(1, :) = 1;
    source.p_mask = sensor.mask;
    
    % Source Pulse
    kgrid.makeTime(medium.sound_speed);
    source.p = 1e6 * toneBurst(1/kgrid.dt, p.us.center_freq, p.us.tone_burst_cycles);

    % --- D. Run Simulation (Silent Mode) ---
    % 'PlotSim', false prevents the window from popping up 12 times
    input_args = {'PMLInside', false, 'PlotSim', false, 'PlotPML', false, 'DataCast', 'single'};
    sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor, input_args{:});

    % --- E. Reconstruction (B-Mode) ---
    scan_lines = double(transpose(sensor_data));
    rf = scan_lines - mean(scan_lines(:));
    
    % Envelope Detection (Use built-in or custom)
    try
        env = abs(hilbert(rf));
    catch
        env = abs(my_hilbert_local(rf));
    end
    
    % Log Compression
    img = 20 * log10(env);
    img = img - max(img(:));
    
    img(img < -50) = -50; % -50dB dynamic range
    img_spatial = imresize(img, [Nx, Ny]);
    
    % Store result
    sweep_volume(:, :, i) = img_spatial;
    fprintf('Done.\n');
end

%% 5. Visualization (Montage)
figure('Name', 'Ultrasound Sweep', 'Color', 'white', 'Position', [100, 100, 1200, 800]);

% Create a tiled layout
rows = 3; cols = 4;
t = tiledlayout(rows, cols, 'TileSpacing', 'none', 'Padding', 'compact');

for i = 1:num_slices
    nexttile;
    imagesc(data.dx*1000*(1:Ny), data.dx*1000*(1:Nx), sweep_volume(:,:,i));
    colormap(gray);
    caxis([-50 0]);
    axis image; axis off; % Turn off axes for clean look
    title(sprintf('Slice %d', i), 'FontSize', 8);
end

% Add a shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'Intensity (dB)';

sgtitle(['Fetal Ultrasound Sweep: ' num2str(num_slices) ' Cross-Sections']);
save(fullfile('data', 'output', 'sweep_results.mat'), 'sweep_volume', 'slice_indices');
fprintf('Sweep Complete. Results saved.\n');


function x_a = my_hilbert_local(x)
    n = size(x, 1);
    fft_x = fft(x);
    h = zeros(n, 1);
    if n > 0, h(1) = 1; 
        if mod(n, 2)==0, h(2:n/2)=2; h(n/2+1)=1;
        else, h(2:(n+1)/2)=2; end
    end
    h = repmat(h, 1, size(x, 2));
    x_a = ifft(fft_x .* h);
end