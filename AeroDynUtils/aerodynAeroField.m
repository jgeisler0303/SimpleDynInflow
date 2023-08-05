% AERODYNAEROFIELD Calculate simulation data for a range of TSRs and pitch angles
%
% This function calls the OpenFAST AeroDyn driver to calculate steady
% state data for the desired outputs for a whole range of tip speed ratios
% and pitch angles. The wind speed is chosen automatically to reasonable 
% values matching the TSR.
% The function expects the environment variable "AD_DRIVER" to point to the
% AeroDyn driver executable program.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   LAM         vector of tip speed ratios to calculate values for
%   TH          vector of pitch angles to calculate values for in degrees
%   FST_file    name of the FAST main parameter file
%   outputs     (default: leave AD_file unchanged)
%               structure with fields "normal", "all" and "num_bld".
%               "normal" must be a cell array of strings defining the
%               desired normal AeroDyn outputs defined in 
%               OutListParameters.xlsx.
%               "all" must be a cell array of strings defining outputs for
%               all blade stations as defined in ad_output_channel.pdf.
%               "num_bld" must be an integer defining the number of blades
%               for which to output all blade stations.
%   param       Parameters for overriding values in the configuration files
%               and for the simulation, including:
%       HubHt       (default: 100) hub height to use in meters
%       ShearExp    (default: 0.2) shear exponent to use
%       Yaw         (default: 0) yaw angle to use in degrees
%       dT          (default: value from AeroDyn file or 0.05 s)
%                   time interval for aerodynamic calculations
%       Tmax        (default: 13*dT) end time for the simulations
%
% Outputs:
%   aerodyndata structure array with first dimension corresponding to the
%               length of LAM and the second dimension corresponding to the
%               length of TH with fields corresponding to the desired
%               simulation output values
%   t           vector of time values corresponding to the simulation
%               results of the individual outputs

function [aerodyndata, t]= aerodynAeroField(LAM, TH, FST_file, outputs, param)

if isempty(getenv('AD_DRIVER'))
    error('The environment variable AD_DRIVER must be set to the path of aerodyn_driver')
end

if ~exist('param', 'var')
    param= struct();
end

if ~isfield(param, 'HubHt')
    param.HubHt= 100;
end

if ~isfield(param, 'ShearExp')
    param.ShearExp= 0.2;
end

if ~isfield(param, 'Yaw')
    param.Yaw= 0;
end

FST= FAST2Matlab(FST_file);
old_dir= cd(fileparts(FST_file));
fst_dir= pwd;
cd(old_dir)

AD_file= strrep(GetFASTPar(FST, 'AeroFile'), '"', '');
if AD_file(1)~=filesep || ~isempty(find(AD_file==':', 1))
    AD_file= fullfile(fst_dir, AD_file);
end
ED_file= strrep(GetFASTPar(FST, 'EDFile'), '"', '');
if ED_file(1)~=filesep || ~isempty(find(ED_file==':', 1))
    ED_file= fullfile(fst_dir, ED_file);
end

if exist('outputs', 'var') && ~isempty(outputs)
    ad_file= tempname(fileparts(AD_file));
    writeADOutputs(AD_file, outputs, ad_file)
    AD_file= ad_file;
    c = onCleanup(@()delete(AD_file));
end

AD= FAST2Matlab(AD_file);
DTAero= GetFASTPar(AD, 'DTAero');
DTAeroNum= str2double(strrep(DTAero, '"', ''));
if ~isfield(param, 'dT')
    if ~isnan(DTAeroNum)
        dT= DTAeroNum;
    else
        dT= 0.05;
    end
else
    dT= param.dT;
    if ~isnan(DTAeroNum)
        if DTAeroNum~=param.dT
            warning('dT ~= DTAero from AD file, using DTAero= %f from AD file', DTAero);
            dT= DTAero;
        end
    end
end

if ~isfield(param, 'Tmax')
    param.Tmax= 13*dT;
end


driver= FAST2Matlab('ad_driver.inp');
ED= FAST2Matlab(ED_file);
ADBld_file= strrep(GetFASTPar(AD, 'ADBlFile(1)'), '"', '');
ADBld = FAST2Matlab(fullfile(fileparts(AD_file), ADBld_file));
R= getFASTTableColumn(ADBld.BldNode, 'BlSpn') + GetFASTPar(ED, 'HubRad');

driver= SetFASTPar(driver, 'AeroFile', ['"' AD_file '"']);

driver= setParam(driver, 'NumBlades(1)', GetFASTPar(ED, 'NumBl'), param);
driver= setParam(driver, 'HubRad(1)', GetFASTPar(ED, 'HubRad'), param);
driver= setParam(driver, 'HubHt(1)', param.HubHt, param);
driver= setParam(driver, 'Overhang(1)', GetFASTPar(ED, 'Overhang'), param);
driver= setParam(driver, 'ShftTilt(1)', GetFASTPar(ED, 'ShftTilt'), param);
driver= setParam(driver, 'Precone(1)', GetFASTPar(ED, 'PreCone(1)'), param);
driver= setParam(driver, 'Twr2Shft(1)', GetFASTPar(ED, 'Twr2Shft'), param);

driver= SetFASTPar(driver, 'OutFmt', '"ES16.6"');

[LLAM, TTH]= meshgrid(LAM, TH);
WIND= interp1([0 4 10 100], [40 14 5 0], LLAM);
SPD= LLAM.*WIND./R(end) /pi*30;

driver.Cases.Table= zeros(numel(LLAM), 7);
driver.Cases.Table(:, 1)= WIND(:);
driver.Cases.Table(:, 2)= param.ShearExp;
driver.Cases.Table(:, 3)= SPD(:);
driver.Cases.Table(:, 4)= TTH(:);
driver.Cases.Table(:, 5)= param.Yaw;
driver.Cases.Table(:, 6)= dT;
driver.Cases.Table(:, 7)= param.Tmax;
driver.Cases.Table(:, 8)= 0; % DOF
driver.Cases.Table(:, 9)= 0; % Amplitude
driver.Cases.Table(:, 10)= 1; % Frequency

driver= SetFASTPar(driver, 'NumCases', size(driver.Cases.Table, 1));

tdir= tempdir;
tfile= fullfile(tdir, 'aerodynAeroField.inp');
Matlab2FAST(driver, 'ad_driver.inp', tfile, 2)

[res, str]= system([getenv('AD_DRIVER') ' ', tfile]);
if res
    error(str)
end

aerodyndata= [];
for i= 1:size(driver.Cases.Table, 1)
    evalc('d= loadFAST(fullfile(tdir, sprintf(''aerodynAeroField.%d.outb'', i)));');
    [i_th, i_lam]= ind2sub(size(LLAM), i);
    ChanName= d.gettimeseriesnames;
    for j= 1:length(ChanName)
        aerodyndata(i_lam, i_th).(ChanName{j})= d.(ChanName{j}).Data;
    end
end

t= d.Time;

function data= setParam(data, label, default, param)
if isfield(param, label)
    val= param.(label);
else
    val= default;
end
data= SetFASTPar(data, label, val);