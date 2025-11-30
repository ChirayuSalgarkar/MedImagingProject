clc; clear; close all;

% 1. Check if we can load our own parameters
try
    p = setup_params();
    fprintf('[PASS] setup_params.m found. US Speed of Sound: %.2f m/s\n', p.us.c0);
catch
    fprintf('[FAIL] Could not run setup_params.m. Check your "scripts" folder path.\n');
end

% 2. Check if k-Wave is installed
if exist('kWaveGrid', 'class') || exist('kWaveGrid', 'file')
    fprintf('[PASS] k-Wave toolbox found!\n');
else
    fprintf('[FAIL] k-Wave not found. Did you run "addpath(genpath(''lib''))"?\n');
end