% aerodynSim Simulate a single time series with the AeroDyn driver
%
% This functions calls the OpenFAST AeroDyn driver to simulate a single
% time series for given sequences of wind speed, rotor speed and pitch
% angle.
% The function expects the environment variable "AD_DRIVER" to point to the
% AeroDyn driver executable program.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   t           vector of time values to be simulated (must be equally
%               spaced).
%   WndSpeed    vector of wind speed at times t in m/s
%   RotSpd      vector of rotor speed at times t in rpm
%   Pitch       vector of pitch angles at times t in degrees
%   FST_file    name of the FAST main parameter file
%   HubHt       (default: 100) hub height to use
%   outputs     (default: leave AD_file unchanged)
%               structure with fields "normal", "all" and "num_bld".
%               "normal" must be a cell array of strings defining the
%               desired normal AeroDyn outputs defined in 
%               OutListParameters.xlsx.
%               "all" must be a cell array of strings defining outputs for
%               all blade stations as defined in ad_output_channel.pdf.
%               "num_bld" must be an integer defining the number of blades
%               for which to output all blade stations.
%
% Outputs:
%   d           timeseries collection object as returned by loadFAST containing the
%               simulation result with one timeseries object for each
%               desired output.
%
% See also: loadFAST, tscollection, timeseries

function d= aerodynSim(t, WndSpeed, RotSpd, Pitch, FST_file, HubHt, outputs)

if isempty(getenv('AD_DRIVER'))
    error('The environment variable AD_DRIVER must be set to the path of aerodyn_driver')
end

if ~exist('HubHt', 'var') || isempty(HubHt)
    HubHt= 100;
end

FST= FAST2Matlab(FST_file);
old_dir= cd(fileparts(FST_file));
fst_dir= pwd;
cd(old_dir)

AD_file= fullfile(fst_dir, strrep(GetFASTPar(FST, 'AeroFile'), '"', ''));
ED_file= fullfile(fst_dir, strrep(GetFASTPar(FST, 'EDFile'), '"', ''));

if exist('outputs', 'var') && ~isempty(outputs)
    ad_file= tempname(fileparts(AD_file));
    writeADOutputs(AD_file, outputs, ad_file)
    AD_file= ad_file;
    c = onCleanup(@()delete(AD_file));
end

driver= FAST2Matlab('ad_driver.inp');
ED= FAST2Matlab(ED_file);

driver= SetFASTPar(driver, 'AD_InputFile', ['"' AD_file '"']);

driver= SetFASTPar(driver, 'NumBlades', GetFASTPar(ED, 'NumBl'));
driver= SetFASTPar(driver, 'HubRad', GetFASTPar(ED, 'HubRad'));
driver= SetFASTPar(driver, 'HubHt', HubHt);
driver= SetFASTPar(driver, 'Overhang', GetFASTPar(ED, 'Overhang'));
driver= SetFASTPar(driver, 'ShftTilt', GetFASTPar(ED, 'ShftTilt'));
driver= SetFASTPar(driver, 'Precone', GetFASTPar(ED, 'PreCone(1)'));

driver= SetFASTPar(driver, 'OutFileRoot', '"aerodynSim"');

driver= SetFASTPar(driver, 'OutFmt', '"ES16.6"');

driver.Cases.Table= {'@aerodynSim_timeseries.inp' [] [] [] [] [] []};
driver.Cases.Comments= {''};

driver= SetFASTPar(driver, 'NumCases', 1);

tdir= tempdir;
tfile= fullfile(tdir, 'aerodynSim.inp');
Matlab2FAST(driver, 'ad_driver.inp', tfile, 2)

fid= fopen(fullfile(tdir, 'aerodynSim_timeseries.inp'), 'w');
fprintf(fid, 'Time   WndSpeed   ShearExp     RotSpd     Pitch          Yaw\n');
fprintf(fid, '(s)   (m/s)       (-)          (rpm)      (deg)         (deg)\n');
for i= 1:length(t)
    fprintf(fid, '%g\t%g\t%g\t%g\t%g\t%g\n', t(i), WndSpeed(i), 0, RotSpd(i), Pitch(i), 0);
end
fclose(fid);

[res, str]= system([getenv('AD_DRIVER') ' ' tfile]);
if res
    error(str)
end

d= loadFAST(fullfile(tdir, 'aerodynSim.out'));