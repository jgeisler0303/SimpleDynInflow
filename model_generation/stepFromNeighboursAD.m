% stepFromNeighboursAD Calculate step responses from several TSR/pitch angle
% points towards one point
%
% This function calls aerodynSim to calculate the step responses from
% operating points with differen TSRs and pitch angles towards one common
% operating point. The functions returns data that is necessary to derive a
% simplified inflow model.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   fst_file    name of the FAST main parameter file that configures the
%               properties of the blade for which to calculate the values
%   data        relevant aerodynamics data as loaded by loadAeroData
%   lambda      vector of TSRs. The first value is the common step target
%               and all further values are the origines of the steps
%   pitch       vector of pitch angles. The first value is the common step target
%               and all further values are the origines of the steps
%   v_wind      vector of wind speeds. The first value is the common step target
%               and all further values are the origines of the steps
%   outputs     (default: leave AD_file unchanged)
%               structure with fields "normal", "all" and "num_bld".
%               "normal" must be a cell array of strings defining the
%               desired normal AeroDyn outputs defined in 
%               OutListParameters.xlsx.
%               "all" must be a cell array of strings defining outputs for
%               all blade stations as defined in ad_output_channel.pdf.
%               "num_bld" must be an integer defining the number of blades
%               for which to output all blade stations.
%   save_file   flag whether to save the full simulation output in a file
%               (default: true)
%
% Outputs:
%   T           vector of approximated first order decay time constants
%               scaled by the wind speed
%   cp01        vector of cp values directly after the step
%   cp0         vector of cp values directly before the step
%   a0          vector of rotor averaged axial induction factors before step
%   ad_step     structure of simulation data as returned by aerodynSim
%   ba2         vector of approximated second order transfer function numerator and denominator coefficients 
%
% See also: allStepsFromNeighboursAD, aerodynSim, loadAeroData

function [T, cp01, cp0, a0, ad_step, ba2]= stepFromNeighboursAD(fst_file, data, lambda, pitch, v_wind, outputs, save_file)
if ~exist('outputs', 'var')
    outputs= [];
end
if ~exist('save_file', 'var')
    save_file= true;
end

n= length(lambda)-1;

T= nan(1, n);
cp01= nan(1, n);
cp0= nan(1, n);
a0= nan(1, n);

Ts= 0.1;
t= 0:Ts:50;
idx10= find(t>10, 1);

u= zeros(size(t));
u(t>=10)= 1;

WndSpeed= zeros(size(t));
RotSpd= zeros(size(t));
Pitch= zeros(size(t));

for i= 1:n
    file_name= sprintf('ad_step_from_lam%05.2f_th%05.2f_v%05.2f_to_lam%05.2f_th%05.2f_v%05.2f.mat', lambda(1), pitch(1), v_wind(1), lambda(1+i), pitch(1+i), v_wind(1+i));
    if exist(file_name, 'file')
        load(file_name)
    else
        Pitch(t<=10)= pitch(1+i);
        Pitch(t>10)= pitch(1);
        WndSpeed(t<=10)= v_wind(1+i);
        WndSpeed(t>10)= v_wind(1);
        RotSpd(t<=10)= lambda(1+i)*WndSpeed(t<=10)/data.R(end) /pi*30;
        RotSpd(t>10)= lambda(1)*WndSpeed(t>10)/data.R(end) /pi*30;

        ad_step= aerodynSim(t, WndSpeed, RotSpd, Pitch, fst_file, [], outputs);
    end
    
    y= ad_step.RtAeroCq.Data';
    y= y-y(idx10);
    y(t<=10)= 0;
    id= iddata(y', u', Ts);
    sys= tfest(id, 1);
    [~, a]= tfdata(sys, 'v');
    
    T(i)= 1/a(2);
    T(i)= T(i)*v_wind(1);
    
    sys2= tfest(id, 2);
    [b, a]= tfdata(sys2, 'v');
    ba2= [b a];
    
    cp0(i)= ad_step.RtAeroCp.Data(1);
    cp01(i)= ad_step.RtAeroCp.Data(idx10);
    a0(i)= mean(ad_step.B1AxInd.Data(1, :), 'all');
    
    if save_file
        save(file_name, 'ad_step');
    end
end
