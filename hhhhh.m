clear; clc;

W = 564000;
Iy = 30.5e6;
S = 5500;
c_bar = 27.3;
V = 280;

CL = 1.11;
CD = 0.102;
CL_alpha = 5.7;
Cm_alpha = -1.26;
Cm_alphadot = -3.2;
Cm_q = -20.8;

g = 32.174;
rho = 0.002377;

m = W / g;
q_bar = 0.5 * rho * V^2;

Z_alpha = -(q_bar * S * CL_alpha) / m;
M_alpha = (q_bar * S * c_bar * Cm_alpha) / Iy;
M_q = (q_bar * S * c_bar^2 * Cm_q) / (2 * V * Iy);
M_alphadot = (q_bar * S * c_bar^2 * Cm_alphadot) / (2 * V * Iy);

X_u = -(2 * CD * q_bar * S) / (m * V);
Z_u = -(2 * CL * q_bar * S) / (m * V);

wn_sp = sqrt((Z_alpha * M_q / V) - M_alpha);
zeta_sp = -(M_q + M_alphadot + (Z_alpha / V)) / (2 * wn_sp);

wn_ph = sqrt( -(Z_u * g) / V );
zeta_ph = -X_u / (2 * wn_ph);

fprintf('Short Period Frequency (wn_sp): %.4f rad/s\n', wn_sp);
fprintf('Short Period Damping (zeta_sp): %.4f\n', zeta_sp);
fprintf('Phugoid Frequency (wn_ph): %.4f rad/s\n', wn_ph);
fprintf('Phugoid Damping (zeta_ph): %.4f\n', zeta_ph);