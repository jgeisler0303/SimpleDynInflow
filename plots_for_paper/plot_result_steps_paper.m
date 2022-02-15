fst_file= '../example_data/sim/coh_URef-4_maininput.fst';
% load('allStepsFromNeighbours.mat')
% load('sol_dyn_cp.mat')
% load('sol_dyn_cp_lin.mat')

variant= 'sq';

data.A1_opt= sol.a;
data.TT= sol_tt.tt;
data.DCP2= sol.dcp_da;
data.CP1= CP1;

tiledlayout(2, 2)
nexttile
llam= [11 12];
tth= [0 0];
spd= llam(1)*6/data.R(end);
vv= [6 spd*data.R(end)/llam(2)];
vv= [5, 5];
plotStep(fst_file, data, llam, tth, vv, variant, 'Step in \lambda from 12 to 11 at {V_0}=5m/s, \theta=0°')

nexttile
llam= [7 6];
tth= [0 0];
spd= llam(1)*6/data.R(end);
vv= [6 spd*data.R(end)/llam(2)];
vv= [9, 9];
plotStep(fst_file, data, llam, tth, vv, variant, 'Step in \lambda from 6 to 7 at {V_0}=9m/s, \theta=0°')

nexttile
llam= [5 5];
tth= [1 0];
spd= llam(1)*6/data.R(end);
vv= [6 spd*data.R(end)/llam(2)];
vv= [13, 13];
plotStep(fst_file, data, llam, tth, vv, variant, 'Step in \theta from 0° to 1° at {V_0}=13m/s, \lambda=5')

nexttile
llam= [4 4];
tth= [6 5];
spd= llam(1)*6/data.R(end);
vv= [6 spd*data.R(end)/llam(2)];
vv= [16, 16];
plotStep(fst_file, data, llam, tth, vv, variant, 'Step in \theta from 5° to 6° at {V_0}=16m/s, \lambda=4')

lg= legend('Orientation', 'horizontal');
lg.Layout.Tile = 'South';

set(gcf, 'PaperSize', [16, 10]);
set(gcf, 'PaperPosition', [0 0 16, 10]);
print('result_steps_paper', '-dpdf', '-r300', '-painters')

function plotStep(fst_file, data, llam, tth, vv, variant, tit)
outputs.normal= {'RtTSR', 'RtVAvgxh', 'RtAeroCp', 'RtAeroCq', 'RtAeroCt'};
outputs.all= {'AxInd', 'TnInd', 'Cx', 'Cy', 'VRel', 'Alpha'};
[~, ~, ~, ~, ad_step]= stepFromNeighboursAD(fst_file, data, llam, tth, vv, outputs, false);

plot(ad_step.Time, ad_step.RtAeroCp.Data, 'DisplayName', 'AD simulation')
hold on

Ts= 0.1;
t= (0:Ts:50)';
idx10= find(t>10, 1);
WndSpeed= zeros(size(t));
RotSpd= zeros(size(t));
Pitch= zeros(size(t));
Pitch(t<=10)= tth(2);
Pitch(t>10)= tth(1);
WndSpeed(t<=10)= vv(2);
WndSpeed(t>10)= vv(1);
RotSpd(t<=10)= llam(2)*WndSpeed(t<=10)/data.R(end);
RotSpd(t>10)= llam(1)*WndSpeed(t>10)/data.R(end);
[cp_dyn, cp]= simDynInflow(data, t, WndSpeed, RotSpd, Pitch, variant);

plot(t, cp_dyn, 'DisplayName', 'simplified model')
plot(t, cp, 'DisplayName', 'qs model')
title(tit)
xlabel('time in s')
ylabel('c_p')
grid on


end