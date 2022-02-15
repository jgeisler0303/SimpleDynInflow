% LOADFAST Load OpenFAST simulation file into a timeseries collection
%       object
%
% Loads any OpenFAST simulation result file using ReadFASTtext or
% ReadFASTbinary and rearranges the data into a timeseries collection
% object with one timeseries object per output sensor.
% In case the output name is that of an "all blade stations" output, the
% data for all blade stations is aggregated into one timeseries with a
% second dimension with length of the number of blade stations.
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   file_name   name of the OpenFAST simulation result file
%
% Outputs:
%   d           timeseries collection object containing the simulation
%               result with one timeseries object for each output.
%
% See also: READFASTTEXT, READFASTBINARY, TSCOLLECTION, TIMESERIES
 
function d= loadFAST(file_name)
[~, ~, ext]= fileparts(file_name);
if strcmp(ext, '.out')
    [Channels, ChanName, ChanUnit, ~] = ReadFASTtext(file_name);
else
    [Channels, ChanName, ChanUnit, ~, ~] = ReadFASTbinary(file_name);
end
d= tscollection(Channels(:, 1));
[~, d.Name]= fileparts(file_name);
% d.Description= DescStr;

exclude_idx= false(size(ChanName));
for i= 2:length(ChanName)
    if exclude_idx(i)
        continue
    end
    
    res= regexp(ChanName{i}, '(A?)B(\d)N\d{2,3}(.*)', 'tokens', 'once');
    if ~isempty(res)
        idx= regexp(ChanName, sprintf('%sB%sN\\d{2,3}%s', res{1}, res{2}, res{3}), 'once');
        idx= cellfun(@(c)~isempty(c), idx);
            
        name= sprintf('B%s%s', res{2}, res{3});
        unit= ChanUnit{find(idx, 1)};
        exclude_idx= exclude_idx | idx;
    else
        idx= i;
        name= ChanName{i};
        unit= ChanUnit{i};
    end
    
    ts= timeseries(name);
    ts.Time= Channels(:, 1);
    ts.Data= Channels(:, idx);
    ts.DataInfo.Units= unit;
    ts.TimeInfo.Units= 's';
    
    d= d.addts(ts);
end