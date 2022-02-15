% SIMDYNINFLOW Calculate a time series of dynamic cp values for given
%       sequence of wind speed, rotor speed and pitch angle
%
% This function simulates the aerodynamic power coefficient according to
% the new approach for given sequences of wind speed, rotor speed and pitch
% angle.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   data        relevant aerodynamics data as loaded by loadAeroData
%               plus the fields LAM and TH which are the break point
%               vectors for the tables AxInd and TnInd
%               plus fields A1_opt, DCP2 and CP1 that are the parameters of
%               the simplified inflow model
%   time        vector of time values to simulate
%   vwind       vector of wind speed at times t in m/s
%   omega       vector of rotor speed at times t in rad/s
%   tth         vector of pitch angles at times t in degrees
%   variant     string "sq" or "lin" to indicate the taylor approximation
%               scheme used to calculate the parameter tables.
%
% Outputs:
%   cp_dyn      vector of the simulated dynamic power coefficient including
%               the dynamic inflow effect.
%   cp          vector of the simulated steady state power coefficient
%
% See also: LOADAERODATA


function [cp_dyn, cp]= simDynInflow(data, time, vwind, omega, tth, variant)

dt= time(2)-time(1);

tth= min(max(tth, data.TH(1)), data.TH(end));
llam= min(max(omega*data.R(end)./vwind, data.LAM(1)), data.LAM(end));

tt= interp2(data.LAM, data.TH, data.TT', llam, tth) ./ vwind;
aalpha= exp(-dt./(tt));

aa= interp2(data.LAM, data.TH, data.A1_opt', llam, tth, 'spline');
dcp_dv_ind= interp2(data.LAM, data.TH, data.DCP2', llam, tth);

v_ind= vwind.*aa;
v_ind_dyn= zeros(length(time), 1);
v_ind_dyn(1)= v_ind(1);
for i= 2:length(time)
    v_ind_dyn(i)= v_ind_dyn(i-1) + (1-aalpha(i))*(v_ind(i)-v_ind_dyn(i-1));
end

switch variant
    case 'sq'
        Dcp= dcp_dv_ind.*((1-v_ind_dyn./vwind).^2 - (1-aa).^2);
    case 'lin'
        Dcp= dcp_dv_ind.*(v_ind_dyn./vwind - aa);
    otherwise
        error('unknown variant')
end

cp= interp2(data.LAM, data.TH, data.CP1', llam, tth, 'spline');
cp_dyn= cp+Dcp;
