% aerodynAeroQSField Calculate steady state data for a range of TSRs and pitch angles
%
% This function calls aerodynAeroField to calculate steady state data for
% the desired outputs for a whole range of tip speed ratios and pitch
% angles. The function modifies the OpenFAST configuration files to produce
% steady state simulation results.
% The result from aerodynAeroField is processed by calcMeanField to return
% a structure of aero field tables.
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
%       ShearExp    (default: 0) shear exponent to use
%       Yaw         (default: 0) yaw angle to use in degrees
%       dT          (default: 0.01)
%                   time interval for aerodynamic calculations
%       Tmax        (default: 0.01) end time for the simulations
%
% Outputs:
%   aerofields  structure of aerodynamic fields
%
% See also: aerodynAeroField, calcMeanField

function aerofields= aerodynAeroQSField(LAM, TH, FST_file, outputs, param)

if ~exist('outputs', 'var')
    outputs= [];
end
if ~exist('param', 'var')
    param= struct();
end

if ~isfield(param, 'HubHt')
    param.HubHt= 100;
end
if ~isfield(param, 'ShearExp')
    param.ShearExp= 0;
end
if ~isfield(param, 'Yaw')
    param.Yaw= 0;
end
if ~isfield(param, 'dT')
    param.dT= 0.01;
end
if ~isfield(param, 'Tmax')
    param.Tmax= 0.01;
end


FST= FAST2Matlab(FST_file);
fst_dir= fileparts(FST_file);

AD_file= strrep(GetFASTPar(FST, 'AeroFile'), '"', '');
adDataOut= FAST2Matlab(fullfile(fst_dir, AD_file));
adDataOut= setParam(adDataOut, 'WakeMod', 1, param);
adDataOut= setParam(adDataOut, 'AFAeroMod', 1, param);
adDataOut= setParam(adDataOut, 'TwrPotent', 0, param);
adDataOut= setParam(adDataOut, 'TwrShadow', '0', param);
adDataOut= setParam(adDataOut, 'TwrAero', 'False', param);
ad_tfile= [AD_file '.tmp'];
ad_tpath= fullfile(fst_dir, ad_tfile);
FST= SetFASTPar(FST, 'AeroFile', ad_tfile);
Matlab2FAST(adDataOut, fullfile(fst_dir, AD_file), fullfile(fst_dir, ad_tfile))

ED_file= strrep(GetFASTPar(FST, 'EDFile'), '"', '');
edDataOut= FAST2Matlab(fullfile(fst_dir, ED_file));
edDataOut= SetFASTPar(edDataOut, 'ShftTilt', 0);
edDataOut= SetFASTPar(edDataOut, 'Precone(1)', 0);
edDataOut= SetFASTPar(edDataOut, 'Precone(2)', 0);
edDataOut= SetFASTPar(edDataOut, 'Precone(3)', 0);
ed_tfile= [ED_file '.tmp'];
ed_tpath= fullfile(fst_dir, ed_tfile);
FST= SetFASTPar(FST, 'EDFile', ed_tfile);
Matlab2FAST(edDataOut, fullfile(fst_dir, ED_file), ed_tpath)

fst_tfile= [FST_file '.tmp'];
Matlab2FAST(FST, FST_file, fst_tfile)
c= onCleanup(@()delete_temp({ad_tpath, ed_tpath, fst_tfile}));

aerodyndata= aerodynAeroField(LAM, TH, fst_tfile, outputs, param);

fields= fieldnames(aerodyndata);
for i_field= 1:length(fields)
    if strncmp(fields{i_field}, 'B1N', 3) || strncmp(fields{i_field}, 'B2N', 3) || strncmp(fields{i_field}, 'B3N', 3)
        if ~strncmp(fields{i_field}, 'B1N1', 4), continue, end

        fieldname= fields{i_field}(5:end);
        toks= regexp(fields, ['B(\d)N(\d)' fieldname], 'tokens');
        idx= cellfun(@(c)~isempty(c), toks, 'UniformOutput', true);

        toks= toks(idx);
        max_bld= max(str2double(cellfun(@(c)c{1}{1}, toks, 'UniformOutput', false)));
        max_station= max(str2double(cellfun(@(c)c{1}{2}, toks, 'UniformOutput', false)));
        
        f= zeros([size(aerodyndata), max_station, max_bld]);
        for i= 1:max_bld
            for j= 1:max_station
                f(:, :, j, i)= reshape([aerodyndata.(sprintf('B%dN%03d%s', i, j, fieldname))], size(aerodyndata));
            end
        end
        aerofields.(fieldname)= f;
    elseif strncmp(fields{i_field}, 'AB1N', 3) || strncmp(fields{i_field}, 'AB2N', 3) || strncmp(fields{i_field}, 'AB3N', 3)
        if ~strncmp(fields{i_field}, 'AB1N001', 4), continue, end

        fieldname= fields{i_field}(8:end);
        toks= regexp(fields, ['AB(\d)N(\d\d\d)' fieldname], 'tokens');
        idx= cellfun(@(c)~isempty(c), toks, 'UniformOutput', true);

        toks= toks(idx);
        max_bld= max(str2double(cellfun(@(c)c{1}{1}, toks, 'UniformOutput', false)));
        max_station= max(str2double(cellfun(@(c)c{1}{2}, toks, 'UniformOutput', false)));
        
        f= zeros([size(aerodyndata), max_station, max_bld]);
        for i= 1:max_bld
            for j= 1:max_station
                f(:, :, j, i)= reshape([aerodyndata.(sprintf('AB%dN%03d%s', i, j, fieldname))], size(aerodyndata));
            end
        end
        aerofields.(fieldname)= f;
    elseif strncmp(fields{i_field}, 'B1', 2) || strncmp(fields{i_field}, 'B22', 2) || strncmp(fields{i_field}, 'B3', 2)
        fieldname= fields{i_field}(3:end);
        i_bld= str2double(fields{i_field}(2));

        max_station= size(aerodyndata(1, 1).(fields{i_field}), 2);
        if ~isfield(aerofields, fieldname)
            f= zeros([size(aerodyndata), max_station, 1]);
        else
            f= aerofields.(fieldname);
        end

        f(:, :, :, i_bld)= permute(reshape([aerodyndata.(fields{i_field})], [], size(aerodyndata, 1), size(aerodyndata, 2)), [2 3 1]);
        aerofields.(fieldname)= f;        
    else
        aerofields.(fields{i_field})= reshape([aerodyndata.(fields{i_field})], size(aerodyndata));
    end
end


function delete_temp(names)
for i= 1:length(names)
    delete(names{i})
end

function data= setParam(data, label, default, param)
if isfield(param, label)
    val= param.(label);
else
    val= default;
end
data= SetFASTPar(data, label, val);