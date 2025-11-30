% setup_params.m
% Purpose: Define physical constants for Fetal Imaging Simulation
% Reference: BIME 660 Project - Modality Physics Setup

function params = setup_params()

    %% General Constants
    params.fetal_age_weeks = 20; % Assumption for size scaling

    %% 1. Ultrasound Parameters (Soft Tissue / Fetus)
    % Justification: Fetal soft tissue approximates water/liver properties
    us.c0 = 1540;          % Speed of sound [m/s]
    us.rho0 = 1000;        % Density [kg/m^3]
    us.alpha_coeff = 0.75; % Attenuation [dB/(MHz^y cm)]
    us.alpha_power = 1.5;  % Power law exponent

    % Transducer Settings (Curvilinear for Fetal)
    us.center_freq = 3.5e6; % 3.5 MHz is standard for OB/GYN
    us.tone_burst_cycles = 3;

    %% 2. CT Parameters (If chosen)
    % Hounsfield Units (HU) approximations
    ct.mu_water = 0.019;   % Linear attenuation coeff [1/mm]
    ct.mu_bone = 0.045;    % Fetal bone is less dense than adult
    ct.num_projections = 180;

    %% Pack into output structure
    params.us = us;
    params.ct = ct;

    fprintf('Physics parameters loaded for Fetal Imaging.\n');
end