clear; clc;

input_file = fullfile('data', 'output', 'phantom_data.mat');
if ~isfile(input_file), error('Phantom data not found!'); end
data = load(input_file);


z_idx = round(size(data.medium.sound_speed, 3) / 2);
slice_mask = data.vol_mask(:, :, z_idx);

p = setup_params();

Nx = size(slice_mask, 1);
Ny = size(slice_mask, 2);
dx = data.dx; 
kgrid = kWaveGrid(Nx, dx, Ny, dx);


medium.sound_speed = squeeze(data.medium.sound_speed(:, :, z_idx));
medium.density     = squeeze(data.medium.density(:, :, z_idx));
medium.alpha_coeff = squeeze(data.medium.alpha_coeff(:, :, z_idx));
medium.alpha_power = p.us.alpha_power;



sensor.mask = zeros(Nx, Ny);
sensor.mask(1, :) = 1; 


source.p_mask = sensor.mask; 
source_freq = p.us.center_freq; 
source_mag = 1e6; % 1 MPa pressure
tone_burst_cycles = p.us.tone_burst_cycles;


kgrid.makeTime(medium.sound_speed); 
source.p = source_mag * toneBurst(1/kgrid.dt, source_freq, tone_burst_cycles);


fprintf('Running k-Wave 2D Simulation...\n');
fprintf('Grid Size: %d x %d\n', Nx, Ny);


input_args = {'PlotScale', [-1, 1] * source_mag * 0.5, 'PMLInside', false, 'PlotPML', false};


sensor_data = kspaceFirstOrder2D(kgrid, medium, source, sensor, input_args{:});


output_file = fullfile('data', 'output', 'sensor_data_us.mat');
save(output_file, 'sensor_data', 'kgrid', 'medium', 'source_freq');
fprintf('Simulation complete. RF Data saved to %s\n', output_file);

figure;
imagesc(sensor_data);
title('Raw Ultrasound Echo Data (RF)');
xlabel('Sensor Element');
ylabel('Time Step');
colormap(gray);