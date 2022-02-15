% SIMDYNINFLOWFAST Calculate a time series of dynamic cp values for a given
%       FAST reference simulation
%
% This function simulates the aerodynamic power coefficient according to
% the new approach for given sequences of wind speed, rotor speed and pitch
% angle from a FAST reference.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   data        relevant aerodynamics data as loaded by loadAeroData
%               plus the fields LAM and TH which are the break point
%               vectors for the tables AxInd and TnInd
%               plus fields A1_opt, DCP2 and CP1 that are the parameters of
%               the simplified inflow model
%   d           reference simulation data as loaded by loadFAST
%   variant     string "sq" or "lin" to indicate the taylor approximation
%               scheme used to calculate the parameter tables.
%
% Outputs:
%   cp_dyn      vector of the simulated dynamic power coefficient including
%               the dynamic inflow effect.
%   cp          vector of the simulated steady state power coefficient
%
% See also: LOADAERODATA, SIMDYNINFLOW

function [cp_dyn, cp]= simDynInflowFAST(data, d, variant)
if ischar(d)
    d= loadFAST(d);
end

[cp_dyn, cp]= simDynInflow(data, d.Time, d.RtVAvgxh.Data, d.LSSTipVxa.Data/30*pi, d.BldPitch1.Data, variant);

