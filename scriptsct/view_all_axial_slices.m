function view_all_axial_slices()
% view_all_axial_slices  | Scroll through all axial slices of the 3D volume

%% --- Load volume ---
vol_file = fullfile('D:', 'Profiles', 'jib7395', 'Downloads', ...
    'astra-toolbox-2.4.0-matlab-win-x64', 'astra-2.4.0', 'data', 'output', ...
    'phantom_data_recon3D.mat');

if ~isfile(vol_file)
    error('Volume file not found: %s', vol_file);
end

S = load(vol_file);

if isfield(S, 'mu')
    volume = S.mu;
elseif isfield(S, 'reconVol')
    volume = S.reconVol;
else
    error('File does not contain mu or reconVol.');
end

%% --- Check volume ---
if ndims(volume) ~= 3
    error('Loaded data is not a 3D volume.');
end

[nx, ny, nz] = size(volume);
fprintf('Loaded volume: %d × %d × %d\n', nx, ny, nz);
fprintf('Displaying all axial slices (1 to %d)...\n', nz);

%% --- Scroll through slices ---
figure('Name','Axial Slices','Color','w');

for k = 1:nz
    imagesc(volume(:,:,k));
    axis image off;
    colormap(gray);
    title(sprintf('Axial slice %d / %d', k, nz), 'FontSize', 14);
    pause(0.2);  % adjust speed of scrolling
end

fprintf('Finished displaying all axial slices.\n');
end
