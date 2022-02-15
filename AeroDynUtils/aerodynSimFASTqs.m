% aerodynSimFASTqs Simulate a single time steady state series with the AeroDyn driver
%           using an OpenFAST simulation as refernce
%
% This functions calls the OpenFAST AeroDyn driver to simulate a single
% time series for given sequences of wind speed, rotor speed and pitch
% angle which are read from an existing full OpenFAST simulation result
% file. The function loads the reference simulation and then calls
% aerodynSim. The function modifies the OpenFAST configuration files to 
% produce steady state simulation results.
% The function expects the environment variable "AD_DRIVER" to point to the
% AeroDyn driver executable program.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   FASTSim     a timeseries collection object as returned by loadFAST or a
%               string name of the reference simulation file
%               spaced).
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
% See also: AERODYNSIM, LOADFAST, TSCOLLECTION, TIMESERIES

function d= aerodynSimFASTqs(FASTSim, FST_file, HubHt, outputs)

if ~exist('HubHt', 'var') || isempty(HubHt)
    HubHt= 100;
end

if ~exist('outputs', 'var')
    outputs= [];
end

if isa(FASTSim, 'tscollection')
    f= FASTSim;
else
    f= loadFAST(FASTSim);
end

try
    wind= f.RtVAvgxh.Data;
catch e
    error('FAST simulation must contain sensor "RtVAvgxh"\n');
end
try
    speed= f.LSSTipVxa.Data;
catch e
    error('FAST simulation must contain sensor "LSSTipVxa"\n');
end
try
    pitch= f.BldPitch1.Data;
catch e
    error('FAST simulation must contain sensor "BldPitch1"\n');
end

FST= FAST2Matlab(FST_file);
fst_dir= fileparts(FST_file);

AD_file= strrep(GetFASTPar(FST, 'AeroFile'), '"', ''));
adDataOut= FAST2Matlab(fullfile(fst_dir, AD_file));
adDataOut= SetFASTPar(adDataOut, 'WakeMod', 1);
adDataOut= SetFASTPar(adDataOut, 'AFAeroMod', 1);
adDataOut= SetFASTPar(adDataOut, 'TwrPotent', 0);
adDataOut= SetFASTPar(adDataOut, 'TwrShadow', 'False');
adDataOut= SetFASTPar(adDataOut, 'TwrAero', 'False');
ad_tfile= [AD_file '.tmp'];
ad_tpath= fullfile(fst_dir, ad_tfile);
FST= SetFASTPar(FST, 'AeroFile', ad_tfile);
Matlab2FAST(adDataOut, fullfile(fst_dir, AD_file), ad_tpath)

ED_file= strrep(GetFASTPar(FST, 'EDFile'), '"', '');
edDataOut= FAST2Matlab(fullfile(fst_dir, ED_file));
edDataOut= SetFASTPar(edDataOut, 'ShftTilt', 0);
edDataOut= SetFASTPar(edDataOut, 'Precone(1)', 0);
edDataOut= SetFASTPar(edDataOut, 'Precone(2)', 0);
edDataOut= SetFASTPar(edDataOut, 'Precone(3)', 0);
ed_tfile= [ED_file '.tmp'];
ed_tpath= fullfile(fst_dir, ad_tfile);
FST= SetFASTPar(FST, 'EDFile', ed_tfile);
Matlab2FAST(edDataOut, fullfile(fst_dir, ED_file), ed_tpath)

fst_tfile= [FST_file '.tmp'];
Matlab2FAST(FST, FST_file, fst_tfile)
c= onCleanup(@()delete_temp({ad_tpath, ed_tpath, fst_tfile}));

d= aerodynSim(f.Time, wind, speed, pitch, fst_tfile, HubHt, outputs);


function delete_temp(names)
for i= 1:length(names)
    delete(names{i})
end