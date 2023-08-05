% LOADAERODATA Load relevant aerodynamic data from FAST parameter files
%
% Author: Jens Geisler, Flensburg University of Applied Sciences
%
% Inputs:
%   FST_file    name of the FAST main parameter file
%
% Outputs:
%   data        structure with relevant aerodynamic data

function data= loadAeroData(fst_file)
fst_dir= fileparts(fst_file);
fstDataOut = FAST2Matlab(fst_file);

EDFile= strrep(GetFASTPar(fstDataOut, 'EDFile'), '"', '');
edDataOut = FAST2Matlab(fullfile(fst_dir, EDFile));

AeroFile= strrep(GetFASTPar(fstDataOut, 'AeroFile'), '"', '');
adDataOut = FAST2Matlab(fullfile(fst_dir, AeroFile));

ADBldFile= strrep(GetFASTPar(adDataOut, 'ADBlFile(1)'), '"', '');
adbldDataOut = FAST2Matlab(fullfile(fst_dir, ADBldFile));

data= [];
data.R= getFASTTableColumn(adbldDataOut.BldNode, 'BlSpn') + GetFASTPar(edDataOut, 'HubRad');
data.chord= getFASTTableColumn(adbldDataOut.BldNode, 'BlChord');
data.twist= getFASTTableColumn(adbldDataOut.BldNode, 'BlTwist')/180*pi;
data.airfoil_idx= getFASTTableColumn(adbldDataOut.BldNode, 'BlAFID');
data.rho= GetFASTPar(fstDataOut, 'AirDens');
data.TipLoss= double(strcmpi(GetFASTPar(adDataOut, 'TipLoss'), 'true'));
data.HubLoss= double(strcmpi(GetFASTPar(adDataOut, 'HubLoss'), 'true'));
data.TanInd= double(strcmpi(GetFASTPar(adDataOut, 'TanInd'), 'true'));
data.AIDrag= double(strcmpi(GetFASTPar(adDataOut, 'AIDrag'), 'true'));
data.TIDrag= double(strcmpi(GetFASTPar(adDataOut, 'TIDrag'), 'true'));
data.SkewMod= GetFASTPar(adDataOut, 'SkewMod');
data.SkewModFactor= GetFASTPar(adDataOut, 'SkewModFactor');
data.AeroFile= AeroFile;
data.B= GetFASTPar(edDataOut, 'NumBl');
data.IndToler= GetFASTPar(adDataOut, 'IndToler');
if strcmpi(strrep(data.IndToler, '"', ''), 'default')
    data.IndToler= 1e-6;
end

for i= 1:length(adDataOut.FoilNm)
    AirFoil= FAST2Matlab(fullfile(fst_dir, strrep(adDataOut.FoilNm{i}, '"', '')));
    data.AirFoil(i).alpha= getFASTTableColumn(AirFoil.AFCoeff, 'Alpha')/180*pi;
    data.AirFoil(i).cl= getFASTTableColumn(AirFoil.AFCoeff, 'Cl');
    data.AirFoil(i).cd= getFASTTableColumn(AirFoil.AFCoeff, 'Cd');
end

data.acorr= 0.3;
