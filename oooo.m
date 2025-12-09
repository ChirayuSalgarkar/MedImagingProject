clear; clc;

Y_beta = -7.8;
Y_r    = 2.47;
N_beta = 0.64;
N_r    = -0.34;
u0     = 154;

A11 = Y_beta / u0;
A12 = -(1 - (Y_r / u0));
A21 = N_beta;
A22 = N_r;

A_DR = [A11, A12; 
        A21, A22];

roots_DR = eig(A_DR);

[wn_vec, zeta_vec, poles] = damp(A_DR);

wn = wn_vec(1);
zeta = zeta_vec(1);

damp(A_DR);
