% calcNonlinearity Calculate step responses from a grid of TSR/pitch angle
% points towards around one TSR/pitch angle
%
% This function calls stepFromNeighboursAD to calculate the step responses 
% from a grid of operating points with differen TSRs and pitch angles towards
% one common operating point. The functions returns the difference between
% the cp value directly after the step and the steady state value of cp.
% This enables an estimation of the nonlinearity in the difference between
% dynamic and static cp in relation to the step height.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   fst_file    name of the FAST main parameter file that configures the
%               properties of the blade for which to calculate the values
%   lam         TSR towards which the steps are taken
%   th          pitch angle towards which the steps are taken
%   DLAM        vector of relative TSRs that form the grid around lam
%   DTH         vector of relative pitch angles that form the grid around th
%
% Outputs:
%   DCP         matrix of differences between dynamic and static cp values
%
% See also: stepFromNeighboursAD
 
function DCP= calcNonlinearity(fst_file, lam, th, DLAM, DTH)

if ~exist('DLAM', 'var')
    DLAM= -1.25:0.25:1.25;
end
if ~exist('DTH', 'var')
    DTH= -1:0.25:1;
end

outputs.normal= {'RtTSR', 'RtVAvgxh', 'RtAeroCp', 'RtAeroCq', 'RtAeroCt'};
outputs.all= {'AxInd', 'TnInd', 'Cx', 'Cy', 'VRel', 'Alpha'};
data= loadAeroData(fst_file);

aerofields= aerodynAeroQSField(lam, th, fst_file, outputs);
cp1= aerofields.RtAeroCp;

DCP= zeros(length(DLAM), length(DTH));
for i_lam= 1:length(DLAM)
    for i_th= 1:length(DTH)
        if DLAM(i_lam)==0 && DTH(i_th)==0, continue, end
        
        v_wind= interp1([0 4 10 100], [40 14 5 0], lam);

        LLAM= [lam lam+DLAM(i_lam)];
        TTH= [th, th+DTH(i_th)];
        VV= ones(size(TTH))*v_wind;
        
        [~, cp01]= stepFromNeighboursAD(fst_file, data, LLAM, TTH, VV, outputs, false);
        DCP(i_lam, i_th)= cp01-cp1;
    end
end
