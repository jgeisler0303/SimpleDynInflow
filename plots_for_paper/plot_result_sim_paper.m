fst_file= '../example_data/sim/coh_URef-4_maininput.fst';
sim_dir= '../example_data/sim';
% load('aerodata.mat')
% load('allStepsFromNeighbours.mat')
% load('sol_dyn_cp.mat')
% load('sol_dyn_cp_lin.mat')

AxInd= aerofields.AxInd;
TnInd= aerofields.TnInd;

variant= 'sq';

data.A1_opt= sol.a;
data.TT= sol_tt.tt;
data.DCP2= sol.dcp_da;
data.CP1= CP1;

%% result_sum_paper
tiledlayout(2, 2)
nexttile
plotSim(fst_file, sim_dir, data, AxInd, TnInd, variant, 6);

nexttile
plotSim(fst_file, sim_dir, data, AxInd, TnInd, variant, 10);

nexttile
plotSim(fst_file, sim_dir, data, AxInd, TnInd, variant, 12);

nexttile
plotSim(fst_file, sim_dir, data, AxInd, TnInd, variant, 18);

lg= legend('Orientation', 'horizontal');
lg.Layout.Tile = 'South';

set(gcf, 'PaperSize', [16, 10]);
set(gcf, 'PaperPosition', [0 0 16, 10]);
print('result_sim_paper', '-dpdf', '-r300', '-painters')

%% result_sum_paper
vv= 5:20;
rmse_dyn_cp= zeros(length(vv), 1);
rmse_bcp= zeros(length(vv), 1);
rmse_no_dyn= zeros(length(vv), 1);
for i= 1:length(vv)
    v= vv(i);
    [rmse_dyn_cp(i), rmse_bcp(i), rmse_no_dyn(i)]= plotSim(fst_file, sim_dir, data, AxInd, TnInd, variant, v);
end

tiledlayout(2, 1)
nexttile
bar(vv, [rmse_dyn_cp rmse_bcp rmse_no_dyn])
ylabel('RMS difference of c_p')
grid on
lg= legend('simplified model', 'bcp model', 'qs model', 'Orientation', 'horizontal');
lg.Layout.Tile = 'South';

nexttile
bar(vv, [rmse_dyn_cp./rmse_no_dyn, rmse_bcp./rmse_no_dyn])
grid on
xlabel('mean wind speed in m/s')
ylabel('relative improvement')


set(gcf, 'PaperSize', [16, 10]);
set(gcf, 'PaperPosition', [0 0 16, 10]);
print('result_sum_paper', '-dpdf', '-r300', '-painters')

%%
function [rmse_dyn_cp, rmse_bcp, rmse_no_dyn]= plotSim(fst_file, sim_dir, data, AxInd, TnInd, variant, v)
outputs.normal= {'RtTSR', 'RtVAvgxh', 'RtAeroCp', 'RtAeroCq', 'RtAeroCt'};
outputs.all= {'AxInd', 'TnInd', 'Cx', 'Cy', 'VRel', 'Alpha'};
w_type= 'coh';

d_dyn= loadFAST(fullfile(sim_dir, sprintf('%s_URef-%d_maininput.outb', w_type, v)));

ext_file_name= sprintf('ext_data_%s_v%02d.mat', w_type, v);
if exist(['./' ext_file_name], 'file')
    load(ext_file_name)
else
    d_qs= aerodynSimFASTqs(d_dyn, fst_file, [], outputs);
    bcp= beyond_cp(d_dyn, data, AxInd, TnInd);
    
    save(ext_file_name, 'bcp', 'd_qs');
end

cp_dyn= simDynInflowFAST(data, d_dyn, variant);

%% Plot
idx_t100= d_dyn.Time>100;

plot(d_dyn.Time(idx_t100), d_dyn.RtAeroCp.Data(idx_t100), 'DisplayName', 'OpenFAST simulation')
hold on
plot(d_dyn.Time(idx_t100), cp_dyn(idx_t100), 'DisplayName', 'simplified model')
plot(d_dyn.Time(idx_t100), bcp.cp(idx_t100), 'DisplayName', 'bcp model')
plot(d_qs.Time(idx_t100), d_qs.RtAeroCp.Data(idx_t100), 'DisplayName', 'qs model')
grid on

xlim([300 350])
xlabel('time in s')
ylabel('c_p')

title(sprintf('{V_0}=%d m/s', v))

e_dyn_cp3= cp_dyn-d_dyn.RtAeroCp.Data;
e_bcp= bcp.cp-d_dyn.RtAeroCp.Data;
e_no_dyn= d_qs.RtAeroCp.Data-d_dyn.RtAeroCp.Data;

rmse_dyn_cp= rms(e_dyn_cp3(idx_t100));
rmse_bcp= rms(e_bcp(idx_t100));
rmse_no_dyn= rms(e_no_dyn(idx_t100));

end