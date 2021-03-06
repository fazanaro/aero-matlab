function [DuDt] = MatDev(u,u_old,c,dtdx)
% This function evaluates the material Derivate:  Du/Dt = du/dt + c du/dx
% in this function, u and u_next must be vector arrays of the same size.

strategy = 1;
switch strategy
    case{1} % Upwind
        [cu_left,cu_right] = Upwindflux1d(u,c); % Compute Upwind Fluxes
        DuDt = (u - u_old) + dtdx.*(cu_right-cu_left);
    case{2} % TVD
        [r] = theta1d(u,c); % Compute the smoothness factors, r(j)
        [phi] = fluxlimiter1d(r,1); % Flux Limiter: {1} Van Leer Limiter
        [cu_left,cu_right] = TVDflux1d(u,c,dtdx,phi); % Compute TVD Fluxes
        DuDt = (u - u_old) + dtdx.*(cu_right-cu_left);
    case{3} % WENO3
        [vp,vn] = WENO_scalarfluxsplit(c*u); % Slip Positive and Negative Scalar Fluxes
        [cu_left,cu_right] = WENO3_1d_driver(vp,vn); % Compute WENO3 Fluxes
        DuDt = (u - u_old) + dtdx.*(cu_right-cu_left);
end