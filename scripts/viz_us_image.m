
clear; clc;
load(fullfile('data', 'output', 'sensor_data_us.mat'));


scan_lines = transpose(sensor_data); 

rf_image = scan_lines - mean(scan_lines(:));
envelope = abs(hilbert(rf_image));

dynamic_range = 40; % dB
b_mode = 20 * log10(envelope);
b_mode = b_mode - max(b_mode(:)); % Normalize to 0 dB max
b_mode(b_mode < -dynamic_range) = -dynamic_range;

figure;
imagesc(kgrid.y_vec * 1000, kgrid.x_vec * 1000 - min(kgrid.x_vec * 1000), b_mode);
colormap(gray);
axis image;
title('Reconstructed Ultrasound Image');
xlabel('Lateral Position (mm)');
ylabel('Depth (mm)');
c = colorbar;
c.Label.String = 'Intensity (dB)';

% Helper function for hilbert
function x_a = my_hilbert(x)
    % Computes analytic signal using FFT (works on columns)
    n = size(x, 1);
    fft_x = fft(x);
    h = zeros(n, 1);
    
    if n > 0
        h(1) = 1;
        if mod(n, 2) == 0
            h(2:n/2) = 2;
            h(n/2+1) = 1;
        else
            h(2:(n+1)/2) = 2;
        end
    end
    
    % Replicate h for all columns
    h = repmat(h, 1, size(x, 2));
    x_a = ifft(fft_x .* h);
end