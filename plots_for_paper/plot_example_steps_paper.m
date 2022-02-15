fst_file= '../example_data/sim/coh_URef-4_maininput.fst';

tiledlayout(1, 2)
nexttile
llam= [7 6];
tth= [1 1];
spd= llam(1)*6/data.R(end);
vv= [6 spd*data.R(end)/llam(2)];
vv= [9, 9];
plotStep(fst_file, data, llam, tth, vv, 'Step in \lambda from 6 to 7 at \theta=1°')


nexttile
llam= [7 7];
tth= [1 0];
spd= llam(1)*6/data.R(end);
vv= [6 spd*data.R(end)/llam(2)];
vv= [9, 9];
plotStep(fst_file, data, llam, tth, vv, 'Step in \theta from 0° to 1° at \lambda=7')

lg= legend('Orientation', 'horizontal');
lg.Layout.Tile = 'South';

set(gcf, 'PaperSize', [16, 6]);
set(gcf, 'PaperPosition', [0 0 16, 6]);
print('example_steps_paper', '-dpdf', '-r300', '-painters')

function plotStep(fst_file, data, llam, tth, vv, tit)
outputs.normal= {'RtTSR', 'RtVAvgxh', 'RtAeroCp', 'RtAeroCq', 'RtAeroCt'};
outputs.all= {'AxInd', 'TnInd', 'Cx', 'Cy', 'VRel', 'Alpha'};

aerofields= aerodynAeroQSField(llam(1), tth(1), fst_file, [], outputs);
cp1= aerofields.RtAeroCp;

[~, cp01, cp0, ~, ad_step]= stepFromNeighboursAD(fst_file, data, llam, tth, vv, outputs, false);

plot(ad_step.Time, ad_step.RtAeroCp.Data, 'DisplayName', 'AD simulation')
hold on
plot([0 10 10 50], [cp0 cp0 cp1 cp1], 'DisplayName', 'qs simulation')
plot([10 10], [cp1 cp01], '-o', 'DisplayName', 'initial dynamic response')
title(tit)
xlabel('time in s')
ylabel('c_p')
grid on

end