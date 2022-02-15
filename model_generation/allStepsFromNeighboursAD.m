% allStepsFromNeighboursAD Calculate step responses to a grid of TSRs and
%           pitch angles from neighbouring points
%
% This functions calls stepFromNeighboursAD for all combinations over the
% grid of LAM and TH to calculate the step responses from eight points
% equally spaced on an ellipses with radii dlam and dth around every grid
% point. The functions returns the collected data of all step responses
% that is necessary to derive a simplified inflow model via
% optDynInflowModel.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   fst_file    name of the FAST main parameter file that configures the
%               properties of the blade for which to calculate the values
%   LAM         vector of TSR break points of the calculated grid/table
%   TH          vector of pitch angle break points of the calculated grid/table
%   dlam        radius in TSR direction of the ellipse on which the step origines lie
%   dth         radius in pitch angle direction of the ellipse on which the step origines lie
%   mask        matrix of logical values for each grid point, if true the
%               step response is calculated, otherwise not
%
% Outputs:
%   TT          table of mean scaled decay time constants
%   V1          table of wind speeds that are used for the steps simulations
%   CP01        cell matrix of the cp values directly after the step
%   CP0         cell matrix of the cp values directly before the step
%   LAM0        cell matrix of the TSRs before the step (points on the
%               ellipse around the grid point)
%   TH0         cell matrix of the pitch angles before the step (points on the
%               ellipse around the grid point)
%   V0          cell matrix of the wind speeds before the step (points on the
%               ellipse around the grid point)
%   sTT         matrix of the standard deviation of the scaled decay time
%               constants per grid point
%
% See also: stepFromNeighboursAD, optDynInflowModel, loadAeroData

function [TT, V1, CP01, CP0, LAM0, TH0, V0, sTT]= allStepsFromNeighboursAD(fst_file, LAM, TH, dlam, dth, mask)

outputs.normal= {'RtTSR', 'RtVAvgxh', 'RtAeroCp', 'RtAeroCq', 'RtAeroCt'};
outputs.all= {'AxInd', 'TnInd', 'Cx', 'Cy', 'VRel', 'Alpha'};

data= loadAeroData(fst_file);

% angular coordinates of the points around the grid points from which to 
% step to towards the grid points
tt= linspace(0, 2*pi, 9);
tt= tt(1:end-1);

TT= zeros(length(LAM), length(TH));
sTT= zeros(length(LAM), length(TH));
V1= zeros(length(LAM), length(TH));
CP01= cell(length(LAM), length(TH));
CP0= cell(length(LAM), length(TH));
LAM0= cell(length(LAM), length(TH));
TH0= cell(length(LAM), length(TH));
V0= cell(length(LAM), length(TH));

for i_lam= 1:length(LAM)
    for i_th= 1:length(TH)
        if ~mask(i_lam, i_th)
            continue
        end
        
        v_wind= interp1([0 4 10 100], [40 14 5 0], LAM(i_lam));
        XY= [cos(tt)*dlam; sin(tt)*dth]+[LAM(i_lam); TH(i_th)];

        LLAM= [LAM(i_lam) XY(1, :)];
        TTH= [TH(i_th) XY(2, :)];
        VV= ones(size(TTH))*v_wind;
        
        [T, cp01, cp0]= stepFromNeighboursAD(fst_file, data, LLAM, TTH, VV, outputs);
        TT(i_lam, i_th)= mean(T);
        sTT(i_lam, i_th)= std(T);
        V1(i_lam, i_th)= v_wind;
        CP01{i_lam, i_th}= cp01;
        CP0{i_lam, i_th}= cp0;
        LAM0{i_lam, i_th}= LLAM(2:end);
        TH0{i_lam, i_th}= TTH(2:end);
        V0{i_lam, i_th}= VV(2:end);
    end
end
