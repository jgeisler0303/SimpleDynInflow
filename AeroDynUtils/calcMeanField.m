% calcMeanField Calculate table data for one output from aerodynAeroField
%
% Calculate the mean value over the time values stored in the output from
% aerodynAeroField simulations for one output sensor to form a table of
% scalar values.
% In case the desired output name is that of an "all blade stations" output,
% the table has a third dimension with one element per blade station.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   aerodyndata output of aerodynAeroField: a structure array with first 
%               dimension corresponding to the length of LAM and the second
%               dimension corresponding to the length of TH with fields 
%               corresponding to the desired simulation output values
%   t           output of aerodynAeroField: vector of time values
%               corresponding to the simulation results of the individual outputs
%   fieldname   name of the output sensor to calculate the table for
%   t_start     time below which to ignore data when calculating the mean
%
% Outputs:
%   f           matrix with the same dimensions as aerodyndata with the
%               averaged data for output "fieldname". In case "fieldname"
%               is an "all blade stations" output, the matrix has a third
%               dimension with one element per blade station
%
% See also: AERODYNAEROFIELD

function f= calcMeanField(aerodyndata, t, fieldname, t_start)

if ~isfield(aerodyndata, fieldname)
    fields= fieldnames(aerodyndata);
    toks= regexp(fields, ['AB(\d)N(\d\d\d)' fieldname], 'tokens');
    idx= cellfun(@(c)~isempty(c), toks, 'UniformOutput', true);
    if sum(idx)==0
        error('"%s" is not a field of aerodyndata', fieldname);
    end
    
    toks= toks(idx);
    max_bld= max(str2double(cellfun(@(c)c{1}{1}, toks, 'UniformOutput', false)));
    max_station= max(str2double(cellfun(@(c)c{1}{2}, toks, 'UniformOutput', false)));
    
    f= zeros([size(aerodyndata), max_station, max_bld]);
    for i= 1:max_bld
        for j= 1:max_station
            f(:, :, j, i)= calcMeanField(aerodyndata, t, sprintf('AB%dN%03d%s', i, j, fieldname), t_start);
        end
    end
    return
end

f= zeros(size(aerodyndata));
for i= 1:size(aerodyndata, 1)
    for j= 1:size(aerodyndata, 2)
        f(i, j)= mean(aerodyndata(i, j).(fieldname)(t>t_start));
    end
end