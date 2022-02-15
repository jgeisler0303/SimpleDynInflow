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
%   HubHt       (default: 100) hub height to use in meters
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
%   aerofields  structure of aerodynamic fields
%
% See also: aerodynAeroField, calcMeanField

function aerofields= aerodynAeroQSField(LAM, TH, FST_file, HubHt, outputs)

if ~exist('HubHt', 'var') || isempty(HubHt)
    HubHt= 100;
end

if ~exist('outputs', 'var')
    outputs= [];
end

FST= FAST2Matlab(FST_file);
fst_dir= fileparts(FST_file);

AD_file= strrep(GetFASTPar(FST, 'AeroFile'), '"', '');
adDataOut= FAST2Matlab(fullfile(fst_dir, AD_file));
adDataOut= SetFASTPar(adDataOut, 'WakeMod', 1);
adDataOut= SetFASTPar(adDataOut, 'AFAeroMod', 1);
adDataOut= SetFASTPar(adDataOut, 'TwrPotent', 0);
adDataOut= SetFASTPar(adDataOut, 'TwrShadow', 'False');
adDataOut= SetFASTPar(adDataOut, 'TwrAero', 'False');
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

aerodyndata= aerodynAeroField(LAM, TH, fst_tfile, HubHt, 0, 0, 0.01, 0.01, outputs);

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
                f(:, :, j, i)= reshape([aerodyndata.(sprintf('B%dN%03d%s', i, j, fieldname))], size(aerodyndata));;
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
    else
        aerofields.(fields{i_field})= reshape([aerodyndata.(fields{i_field})], size(aerodyndata));
    end

end

function delete_temp(names)
for i= 1:length(names)
    delete(names{i})
end