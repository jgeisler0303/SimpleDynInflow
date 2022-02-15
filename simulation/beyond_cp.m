% BEYOND_CP Resimulate a given FAST simulation using the beyond cp approach
%
% This function simulates the aerodynamic load coefficients using the 
% beyond cp approach. The simulation follows the sequence of wind speed,
% rotor speed and pitch angle as previously simulated by OpenFAST.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   d           reference simulation data as loaded by loadFAST
%   data        relevant aerodynamics data as loaded by loadAeroData
%               plus the fields LAM and TH which are the break point
%               vectors for the tables AxInd and TnInd
%   AxInd       steady state axial induction table as calculated by 
%               aerodynAeroField followed by calcMeanField
%   TnInd       steady state tangential induction table as calculated by 
%               aerodynAeroField followed by calcMeanField
%
% Outputs:
%   result      structure with fields Cx, Cy, Cx_qs, Cy_qs, W, W_qs, ct,
%               cm, cp which are the time series of the simulated values as
%               calculated by the beyond cp method.
%
% See also: LOADAERODATA, LOADFAST, AERODYNAEROFIELD, CALCMEANFIELD

function result= beyond_cp(d, data, AxInd, TnInd)

try
    wind= d.RtVAvgxh.Data';
catch e
    error('FAST simulation must contain sensor "RtVAvgxh"\n');
end
try
    speed= d.LSSTipVxa.Data';
    om= speed/30*pi;
catch e
    error('FAST simulation must contain sensor "LSSTipVxa"\n');
end
try
    pitch= d.BldPitch1.Data'/180*pi;
catch e
    error('FAST simulation must contain sensor "BldPitch1"\n');
end

result.Cx= zeros(length(data.R), length(d.Time));
result.Cy= zeros(length(data.R), length(d.Time));
result.Cx_qs= zeros(length(data.R), length(d.Time));
result.Cy_qs= zeros(length(data.R), length(d.Time));
result.W= zeros(length(data.R), length(d.Time));
result.W_qs= zeros(length(data.R), length(d.Time));

[TTH, LLAM]= meshgrid(data.TH, data.LAM);
AxInd_interp= griddedInterpolant(LLAM, TTH, AxInd, 'cubic');
TnInd_interp= griddedInterpolant(LLAM, TTH, TnInd, 'cubic');

CL= zeros(length(data.R), 1);
CD= zeros(length(data.R), 1);
CL_qs= zeros(length(data.R), 1);
CD_qs= zeros(length(data.R), 1);

dt= d.Time(2)-d.Time(1);
for i_t= 1:length(d.Time)
    th= d.BldPitch1.Data(i_t);
    lam= d.RtTSR.Data(i_t);
    
    an_qs= squeeze(AxInd_interp(lam, th));
    at_qs= squeeze(TnInd_interp(lam, th));
    an_qs_bar= mean(an_qs);

    if i_t==1
        vn_bar= wind(i_t)*an_qs_bar;
    end
    
    tau= 1/2 * (1.1*data.R(end))/(wind(i_t) - 1.3*vn_bar);
    
    vn_bar= vn_bar + (1-exp(-dt/tau))*(wind(i_t)*an_qs_bar - vn_bar);   
    
    vn= an_qs/an_qs_bar * vn_bar;
    Vn= wind(i_t) - vn;
    Vn_qs= wind(i_t)*(1-an_qs);
    Vt= (data.R*om(i_t)).*(1+at_qs);
    
    result.W(:, i_t)= sqrt(Vn.^2 + Vt.^2);
    result.W_qs(:, i_t)= sqrt(Vn_qs.^2 + Vt.^2);
    phi= atan(Vn./Vt);
    phi_qs= atan(Vn_qs./Vt);

    for i_n= 1:length(data.R)
        [CL(i_n), CD(i_n)]= clcd(phi(i_n), data, [], pitch(i_t), i_n);
        [CL_qs(i_n), CD_qs(i_n)]= clcd(phi_qs(i_n), data, [], pitch(i_t), i_n);
    end

    result.Cx(:, i_t)= CL.*cos(phi) + CD.*sin(phi);
    result.Cy(:, i_t)= CL.*sin(phi) - CD.*cos(phi);    
    result.Cx_qs(:, i_t)= CL_qs.*cos(phi_qs) + CD_qs.*sin(phi_qs);
    result.Cy_qs(:, i_t)= CL_qs.*sin(phi_qs) - CD_qs.*cos(phi_qs);    
end

Fx_bcp= data.rho/2*repmat(data.chord', length(d.Time), 1).*result.Cx'.*result.W'.^2;
Fy_bcp= data.rho/2*repmat(data.chord', length(d.Time), 1).*result.Cy'.*result.W'.^2;

RtFx_bcp= trapz(data.R, Fx_bcp')'*3;
RtMx_bcp= sum(int_torque_m(Fy_bcp, data.R), 2)*3;

Fwind= data.rho/2 * pi*data.R(end)^2 * wind.^2;
result.ct= RtFx_bcp(:)./Fwind(:);
result.cm= RtMx_bcp(:)./Fwind(:)/data.R(end);
result.cp= result.cm(:).*d.RtTSR.Data(:);
