% WRITEADOUTPUTS Write aerodyn parameter file with different outputs
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   AD_file     name of the input AeroDyn parameter file
%   outputs     (default: leave AD_file unchanged)
%               structure with fields "normal", "all" and "num_bld".
%               "normal" must be a cell array of strings defining the
%               desired normal AeroDyn outputs defined in 
%               OutListParameters.xlsx.
%               "all" must be a cell array of strings defining outputs for
%               all blade stations as defined in ad_output_channel.pdf.
%               "num_bld" must be an integer defining the number of blades
%               for which to output all blade stations.
%   out_file    name of the target parameter file

function writeADOutputs(AD_file, outputs, out_file)

ifid= fopen(AD_file, 'r');
ofid= fopen(out_file, 'w');

while 1
    l= fgets(ifid);
    if l==-1, break, end
    fprintf(ofid, l);

    if contains(l, 'OutList'), break, end
end

for i= 1:length(outputs.normal)
    if outputs.normal{i}(1)~='"'
        fprintf(ofid, '"%s"\n', outputs.normal{i});
    else
        fprintf(ofid, '%s\n', outputs.normal{i});
    end
end

fprintf(ofid, 'END of input file (the word "END" must appear in the first 3 columns of this last OutList line)\n');

if ~isempty(outputs.all)
    fprintf(ofid, '====== Outputs for all blade stations (same ending as above for B1N1.... =========================== [optional section]\n');
    if ~isfield(outputs, 'num_bld')
        outputs.num_bld= 1;
    end
    fprintf(ofid, '%d              BldNd_BladesOut     - Number of blades to output all node information at.  Up to number of blades on turbine. (-)\n', outputs.num_bld);
    fprintf(ofid, '"All"          BldNd_BlOutNd       - Future feature will allow selecting a portion of the nodes to output.  Not implemented yet. (-)\n');
    fprintf(ofid, '                  OutList             - The next line(s) contains a list of output parameters.  See OutListParameters.xlsx for a listing of available output channels, (-)\n'); % there needs to be an empty line here, maybe a bug in the curretn version of AeroDyn driver
    for i= 1:length(outputs.all)
        if outputs.all{i}(1)~='"'
            fprintf(ofid, '"%s"\n', outputs.all{i});
        else
            fprintf(ofid, '%s\n', outputs.all{i});
        end
    end
    fprintf(ofid, 'END (of optional section)\n');    
end

fclose(ifid);
fclose(ofid);